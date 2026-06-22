package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.FoodComboResponse;
import com.cineluxe.repository.FoodComboRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public endpoint for food combos (R20-4).
 * GET /api/food-combos – chỉ trả về active=true, ẩn inactive khỏi khách hàng.
 */
@RestController
@RequestMapping("/api/food-combos")
@RequiredArgsConstructor
@Tag(name = "Food Combos", description = "Public active food combos (R20)")
public class FoodComboController {

    private final FoodComboRepository foodComboRepository;

    @GetMapping
    @Operation(summary = "Lấy danh sách combo (chỉ active)")
    public ResponseEntity<ApiResponse<List<FoodComboResponse>>> listActiveCombos() {
        var list = foodComboRepository.findAll()
                .stream()
                .filter(c -> c.isActive())
                .map(FoodComboResponse::from)
                .collect(Collectors.toList());
        return ApiResponse.success(list);
    }
}
