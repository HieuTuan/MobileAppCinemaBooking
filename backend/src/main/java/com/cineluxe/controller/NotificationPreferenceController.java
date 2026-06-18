package com.cineluxe.controller;

import com.cineluxe.dto.request.UpdateNotificationPreferenceRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.NotificationPreferenceResponse;
import com.cineluxe.service.NotificationPreferenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Notification Preferences", description = "User notification preferences management")
public class NotificationPreferenceController {

  private final NotificationPreferenceService preferenceService;

  @Operation(summary = "Get notification preferences",
      description = "Retrieve current notification preference settings for a user. "
          + "Returns default values (all enabled) if no preferences have been set.")
  @ApiResponses(value = {
      @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200",
          description = "Preferences retrieved successfully")
  })
  @GetMapping("/users/{userId}/notification-preferences")
  public ResponseEntity<ApiResponse<NotificationPreferenceResponse>> getPreferences(
      @Parameter(description = "User ID") @PathVariable String userId) {
    return ApiResponse.success(preferenceService.getPreferences(userId),
        "Lấy tùy chọn thông báo thành công");
  }

  @Operation(summary = "Update notification preferences",
      description = "Update notification preference settings for a user. "
          + "All preference fields are required and must be explicitly set.")
  @ApiResponses(value = {
      @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200",
          description = "Preferences updated successfully"),
      @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400",
          description = "Invalid request body", content = @Content)
  })
  @PatchMapping("/users/{userId}/notification-preferences")
  public ResponseEntity<ApiResponse<NotificationPreferenceResponse>> updatePreferences(
      @Parameter(description = "User ID") @PathVariable String userId,
      @Valid @RequestBody UpdateNotificationPreferenceRequest request) {
    return ApiResponse.success(preferenceService.updatePreferences(userId, request),
        "Cập nhật tùy chọn thông báo thành công");
  }
}
