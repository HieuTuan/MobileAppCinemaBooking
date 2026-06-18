package com.cineluxe.dto.response;

public record DeviceRegistrationResponse(
    String deviceToken,
    String userId,
    boolean registered
) {}
