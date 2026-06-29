package com.cineluxe.controller;

import com.cineluxe.dto.request.UpdateProfileRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.UserProfileResponse;
import com.cineluxe.service.UserProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users/{userId}")
@RequiredArgsConstructor
@Tag(name = "User Profile", description = "User profile management")
public class UserProfileController {

    private final UserProfileService userProfileService;

    @GetMapping("/profile")
    @Operation(summary = "Get user profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfile(
            @PathVariable String userId) {
        return ApiResponse.success(userProfileService.getProfile(userId));
    }

    @PutMapping("/profile")
    @Operation(summary = "Update user profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @PathVariable String userId,
            @Valid @RequestBody UpdateProfileRequest request) {
        return ApiResponse.success(userProfileService.updateProfile(userId, request));
    }
}
