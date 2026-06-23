package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.FoodComboResponse;
import com.cineluxe.entity.FoodCombo;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.FoodComboRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/staff/food-combos")
@RequiredArgsConstructor
@Tag(name = "Staff Food Combos", description = "Food combo availability controls for staff")
public class StaffFoodComboController {

    private final FoodComboRepository foodComboRepository;

    @GetMapping
    @Operation(summary = "Staff xem tất cả combo và tồn kho")
    public ResponseEntity<ApiResponse<List<FoodComboResponse>>> listAll() {
        var list = foodComboRepository.findAll()
                .stream()
                .map(FoodComboResponse::from)
                .toList();
        return ApiResponse.success(list);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Staff bật/tắt trạng thái bán combo")
    public ResponseEntity<ApiResponse<FoodComboResponse>> updateStatus(
            @PathVariable String id,
            @RequestBody Map<String, Boolean> body) {

        var combo = findOrThrow(id);
        Boolean isActive = body.get("isActive");
        if (isActive == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Body phải chứa trường 'isActive' (true/false)");
        }

        combo.setActive(isActive);
        foodComboRepository.save(combo);
        return ApiResponse.success(FoodComboResponse.from(combo),
                isActive ? "Đã mở bán combo" : "Đã tạm ngưng combo");
    }

    private FoodCombo findOrThrow(String id) {
        return foodComboRepository.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy combo với id: " + id));
    }
}
