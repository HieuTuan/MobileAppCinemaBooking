package com.cineluxe;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
  @Autowired com.cineluxe.repository.ShowtimeSeatRepository seatRepository;
  @Autowired com.cineluxe.repository.ReviewRepository reviewRepository;
  @Autowired com.cineluxe.repository.MovieRepository movieRepository;
  @Autowired com.cineluxe.repository.ShowtimeRepository showtimeRepository;
  @Autowired com.cineluxe.repository.UserProfileRepository userProfileRepository;

  @org.junit.jupiter.api.BeforeEach
  void setUp() {
    bookingRepository.deleteAll();
    reviewRepository.deleteAll();
    showtimeRepository.deleteAll();

    var showtime = new com.cineluxe.entity.Showtime(
        "ST_REV",
        "MV001",
        "room-1",
        "CineLuxe Central",
        java.time.Instant.now().minus(java.time.Duration.ofHours(3))
    );
    showtimeRepository.save(showtime);

    var existingSeatsForRev = seatRepository.findAll().stream()
        .filter(s -> "ST_REV".equals(s.getShowtimeId()))
        .toList();
    if (!existingSeatsForRev.isEmpty()) {
      seatRepository.deleteAll(existingSeatsForRev);
    }

    var reviewSeat = new com.cineluxe.entity.ShowtimeSeat(
        "ST_REV", "R1", "R", 1, "standard"
    );
    seatRepository.save(reviewSeat);

    var seats = seatRepository.findAll();
    for (var seat : seats) {
      seat.release();
    }
    seatRepository.saveAll(seats);

    var movie = movieRepository.findById("MV001").orElse(null);
    if (movie != null) {
      movie.setRating(4.6);
      movieRepository.save(movie);
    }
  }

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
        .andExpect(jsonPath("$.data.data[0].bookingId").value(bookingId));

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

  @Test
  void createsVerifiedReviewRecalculatesRatingAndRejectsUnwatched() throws Exception {
    // 1. User reviews without watching -> 403 Forbidden
    mockMvc.perform(post("/api/reviews")
            .header("X-User-Id", "unwatched-user")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"userId\":\"unwatched-user\",\"movieId\":\"MV001\",\"comment\":\"This is an unwatched review comment length 10\",\"rating\":5}"))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.message").value("You must watch the movie before reviewing"));

    // 2. User has a "used" booking for ST_REV (associated with MV001)
    var holdResult = mockMvc.perform(post("/api/showtimes/ST_REV/seats/hold")
            .header("X-User-Id", "watched-user")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"seatCodes\":[\"R1\"]}"))
        .andExpect(status().isOk())
        .andReturn().getResponse().getContentAsString();

    var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
    var holdId = mapper.readTree(holdResult).get("data").get("holdId").asText();

    var bookingResult = mockMvc.perform(post("/api/bookings")
            .header("X-User-Id", "watched-user")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"holdId\":\"" + holdId + "\",\"combos\":[]}"))
        .andExpect(status().isCreated())
        .andReturn().getResponse().getContentAsString();
    var bookingId = mapper.readTree(bookingResult).get("data").get("bookingId").asText();

    var page = mockMvc.perform(get("/api/payments/sandbox/{bookingId}", bookingId))
        .andReturn().getResponse().getContentAsString();
    var matcher = java.util.regex.Pattern.compile("href=\"([^\"]+)\"").matcher(page);
    org.junit.jupiter.api.Assertions.assertTrue(matcher.find());
    mockMvc.perform(get(java.net.URI.create(matcher.group(1))))
        .andExpect(status().isFound());

    var booking = bookingRepository.findById(bookingId).orElseThrow();
    booking.validateTicket("staff-001");
    bookingRepository.save(booking);

    // 3. User reviews now -> 201 Created and verified = true
    mockMvc.perform(post("/api/reviews")
            .header("X-User-Id", "watched-user")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"userId\":\"watched-user\",\"movieId\":\"MV001\",\"comment\":\"This is a verified review comment length 10\",\"rating\":4}"))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.data.isVerified").value(true))
        .andExpect(jsonPath("$.data.rating").value(4));

    // Verify movie average rating is recalculated (original rating is 4.6, but average of the single review is 4.0)
    var movie = movieRepository.findById("MV001").orElseThrow();
    org.junit.jupiter.api.Assertions.assertEquals(4.0, movie.getRating());
  }

  @Test
  void verifiesProfileUpdatesValidationAndEmailChangeConfirmationFlow() throws Exception {
    var userId = "profile-test-user";
    userProfileRepository.deleteById(userId);

    // 1. Get profile (will create if not exists)
    mockMvc.perform(get("/api/users/{userId}/profile", userId))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.memberRank").value("silver"))
        .andExpect(jsonPath("$.data.points").value(0));

    // 2. Validate phone formatting (invalid)
    mockMvc.perform(put("/api/users/{userId}/profile", userId)
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"phone\":\"12345\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.message").value("Invalid phone format: must be 0XXXXXXXXX or +84XXXXXXXXX"));

    // Valid phone (09XXXXXXXX)
    mockMvc.perform(put("/api/users/{userId}/profile", userId)
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"phone\":\"0987654321\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.phone").value("0987654321"));

    // 3. Validate birthdate (future date -> 400 Bad Request)
    var futureDate = java.time.LocalDate.now().plusDays(1).toString();
    mockMvc.perform(put("/api/users/{userId}/profile", userId)
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"birthdate\":\"" + futureDate + "\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.message").value("Birthdate cannot be in the future"));

    // 4. Validate member rank dynamic calculation
    var profile = userProfileRepository.findById(userId).orElseThrow();
    // Silver (0-999)
    profile.setPoints(999);
    userProfileRepository.save(profile);
    mockMvc.perform(get("/api/users/{userId}/profile", userId))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.memberRank").value("silver"));

    // Gold (1000-4999)
    profile.setPoints(1000);
    userProfileRepository.save(profile);
    mockMvc.perform(get("/api/users/{userId}/profile", userId))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.memberRank").value("gold"));

    // Platinum (>= 5000)
    profile.setPoints(5000);
    userProfileRepository.save(profile);
    mockMvc.perform(get("/api/users/{userId}/profile", userId))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.memberRank").value("platinum"));

    // 5. Email confirmation flow
    mockMvc.perform(put("/api/users/{userId}/profile", userId)
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"email\":\"new-email@cineluxe.vn\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.email").value(userId + "@demo.cineluxe.vn")); // Still old email

    var updatedProfile = userProfileRepository.findById(userId).orElseThrow();
    var code = updatedProfile.getEmailVerificationCode();
    org.junit.jupiter.api.Assertions.assertNotNull(code);
    org.junit.jupiter.api.Assertions.assertEquals("new-email@cineluxe.vn", updatedProfile.getPendingEmail());

    // Confirm with wrong code -> 400
    mockMvc.perform(post("/api/users/{userId}/profile/confirm-email", userId)
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"code\":\"000000\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.message").value("Mã xác thực không chính xác"));

    // Confirm with correct code -> 200 OK and email updated
    mockMvc.perform(post("/api/users/{userId}/profile/confirm-email", userId)
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"code\":\"" + code + "\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.email").value("new-email@cineluxe.vn"));
  }
}
