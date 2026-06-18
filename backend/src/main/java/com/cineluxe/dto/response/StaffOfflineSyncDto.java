package com.cineluxe.dto.response;

import java.time.Instant;
import java.util.List;


public record StaffOfflineSyncDto(
    List<BookingSearchResult> activeBookings,

    int totalCount,

    Instant syncedAt,

    Instant expiresAt,

    long version
) {}
