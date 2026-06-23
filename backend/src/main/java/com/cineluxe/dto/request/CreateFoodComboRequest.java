package com.cineluxe.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Positive;

/**
 * Request body for POST /api/admin/food-combos (R20-1).
 */
public record CreateFoodComboRequest(

        @NotBlank(message = "Tên combo không được để trống")
        String name,

        String description,

        @Positive(message = "Giá phải là số nguyên dương")
        long price,

        String imageUrl,

        @PositiveOrZero(message = "Số lượng không được âm")
        Integer quantity,

        Boolean isActive
) {}
