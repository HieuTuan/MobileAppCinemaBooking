package com.cineluxe.dto.response;

import com.cineluxe.entity.Actor;
import java.time.Instant;

public record ActorResponse(
        String id,
        String name,
        String avatarUrl,
        String description,
        Instant createdAt,
        Instant updatedAt
) {
    public static ActorResponse from(Actor actor) {
        return new ActorResponse(
                actor.getId(),
                actor.getName(),
                actor.getAvatarUrl() != null ? actor.getAvatarUrl() : "",
                actor.getDescription() != null ? actor.getDescription() : "",
                actor.getCreatedAt(),
                actor.getUpdatedAt()
        );
    }
}
