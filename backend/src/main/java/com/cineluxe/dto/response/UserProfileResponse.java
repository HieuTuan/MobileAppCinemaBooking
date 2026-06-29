package com.cineluxe.dto.response;

import com.cineluxe.entity.UserProfile;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.time.LocalDate;

public record UserProfileResponse(
    @JsonProperty("id") String userId,
    String fullName,
    String phone,
    LocalDate birthdate,
    String email,
    String avatarUrl,
    String memberRank,
    int points,
    String role,
    @JsonProperty("isActive") boolean active,
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
