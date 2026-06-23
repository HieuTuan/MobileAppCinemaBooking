package com.cineluxe.dto.response;

import com.cineluxe.entity.RoomSeat;

public record RoomSeatResponse(
        String seatCode,
        String row,
        int column,
        String seatType
) {
    public static RoomSeatResponse from(RoomSeat seat) {
        return new RoomSeatResponse(
                seat.getSeatCode(),
                seat.getSeatRow(),
                seat.getSeatColumn(),
                seat.getSeatType());
    }
}
