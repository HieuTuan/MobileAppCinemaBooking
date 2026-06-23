package com.cineluxe.dto.response;

import com.cineluxe.entity.FoodCombo;

/**
 * Response DTO for FoodCombo (R20).
 */
public record FoodComboResponse(
        String id,
        String name,
        String description,
        long price,
        String imageUrl,
        int quantity,
        boolean isActive
) {
    public static FoodComboResponse from(FoodCombo c) {
        return new FoodComboResponse(
                c.getId(),
                c.getName(),
                c.getDescription(),
                c.getPrice(),
                c.getImageUrl(),
                c.getQuantity(),
                c.isActive()
        );
    }
}
