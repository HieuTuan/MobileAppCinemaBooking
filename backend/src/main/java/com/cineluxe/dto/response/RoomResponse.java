package com.cineluxe.dto.response;

import com.cineluxe.entity.Room;
import java.util.List;

public record RoomResponse(
        String id,
        String theaterId,
        String name,
        String status,
        int capacity,
        int totalSeats,
        String screenType,
        List<RoomSeatResponse> seatLayout
) {
    public static RoomResponse from(Room room, List<RoomSeatResponse> seatLayout) {
        return new RoomResponse(
                room.getId(),
                room.getTheaterId(),
                room.getName(),
                room.getStatus(),
                room.getCapacity(),
                seatLayout.size(),
                room.getScreenType(),
                seatLayout);
    }
}
