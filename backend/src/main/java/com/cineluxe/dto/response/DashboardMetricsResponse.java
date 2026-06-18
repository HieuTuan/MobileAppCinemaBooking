package com.cineluxe.dto.response;

import java.util.List;

public record DashboardMetricsResponse(
    long todayRevenue,
    int todayBookings,
    int activeUsers,
    int concurrentUsers,
    List<ShowtimeOccupancyDto> upcomingShowtimes,
    List<MovieSalesDto> topMovies,
    List<RecentBookingDto> recentBookings
) {}
