package com.cineluxe.controller;

import com.cineluxe.dto.request.RegisterDeviceRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.DeviceRegistrationResponse;
import com.cineluxe.service.DeviceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Device", description = "Device registration for push notifications")
public class DeviceController {

  private final DeviceService deviceService;

  @Operation(summary = "Register device for push notifications",
      description = "Register or update a device FCM/APNs token for the authenticated user")
  @ApiResponses(value = {
      @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Device registered successfully"),
      @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid request")
  })
  @PostMapping("/devices/register")
  public ResponseEntity<ApiResponse<DeviceRegistrationResponse>> registerDevice(
      @Valid @RequestBody RegisterDeviceRequest request,
      @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
    deviceService.registerDevice(userId, request);
    var response = new DeviceRegistrationResponse(request.deviceToken(), userId, true);
    return ApiResponse.success(response, "Đăng ký thiết bị thành công");
  }

  @Operation(summary = "Register user device for push notifications",
      description = "Requirement-compatible endpoint: POST /api/users/{userId}/devices")
  @PostMapping("/users/{userId}/devices")
  public ResponseEntity<ApiResponse<DeviceRegistrationResponse>> registerUserDevice(
      @PathVariable String userId,
      @Valid @RequestBody RegisterDeviceRequest request) {
    deviceService.registerDevice(userId, request);
    var response = new DeviceRegistrationResponse(request.deviceToken(), userId, true);
    return ApiResponse.success(response, "Đăng ký thiết bị thành công");
  }

  @Operation(summary = "Unregister device on logout",
      description = "Clear all device tokens for the authenticated user when logging out")
  @ApiResponses(value = {
      @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Device unregistered successfully")
  })
  @PostMapping("/devices/unregister")
  public ResponseEntity<ApiResponse<Void>> unregisterDevice(
      @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
    deviceService.unregisterDevice(userId);
    return ApiResponse.success(null, "Đã hủy đăng ký thiết bị");
  }

  @Operation(summary = "Unregister one user device on logout",
      description = "Requirement-compatible endpoint: DELETE /api/users/{userId}/devices/{deviceToken}")
  @DeleteMapping("/users/{userId}/devices/{deviceToken}")
  public ResponseEntity<Void> unregisterUserDevice(
      @PathVariable String userId,
      @PathVariable String deviceToken) {
    deviceService.unregisterDevice(userId, deviceToken);
    return ResponseEntity.noContent().build();
  }

  @Operation(summary = "Refresh device token",
      description = "Update the FCM/APNs token when it changes (e.g., after app update or token rotation)")
  @ApiResponses(value = {
      @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Token refreshed successfully")
  })
  @PostMapping("/devices/refresh")
  public ResponseEntity<ApiResponse<DeviceRegistrationResponse>> refreshToken(
      @Valid @RequestBody RegisterDeviceRequest request,
      @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
    deviceService.refreshToken(userId, request.deviceToken());
    var response = new DeviceRegistrationResponse(request.deviceToken(), userId, true);
    return ApiResponse.success(response, "Token thiết bị đã được làm mới");
  }
}
