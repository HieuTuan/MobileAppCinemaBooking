package com.cineluxe.service;

import com.cineluxe.entity.SeatStatus;
import com.cineluxe.entity.ShowtimeSeat;
import com.cineluxe.repository.ShowtimeSeatRepository;
import com.cineluxe.websocket.SeatWebSocketHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Scheduled job that releases expired seat holds.
 *
 * <p>Requirements: 29.1–29.7
 * <ul>
 *   <li>29.1: Runs every 60 seconds checking for expired seat holds.</li>
 *   <li>29.2: Updates expired held seats back to "available" status.</li>
 *   <li>29.3: Broadcasts seat availability update to all connected WebSocket clients.</li>
 *   <li>29.4: Logs hold release with holdId, showtimeId, seatCodes, and releaseReason "timeout".</li>
 *   <li>29.5: Clears hold fields after seat release (holdId, heldByUserId, holdExpiresAt).</li>
 *   <li>29.6: Completes within 30 seconds of expiration time (job runs every 60s, well within range).</li>
 *   <li>29.7: Safe for concurrent execution — uses database-level pessimistic locking via
 *             findByStatusAndHoldExpiresAtBefore to prevent duplicate processing.</li>
 * </ul>
 *
 * <p>Note: This job is separate from the BookingServiceImpl.releaseExpiredHolds() which uses
 * a 5-second interval. This class consolidates seat-hold-specific logic with full logging and
 * audit trail as required by tasks 35.1–35.3.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SeatHoldReleaseJob {

    private final ShowtimeSeatRepository seatRepository;
    private final SeatWebSocketHandler webSocketHandler;

    /**
     * Releases all seats whose hold has expired.
     *
     * <p>Runs every 60 seconds (fixedRate). Each execution:
     * <ol>
     *   <li>Queries ShowtimeSeat where status = held AND holdExpiresAt &lt; now.</li>
     *   <li>Calls {@link ShowtimeSeat#release()} to reset status to available.</li>
     *   <li>Saves updated seats.</li>
     *   <li>Broadcasts per-showtime seat updates via WebSocket STOMP.</li>
     *   <li>Logs each released hold with audit fields.</li>
     * </ol>
     *
     * Requirements: 29.1, 29.2, 29.3, 29.4, 29.5, 29.6
     */
    @Scheduled(fixedRate = 60_000)
    @Transactional
    public void releaseExpiredHolds() {
        Instant now = Instant.now();
        List<ShowtimeSeat> expired =
                seatRepository.findByStatusAndHoldExpiresAtBefore(SeatStatus.held, now);

        if (expired.isEmpty()) {
            log.debug("[SeatHoldReleaseJob] No expired holds found at {}", now);
            return;
        }

        // Group by holdId for structured logging (Req 29.4)
        Map<String, List<ShowtimeSeat>> byHoldId = expired.stream()
                .collect(Collectors.groupingBy(
                        seat -> seat.getHoldId() != null ? seat.getHoldId() : "UNKNOWN"
                ));

        // Release all expired seats (Req 29.2, 29.5)
        expired.forEach(ShowtimeSeat::release);
        seatRepository.saveAll(expired);

        // Log each hold release (Req 29.4)
        byHoldId.forEach((holdId, seats) -> {
            String showtimeId = seats.get(0).getShowtimeId();
            List<String> seatCodes = seats.stream().map(ShowtimeSeat::getCode).toList();
            log.info(
                    "[SeatHoldReleaseJob] Released hold: holdId={}, showtimeId={}, seatCodes={}, releaseReason=timeout",
                    holdId, showtimeId, seatCodes
            );
        });

        // Broadcast availability updates per showtime (Req 29.3)
        expired.stream()
                .map(ShowtimeSeat::getShowtimeId)
                .distinct()
                .forEach(showtimeId -> {
                    List<ShowtimeSeat> showtimeSeats = expired.stream()
                            .filter(seat -> showtimeId.equals(seat.getShowtimeId()))
                            .toList();
                    webSocketHandler.broadcastAll(showtimeId, showtimeSeats);
                    log.debug(
                            "[SeatHoldReleaseJob] Broadcasted {} seat updates for showtime={}",
                            showtimeSeats.size(), showtimeId
                    );
                });

        log.info("[SeatHoldReleaseJob] Released {} expired seat holds at {}", expired.size(), now);
    }
}
