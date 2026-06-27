package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.ComboDto;
import com.cineluxe.service.BookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Luồng Chọn combo đồ ăn — Requirement R8.
 *
 * <p>Bước 1: GET /api/food-combos → danh sách combo active (trong 200ms).
 * <p>Lỗi: ComboId invalid hoặc inactive → 400 "Invalid food combo selection"
 *   (được xử lý tại BookingServiceImpl khi submit booking).
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Food Combos", description = "Danh sách combo đồ ăn đặt kèm vé (R8)")
public class FoodComboController {

    private final BookingService bookingService;

    /**
     * Bước 1 — GET /api/food-combos.
     *
     * <p>Trả về tất cả combo có {@code active = true}.
     * Không có combo active → mảng rỗng, 200 OK.
     * Phản hồi trong 200ms (chỉ đọc từ cache DB).
     */
    @GetMapping("/food-combos")
    @Operation(
        summary     = "Lấy danh sách combo đồ ăn active",
        description = """
            Trả về tất cả combo có trạng thái active = true.
            - Phản hồi trong 200ms
            - Không có combo → mảng rỗng, 200 OK
            - Combo được dùng ở bước 4: submit booking kèm [{comboId, quantity}]
            """
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(
            responseCode = "200",
            description  = "Danh sách combo active (rỗng nếu không có)"
        )
    })
    public ResponseEntity<ApiResponse<List<ComboDto>>> getFoodCombos() {
        return ApiResponse.success(bookingService.getCombos());
    }
}
