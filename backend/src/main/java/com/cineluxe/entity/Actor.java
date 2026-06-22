package com.cineluxe.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "actors")
public class Actor {

    @Id
    private String id;

    private String name;
    private String avatarUrl;

    @jakarta.persistence.Column(length = 1200)
    private String description;

    private Instant createdAt;
    private Instant updatedAt;

    protected Actor() {}

    public Actor(String id) {
        this.id = id;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    public String getId() { return id; }
    public String getName() { return name; }
    public String getAvatarUrl() { return avatarUrl; }
    public String getDescription() { return description; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setName(String name) { this.name = name; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public void setDescription(String description) { this.description = description; }
}
