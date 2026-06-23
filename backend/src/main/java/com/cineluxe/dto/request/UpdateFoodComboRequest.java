package com.cineluxe.dto.request;

import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

/**
 * Request body for PUT /api/admin/food-combos/{id} (R20-2).
 * All fields optional – only non-null values are applied.
 */
public record UpdateFoodComboRequest(
        String name,
        String description,

        @Positive(message = "Giá phải là số nguyên dương")
        Long price,

        String imageUrl,
        @PositiveOrZero(message = "Số lượng không được âm")
        Integer quantity,
        Boolean isActive
) {}
