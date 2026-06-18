package com.cineluxe.service.impl;

import com.cineluxe.dto.response.BookingReportResponse;
import com.cineluxe.dto.response.BookingStatsDto;
import com.cineluxe.dto.response.DailyRevenueDto;
import com.cineluxe.dto.response.DashboardMetricsResponse;
import com.cineluxe.dto.response.MovieRankingDto;
import com.cineluxe.dto.response.MovieSalesDto;
import com.cineluxe.dto.response.RecentBookingDto;
import com.cineluxe.dto.response.RevenueByPaymentMethodDto;
import com.cineluxe.dto.response.RevenueReportResponse;
import com.cineluxe.dto.response.ShowtimeOccupancyDto;
import com.cineluxe.dto.response.TheaterOccupancyDto;
import com.cineluxe.entity.Booking;
import com.cineluxe.repository.BookingRepository;
import com.cineluxe.service.AdminDashboardService;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class AdminDashboardServiceImpl implements AdminDashboardService {

    private final BookingRepository bookingRepository;

    @Override
    public DashboardMetricsResponse getDashboardMetrics() {
        var allBookings = bookingRepository.findAll();
        var today = LocalDate.now();
        var todayStart = today.atStartOfDay(ZoneOffset.UTC).toInstant();
        var todayEnd = today.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();

        // todayRevenue: sum totalAmount for bookings with status "active" or "used" created today
        long todayRevenue = allBookings.stream()
            .filter(b -> b.getCreatedAt().isAfter(todayStart) && b.getCreatedAt().isBefore(todayEnd))
            .filter(b -> "active".equals(b.getStatus()) || "used".equals(b.getStatus()))
            .mapToLong(Booking::getTotalAmount).sum();

        // todayBookings: count ALL bookings created today
        int todayBookings = (int) allBookings.stream()
            .filter(b -> b.getCreatedAt().isAfter(todayStart) && b.getCreatedAt().isBefore(todayEnd))
            .count();

        // activeUsers: distinct userIds with any booking in last 30 days
        var thirtyDaysAgo = java.time.Instant.now().minus(30, ChronoUnit.DAYS);
        int activeUsers = (int) allBookings.stream()
            .filter(b -> b.getCreatedAt().isAfter(thirtyDaysAgo))
            .map(Booking::getUserId).distinct().count();

        // concurrentUsers: bookings with status "pendingPayment" right now
        int concurrentUsers = (int) allBookings.stream()
            .filter(b -> "pendingPayment".equals(b.getStatus())).count();

        // upcomingShowtimes: empty list (no Showtime entity exists yet)
        var upcomingShowtimes = List.<ShowtimeOccupancyDto>of();

        // topMovies: group by movieTitle, sum seatCodes.size() and totalAmount, top 5 desc by tickets
        var topMovies = allBookings.stream()
            .filter(b -> "active".equals(b.getStatus()) || "used".equals(b.getStatus()))
            .collect(Collectors.groupingBy(Booking::getMovieTitle))
            .entrySet().stream()
            .map(e -> new MovieSalesDto(
                e.getKey().toLowerCase().replace(" ", "-"),
                e.getKey(),
                e.getValue().stream().mapToInt(b -> b.getSeatCodes().size()).sum(),
                e.getValue().stream().mapToLong(Booking::getTotalAmount).sum()))
            .sorted(Comparator.comparingInt(MovieSalesDto::ticketsSold).reversed())
            .limit(5)
            .toList();

        // recentBookings: last 10 by createdAt desc
        var recentBookings = allBookings.stream()
            .sorted(Comparator.comparing(Booking::getCreatedAt).reversed())
            .limit(10)
            .map(b -> new RecentBookingDto(b.getId(), b.getUserId(), b.getMovieTitle(),
                b.getTotalAmount(), b.getStatus(), b.getCreatedAt()))
            .toList();

        return new DashboardMetricsResponse(todayRevenue, todayBookings, activeUsers,
            concurrentUsers, upcomingShowtimes, topMovies, recentBookings);
    }

    @Override
    public RevenueReportResponse getRevenueReport(LocalDate startDate, LocalDate endDate) {
        var from = startDate.atStartOfDay(ZoneOffset.UTC).toInstant();
        var to = endDate.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        var bookings = bookingRepository.findAll().stream()
            .filter(b -> b.getCreatedAt().isAfter(from) && b.getCreatedAt().isBefore(to))
            .filter(b -> "active".equals(b.getStatus()) || "used".equals(b.getStatus()))
            .toList();

        long totalRevenue = bookings.stream().mapToLong(Booking::getTotalAmount).sum();
        int totalBookings = bookings.size();
        long avg = totalBookings > 0 ? totalRevenue / totalBookings : 0;

        // All bookings go through VNPay in this demo
        var byMethod = List.of(new RevenueByPaymentMethodDto("vnpay", totalRevenue, totalBookings));

        // Daily series: group by date
        var dailySeries = bookings.stream()
            .collect(Collectors.groupingBy(
                b -> b.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate()))
            .entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .map(e -> new DailyRevenueDto(
                e.getKey(),
                e.getValue().stream().mapToLong(Booking::getTotalAmount).sum(),
                e.getValue().size()))
            .toList();

        return new RevenueReportResponse(startDate, endDate, totalRevenue, totalBookings, avg,
            byMethod, dailySeries);
    }

    @Override
    public BookingReportResponse getBookingReport(LocalDate startDate, LocalDate endDate) {
        var from = startDate.atStartOfDay(ZoneOffset.UTC).toInstant();
        var to = endDate.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        var bookings = bookingRepository.findAll().stream()
            .filter(b -> b.getCreatedAt().isAfter(from) && b.getCreatedAt().isBefore(to))
            .toList();

        int total = bookings.size();
        int confirmed = (int) bookings.stream().filter(b -> "active".equals(b.getStatus())).count();
        int cancelled = (int) bookings.stream().filter(b -> "cancelled".equals(b.getStatus())).count();
        int refunded = (int) bookings.stream().filter(b -> "refunded".equals(b.getStatus())).count();
        var stats = new BookingStatsDto(total, confirmed, cancelled, refunded);

        // Movie rankings by tickets sold
        var grouped = bookings.stream()
            .filter(b -> "active".equals(b.getStatus()) || "used".equals(b.getStatus()))
            .collect(Collectors.groupingBy(Booking::getMovieTitle))
            .entrySet().stream()
            .sorted(Comparator.comparingInt((Map.Entry<String, List<Booking>> e) ->
                e.getValue().stream().mapToInt(b -> b.getSeatCodes().size()).sum()).reversed())
            .toList();
        var movieRankings = new ArrayList<MovieRankingDto>();
        for (int i = 0; i < grouped.size(); i++) {
            var e = grouped.get(i);
            movieRankings.add(new MovieRankingDto(
                i + 1,
                e.getKey().toLowerCase().replace(" ", "-"),
                e.getKey(),
                e.getValue().stream().mapToInt(b -> b.getSeatCodes().size()).sum(),
                e.getValue().stream().mapToLong(Booking::getTotalAmount).sum()));
        }

        // Theater occupancy stub (no Theater entity yet)
        int totalSeats = 60;
        int bookedSeats = (int) bookings.stream()
            .filter(b -> "active".equals(b.getStatus()) || "used".equals(b.getStatus()))
            .mapToLong(b -> b.getSeatCodes().size()).sum();
        var theater = new TheaterOccupancyDto(
            "theater-1", "CineLuxe Tràng Tiền", totalSeats,
            Math.min(bookedSeats, totalSeats),
            totalSeats > 0 ? Math.min(1.0, (double) bookedSeats / totalSeats) : 0.0);

        return new BookingReportResponse(startDate, endDate, stats, movieRankings, List.of(theater));
    }
}
