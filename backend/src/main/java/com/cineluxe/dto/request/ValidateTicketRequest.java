package com.cineluxe.dto.request;

import jakarta.validation.constraints.NotBlank;

public record ValidateTicketRequest(
    @NotBlank(message = "Mã suất chiếu dự kiến không được để trống")
    String expectedShowtimeId,
    
    String staffId
) {}
