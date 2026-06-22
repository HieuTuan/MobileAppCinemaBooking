package com.cineluxe.repository;

import com.cineluxe.entity.NotificationPreferences;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository for NotificationPreferences entity.
 * 
 * Requirements Coverage:
 * - Requirement 38.1: Query preferences by userId
 * - Requirement 38.3: Update preferences by userId
 */
@Repository
public interface NotificationPreferencesRepository extends JpaRepository<NotificationPreferences, String> {
    
    /**
     * Find notification preferences by user ID
     * 
     * @param userId User ID
     * @return Optional containing preferences if found
     */
    Optional<NotificationPreferences> findByUserId(String userId);
    
    /**
     * Check if preferences exist for a user
     * 
     * @param userId User ID
     * @return true if preferences exist
     */
    boolean existsByUserId(String userId);
}
