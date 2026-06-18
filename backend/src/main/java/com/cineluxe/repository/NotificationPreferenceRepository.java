package com.cineluxe.repository;

import com.cineluxe.entity.NotificationPreference;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface NotificationPreferenceRepository extends JpaRepository<NotificationPreference, String> {

  Optional<NotificationPreference> findByUserId(String userId);
}
