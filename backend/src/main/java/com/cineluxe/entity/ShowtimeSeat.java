package com.cineluxe.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Version;
import java.time.Instant;

@Entity
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"showtimeId", "code"}))
public class ShowtimeSeat {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;
  private String showtimeId;
  private String code;
  private String seatRow;
  private int seatColumn;
  private String type;
  @Enumerated(EnumType.STRING)
  private SeatStatus status = SeatStatus.available;
  private String holdId;
  private String heldByUserId;
  private Instant holdExpiresAt;
  @Version
  private long version;

  protected ShowtimeSeat() {}

  public ShowtimeSeat(String showtimeId, String code, String seatRow, int seatColumn, String type) {
    this.showtimeId = showtimeId;
    this.code = code;
    this.seatRow = seatRow;
    this.seatColumn = seatColumn;
    this.type = type;
  }

  public String getShowtimeId() { return showtimeId; }
  public String getCode() { return code; }
  public String getSeatRow() { return seatRow; }
  public int getSeatColumn() { return seatColumn; }
  public String getType() { return type; }
  public SeatStatus getStatus() { return status; }
  public String getHoldId() { return holdId; }
  public String getHeldByUserId() { return heldByUserId; }
  public Instant getHoldExpiresAt() { return holdExpiresAt; }

  public void hold(String holdId, String userId, Instant expiresAt) {
    this.status = SeatStatus.held;
    this.holdId = holdId;
    this.heldByUserId = userId;
    this.holdExpiresAt = expiresAt;
  }

  public void book() {
    this.status = SeatStatus.booked;
    clearHold();
  }

  public void release() {
    this.status = SeatStatus.available;
    clearHold();
  }

  private void clearHold() {
    this.holdId = null;
    this.heldByUserId = null;
    this.holdExpiresAt = null;
  }
}
