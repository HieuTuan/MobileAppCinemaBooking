package com.cineluxe.dto.response;

import com.cineluxe.entity.UserProfile;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public record AuthUserResponse(
        String id,
        String email,
        String fullName,
        String phone,
        LocalDate birthdate,
        String avatarUrl,
        String memberRank,
        int points,
        String role,
        List<String> permissions,
        @JsonProperty("isActive") boolean active,
        Instant createdAt
) {
    public static AuthUserResponse from(UserProfile profile) {
        return new AuthUserResponse(
                profile.getUserId(),
                profile.getEmail(),
                profile.getFullName(),
                profile.getPhone(),
                profile.getBirthdate(),
                profile.getAvatarUrl(),
                profile.getMemberRank(),
                profile.getPoints(),
                profile.getRole(),
                null,
                profile.isActive(),
                profile.getCreatedAt()
        );
    }
}
