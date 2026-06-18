package com.cineluxe.dto.request;

import jakarta.validation.constraints.NotNull;

/**
 * Request DTO for updating notification preferences.
 * All fields are optional; only provided fields are applied (partial update).
 */
public record UpdateNotificationPreferenceRequest(
    @NotNull(message = "Giá trị nhắc nhở lịch chiếu không được để trống")
    Boolean showtimeReminders,

    @NotNull(message = "Giá trị khuyến mãi không được để trống")
    Boolean promotions,

    @NotNull(message = "Giá trị phim mới không được để trống")
    Boolean newMovies,

    @NotNull(message = "Giá trị cập nhật đặt vé không được để trống")
    Boolean bookingUpdates
) {}
