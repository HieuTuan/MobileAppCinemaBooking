package com.cineluxe.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record VerifyRegistrationRequest(
        @NotBlank(message = "Email không được để trống")
        @Email(message = "Email không đúng định dạng")
        String email,

        @NotBlank(message = "Mã xác nhận không được để trống")
        @Pattern(regexp = "^[0-9]{6}$", message = "Mã xác nhận phải gồm 6 chữ số")
        String code
) {}
