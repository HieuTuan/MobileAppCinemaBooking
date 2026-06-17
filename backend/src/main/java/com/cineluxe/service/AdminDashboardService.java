package com.cineluxe.service;

import com.cineluxe.dto.response.BookingReportResponse;
import com.cineluxe.dto.response.DashboardMetricsResponse;
import com.cineluxe.dto.response.RevenueReportResponse;
import java.time.LocalDate;

public interface AdminDashboardService {
    DashboardMetricsResponse getDashboardMetrics();
    RevenueReportResponse getRevenueReport(LocalDate startDate, LocalDate endDate);
    BookingReportResponse getBookingReport(LocalDate startDate, LocalDate endDate);
}
