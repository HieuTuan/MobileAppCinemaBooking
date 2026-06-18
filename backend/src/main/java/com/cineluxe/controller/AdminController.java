package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.BookingReportResponse;
import com.cineluxe.dto.response.DashboardMetricsResponse;
import com.cineluxe.dto.response.RevenueReportResponse;
import com.cineluxe.service.AdminDashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Tag(name = "Admin", description = "Admin dashboard and report endpoints")
public class AdminController {

    private final AdminDashboardService adminDashboardService;

    @GetMapping("/dashboard/metrics")
    @Operation(summary = "Get admin dashboard metrics")
    public ResponseEntity<ApiResponse<DashboardMetricsResponse>> getDashboardMetrics() {
        return ApiResponse.success(adminDashboardService.getDashboardMetrics());
    }

    @GetMapping("/reports/revenue")
    @Operation(summary = "Get revenue report for date range")
    public ResponseEntity<ApiResponse<RevenueReportResponse>> getRevenueReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ApiResponse.success(adminDashboardService.getRevenueReport(startDate, endDate));
    }

    @GetMapping("/reports/bookings")
    @Operation(summary = "Get booking statistics report for date range")
    public ResponseEntity<ApiResponse<BookingReportResponse>> getBookingReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ApiResponse.success(adminDashboardService.getBookingReport(startDate, endDate));
    }
}
