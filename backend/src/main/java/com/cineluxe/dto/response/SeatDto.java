package com.cineluxe.dto.response;

import com.cineluxe.entity.ShowtimeSeat;

public record SeatDto(
    String code,
    String row,
    int column,
    String type,
    String status
) {
  public static SeatDto from(ShowtimeSeat seat) {
    return new SeatDto(
        seat.getCode(),
        seat.getSeatRow(),
        seat.getSeatColumn(),
        seat.getType(),
        seat.getStatus().name());
  }
}
