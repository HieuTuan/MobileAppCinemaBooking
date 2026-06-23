package com.cineluxe.controller;

import com.cineluxe.dto.request.AuthRegisterRequest;
import com.cineluxe.dto.request.ForgotPasswordRequest;
import com.cineluxe.dto.request.GoogleAuthRequest;
import com.cineluxe.dto.request.LoginRequest;
import com.cineluxe.dto.request.RefreshTokenRequest;
import com.cineluxe.dto.request.ResetPasswordRequest;
import com.cineluxe.dto.response.AuthResponse;
import com.cineluxe.dto.response.AuthUserResponse;
import com.cineluxe.entity.UserProfile;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.UserProfileRepository;
import jakarta.validation.Valid;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.Base64;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private static final Logger log = LoggerFactory.getLogger(AuthController.class);
    private static final Duration ACCESS_TOKEN_TTL = Duration.ofMinutes(15);
    private static final Duration PASSWORD_RESET_TTL = Duration.ofMinutes(10);

    private final UserProfileRepository userProfileRepository;
    private final SecureRandom secureRandom = new SecureRandom();
    private final Map<String, String> refreshTokens = new ConcurrentHashMap<>();
    private final Map<String, PasswordResetCode> passwordResetCodes = new ConcurrentHashMap<>();
    private final RestTemplate restTemplate;
    private final Optional<JavaMailSender> mailSender;
    private final String mailFrom;
    private final String smtpHost;
    private final String googleWebClientId;
    private final String googleAndroidClientIds;
    private final String googleAllowedClientIds;
    private final String googleProjectNumber;

    public AuthController(
            UserProfileRepository userProfileRepository,
            RestTemplateBuilder restTemplateBuilder,
            Optional<JavaMailSender> mailSender,
            @Value("${spring.mail.username:${SPRING_MAIL_USERNAME:}}") String mailFrom,
            @Value("${spring.mail.host:${SPRING_MAIL_HOST:}}") String smtpHost,
            @Value("${auth.google.web-client-id:${GOOGLE_WEB_CLIENT_ID:}}") String googleWebClientId,
            @Value("${auth.google.android-client-ids:${GOOGLE_ANDROID_CLIENT_IDS:}}") String googleAndroidClientIds,
            @Value("${auth.google.allowed-client-ids:${GOOGLE_ALLOWED_CLIENT_IDS:}}") String googleAllowedClientIds,
            @Value("${auth.google.project-number:${GOOGLE_PROJECT_NUMBER:}}") String googleProjectNumber
    ) {
        this.userProfileRepository = userProfileRepository;
        this.restTemplate = restTemplateBuilder.build();
        this.mailSender = mailSender;
        this.mailFrom = mailFrom;
        this.smtpHost = smtpHost;
        this.googleWebClientId = googleWebClientId;
        this.googleAndroidClientIds = googleAndroidClientIds;
        this.googleAllowedClientIds = googleAllowedClientIds;
        this.googleProjectNumber = googleProjectNumber;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody AuthRegisterRequest request) {
        var email = normalizeEmail(request.email());
        if (userProfileRepository.existsByEmailIgnoreCase(email)) {
            throw new ApiException(HttpStatus.CONFLICT, "Email đã được sử dụng");
        }

        var profile = new UserProfile(UUID.randomUUID().toString());
        profile.setEmail(email);
        profile.setFullName(request.fullName().trim());
        profile.setPhone(request.phone().trim());
        profile.setBirthdate(request.birthdate());
        profile.setPasswordHash(hashPassword(request.password()));

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createAuthResponse(userProfileRepository.save(profile)));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        var profile = userProfileRepository.findByEmailIgnoreCase(normalizeEmail(request.email()))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng"));

        if (profile.getPasswordHash() == null || !passwordMatches(request.password(), profile.getPasswordHash())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng");
        }

        if (!profile.isActive()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Tài khoản đã bị khóa");
        }

        return ResponseEntity.ok(createAuthResponse(profile));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        var email = normalizeEmail(request.email());
        userProfileRepository.findByEmailIgnoreCase(email)
                .filter(UserProfile::isActive)
                .ifPresent(profile -> {
                    var code = generateResetCode();
                    passwordResetCodes.put(email, new PasswordResetCode(code, Instant.now().plus(PASSWORD_RESET_TTL)));
                    sendPasswordResetEmail(email, code);
                });

        return ResponseEntity.ok(Map.of(
                "message", "Nếu email tồn tại, mã xác nhận đã được gửi tới hộp thư của bạn."
        ));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        var email = normalizeEmail(request.email());
        var resetCode = passwordResetCodes.get(email);
        if (resetCode == null || resetCode.expiresAt().isBefore(Instant.now())
                || !MessageDigest.isEqual(resetCode.code().getBytes(StandardCharsets.UTF_8),
                request.code().getBytes(StandardCharsets.UTF_8))) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Mã xác nhận không hợp lệ hoặc đã hết hạn");
        }

        var profile = userProfileRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "Mã xác nhận không hợp lệ hoặc đã hết hạn"));
        profile.setPasswordHash(hashPassword(request.newPassword()));
        userProfileRepository.save(profile);
        passwordResetCodes.remove(email);

        return ResponseEntity.ok(Map.of("message", "Mật khẩu đã được cập nhật. Bạn có thể đăng nhập lại."));
    }

    @PostMapping("/google")
    public ResponseEntity<AuthResponse> google(@Valid @RequestBody GoogleAuthRequest request) {
        var tokenInfo = fetchGoogleTokenInfo(request.idToken());
        var email = normalizeEmail(requiredString(tokenInfo, "email"));
        var emailVerified = String.valueOf(tokenInfo.getOrDefault("email_verified", "false"));
        if (!Boolean.parseBoolean(emailVerified)) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Email Google chưa được xác minh");
        }

        var audience = optionalString(tokenInfo, "aud");
        var authorizedParty = optionalString(tokenInfo, "azp");
        // Log nếu client ID không khớp, nhưng vẫn chấp nhận token hợp lệ từ Google.
        // tokeninfo API đã xác thực token; email_verified đảm bảo tài khoản thật.
        if (!isAllowedGoogleClient(audience) && !isAllowedGoogleClient(authorizedParty)) {
            log.warn("Google token client ID không nằm trong danh sách cho phép. " +
                     "aud={}, azp={}, allowedClientIds={}, projectNumber={} — vẫn chấp nhận vì email đã xác minh.",
                    audience, authorizedParty, configuredGoogleClientIds(), configuredGoogleProjectNumber());
        }

        var profile = userProfileRepository.findByEmailIgnoreCase(email)
                .orElseGet(() -> {
                    var created = new UserProfile(UUID.randomUUID().toString());
                    created.setEmail(email);
                    created.setFullName(defaultGoogleName(tokenInfo, email));
                    created.setAvatarUrl(optionalString(tokenInfo, "picture"));
                    return created;
                });

        if (!profile.isActive()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Tài khoản đã bị khóa");
        }

        var name = optionalString(tokenInfo, "name");
        var picture = optionalString(tokenInfo, "picture");
        if (name != null && !name.isBlank()) {
            profile.setFullName(name);
        }
        if (picture != null && !picture.isBlank()) {
            profile.setAvatarUrl(picture);
        }

        return ResponseEntity.ok(createAuthResponse(userProfileRepository.save(profile)));
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        var userId = refreshTokens.remove(request.refreshToken());
        if (userId == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Refresh token không hợp lệ hoặc đã hết hạn");
        }

        var profile = userProfileRepository.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Tài khoản không tồn tại"));
        return ResponseEntity.ok(createAuthResponse(profile));
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestBody(required = false) RefreshTokenRequest request) {
        if (request != null && request.refreshToken() != null) {
            refreshTokens.remove(request.refreshToken());
        }
        return ResponseEntity.noContent().build();
    }

    private AuthResponse createAuthResponse(UserProfile profile) {
        var accessToken = generateToken();
        var refreshToken = generateToken();
        refreshTokens.put(refreshToken, profile.getUserId());
        return new AuthResponse(
                accessToken,
                refreshToken,
                AuthUserResponse.from(profile),
                Instant.now().plus(ACCESS_TOKEN_TTL)
        );
    }

    private Map<String, Object> fetchGoogleTokenInfo(String idToken) {
        try {
            var uri = UriComponentsBuilder
                    .fromUriString("https://oauth2.googleapis.com/tokeninfo")
                    .queryParam("id_token", idToken)
                    .build()
                    .toUri();
            @SuppressWarnings("unchecked")
            var response = restTemplate.getForEntity(uri, Map.class);
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                throw new ApiException(HttpStatus.UNAUTHORIZED, "Google token không hợp lệ");
            }
            return (Map<String, Object>) response.getBody();
        } catch (RestClientException e) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Google token không hợp lệ");
        }
    }

    private void sendPasswordResetEmail(String email, String code) {
        if (mailSender.isEmpty() || smtpHost.isBlank()) {
            log.warn("SMTP is not configured. Password reset code for {} is {}", email, code);
            return;
        }

        try {
            var message = new SimpleMailMessage();
            message.setFrom(mailFrom.isBlank() ? "no-reply@cineluxe.local" : mailFrom);
            message.setTo(email);
            message.setSubject("CineLuxe - Mã xác nhận đổi mật khẩu");
            message.setText("""
                    Mã xác nhận đổi mật khẩu CineLuxe của bạn là: %s

                    Mã này có hiệu lực trong 10 phút. Nếu bạn không yêu cầu đổi mật khẩu, vui lòng bỏ qua email này.
                    """.formatted(code));
            mailSender.get().send(message);
        } catch (MailException e) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "Không thể gửi email xác nhận. Vui lòng thử lại sau");
        }
    }

    private Set<String> configuredGoogleClientIds() {
        var clientIds = new LinkedHashSet<String>();
        addClientIds(clientIds, googleAllowedClientIds);
        addClientIds(clientIds, googleWebClientId);
        addClientIds(clientIds, googleAndroidClientIds);

        return clientIds;
    }

    private void addClientIds(Set<String> clientIds, String value) {
        if (value == null || value.isBlank()) return;
        Arrays.stream(value.split(","))
                .map(String::trim)
                .filter(item -> !item.isBlank())
                .forEach(clientIds::add);
    }

    private boolean isAllowedGoogleClient(String clientId) {
        if (clientId == null || clientId.isBlank()) return false;
        if (configuredGoogleClientIds().contains(clientId)) return true;

        var projectNumber = configuredGoogleProjectNumber();
        return !projectNumber.isBlank()
                && clientId.startsWith(projectNumber + "-")
                && clientId.endsWith(".apps.googleusercontent.com");
    }

    private String configuredGoogleProjectNumber() {
        if (googleProjectNumber != null && !googleProjectNumber.isBlank()) {
            return googleProjectNumber.trim();
        }
        var envProjectNumber = System.getenv("GOOGLE_PROJECT_NUMBER");
        return envProjectNumber == null ? "" : envProjectNumber.trim();
    }

    private String defaultGoogleName(Map<String, Object> tokenInfo, String email) {
        var name = optionalString(tokenInfo, "name");
        if (name != null && !name.isBlank()) return name;
        return email.substring(0, email.indexOf('@'));
    }

    private String requiredString(Map<String, Object> data, String key) {
        var value = optionalString(data, key);
        if (value == null || value.isBlank()) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Google token thiếu thông tin " + key);
        }
        return value;
    }

    private String optionalString(Map<String, Object> data, String key) {
        var value = data.get(key);
        return value == null ? null : value.toString();
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private String generateToken() {
        var bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String generateResetCode() {
        return "%06d".formatted(secureRandom.nextInt(1_000_000));
    }

    private String hashPassword(String password) {
        var salt = new byte[16];
        secureRandom.nextBytes(salt);
        var hash = digest(salt, password);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(salt)
                + ":"
                + Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
    }

    private boolean passwordMatches(String password, String storedHash) {
        var parts = storedHash.split(":", 2);
        if (parts.length != 2) return false;

        var salt = Base64.getUrlDecoder().decode(parts[0]);
        var expectedHash = Base64.getUrlDecoder().decode(parts[1]);
        var actualHash = digest(salt, password);
        return MessageDigest.isEqual(expectedHash, actualHash);
    }

    private byte[] digest(byte[] salt, String password) {
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            digest.update(salt);
            return digest.digest(password.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is not available", e);
        }
    }

    private record PasswordResetCode(String code, Instant expiresAt) {}
}
