package com.cineluxe.controller;

import com.cineluxe.dto.request.ShowtimeScheduleRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.ShowtimeResponse;
import com.cineluxe.entity.Showtime;
import com.cineluxe.entity.ShowtimeSeat;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.MovieRepository;
import com.cineluxe.repository.RoomRepository;
import com.cineluxe.repository.RoomSeatRepository;
import com.cineluxe.repository.ShowtimeRepository;
import com.cineluxe.repository.ShowtimeSeatRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/showtimes")
@RequiredArgsConstructor
@Tag(name = "Admin – Showtimes", description = "Showtime scheduling for admins (R22)")
public class AdminShowtimeController {

    private static final Set<String> ALLOWED_STATUSES =
            Set.of(Showtime.STATUS_SCHEDULED, Showtime.STATUS_CANCELLED, Showtime.STATUS_COMPLETED);

    private final ShowtimeRepository showtimeRepository;
    private final ShowtimeSeatRepository showtimeSeatRepository;
    private final MovieRepository movieRepository;
    private final RoomRepository roomRepository;
    private final RoomSeatRepository roomSeatRepository;

    @PostMapping
    @Transactional
    @Operation(summary = "Tạo suất chiếu và sinh ghế theo layout phòng")
    public ResponseEntity<ApiResponse<ShowtimeResponse>> createShowtime(
            @Valid @RequestBody ShowtimeScheduleRequest request) {
        validateRequest(request);
        var room = roomRepository.findById(request.roomId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng chiếu"));
        var showtime = new Showtime(
                UUID.randomUUID().toString(),
                request.movieId(),
                request.roomId(),
                "CineLuxe",
                request.startTime(),
                request.endTime(),
                request.basePrice());
        showtime.setSeatPrices(
                request.basePrice(),
                seatPriceOrDefault(request.vipSeatPrice(), request.basePrice()),
                seatPriceOrDefault(request.coupleSeatPrice(), request.basePrice()));
        showtime.setStatus(normalizeStatus(request.status()));
        showtimeRepository.save(showtime);

        var seats = roomSeatRepository.findByRoomIdOrderBySeatRowAscSeatColumnAsc(room.getId())
                .stream()
                .map(seat -> new ShowtimeSeat(
                        showtime.getId(),
                        seat.getSeatCode(),
                        seat.getSeatRow(),
                        seat.getSeatColumn(),
                        seat.getSeatType()))
                .toList();
        showtimeSeatRepository.saveAll(seats);

        return ApiResponse.created(ShowtimeResponse.from(showtime, room), "Tạo suất chiếu thành công");
    }

    @PutMapping("/{id}")
    @Transactional
    @Operation(summary = "Cập nhật suất chiếu")
    public ResponseEntity<ApiResponse<ShowtimeResponse>> updateShowtime(
            @PathVariable String id,
            @Valid @RequestBody ShowtimeScheduleRequest request) {
        validateRequest(request);
        var showtime = showtimeRepository.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy suất chiếu"));
        var room = roomRepository.findById(request.roomId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng chiếu"));

        showtime.setMovieId(request.movieId());
        showtime.setRoomId(request.roomId());
        showtime.setStartTime(request.startTime());
        showtime.setEndTime(request.endTime());
        showtime.setSeatPrices(
                request.basePrice(),
                seatPriceOrDefault(request.vipSeatPrice(), request.basePrice()),
                seatPriceOrDefault(request.coupleSeatPrice(), request.basePrice()));
        showtime.setStatus(normalizeStatus(request.status()));
        showtimeRepository.save(showtime);
        return ApiResponse.success(ShowtimeResponse.from(showtime, room), "Cập nhật suất chiếu thành công");
    }

    @DeleteMapping("/{id}")
    @Transactional
    @Operation(summary = "Huỷ suất chiếu")
    public ResponseEntity<ApiResponse<Void>> deleteShowtime(@PathVariable String id) {
        var showtime = showtimeRepository.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy suất chiếu"));
        showtime.setStatus(Showtime.STATUS_CANCELLED);
        showtimeRepository.save(showtime);
        return ApiResponse.success(null, "Đã huỷ suất chiếu");
    }

    private void validateRequest(ShowtimeScheduleRequest request) {
        validateSeatPrices(request);
        if (!movieRepository.existsById(request.movieId())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy phim");
        }
        if (!roomRepository.existsById(request.roomId())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng chiếu");
        }
        if (!request.endTime().isAfter(request.startTime())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "endTime phải sau startTime");
        }
        // Suất chiếu phải bắt đầu sau ít nhất 15 phút (900 giây) kể từ bây giờ
        if (request.startTime().isBefore(Instant.now().plusSeconds(900))) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Suất chiếu phải bắt đầu sau ít nhất 15 phút kể từ bây giờ");
        }
    }

    private void validateSeatPrices(ShowtimeScheduleRequest request) {
        if (request.vipSeatPrice() != null && request.vipSeatPrice() < request.basePrice()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Gia ghe VIP phai lon hon hoac bang ghe thuong");
        }
        if (request.coupleSeatPrice() != null && request.coupleSeatPrice() < request.basePrice()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Gia ghe doi phai lon hon hoac bang ghe thuong");
        }
    }

    private int seatPriceOrDefault(Integer value, int fallback) {
        return value == null ? fallback : value;
    }

    private String normalizeStatus(String status) {
        var normalized = status == null || status.isBlank()
                ? Showtime.STATUS_SCHEDULED
                : status.trim().toLowerCase();
        if (!ALLOWED_STATUSES.contains(normalized)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "status chỉ được là scheduled, cancelled hoặc completed");
        }
        return normalized;
    }
}
