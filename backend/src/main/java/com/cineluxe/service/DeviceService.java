package com.cineluxe.service;

import com.cineluxe.dto.request.RegisterDeviceRequest;

public interface DeviceService {

  void registerDevice(String userId, RegisterDeviceRequest request);

  void unregisterDevice(String userId);

  void refreshToken(String userId, String newDeviceToken);
}
