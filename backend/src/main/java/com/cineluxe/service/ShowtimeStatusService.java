package com.cineluxe.service;

import com.cineluxe.entity.Showtime;
import com.cineluxe.repository.ShowtimeRepository;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ShowtimeStatusService {

    private final ShowtimeRepository showtimeRepository;

    @Scheduled(fixedDelay = 60_000)
    @Transactional
    public void closeExpiredShowtimes() {
        closeExpiredShowtimes(Instant.now());
    }

    @Transactional
    public int closeExpiredShowtimes(Instant now) {
        var expired = showtimeRepository.findByStatusAndEndTimeBefore(
                Showtime.STATUS_SCHEDULED,
                now);
        expired.forEach(showtime -> showtime.setStatus(Showtime.STATUS_COMPLETED));
        if (!expired.isEmpty()) {
            showtimeRepository.saveAll(expired);
            log.info("Closed {} expired showtime(s)", expired.size());
        }
        return expired.size();
    }
}
