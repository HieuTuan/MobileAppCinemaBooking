package com.cineluxe.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Stores per-user notification preference settings.
 * Each user has exactly one preferences record, keyed by userId.
 */
@Entity
@Table(name = "notification_preferences")
public class NotificationPreference {

  @Id
  private String userId;

  @Column(name = "showtime_reminders", nullable = false)
  private boolean showtimeReminders = true;

  @Column(name = "promotions", nullable = false)
  private boolean promotions = true;

  @Column(name = "new_movies", nullable = false)
  private boolean newMovies = true;

  @Column(name = "booking_updates", nullable = false)
  private boolean bookingUpdates = true;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected NotificationPreference() {}

  public NotificationPreference(String userId) {
    this.userId = userId;
    this.createdAt = Instant.now();
    this.updatedAt = Instant.now();
  }

  public void update(boolean showtimeReminders, boolean promotions,
                     boolean newMovies, boolean bookingUpdates) {
    this.showtimeReminders = showtimeReminders;
    this.promotions = promotions;
    this.newMovies = newMovies;
    this.bookingUpdates = bookingUpdates;
    this.updatedAt = Instant.now();
  }

  public String getUserId() { return userId; }
  public boolean isShowtimeReminders() { return showtimeReminders; }
  public boolean isPromotions() { return promotions; }
  public boolean isNewMovies() { return newMovies; }
  public boolean isBookingUpdates() { return bookingUpdates; }
  public Instant getCreatedAt() { return createdAt; }
  public Instant getUpdatedAt() { return updatedAt; }
}
