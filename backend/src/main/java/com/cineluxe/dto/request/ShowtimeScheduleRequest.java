package com.cineluxe.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record ShowtimeScheduleRequest(
        @NotBlank(message = "movieId không được để trống")
        String movieId,

        @NotBlank(message = "roomId không được để trống")
        String roomId,

        @NotNull(message = "startTime không được để trống")
        Instant startTime,

        @NotNull(message = "endTime không được để trống")
        Instant endTime,

        @Min(value = 0, message = "basePrice không được âm")
        int basePrice,

        @Min(value = 0, message = "vipSeatPrice khong duoc am")
        Integer vipSeatPrice,

        @Min(value = 0, message = "coupleSeatPrice khong duoc am")
        Integer coupleSeatPrice,

        String status
) {}
