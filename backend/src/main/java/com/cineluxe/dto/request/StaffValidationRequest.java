package com.cineluxe.dto.request;

import io.swagger.v3.oas.annotations.Parameter;
import jakarta.validation.constraints.NotBlank;

public record StaffValidationRequest(
    @Parameter(description = "Staff ID performing the validation")
    @NotBlank(message = "Mã nhân viên không được để trống")
    String staffId
) {}
