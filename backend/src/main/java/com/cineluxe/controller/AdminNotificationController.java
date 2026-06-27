package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.repository.UserProfileRepository;
import com.cineluxe.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.Locale;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/notifications")
@RequiredArgsConstructor
@Tag(name = "Admin – Notifications", description = "Marketing notification broadcast (R16)")
public class AdminNotificationController {

    private final UserProfileRepository userProfileRepository;
    private final NotificationService notificationService;

    @PostMapping("/promotions")
    @Operation(summary = "Gửi thông báo quảng cáo")
    public ResponseEntity<ApiResponse<MarketingNotificationResponse>> sendPromotion(
            @Valid @RequestBody MarketingNotificationRequest request) {
        var targetRole = request.targetRole() == null || request.targetRole().isBlank()
                ? "customer"
                : request.targetRole().trim().toLowerCase(Locale.ROOT);
        var users = userProfileRepository.findAll()
                .stream()
                .filter(user -> user.isActive() && targetRole.equals(user.getRole()))
                .toList();
        users.forEach(user -> notificationService.sendPromotion(
                user.getUserId(),
                request.title().trim(),
                request.body().trim()));
        return ApiResponse.success(
                new MarketingNotificationResponse(users.size()),
                "Đã gửi thông báo quảng cáo");
    }

    public record MarketingNotificationRequest(
            @NotBlank(message = "title không được để trống")
            String title,
            @NotBlank(message = "body không được để trống")
            String body,
            String targetRole
    ) {}

    public record MarketingNotificationResponse(int deliveredCount) {}
}
