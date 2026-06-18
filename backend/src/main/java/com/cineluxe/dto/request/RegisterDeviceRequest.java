package com.cineluxe.dto.request;

import com.cineluxe.entity.Platform;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record RegisterDeviceRequest(
    @NotBlank(message = "Device token không được để trống")
    String deviceToken,

    @NotNull(message = "Nền tảng không được để trống")
    Platform platform
) {}
