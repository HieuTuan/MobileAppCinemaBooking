package com.cineluxe.api;

import com.cineluxe.domain.FoodCombo;
import com.cineluxe.domain.ShowtimeSeat;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;

public final class ApiDtos {
  private ApiDtos() {}

  public record SeatDto(
      String code, String row, int column, String type, String status) {
    public static SeatDto from(ShowtimeSeat seat) {
      return new SeatDto(
          seat.getCode(),
          seat.getSeatRow(),
          seat.getSeatColumn(),
          seat.getType(),
          seat.getStatus().name());
    }
  }

  public record SeatMapResponse(String showtimeId, List<SeatDto> seats) {}

  public record HoldRequest(
      @NotEmpty @Size(max = 8) List<@NotBlank String> seatCodes,
      String userId) {}

  public record HoldResponse(
      String holdId, String showtimeId, List<String> seatCodes, Instant expiresAt) {}

  public record ComboDto(
      String id, String name, String description, long price, String imageUrl) {
    public static ComboDto from(FoodCombo combo) {
      return new ComboDto(
          combo.getId(),
          combo.getName(),
          combo.getDescription(),
          combo.getPrice(),
          combo.getImageUrl());
    }
  }

  public record ComboSelection(@NotBlank String comboId, @Min(1) @Max(20) int quantity) {}

  public record CreateBookingRequest(
      @NotBlank String holdId,
      String userId,
      List<@Valid ComboSelection> combos) {}

  public record BookingResponse(
      String bookingId,
      String status,
      String paymentStatus,
      long totalAmount,
      String paymentUrl,
      Instant paymentExpiresAt) {}

  public record BookingDetailsResponse(
      String bookingId,
      String userId,
      String showtimeId,
      String movieTitle,
      String roomName,
      String cinemaName,
      Instant showtimeDateTime,
      List<String> seatCodes,
      List<String> combos,
      long totalAmount,
      String status,
      String paymentStatus,
      Instant createdAt,
      String qrCode) {}

  public record BookingQrResponse(
      String bookingId,
      String qrCode,
      String movieTitle,
      Instant showtimeDateTime,
      String roomName,
      String cinemaName,
      List<String> seatCodes) {}

  public record PaymentStatusResponse(
      String bookingId, String status, String paymentStatus, String transactionId, String responseCode) {}

  public record CancelBookingRequest(String userId) {}

  public record CancelBookingResponse(
      String bookingId, String status, long refundAmount, String refundStatus) {}

  public record ValidateTicketRequest(
      @NotBlank String expectedShowtimeId,
      String staffId) {}

  public record ValidationResult(
      boolean success,
      String status,
      String message,
      String bookingId,
      String customerName,
      String movieTitle,
      String showtimeId,
      Instant showtimeDateTime,
      List<String> seatCodes,
      Instant validatedAt) {}
}
