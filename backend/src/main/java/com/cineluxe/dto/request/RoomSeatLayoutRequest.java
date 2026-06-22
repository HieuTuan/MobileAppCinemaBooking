package com.cineluxe.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record RoomSeatLayoutRequest(
        String seatCode,

        @NotBlank(message = "Hàng ghế không được để trống")
        String row,

        @Min(value = 1, message = "Cột ghế phải từ 1")
        int column,

        @NotBlank(message = "Loại ghế không được để trống")
        String seatType
) {}
