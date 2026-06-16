package com.cineluxe.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record ComboSelection(
    @NotBlank(message = "ID combo không được để trống")
    String comboId,
    
    @Min(value = 1, message = "Số lượng combo phải lớn hơn 0")
    @Max(value = 20, message = "Số lượng combo tối đa là 20")
    int quantity
) {}
