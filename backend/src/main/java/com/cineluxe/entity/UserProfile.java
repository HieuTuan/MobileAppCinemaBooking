package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "user_profiles")
public class UserProfile {

    @Id
    private String userId;

    private String fullName;
    private String phone;
    private LocalDate birthdate;
    private String email;
    private String avatarUrl;
    private String memberRank;  // "silver", "gold", "platinum"
    private int points;
    private String role;        // "customer", "staff", "admin"
    private boolean active;
    private Instant createdAt;

    protected UserProfile() {}

    /**
     * Constructor that creates a default profile for a new user.
     */
    public UserProfile(String userId) {
        this.userId = userId;
        this.fullName = userId;   // default display name
        this.email = userId + "@demo.cineluxe.vn";
        this.memberRank = "silver";
        this.points = 0;
        this.role = "customer";
        this.active = true;
        this.createdAt = Instant.now();
    }

    // Getters

    public String getUserId() { return userId; }
    public String getFullName() { return fullName; }
    public String getPhone() { return phone; }
    public LocalDate getBirthdate() { return birthdate; }
    public String getEmail() { return email; }
    public String getAvatarUrl() { return avatarUrl; }
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
}
