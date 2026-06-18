package com.cineluxe.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import java.time.Instant;

@Entity
public class Device {

  @Id
  private String token;

  private String userId;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false)
  private Platform platform;

  private Instant createdAt;
  private Instant lastActiveAt;
  private boolean active = true;

  protected Device() {}

  public Device(String token, String userId, Platform platform) {
    this.token = token;
    this.userId = userId;
    this.platform = platform;
    this.createdAt = Instant.now();
    this.lastActiveAt = Instant.now();
    this.active = true;
  }

  public void refreshLastActive() {
    this.lastActiveAt = Instant.now();
  }

  public void deactivate() {
    this.active = false;
  }

  public String getToken() { return token; }
  public String getUserId() { return userId; }
  public Platform getPlatform() { return platform; }
  public Instant getCreatedAt() { return createdAt; }
  public Instant getLastActiveAt() { return lastActiveAt; }
  public boolean isActive() { return active; }
}
