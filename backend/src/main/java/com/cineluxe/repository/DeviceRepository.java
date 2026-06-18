package com.cineluxe.repository;

import com.cineluxe.entity.Device;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DeviceRepository extends JpaRepository<Device, String> {

  Optional<Device> findByToken(String token);

  Optional<Device> findByUserIdAndActiveTrue(String userId);

  List<Device> findAllByUserIdAndActiveTrue(String userId);

  List<Device> findAllByActiveTrue();

  void deleteByToken(String token);
}
