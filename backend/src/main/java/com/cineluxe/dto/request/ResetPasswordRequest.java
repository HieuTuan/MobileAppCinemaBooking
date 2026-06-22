package com.cineluxe.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
        @NotBlank(message = "Email không được để trống")
        @Email(message = "Email không đúng định dạng")
        String email,

        @NotBlank(message = "Mã xác nhận không được để trống")
        @Pattern(regexp = "^[0-9]{6}$", message = "Mã xác nhận phải gồm 6 chữ số")
        String code,

        @NotBlank(message = "Mật khẩu mới không được để trống")
        @Size(min = 8, message = "Mật khẩu mới phải có ít nhất 8 ký tự")
        @Pattern(
                regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%^&*(),.?\":{}|<>]).+$",
                message = "Mật khẩu mới phải có chữ hoa, chữ thường, số và ký tự đặc biệt"
        )
        String newPassword
) {}
