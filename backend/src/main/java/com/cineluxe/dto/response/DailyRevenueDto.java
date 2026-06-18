package com.cineluxe.dto.response;

import java.time.LocalDate;

public record DailyRevenueDto(LocalDate date, long revenue, int bookings) {}
