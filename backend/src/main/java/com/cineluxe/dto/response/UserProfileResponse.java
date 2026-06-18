package com.cineluxe.dto.response;

import com.cineluxe.entity.UserProfile;
import java.time.Instant;
import java.time.LocalDate;

public record UserProfileResponse(
    String userId,
    String fullName,
    String phone,
    LocalDate birthdate,
    String email,
    String avatarUrl,
    String memberRank,
    int points,
    String role,
    boolean active,
    Instant createdAt
) {
    public static UserProfileResponse from(UserProfile p) {
        return new UserProfileResponse(
            p.getUserId(),
            p.getFullName(),
            p.getPhone(),
            p.getBirthdate(),
            p.getEmail(),
            p.getAvatarUrl(),
            p.getMemberRank(),
            p.getPoints(),
            p.getRole(),
            p.isActive(),
            p.getCreatedAt()
        );
    }
}
