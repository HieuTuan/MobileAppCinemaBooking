package com.cineluxe.dto.response;

import java.time.LocalDate;
import java.util.List;

public record RevenueReportResponse(
    LocalDate startDate, LocalDate endDate,
    long totalRevenue, int totalBookings, long averageBookingValue,
    List<RevenueByPaymentMethodDto> byPaymentMethod,
    List<DailyRevenueDto> dailySeries
) {}
