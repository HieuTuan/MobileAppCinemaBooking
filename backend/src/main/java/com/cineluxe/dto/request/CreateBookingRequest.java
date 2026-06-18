package com.cineluxe.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CreateBookingRequest(
    @NotBlank(message = "ID giữ ghế không được để trống")
    String holdId,

    String userId,

    List<@Valid ComboSelection> combos,

    String movieAgeRating   // nullable — "T18" triggers age check on backend
) {}
