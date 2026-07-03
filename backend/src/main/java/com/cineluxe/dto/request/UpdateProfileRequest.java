package com.cineluxe.dto.request;

import java.time.LocalDate;

public record UpdateProfileRequest(
    String fullName,
    String phone,
    LocalDate birthdate,
    String email
) {}
