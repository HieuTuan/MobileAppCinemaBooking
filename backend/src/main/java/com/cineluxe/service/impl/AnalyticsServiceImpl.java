package com.cineluxe.service.impl;

import com.cineluxe.service.AnalyticsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Structured-log implementation of {@link AnalyticsService}.
 *
 * <p>Each event is emitted as a structured JSON log line. An external
 * aggregator (ELK, CloudWatch Logs, Datadog) can parse these lines and
 * build conversion-rate dashboards from them.
 *
 * <p>Log format (one JSON object per line):
 * <pre>
 * {"event":"seat_hold","userId":"u1","showtimeId":"ST001","holdId":"HOLD-xxx","seatCount":2}
 * </pre>
 *
 * <p>Requirements: 41.5, 41.6
 */
@Service
@Slf4j
public class AnalyticsServiceImpl implements AnalyticsService {

    // ── Funnel stage: showtime_view ───────────────────────────────────────────

    @Override
    public void logShowtimeView(String userId, String showtimeId, String movieId) {
        log.info("{{\"event\":\"showtime_view\",\"userId\":\"{}\",\"showtimeId\":\"{}\",\"movieId\":\"{}\"}}",
                anonymise(userId), showtimeId, movieId);
    }

    // ── Funnel stage: seat_hold ───────────────────────────────────────────────

    @Override
    public void logSeatHold(String userId, String showtimeId, String holdId, int seatCount) {
        log.info("{{\"event\":\"seat_hold\",\"userId\":\"{}\",\"showtimeId\":\"{}\",\"holdId\":\"{}\",\"seatCount\":{}}}",
                anonymise(userId), showtimeId, holdId, seatCount);
    }

    // ── Funnel stage: payment_initiate ────────────────────────────────────────

    @Override
    public void logPaymentInitiate(String userId, String bookingId, String showtimeId, long totalAmount) {
        log.info("{{\"event\":\"payment_initiate\",\"userId\":\"{}\",\"bookingId\":\"{}\",\"showtimeId\":\"{}\",\"totalAmount\":{}}}",
                anonymise(userId), bookingId, showtimeId, totalAmount);
    }

    // ── Funnel stage: payment_complete ────────────────────────────────────────

    @Override
    public void logPaymentComplete(String userId, String bookingId, String transactionId, long totalAmount) {
        log.info("{{\"event\":\"payment_complete\",\"userId\":\"{}\",\"bookingId\":\"{}\",\"transactionId\":\"{}\",\"totalAmount\":{}}}",
                anonymise(userId), bookingId, transactionId, totalAmount);
    }

    // ── Funnel stage: payment_fail ────────────────────────────────────────────

    @Override
    public void logPaymentFail(String userId, String bookingId, String reason) {
        log.info("{{\"event\":\"payment_fail\",\"userId\":\"{}\",\"bookingId\":\"{}\",\"reason\":\"{}\"}}",
                anonymise(userId), bookingId, reason);
    }

    // ── Privacy: anonymise user ID (Req 41.7) ─────────────────────────────────

    /**
     * Truncates userId to the first 8 characters as a lightweight pseudonymisation
     * so that individual users cannot be identified from log data alone.
     */
    private String anonymise(String userId) {
        if (userId == null || userId.length() <= 8) return userId;
        return userId.substring(0, 8) + "****";
    }
}
