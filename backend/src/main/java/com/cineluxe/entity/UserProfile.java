package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

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
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "user_permissions", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "permission")
    private List<String> permissions = new ArrayList<>();
    private boolean active;
    private Instant createdAt;
    private Instant updatedAt;

    /** Soft delete timestamp — null means active (Req 32.8). */
    private Instant deletedAt;

    private String pendingEmail;
    private String emailVerificationCode;
    private Instant emailVerificationExpiresAt;

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
    
    public String getMemberRank() {
        if (points >= 5000) return "platinum";
        if (points >= 1000) return "gold";
        return "silver";
    }

    public int getPoints() { return points; }
    public String getRole() { return role; }
    public List<String> getPermissions() { return permissions; }
    public boolean isActive() { return active; }
    public Instant getCreatedAt() { return createdAt; }
    public String getPendingEmail() { return pendingEmail; }
    public String getEmailVerificationCode() { return emailVerificationCode; }
    public Instant getEmailVerificationExpiresAt() { return emailVerificationExpiresAt; }

    // Setters for mutable fields

    public void setFullName(String fullName) { this.fullName = fullName; }
    public void setPhone(String phone) { this.phone = phone; }
    public void setBirthdate(LocalDate birthdate) { this.birthdate = birthdate; }
    public void setEmail(String email) { this.email = email; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public void setRole(String role) { this.role = role; }
    public void setPermissions(List<String> permissions) {
        this.permissions = permissions != null ? new ArrayList<>(permissions) : new ArrayList<>();
    }
    public void setPoints(int points) { this.points = points; }
    public void setActive(boolean active) { this.active = active; }
    public void setPendingEmail(String pendingEmail) { this.pendingEmail = pendingEmail; }
    public void setEmailVerificationCode(String code) { this.emailVerificationCode = code; }
    public void setEmailVerificationExpiresAt(Instant expiresAt) { this.emailVerificationExpiresAt = expiresAt; }
}
