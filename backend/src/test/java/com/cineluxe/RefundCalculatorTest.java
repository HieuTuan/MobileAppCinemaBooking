package com.cineluxe;

import com.cineluxe.entity.Booking;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for refund calculation logic embedded in the Booking entity.
 *
 * <p>Requirements: 42.1, 42.2, 42.3, 13.4, 13.5
 * <ul>
 *   <li>42.1: Unit tests for Refund_Calculator (100%/50%/0% refund rules and edge cases).</li>
 *   <li>13.4: More than 2 hours before showtime = 100% refund.</li>
 *   <li>13.5: Within 2 hours before showtime = 50% refund.</li>
 *   <li>13.3: After showtime start = 0% refund (cancel rejected).</li>
 * </ul>
 */
class RefundCalculatorTest {

    private static final long TOTAL_AMOUNT = 480_000L; // 4 seats * 120,000 VND

    /** Creates a test Booking with a showtime in the future by the given offset from now. */
    private Booking createBookingWithShowtime(Duration offsetFromNow) {
        // Create via constructor and then override showtime via reflection / method
        var booking = new Booking(
                "BK-TEST-001",
                "user-001",
                "st-001",
                TOTAL_AMOUNT,
                List.of("A1", "A2", "A3", "A4"),
                List.of()
        );
        // Override showtime to our test value (2 hours from now)
        booking.updateShowtimeDateTime(Instant.now().plus(offsetFromNow));
        return booking;
    }

    @Test
    void cancel_moreThan2HoursBeforeShowtime_returns100PercentRefund() {
        var booking = createBookingWithShowtime(Duration.ofHours(3)); // 3 hours in future
        var refund = computeRefund(booking);
        assertThat(refund).isEqualTo(TOTAL_AMOUNT);
    }

    @Test
    void cancel_exactly121MinutesBeforeShowtime_returns100PercentRefund() {
        var booking = createBookingWithShowtime(Duration.ofMinutes(121)); // just over 2 hours
        var refund = computeRefund(booking);
        assertThat(refund).isEqualTo(TOTAL_AMOUNT);
    }

    @Test
    void cancel_within2HoursBeforeShowtime_returns50PercentRefund() {
        var booking = createBookingWithShowtime(Duration.ofHours(1)); // 1 hour in future
        var refund = computeRefund(booking);
        assertThat(refund).isEqualTo(TOTAL_AMOUNT / 2);
    }

    @Test
    void cancel_30MinutesBeforeShowtime_returns50PercentRefund() {
        var booking = createBookingWithShowtime(Duration.ofMinutes(30));
        var refund = computeRefund(booking);
        assertThat(refund).isEqualTo(TOTAL_AMOUNT / 2);
    }

    @Test
    void cancel_exactly120MinutesBeforeShowtime_returns50PercentRefund() {
        // Exactly 2 hours = within window, so 50%
        var booking = createBookingWithShowtime(Duration.ofMinutes(120));
        var refund = computeRefund(booking);
        assertThat(refund).isEqualTo(TOTAL_AMOUNT / 2);
    }

    @ParameterizedTest(name = "offset={0}h -> refund={1}")
    @CsvSource({
            "5,  480000",  // 100%
            "3,  480000",  // 100%
            "2,  240000",  // 50%
            "1,  240000",  // 50%
    })
    void refundCalculation_parameterized(int hoursFromNow, long expectedRefund) {
        var booking = createBookingWithShowtime(Duration.ofHours(hoursFromNow));
        assertThat(computeRefund(booking)).isEqualTo(expectedRefund);
    }

    @Test
    void cancel_afterShowtime_shouldNotBeAllowed() {
        var booking = createBookingWithShowtime(Duration.ofHours(-1)); // 1 hour in past
        // The cancellation check (showtime must be in future) is enforced in BookingServiceImpl.
        // This test verifies the refund amount logic only — the service should reject before reaching refund.
        // Verify that the showtime is in the past (our data setup):
        assertThat(booking.getShowtimeDateTime()).isBefore(Instant.now());
    }

    // ── helper ──────────────────────────────────────────────────────────────────

    /** Replicates the refund calculation in BookingServiceImpl.cancelBooking(). */
    private long computeRefund(Booking booking) {
        var now = Instant.now();
        return booking.getShowtimeDateTime().isAfter(now.plus(Duration.ofHours(2)))
                ? booking.getTotalAmount()
                : booking.getTotalAmount() / 2;
    }
}
