package com.cineluxe.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;

import java.time.LocalDate;

public record UpdateProfileRequest(
        @NotBlank(message = "Full name cannot be blank")
        String fullName,
        @Pattern(
                regexp = "^(0[0-9]{9}|\\+84[0-9]{9})$",
                message = "Invalid phone format: must be 0XXXXXXXXX or +84XXXXXXXXX"
        )
        String phone,
        @PastOrPresent(message = "Birthdate cannot be in the future")
        LocalDate birthdate
) {
}
