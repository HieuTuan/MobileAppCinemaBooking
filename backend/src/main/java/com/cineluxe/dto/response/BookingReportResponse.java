package com.cineluxe.dto.response;

import java.time.LocalDate;
import java.util.List;

public record BookingReportResponse(
    LocalDate startDate, LocalDate endDate,
    BookingStatsDto stats,
    List<MovieRankingDto> movieRankings,
    List<TheaterOccupancyDto> theaterOccupancy
) {}
