package com.cineluxe.dto.response;

import java.time.Instant;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        AuthUserResponse user,
        Instant expiresAt
) {}
