package com.cineluxe.dto.response;

import java.util.List;

public record SeatMapResponse(
    String showtimeId,
    List<SeatDto> seats
) {}
