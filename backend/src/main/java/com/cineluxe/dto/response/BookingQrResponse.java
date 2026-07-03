package com.cineluxe.dto.response;

import java.time.Instant;
import java.util.List;

public record BookingQrResponse(
    String bookingId,
    String qrCode,
    String movieTitle,
    Instant showtimeDateTime,
    String roomName,
    String cinemaName,
    List<String> seatCodes,
    String qrCodeUrl
) {}
