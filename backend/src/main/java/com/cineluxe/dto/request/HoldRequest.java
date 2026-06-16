package com.cineluxe.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

public record HoldRequest(
    @NotEmpty(message = "Danh sách mã ghế không được để trống")
    @Size(max = 8, message = "Tối đa 8 ghế cho mỗi lần đặt")
    List<@NotBlank(message = "Mã ghế không được để trống") String> seatCodes,
    String userId
) {}
