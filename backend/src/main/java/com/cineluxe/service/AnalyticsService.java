package com.cineluxe.service;

/**
 * Backend analytics service interface for conversion funnel tracking.
 *
 * <p>Logs the following funnel stages (Requirements 41.5, 41.6):
 * <ol>
 *   <li>showtime_view  — user opens a showtime page</li>
 *   <li>seat_hold      — user successfully holds seats</li>
 *   <li>payment_initiate — booking created, payment URL opened</li>
 *   <li>payment_complete — VNPay callback returns success</li>
 * </ol>
 *
 * <p>Conversion rates stored / queryable:
 * <ul>
 *   <li>seat_hold → payment_initiate</li>
 *   <li>payment_initiate → payment_complete</li>
 * </ul>
 */
public interface AnalyticsService {

    /**
     * Log that a user viewed a showtime detail page.
     *
     * @param userId     authenticated user ID (or "anonymous")
     * @param showtimeId showtime being viewed
     * @param movieId    movie of the showtime
     */
    void logShowtimeView(String userId, String showtimeId, String movieId);

    /**
     * Log that a user successfully held seats.
     *
     * @param userId     authenticated user ID
     * @param showtimeId showtime of the hold
     * @param holdId     the hold ID returned to the client
     * @param seatCount  number of seats held
     */
    void logSeatHold(String userId, String showtimeId, String holdId, int seatCount);

    /**
     * Log that a booking was created and the payment URL was issued to the client.
     *
     * @param userId      authenticated user ID
     * @param bookingId   newly created booking ID
     * @param showtimeId  showtime of the booking
     * @param totalAmount total amount in VND
     */
    void logPaymentInitiate(String userId, String bookingId, String showtimeId, long totalAmount);

    /**
     * Log that a payment was completed successfully.
     *
     * @param userId        authenticated user ID
     * @param bookingId     booking that was paid
     * @param transactionId VNPay transaction reference
     * @param totalAmount   amount paid in VND
     */
    void logPaymentComplete(String userId, String bookingId, String transactionId, long totalAmount);

    /**
     * Log that a payment failed or timed out.
     *
     * @param userId      authenticated user ID
     * @param bookingId   booking whose payment failed
     * @param reason      VNPay response code or "TIMEOUT"
     */
    void logPaymentFail(String userId, String bookingId, String reason);
}
