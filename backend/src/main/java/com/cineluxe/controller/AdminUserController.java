package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.entity.UserProfile;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.UserProfileRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@Tag(name = "Admin – Users", description = "User and staff account management (R23)")
public class AdminUserController {

    private static final Set<String> ALLOWED_ROLES = Set.of("customer", "staff", "admin");
    private final UserProfileRepository userProfileRepository;
    private final SecureRandom secureRandom = new SecureRandom();

    @GetMapping
    @Operation(summary = "Lấy danh sách tài khoản")
    public ResponseEntity<ApiResponse<PaginatedAdminUsers>> listUsers(
            @RequestParam(required = false) String role,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        var normalizedRole = role == null || role.isBlank() ? null : normalizeRole(role);
        var all = userProfileRepository.findAll()
                .stream()
                .filter(user -> normalizedRole == null || normalizedRole.equals(user.getRole()))
                .sorted(Comparator.comparing(UserProfile::getCreatedAt).reversed())
                .map(AdminUserResponse::from)
                .toList();

        var safePageSize = Math.max(1, pageSize);
        var safePage = Math.max(1, page);
        var from = Math.min((safePage - 1) * safePageSize, all.size());
        var to = Math.min(from + safePageSize, all.size());
        var totalPages = all.isEmpty() ? 1 : (int) Math.ceil((double) all.size() / safePageSize);
        var data = all.subList(from, to);
        return ApiResponse.success(new PaginatedAdminUsers(
                data,
                safePage,
                safePageSize,
                all.size(),
                totalPages,
                safePage < totalPages,
                safePage > 1));
    }

    @PostMapping
    @Operation(summary = "Tạo tài khoản staff/admin")
    public ResponseEntity<ApiResponse<StaffAccountCreationResult>> createUser(
            @Valid @RequestBody CreateAdminUserRequest request) {
        var email = request.email().trim().toLowerCase(Locale.ROOT);
        if (userProfileRepository.existsByEmailIgnoreCase(email)) {
            throw new ApiException(HttpStatus.CONFLICT, "Email đã được sử dụng");
        }
        var role = normalizeRole(request.role());
        if ("customer".equals(role)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Admin chỉ tạo được tài khoản staff/admin");
        }

        var temporaryPassword = "Cine@" + secureRandom.nextInt(100_000, 999_999);
        var user = new UserProfile(UUID.randomUUID().toString());
        user.setFullName(request.fullName().trim());
        user.setEmail(email);
        user.setRole(role);
        user.setActive(true);
        user.setPermissions(request.permissions());
        user.setPasswordHash(hashPassword(temporaryPassword));
        userProfileRepository.save(user);

        var response = new StaffAccountCreationResult(
                AdminUserResponse.from(user),
                temporaryPassword,
                false);
        return ApiResponse.created(response, "Tạo tài khoản thành công");
    }

    @PatchMapping("/{userId}/status")
    @Operation(summary = "Khóa/mở tài khoản")
    public ResponseEntity<ApiResponse<AdminUserResponse>> updateStatus(
            @PathVariable String userId,
            @RequestBody UpdateStatusRequest request) {
        var user = findUser(userId);
        if ("admin".equals(user.getRole())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Không thể khóa tài khoản admin");
        }
        user.setActive(request.active());
        userProfileRepository.save(user);
        return ApiResponse.success(AdminUserResponse.from(user));
    }

    @PatchMapping("/{userId}/permissions")
    @Operation(summary = "Cập nhật quyền staff")
    public ResponseEntity<ApiResponse<AdminUserResponse>> updatePermissions(
            @PathVariable String userId,
            @RequestBody UpdatePermissionsRequest request) {
        var user = findUser(userId);
        user.setPermissions(request.permissions());
        userProfileRepository.save(user);
        return ApiResponse.success(AdminUserResponse.from(user));
    }

    @DeleteMapping("/{userId}")
    @Operation(summary = "Xóa mềm tài khoản")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable String userId) {
        var user = findUser(userId);
        if ("admin".equals(user.getRole())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Không thể xóa tài khoản admin");
        }
        user.softDelete();
        userProfileRepository.save(user);
        return ApiResponse.success(null, "Đã xóa tài khoản");
    }

    private UserProfile findUser(String userId) {
        return userProfileRepository.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy tài khoản"));
    }

    private String normalizeRole(String role) {
        var normalized = role == null ? "" : role.trim().toLowerCase(Locale.ROOT);
        if (!ALLOWED_ROLES.contains(normalized)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "role chỉ được là customer, staff hoặc admin");
        }
        return normalized;
    }

    private String hashPassword(String password) {
        var salt = new byte[16];
        secureRandom.nextBytes(salt);
        var hash = digest(salt, password);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(salt)
                + ":"
                + Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
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

    public record CreateAdminUserRequest(
            @NotBlank(message = "fullName không được để trống")
            String fullName,
            @Email(message = "email không hợp lệ")
            @NotBlank(message = "email không được để trống")
            String email,
            @NotBlank(message = "role không được để trống")
            String role,
            List<String> permissions
    ) {}

    public record UpdateStatusRequest(boolean active) {}

    public record UpdatePermissionsRequest(List<String> permissions) {}

    public record AdminUserResponse(
            String userId,
            String fullName,
            String email,
            String role,
            boolean active,
            List<String> permissions
    ) {
        public static AdminUserResponse from(UserProfile user) {
            return new AdminUserResponse(
                    user.getUserId(),
                    user.getFullName() != null ? user.getFullName() : "",
                    user.getEmail() != null ? user.getEmail() : "",
                    user.getRole(),
                    user.isActive(),
                    user.getPermissions() != null ? user.getPermissions() : List.of());
        }
    }

    public record StaffAccountCreationResult(
            AdminUserResponse user,
            String temporaryPassword,
            boolean welcomeEmailSent
    ) {}

    public record PaginatedAdminUsers(
            List<AdminUserResponse> data,
            int page,
            int pageSize,
            int totalItems,
            int totalPages,
            boolean hasNext,
            boolean hasPrevious
    ) {}
}
