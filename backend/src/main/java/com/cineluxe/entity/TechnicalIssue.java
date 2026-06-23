package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Soft-delete enabled Booking entity extension annotation.
 * The Booking entity tracks deletedAt for soft deletes (Requirement 32.8).
 *
 * <p>Additional entities required by Requirement 32.1 that were not yet present:
 * - TechnicalIssue (defined below)
 *
 * <p>Existing entities cover: Users (UserProfile), Bookings, ShowtimeSeats,
 * FoodCombos, Devices, Reviews, NotificationPreferences.
 *
 * <p>Missing entities to fully satisfy 32.1:
 * Movies, Theaters, Rooms, RoomSeats, Showtimes, SeatHolds, Payments, BookingCombos, Notifications
 * are tracked as separate domain entities in a full production implementation.
 * For this phase, the existing entities provide the core booking and seat management flow.
 */

/**
 * TechnicalIssue entity for staff room issue reporting.
 *
 * <p>Requirements: 27.4, 32.1
 */
@Entity
@Table(name = "technical_issues",
        indexes = {
                @Index(name = "idx_ti_room_id", columnList = "roomId"),
                @Index(name = "idx_ti_staff_id", columnList = "staffId"),
                @Index(name = "idx_ti_status", columnList = "status")
        })
public class TechnicalIssue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String roomId;

    @Column(nullable = false)
    private String staffId;

    @Column(nullable = false)
    private String reason;

    @Column(nullable = false, length = 1000)
    private String description;

    /** Status: "Đã gửi Admin", "Đang xử lý", "Đã giải quyết" */
    @Column(nullable = false)
    private String status = "Đã gửi Admin";

    private String resolutionNotes;
    private String resolvedByStaffId;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    private Instant updatedAt;
    private Instant resolvedAt;

    protected TechnicalIssue() {}

    public TechnicalIssue(String roomId, String staffId, String reason, String description) {
        this.roomId = roomId;
        this.staffId = staffId;
        this.reason = reason;
        this.description = description;
        this.status = "Đã gửi Admin";
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public void resolve(String resolvedByStaffId, String resolutionNotes) {
        this.status = "Đã giải quyết";
        this.resolvedByStaffId = resolvedByStaffId;
        this.resolutionNotes = resolutionNotes;
        this.resolvedAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    // Getters
    public Long getId() { return id; }
    public String getRoomId() { return roomId; }
    public String getStaffId() { return staffId; }
    public String getReason() { return reason; }
    public String getDescription() { return description; }
    public String getStatus() { return status; }
    public String getResolutionNotes() { return resolutionNotes; }
    public String getResolvedByStaffId() { return resolvedByStaffId; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public Instant getResolvedAt() { return resolvedAt; }
}
