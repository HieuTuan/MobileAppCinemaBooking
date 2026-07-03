package com.cineluxe.service.impl;

import com.cineluxe.dto.request.UpdateProfileRequest;
import com.cineluxe.dto.response.UserProfileResponse;
import com.cineluxe.entity.UserProfile;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.UserProfileRepository;
import com.cineluxe.service.UserProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Transactional
public class UserProfileServiceImpl implements UserProfileService {

    private static final Pattern PHONE_PATTERN =
            Pattern.compile("^(0[0-9]{9,10}|\\+84[0-9]{9,10})$");

    private final UserProfileRepository userProfileRepository;
    private final Optional<JavaMailSender> mailSender;

    @Value("${spring.mail.username:${SPRING_MAIL_USERNAME:}}")
    private String mailFrom;

    @Value("${spring.mail.host:${SPRING_MAIL_HOST:}}")
    private String smtpHost;

    @Override
    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(String userId) {
        var profile = findOrCreate(userId);
        return UserProfileResponse.from(profile);
    }

    @Override
    public UserProfileResponse updateProfile(String userId, UpdateProfileRequest request) {
        var profile = findOrCreate(userId);

        if (request.phone() != null) {
            if (!PHONE_PATTERN.matcher(request.phone()).matches()) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                        "Invalid phone format: must be 0XXXXXXXXX or +84XXXXXXXXX");
            }
            profile.setPhone(request.phone());
        }

        if (request.birthdate() != null) {
            if (request.birthdate().isAfter(LocalDate.now())) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                        "Birthdate cannot be in the future");
            }
            profile.setBirthdate(request.birthdate());
        }

        if (request.fullName() != null) {
            profile.setFullName(request.fullName());
        }

        if (request.email() != null && !request.email().isBlank()) {
            var newEmail = request.email().trim().toLowerCase();
            if (!newEmail.equals(profile.getEmail())) {
                if (!newEmail.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) {
                    throw new ApiException(HttpStatus.BAD_REQUEST, "Email không đúng định dạng");
                }
                var existingOpt = userProfileRepository.findByEmailIgnoreCase(newEmail);
                if (existingOpt.isPresent() && !existingOpt.get().getUserId().equals(userId)) {
                    throw new ApiException(HttpStatus.CONFLICT, "Email đã được sử dụng bởi người dùng khác");
                }
                
                var secureRandom = new java.security.SecureRandom();
                var code = String.format("%06d", secureRandom.nextInt(1000000));
                
                profile.setPendingEmail(newEmail);
                profile.setEmailVerificationCode(code);
                profile.setEmailVerificationExpiresAt(Instant.now().plus(java.time.Duration.ofMinutes(10)));
                
                sendEmailVerification(newEmail, code);
            }
        }

        return UserProfileResponse.from(userProfileRepository.save(profile));
    }

    @Override
    public UserProfileResponse confirmEmail(String userId, String code) {
        var profile = findOrCreate(userId);
        if (profile.getPendingEmail() == null || profile.getEmailVerificationCode() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Không có yêu cầu đổi email nào đang chờ xác nhận");
        }
        if (profile.getEmailVerificationExpiresAt().isBefore(Instant.now())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Mã xác thực đã hết hạn");
        }
        if (!profile.getEmailVerificationCode().equals(code)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Mã xác thực không chính xác");
        }
        
        var existingOpt = userProfileRepository.findByEmailIgnoreCase(profile.getPendingEmail());
        if (existingOpt.isPresent() && !existingOpt.get().getUserId().equals(userId)) {
            throw new ApiException(HttpStatus.CONFLICT, "Email đã được sử dụng bởi người dùng khác");
        }
        
        profile.setEmail(profile.getPendingEmail());
        profile.setPendingEmail(null);
        profile.setEmailVerificationCode(null);
        profile.setEmailVerificationExpiresAt(null);
        
        return UserProfileResponse.from(userProfileRepository.save(profile));
    }

    private void sendEmailVerification(String email, String code) {
        if (mailSender.isEmpty() || smtpHost == null || smtpHost.isBlank()) {
            org.slf4j.LoggerFactory.getLogger(UserProfileServiceImpl.class)
                .warn("SMTP is not configured. Email verification code for {} is {}", email, code);
            return;
        }

        try {
            var message = new SimpleMailMessage();
            message.setFrom(mailFrom == null || mailFrom.isBlank() ? "no-reply@cineluxe.local" : mailFrom);
            message.setTo(email);
            message.setSubject("CineLuxe - Mã xác nhận đổi email");
            message.setText(String.format(
                "Mã xác nhận đổi email CineLuxe của bạn là: %s\n\nMã này có hiệu lực trong 10 phút. Nếu bạn không yêu cầu thay đổi này, vui lòng bỏ qua email này.",
                code
            ));
            mailSender.get().send(message);
        } catch (MailException e) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "Không thể gửi email xác nhận. Vui lòng thử lại sau");
        }
    }

    // ─── Private helpers ──────────────────────────────────────────────────

    private UserProfile findOrCreate(String userId) {
        return userProfileRepository.findById(userId)
                .orElseGet(() -> userProfileRepository.save(new UserProfile(userId)));
    }
}
