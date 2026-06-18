package com.cineluxe.dto.response;

public record TheaterOccupancyDto(String theaterId, String theaterName,
    int totalSeats, int bookedSeats, double occupancyRate) {}
