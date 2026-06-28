package com.cineluxe.controller;

import com.cineluxe.dto.request.CreateRoomRequest;
import com.cineluxe.dto.request.RoomSeatLayoutRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.RoomResponse;
import com.cineluxe.dto.response.RoomSeatResponse;
import com.cineluxe.entity.Room;
import com.cineluxe.entity.RoomSeat;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.RoomRepository;
import com.cineluxe.repository.RoomSeatRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/rooms")
@RequiredArgsConstructor
@Tag(name = "Admin Rooms", description = "Room management for the single-theater cinema")
public class AdminRoomController {

    private static final Set<String> ALLOWED_STATUSES = Set.of("ready", "maintenance");
    private static final Set<String> ALLOWED_SEAT_TYPES = Set.of("standard", "vip", "couple");
    private static final Set<String> ALLOWED_SCREEN_TYPES = Set.of("2d", "3d", "imax", "screenx");

    private final RoomRepository roomRepository;
    private final RoomSeatRepository roomSeatRepository;

    @GetMapping
    @Transactional(readOnly = true)
    @Operation(summary = "Lấy danh sách phòng chiếu")
    public ResponseEntity<ApiResponse<List<RoomResponse>>> listRooms() {
        var rooms = roomRepository.findAllByOrderByNameAsc()
                .stream()
                .map(this::toResponse)
                .toList();
        return ApiResponse.success(rooms);
    }

    @PostMapping
    @Transactional
    @Operation(summary = "Tạo phòng chiếu và tự sinh ghế theo seatLayout")
    public ResponseEntity<ApiResponse<RoomResponse>> createRoom(
            @Valid @RequestBody CreateRoomRequest request) {

        validateLayout(request);

        var room = new Room(
                UUID.randomUUID().toString(),
                request.theaterId().trim(),
                request.name().trim(),
                request.capacity(),
                request.screenType().trim());
        roomRepository.save(room);

        var seats = request.seatLayout()
                .stream()
                .map(seat -> toRoomSeat(room.getId(), seat))
                .toList();
        roomSeatRepository.saveAll(seats);

        return ApiResponse.created(toResponse(room), "Tạo phòng chiếu thành công");
    }

    @PatchMapping("/{id}/status")
    @Transactional
    @Operation(summary = "Cập nhật trạng thái phòng: ready / maintenance")
    public ResponseEntity<ApiResponse<RoomResponse>> updateStatus(
            @PathVariable String id,
            @RequestBody Map<String, String> body) {

        var room = roomRepository.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy phòng chiếu với id: " + id));
        var status = normalize(body.get("status"));
        if (!ALLOWED_STATUSES.contains(status)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Trạng thái phòng chỉ được là ready hoặc maintenance");
        }

        room.setStatus(status);
        roomRepository.save(room);
        return ApiResponse.success(toResponse(room), "Cập nhật trạng thái phòng thành công");
    }

    @PatchMapping("/{roomId}/seats/{seatCode}/type")
    @Transactional
    @Operation(summary = "Cập nhật loại ghế trong phòng")
    public ResponseEntity<ApiResponse<RoomResponse>> updateSeatType(
            @PathVariable String roomId,
            @PathVariable String seatCode,
            @RequestBody Map<String, String> body) {
        return updateSeatTypeByCode(roomId, seatCode, body.get("seatType"));
    }

    @PatchMapping("/{roomId}/seats/type")
    @Transactional
    @Operation(summary = "Cập nhật loại ghế trong phòng bằng body")
    public ResponseEntity<ApiResponse<RoomResponse>> updateSeatTypeFromBody(
            @PathVariable String roomId,
            @RequestBody Map<String, String> body) {
        return updateSeatTypeByCode(roomId, body.get("seatCode"), body.get("seatType"));
    }

    private ResponseEntity<ApiResponse<RoomResponse>> updateSeatTypeByCode(
            String roomId,
            String seatCode,
            String rawSeatType) {
        var room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy phòng chiếu với id: " + roomId));
        if (seatCode == null || seatCode.isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "seatCode không được để trống");
        }
        var seatType = normalize(rawSeatType);
        if (!ALLOWED_SEAT_TYPES.contains(seatType)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "seatType chỉ được là standard, vip hoặc couple");
        }
        var seat = roomSeatRepository.findByRoomIdAndSeatCode(
                        roomId,
                        seatCode.toUpperCase())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy ghế " + seatCode + " trong phòng"));
        seat.setSeatType(seatType);
        roomSeatRepository.save(seat);
        return ApiResponse.success(toResponse(room), "Cập nhật loại ghế thành công");
    }

    private void validateLayout(CreateRoomRequest request) {
        if (request.capacity() != request.seatLayout().size()) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "capacity phải khớp đúng tổng số ghế trong seatLayout");
        }
        if (!ALLOWED_SCREEN_TYPES.contains(normalize(request.screenType()))) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "screenType chỉ được là 2D, 3D, IMAX hoặc ScreenX");
        }

        var seatCodes = new HashSet<String>();
        var seatPositions = new HashSet<String>();
        for (var seat : request.seatLayout()) {
            var row = seat.row().trim().toUpperCase();
            var seatCode = seatCode(seat).toUpperCase();
            var position = row + ":" + seat.column();
            var type = normalize(seat.seatType());

            if (!ALLOWED_SEAT_TYPES.contains(type)) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                        "seatType chỉ được là standard, vip hoặc couple");
            }
            if (!seatCodes.add(seatCode)) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                        "seatLayout bị trùng seatCode: " + seatCode);
            }
            if (!seatPositions.add(position)) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                        "seatLayout bị trùng vị trí ghế: " + position);
            }
        }
    }

    private RoomSeat toRoomSeat(String roomId, RoomSeatLayoutRequest seat) {
        var row = seat.row().trim().toUpperCase();
        return new RoomSeat(
                roomId,
                seatCode(seat).toUpperCase(),
                row,
                seat.column(),
                normalize(seat.seatType()));
    }

    private String seatCode(RoomSeatLayoutRequest seat) {
        if (seat.seatCode() != null && !seat.seatCode().isBlank()) {
            return seat.seatCode().trim();
        }
        return seat.row().trim().toUpperCase() + seat.column();
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase();
    }

    private RoomResponse toResponse(Room room) {
        var seats = roomSeatRepository.findByRoomIdOrderBySeatRowAscSeatColumnAsc(room.getId())
                .stream()
                .map(RoomSeatResponse::from)
                .toList();
        return RoomResponse.from(room, seats);
    }
}
