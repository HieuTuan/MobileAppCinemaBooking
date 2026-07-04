package com.cineluxe.service;

import com.cineluxe.entity.Showtime;
import com.cineluxe.repository.ShowtimeRepository;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShowtimeStatusServiceTest {

    @Mock
    private ShowtimeRepository showtimeRepository;

    @InjectMocks
    private ShowtimeStatusService service;

    @Test
    void closesScheduledShowtimesThatAlreadyEnded() {
        var now = Instant.parse("2026-07-04T07:00:00Z");
        var ended = new Showtime(
                "ST-PAST",
                "MV001",
                "ROOM-1",
                "CineLuxe",
                now.minusSeconds(7_200),
                now.minusSeconds(600),
                120_000);
        when(showtimeRepository.findByStatusAndEndTimeBefore(
                Showtime.STATUS_SCHEDULED,
                now)).thenReturn(List.of(ended));

        var closed = service.closeExpiredShowtimes(now);

        assertThat(closed).isEqualTo(1);
        assertThat(ended.getStatus()).isEqualTo(Showtime.STATUS_COMPLETED);
        verify(showtimeRepository).saveAll(List.of(ended));
    }

    @Test
    void doesNotSaveWhenNoShowtimesExpired() {
        var now = Instant.parse("2026-07-04T07:00:00Z");
        when(showtimeRepository.findByStatusAndEndTimeBefore(
                Showtime.STATUS_SCHEDULED,
                now)).thenReturn(List.of());

        var closed = service.closeExpiredShowtimes(now);

        assertThat(closed).isZero();
        verify(showtimeRepository).findByStatusAndEndTimeBefore(
                Showtime.STATUS_SCHEDULED,
                now);
        verifyNoMoreInteractions(showtimeRepository);
    }
}
