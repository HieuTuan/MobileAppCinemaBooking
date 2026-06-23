package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "user_profiles",
    indexes = {
        @Index(name = "idx_user_profile_email", columnList = "email"),
        @Index(name = "idx_user_profile_role",  columnList = "role")
    })
public class UserProfile {

    @Id
    private String userId;

    private String fullName;
    private String phone;
    private LocalDate birthdate;
    private String email;
    private String avatarUrl;
    private String passwordHash;
    private String memberRank;  // "silver", "gold", "platinum"
    private int points;
    private String role;        // "customer", "staff", "admin"
    private boolean active;
    private Instant createdAt;
    private Instant updatedAt;

    /** Soft delete timestamp — null means active (Req 32.8). */
    private Instant deletedAt;

    protected UserProfile() {}

    /**
     * Constructor that creates a default profile for a new user.
     */
    public UserProfile(String userId) {
        this.userId = userId;
        this.fullName = userId;
        this.email = userId + "@demo.cineluxe.vn";
        this.memberRank = "silver";
        this.points = 0;
        this.role = "customer";
        this.active = true;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    /** Soft-delete this user profile (Req 32.8). */
    public void softDelete() {
        this.deletedAt = Instant.now();
        this.active = false;
    }

    // Getters

    public String getUserId() { return userId; }
    public String getFullName() { return fullName; }
    public String getPhone() { return phone; }
    public LocalDate getBirthdate() { return birthdate; }
    public String getEmail() { return email; }
    public String getAvatarUrl() { return avatarUrl; }
    public String getPasswordHash() { return passwordHash; }
    public String getMemberRank() { return memberRank; }
    public int getPoints() { return points; }
    public String getRole() { return role; }
    public boolean isActive() { return active; }
    public Instant getCreatedAt() { return createdAt; }

    // Setters for mutable fields

    public void setFullName(String fullName) { this.fullName = fullName; }
    public void setPhone(String phone) { this.phone = phone; }
    public void setBirthdate(LocalDate birthdate) { this.birthdate = birthdate; }
    public void setEmail(String email) { this.email = email; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public void setRole(String role) { this.role = role; }
    public void setActive(boolean active) { this.active = active; }
}
