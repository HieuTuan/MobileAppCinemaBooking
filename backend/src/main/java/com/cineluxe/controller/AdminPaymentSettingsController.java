package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/settings/payment")
@Tag(name = "Admin – Payment Settings", description = "VNPay payment configuration (R26)")
public class AdminPaymentSettingsController {

    private PaymentSettingsResponse settings;

    public AdminPaymentSettingsController(
            @Value("${booking.vnpay-secret}") String secretKey,
            @Value("${booking.api-base-url}") String apiBaseUrl) {
        this.settings = new PaymentSettingsResponse(
                "CINELUXE_SANDBOX",
                secretKey,
                "sandbox",
                stripTrailingSlash(apiBaseUrl) + "/api/payments/vnpay/return",
                true);
    }

    @GetMapping
    @Operation(summary = "Lấy cấu hình VNPay")
    public ResponseEntity<ApiResponse<PaymentSettingsResponse>> getPaymentSettings() {
        return ApiResponse.success(settings);
    }

    @PutMapping
    @Operation(summary = "Cập nhật cấu hình VNPay")
    public ResponseEntity<ApiResponse<PaymentSettingsResponse>> updatePaymentSettings(
            @RequestBody PaymentSettingsResponse request) {
        settings = new PaymentSettingsResponse(
                valueOrDefault(request.terminalId(), settings.terminalId()),
                valueOrDefault(request.secretKey(), settings.secretKey()),
                valueOrDefault(request.environment(), settings.environment()),
                valueOrDefault(request.returnUrl(), settings.returnUrl()),
                request.enabled());
        return ApiResponse.success(settings, "Cập nhật cấu hình thanh toán thành công");
    }

    private String valueOrDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private String stripTrailingSlash(String value) {
        return value != null && value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }

    public record PaymentSettingsResponse(
            String terminalId,
            String secretKey,
            String environment,
            String returnUrl,
            boolean enabled
    ) {}
}
