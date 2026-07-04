package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.ShowtimeResponse;
import com.cineluxe.entity.Showtime;
import com.cineluxe.repository.RoomRepository;
import com.cineluxe.repository.ShowtimeRepository;
import com.cineluxe.service.ShowtimeStatusService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/showtimes")
@RequiredArgsConstructor
@Tag(name = "Showtimes", description = "Public showtime listing endpoints")
public class ShowtimeController {

    private final ShowtimeRepository showtimeRepository;
    private final RoomRepository roomRepository;
    private final ShowtimeStatusService showtimeStatusService;

    @GetMapping
    @Operation(summary = "Lấy danh sách suất chiếu, có thể lọc theo movieId")
    public ResponseEntity<ApiResponse<List<ShowtimeResponse>>> listShowtimes(
            @RequestParam(required = false) String movieId) {
        showtimeStatusService.closeExpiredShowtimes();
        var showtimes = movieId == null || movieId.isBlank()
                ? showtimeRepository.findByStatusNotOrderByStartTimeAsc(Showtime.STATUS_CANCELLED)
                : showtimeRepository.findByMovieIdAndStatusNotOrderByStartTimeAsc(
                        movieId,
                        Showtime.STATUS_CANCELLED);

        var responses = showtimes.stream()
                .map(showtime -> ShowtimeResponse.from(
                        showtime,
                        roomRepository.findById(showtime.getRoomId()).orElse(null)))
                .toList();

        return ApiResponse.success(responses);
    }
}
