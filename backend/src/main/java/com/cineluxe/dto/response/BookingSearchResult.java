package com.cineluxe.dto.response;

import java.time.Instant;
import java.util.List;

public record BookingSearchResult(
    String bookingId,
    String userId,
    String movieTitle,
    String roomName,
    String cinemaName,
    Instant showtimeDateTime,
    List<String> seatCodes,
    long totalAmount,
    String status,
    Instant createdAt
) {
    public static BookingSearchResult from(com.cineluxe.entity.Booking booking) {
        return new BookingSearchResult(
            booking.getId(),
            booking.getUserId(),
            booking.getMovieTitle(),
            booking.getRoomName(),
            booking.getCinemaName(),
            booking.getShowtimeDateTime(),
            List.copyOf(booking.getSeatCodes()),
            booking.getTotalAmount(),
            booking.getStatus(),
            booking.getCreatedAt()
        );
    }
}
