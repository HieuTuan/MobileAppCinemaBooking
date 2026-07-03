package com.cineluxe.dto.request;

import jakarta.validation.constraints.NotBlank;

public record ConfirmEmailRequest(
    @NotBlank(message = "Mã xác thực không được để trống")
    String code
) {}
