package com.cineluxe.dto.request;

import jakarta.validation.constraints.NotBlank;

public record GoogleAuthRequest(
        @NotBlank(message = "Google ID token không được để trống")
        String idToken
) {}
