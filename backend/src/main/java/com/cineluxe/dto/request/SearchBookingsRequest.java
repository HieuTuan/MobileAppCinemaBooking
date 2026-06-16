package com.cineluxe.dto.request;

import io.swagger.v3.oas.annotations.Parameter;
import jakarta.validation.constraints.Size;

public record SearchBookingsRequest(
    @Parameter(description = "Booking ID to search (partial match supported)")
    @Size(max = 50, message = "Mã đặt vé không được vượt quá 50 ký tự")
    String bookingId,

    @Parameter(description = "Customer name/ID to search (partial match supported)")
    @Size(max = 100, message = "Tên khách hàng không được vượt quá 100 ký tự")
    String customerName
) {}
