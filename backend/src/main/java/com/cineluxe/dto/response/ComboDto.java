package com.cineluxe.dto.response;

import com.cineluxe.entity.FoodCombo;

public record ComboDto(
    String id,
    String name,
    String description,
    long price,
    String imageUrl
) {
  public static ComboDto from(FoodCombo combo) {
    return new ComboDto(
        combo.getId(),
        combo.getName(),
        combo.getDescription(),
        combo.getPrice(),
        combo.getImageUrl());
  }
}
