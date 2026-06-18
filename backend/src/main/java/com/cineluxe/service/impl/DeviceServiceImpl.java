package com.cineluxe.service.impl;

import com.cineluxe.dto.request.RegisterDeviceRequest;
import com.cineluxe.entity.Device;
import com.cineluxe.repository.DeviceRepository;
import com.cineluxe.service.DeviceService;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceServiceImpl implements DeviceService {

  private final DeviceRepository deviceRepository;

  @Override
  @Transactional
  public void registerDevice(String userId, RegisterDeviceRequest request) {
    var existing = deviceRepository.findByToken(request.deviceToken());

    if (existing.isPresent()) {
      var device = existing.get();
      if (device.getUserId().equals(userId)) {
        device.refreshLastActive();
        log.debug("Refreshed active device for user: {}", userId);
      } else {
        deviceRepository.deleteByToken(request.deviceToken());
        var newDevice = new Device(request.deviceToken(), userId, request.platform());
        deviceRepository.save(newDevice);
        log.debug("Replaced device token from user {} to user {}", device.getUserId(), userId);
      }
    } else {
      var device = new Device(request.deviceToken(), userId, request.platform());
      deviceRepository.save(device);
      log.debug("Registered new device for user: {}", userId);
    }
  }

  @Override
  @Transactional
  public void unregisterDevice(String userId) {
    var devices = deviceRepository.findAllByUserIdAndActiveTrue(userId);
    if (devices.isEmpty()) {
      log.debug("No active devices found for user: {}", userId);
      return;
    }
    devices.forEach(Device::deactivate);
    deviceRepository.saveAll(devices);
    log.debug("Deactivated {} device(s) for user: {}", devices.size(), userId);
  }

  @Override
  @Transactional
  public void refreshToken(String userId, String newDeviceToken) {
    var devices = deviceRepository.findAllByUserIdAndActiveTrue(userId);
    if (devices.isEmpty()) {
      log.debug("No active devices to refresh token for user: {}", userId);
      return;
    }
    for (var device : devices) {
      deviceRepository.deleteByToken(device.getToken());
    }
    var firstDevice = devices.get(0);
    var refreshed = new Device(newDeviceToken, userId, firstDevice.getPlatform());
    deviceRepository.save(refreshed);
    log.debug("Refreshed device token for user: {}", userId);
  }
}
