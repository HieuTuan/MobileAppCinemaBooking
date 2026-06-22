package com.cineluxe.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record CreateRoomRequest(
        @NotBlank(message = "theaterId không được để trống")
        String theaterId,

        @NotBlank(message = "Tên phòng không được để trống")
        String name,

        @Min(value = 1, message = "Sức chứa phải lớn hơn 0")
        int capacity,

        @NotBlank(message = "Công nghệ chiếu không được để trống")
        String screenType,

        @NotEmpty(message = "seatLayout không được để trống")
        List<@Valid RoomSeatLayoutRequest> seatLayout
) {}
