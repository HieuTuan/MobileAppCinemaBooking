package com.cineluxe.dto.response;

import java.time.Instant;

public record ShowtimeOccupancyDto(
    String showtimeId, String movieTitle, Instant startTime,
    String roomName, int totalSeats, int bookedSeats, double occupancyRate
) {}
