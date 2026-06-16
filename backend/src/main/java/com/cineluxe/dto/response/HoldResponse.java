package com.cineluxe.dto.response;

import java.time.Instant;
import java.util.List;

public record HoldResponse(
    String holdId,
    String showtimeId,
    List<String> seatCodes,
    Instant expiresAt
) {}
