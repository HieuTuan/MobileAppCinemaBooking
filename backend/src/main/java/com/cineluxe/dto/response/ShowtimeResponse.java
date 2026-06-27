package com.cineluxe.dto.response;

import com.cineluxe.entity.Room;
import com.cineluxe.entity.Showtime;
import java.time.Instant;

public record ShowtimeResponse(
        String id,
        String movieId,
        String roomId,
        Instant startTime,
        Instant endTime,
        int basePrice,
        String status,
        String roomName,
        String cinemaName,
        String cinemaAddress
) {
    public static ShowtimeResponse from(Showtime showtime, Room room) {
        return new ShowtimeResponse(
                showtime.getId(),
                showtime.getMovieId(),
                showtime.getRoomId(),
                showtime.getStartTime(),
                showtime.getEndTime(),
                showtime.getBasePrice(),
                showtime.getStatus(),
                room != null ? room.getName() : "",
                showtime.getCinemaName() != null ? showtime.getCinemaName() : "CineLuxe",
                ""
        );
    }
}
