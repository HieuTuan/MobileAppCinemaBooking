package com.cineluxe.dto.response;

public record BookingStatsDto(int total, int confirmed, int cancelled, int refunded) {}
