package com.cineluxe.dto.request;

public record ValidateTicketRequest(
    String expectedShowtimeId,
    String staffId
) {}
