package com.cineluxe.controller;

import com.cineluxe.dto.request.CreateFoodComboRequest;
import com.cineluxe.dto.request.UpdateFoodComboRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.FoodComboResponse;
import com.cineluxe.entity.FoodCombo;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.FoodComboRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Admin CRUD endpoints for Food Combo management (R20).
 *
 * POST  /api/admin/food-combos          – tạo combo
 * PUT   /api/admin/food-combos/{id}     – cập nhật combo
 * PATCH /api/admin/food-combos/{id}     – vô hiệu hoá (isActive=false)
 * GET   /api/admin/food-combos          – tất cả combo (kể cả inactive)
 */
@RestController
@RequestMapping("/api/admin/food-combos")
@RequiredArgsConstructor
@Tag(name = "Admin – Food Combos", description = "Food combo management for admins (R20)")
public class AdminFoodComboController {

    private final FoodComboRepository foodComboRepository;

    // ── GET all (admin view, includes inactive) ────────────────────────────

    @GetMapping
    @Operation(summary = "Lấy tất cả combo (bao gồm inactive)")
    public ResponseEntity<ApiResponse<List<FoodComboResponse>>> listAll() {
        var list = foodComboRepository.findAll()
                .stream().map(FoodComboResponse::from).collect(Collectors.toList());
        return ApiResponse.success(list);
    }

    // ── POST /api/admin/food-combos ────────────────────────────────────────

    @PostMapping
    @Operation(summary = "Tạo combo mới")
    public ResponseEntity<ApiResponse<FoodComboResponse>> createCombo(
            @Valid @RequestBody CreateFoodComboRequest req) {

        if (req.price() <= 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Giá phải lớn hơn 0");
        }

        var combo = new FoodCombo(
                UUID.randomUUID().toString(),
                req.name().trim(),
                req.description() != null ? req.description().trim() : "",
                req.price(),
                req.imageUrl() != null ? req.imageUrl() : "",
                req.quantity() != null ? req.quantity() : 0
        );
        if (req.isActive() != null) combo.setActive(req.isActive());

        foodComboRepository.save(combo);
        return ApiResponse.created(FoodComboResponse.from(combo), "Tạo combo thành công");
    }

    // ── PUT /api/admin/food-combos/{id} ───────────────────────────────────

    @PutMapping("/{id}")
    @Operation(summary = "Cập nhật combo")
    public ResponseEntity<ApiResponse<FoodComboResponse>> updateCombo(
            @PathVariable String id,
            @Valid @RequestBody UpdateFoodComboRequest req) {

        var combo = findOrThrow(id);

        if (req.price() != null && req.price() <= 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Giá phải lớn hơn 0");
        }

        if (req.name()        != null) combo.setName(req.name().trim());
        if (req.description() != null) combo.setDescription(req.description().trim());
        if (req.price()       != null) combo.setPrice(req.price());
        if (req.imageUrl()    != null) combo.setImageUrl(req.imageUrl());
        if (req.quantity()    != null) combo.setQuantity(req.quantity());
        if (req.isActive()    != null) combo.setActive(req.isActive());

        foodComboRepository.save(combo);
        return ApiResponse.success(FoodComboResponse.from(combo), "Cập nhật combo thành công");
    }

    // ── PATCH /api/admin/food-combos/{id} ─────────────────────────────────
    // Body: { "isActive": false }  hoặc {"isActive": true}

    @PatchMapping("/{id}")
    @Operation(summary = "Vô hiệu hoá hoặc kích hoạt lại combo (R20-3)")
    public ResponseEntity<ApiResponse<FoodComboResponse>> toggleActive(
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
                isActive ? "Kích hoạt combo thành công" : "Vô hiệu hoá combo thành công");
    }

    // ── helpers ───────────────────────────────────────────────────────────

    private FoodCombo findOrThrow(String id) {
        return foodComboRepository.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy combo với id: " + id));
    }
}
