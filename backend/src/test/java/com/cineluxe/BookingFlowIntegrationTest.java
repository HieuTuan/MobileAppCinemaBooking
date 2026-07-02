package com.cineluxe;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import com.cineluxe.repository.BookingRepository;

@SpringBootTest
@AutoConfigureMockMvc
class BookingFlowIntegrationTest {
  @Autowired MockMvc mockMvc;
  @Autowired BookingRepository bookingRepository;

  @Test
  void returnsSeatMapAndActiveCombos() throws Exception {
    mockMvc.perform(get("/api/showtimes/ST001/seats"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.showtimeId").value("ST001"))
        .andExpect(jsonPath("$.data.seats", hasSize(60)));

    mockMvc.perform(get("/api/food-combos"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data", hasSize(2)));
  }

  @Test
  void rejectsASeatHeldByAnotherUser() throws Exception {
    hold("A1", "user-one").andExpect(status().isOk());
    hold("A1", "user-two")
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.unavailableSeats[0]").value("A1"));
  }

  @Test
  void createsBookingFromValidHold() throws Exception {
    var holdResult = hold("B1", "booking-user").andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();
    var holdId = new com.fasterxml.jackson.databind.ObjectMapper()
        .readTree(holdResult).get("data").get("holdId").asText();

    mockMvc.perform(post("/api/bookings")
            .header("X-User-Id", "booking-user")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"holdId":"%s","combos":[{"comboId":"CB01","quantity":1}]}
                """.formatted(holdId)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.data.status").value("pendingPayment"))
        .andExpect(jsonPath("$.data.totalAmount").value(269000));
  }

  @Test
  void extendsExistingHoldForSameUserAndShowtime() throws Exception {
    var first = hold("C1", "extend-user").andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();
    var second = hold("C2", "extend-user").andExpect(status().isOk())
        .andExpect(jsonPath("$.data.seatCodes", hasSize(2)))
        .andReturn().getResponse().getContentAsString();
    var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
    org.junit.jupiter.api.Assertions.assertEquals(
        mapper.readTree(first).get("data").get("holdId").asText(),
        mapper.readTree(second).get("data").get("holdId").asText());
  }

  @Test
  void completesPaymentRetrievesQrHistoryAndCancelsBooking() throws Exception {
    var booking = createBooking("D1", "payment-user");
    var bookingId = booking.get("bookingId").asText();

    var page = mockMvc.perform(get("/api/payments/sandbox/{bookingId}", bookingId))
        .andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();
    var matcher = java.util.regex.Pattern.compile("href=\"([^\"]+)\"").matcher(page);
    org.junit.jupiter.api.Assertions.assertTrue(matcher.find());

    mockMvc.perform(get(java.net.URI.create(matcher.group(1))))
        .andExpect(status().isFound());

    mockMvc.perform(get("/api/bookings/{bookingId}", bookingId))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.status").value("active"))
        .andExpect(jsonPath("$.data.paymentStatus").value("success"));
    mockMvc.perform(get("/api/bookings/{bookingId}/qr", bookingId))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.qrCode", containsString("CINELUXE|" + bookingId)));
    mockMvc.perform(get("/api/users/payment-user/bookings"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data[0].bookingId").value(bookingId));

    mockMvc.perform(post("/api/bookings/{bookingId}/cancel", bookingId)
            .header("X-User-Id", "payment-user")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.status").value("cancelled"))
        .andExpect(jsonPath("$.data.refundAmount").value(120000));
    mockMvc.perform(get("/api/showtimes/ST001/seats"))
        .andExpect(jsonPath("$.data.seats[?(@.code == 'D1')].status").value("available"));
  }

  @Test
  void rejectsInvalidPaymentSignature() throws Exception {
    var bookingId = createBooking("D2", "signature-user").get("bookingId").asText();
    mockMvc.perform(get("/api/payments/vnpay/return")
            .queryParam("bookingId", bookingId)
            .queryParam("responseCode", "00")
            .queryParam("transactionId", "VNP-TAMPERED")
            .queryParam("signature", "invalid"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void validatesActiveTicketWithinWindowAndRejectsSecondValidation() throws Exception {
    var bookingId = createPaidBooking("E1", "ticket-user");
    var booking = bookingRepository.findById(bookingId).orElseThrow();
    booking.updateShowtimeDateTime(java.time.Instant.now().plusSeconds(60 * 60));
    bookingRepository.save(booking);

    validate(bookingId, "ST001")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.success").value(true))
        .andExpect(jsonPath("$.data.status").value("used"))
        .andExpect(jsonPath("$.data.movieTitle").value("CineLuxe Premiere"))
        .andExpect(jsonPath("$.data.seatCodes[0]").value("E1"));

    validate(bookingId, "ST001")
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.message").value("Ticket already validated"));
  }

  @Test
  void enforcesShowtimeAndValidationWindow() throws Exception {
    var wrongShowtimeBookingId = createPaidBooking("E2", "wrong-showtime-user");
    var wrongShowtimeBooking = bookingRepository.findById(wrongShowtimeBookingId).orElseThrow();
    wrongShowtimeBooking.updateShowtimeDateTime(java.time.Instant.now().plusSeconds(60 * 60));
    bookingRepository.save(wrongShowtimeBooking);
    validate(wrongShowtimeBookingId, "ST999")
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.message", containsString("Wrong showtime")));

    var outsideWindowBookingId = createPaidBooking("E3", "outside-window-user");
    validate(outsideWindowBookingId, "ST001")
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.message").value("Validation window closed"));
  }

  private com.fasterxml.jackson.databind.JsonNode createBooking(String seat, String user)
      throws Exception {
    var holdResult = hold(seat, user).andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();
    var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
    var holdId = mapper.readTree(holdResult).get("data").get("holdId").asText();
    var bookingResult = mockMvc.perform(post("/api/bookings")
            .header("X-User-Id", user)
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"holdId\":\"" + holdId + "\",\"combos\":[]}"))
          .andExpect(status().isCreated())
        .andReturn().getResponse().getContentAsString();
    return mapper.readTree(bookingResult).get("data");
  }

  private String createPaidBooking(String seat, String user) throws Exception {
    var bookingId = createBooking(seat, user).get("bookingId").asText();
    var page = mockMvc.perform(get("/api/payments/sandbox/{bookingId}", bookingId))
        .andReturn().getResponse().getContentAsString();
    var matcher = java.util.regex.Pattern.compile("href=\"([^\"]+)\"").matcher(page);
    org.junit.jupiter.api.Assertions.assertTrue(matcher.find());
    mockMvc.perform(get(java.net.URI.create(matcher.group(1))))
        .andExpect(status().isFound());
    return bookingId;
  }

  private org.springframework.test.web.servlet.ResultActions validate(
      String bookingId, String expectedShowtimeId) throws Exception {
    return mockMvc.perform(post("/api/bookings/{bookingId}/validate", bookingId)
        .header("X-Staff-Id", "staff-001")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"expectedShowtimeId\":\"" + expectedShowtimeId + "\"}"));
  }

  private org.springframework.test.web.servlet.ResultActions hold(String seat, String user)
      throws Exception {
    return mockMvc.perform(post("/api/showtimes/ST001/seats/hold")
        .header("X-User-Id", user)
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"seatCodes\":[\"" + seat + "\"]}"));
  }
}
