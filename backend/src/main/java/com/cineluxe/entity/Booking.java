package com.cineluxe.entity;

import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Booking entity with database indexes (Req 32.3) and soft-delete support (Req 32.8).
 */
@Entity
@Table(name = "bookings",
    indexes = {
        @Index(name = "idx_booking_user_id",     columnList = "userId"),
        @Index(name = "idx_booking_showtime_id", columnList = "showtimeId"),
        @Index(name = "idx_booking_status",      columnList = "status")
    })
public class Booking {
  @Id
  private String id;
  private String userId;
  private String showtimeId;
  private String status;
  private String paymentStatus;
  private long totalAmount;
  private Instant createdAt;
  private Instant showtimeDateTime;
  private Instant paymentExpiresAt;
  private Instant paidAt;
  private Instant cancelledAt;
  private Instant validatedAt;
  private Instant refundedAt;
  private String validatedByStaffId;
  private long refundAmount;
  private String transactionId;
  private String responseCode;
  private String movieTitle;
  private String roomName;
  private String cinemaName;
  private String qrCode;
  private String qrCodeUrl;
  @ElementCollection
  private List<String> seatCodes = new ArrayList<>();
  @ElementCollection
  private List<String> comboSelections = new ArrayList<>();

  /** Soft delete timestamp — null means not deleted (Req 32.8). */
  private Instant deletedAt;

  /** Last modification timestamp (Req 32.6). */
  private Instant updatedAt;

  @PreUpdate
  protected void onUpdate() {
    this.updatedAt = Instant.now();
  }

  /** Soft-delete this booking (Req 32.8). */
  public void softDelete() {
    this.deletedAt = Instant.now();
  }

  public Instant getDeletedAt() { return deletedAt; }
  public Instant getUpdatedAt() { return updatedAt; }

  protected Booking() {}

  public Booking(
      String id,
      String userId,
      String showtimeId,
      long totalAmount,
      List<String> seatCodes,
      List<String> comboSelections) {
    this.id = id;
    this.userId = userId;
    this.showtimeId = showtimeId;
    this.status = "pendingPayment";
    this.paymentStatus = "pending";
    this.totalAmount = totalAmount;
    this.createdAt = Instant.now();
    this.showtimeDateTime = Instant.now().plusSeconds(4 * 60 * 60);
    this.paymentExpiresAt = Instant.now().plusSeconds(15 * 60);
    this.movieTitle = "CineLuxe Premiere";
    this.roomName = "Phòng 1";
    this.cinemaName = "CineLuxe Tràng Tiền";
    this.seatCodes = new ArrayList<>(seatCodes);
    this.comboSelections = new ArrayList<>(comboSelections);
  }

  public String getId() { return id; }
  public String getUserId() { return userId; }
  public String getShowtimeId() { return showtimeId; }
  public String getStatus() { return status; }
  public String getPaymentStatus() { return paymentStatus; }
  public long getTotalAmount() { return totalAmount; }
  public Instant getCreatedAt() { return createdAt; }
  public Instant getShowtimeDateTime() { return showtimeDateTime; }
  public Instant getPaymentExpiresAt() { return paymentExpiresAt; }
  public Instant getPaidAt() { return paidAt; }
  public Instant getCancelledAt() { return cancelledAt; }
  public Instant getValidatedAt() { return validatedAt; }
  public Instant getRefundedAt() { return refundedAt; }
  public void setRefundedAt(Instant refundedAt) { this.refundedAt = refundedAt; }
  public String getValidatedByStaffId() { return validatedByStaffId; }
  public long getRefundAmount() { return refundAmount; }
  public String getTransactionId() { return transactionId; }
  public String getResponseCode() { return responseCode; }
  public String getMovieTitle() { return movieTitle; }
  public String getRoomName() { return roomName; }
  public String getCinemaName() { return cinemaName; }
  public String getQrCode() { return qrCode; }
  public String getQrCodeUrl() { return qrCodeUrl; }
  public void setQrCodeUrl(String qrCodeUrl) { this.qrCodeUrl = qrCodeUrl; }
  public List<String> getSeatCodes() { return seatCodes; }
  public List<String> getComboSelections() { return comboSelections; }

  public void completePayment(String transactionId, String responseCode) {
    this.status = "active";
    this.paymentStatus = "success";
    this.transactionId = transactionId;
    this.responseCode = responseCode;
    this.paidAt = Instant.now();
    this.qrCode = "CINELUXE|" + id + "|" + userId + "|" + showtimeId + "|"
        + String.join("-", seatCodes);
  }

  public void failPayment(String transactionId, String responseCode) {
    this.status = "cancelled";
    this.paymentStatus = "failed";
    this.transactionId = transactionId;
    this.responseCode = responseCode;
    this.cancelledAt = Instant.now();
  }

  public void cancel(long refundAmount) {
    this.status = "cancelled";
    this.paymentStatus = refundAmount > 0 ? "refunded" : paymentStatus;
    this.refundAmount = refundAmount;
    this.cancelledAt = Instant.now();
  }

  public void validateTicket(String staffId) {
    this.status = "used";
    this.validatedAt = Instant.now();
    this.validatedByStaffId = staffId;
  }

  public void updateShowtimeDateTime(Instant showtimeDateTime) {
    this.showtimeDateTime = showtimeDateTime;
  }

  /** Cập nhật tên rạp và tên phòng từ Showtime/Room thực tế (R5 — Req 9.1). */
  public void updateCinemaInfo(String cinemaName, String roomName) {
    this.cinemaName = cinemaName;
    this.roomName = roomName;
  }
}
