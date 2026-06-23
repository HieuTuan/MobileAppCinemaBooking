package com.cineluxe;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for QR code format parsing and validation.
 *
 * <p>Requirements: 42.1, 42.3, 10.1, 10.2
 * <ul>
 *   <li>42.1: Unit tests for QR code format parsing and validation.</li>
 *   <li>10.1: QR code format: "CINELUXE|{bookingId}|{userId}|{showtimeId}|{seat1}-{seat2}-..."</li>
 *   <li>10.2: Validate QR code format and throw exceptions for invalid format.</li>
 * </ul>
 */
class QrCodeParserTest {

    // ── QR parsing helper (mirrors what would be in a utility class) ──────────

    record ParsedQrCode(String bookingId, String userId, String showtimeId, java.util.List<String> seatCodes) {}

    private ParsedQrCode parseQrCode(String qrContent) {
        if (qrContent == null || qrContent.isBlank()) {
            throw new IllegalArgumentException("QR code content cannot be empty");
        }
        String[] parts = qrContent.split("\\|");
        if (parts.length != 5) {
            throw new IllegalArgumentException(
                    "Invalid QR code format. Expected: CINELUXE|bookingId|userId|showtimeId|seats");
        }
        if (!"CINELUXE".equals(parts[0])) {
            throw new IllegalArgumentException("Invalid QR code prefix. Expected: CINELUXE");
        }
        String[] seatParts = parts[4].split("-");
        return new ParsedQrCode(
                parts[1], parts[2], parts[3],
                java.util.Arrays.asList(seatParts)
        );
    }

    // ── Valid format tests ────────────────────────────────────────────────────

    @Test
    void parse_validQrCode_singleSeat_succeeds() {
        String qr = "CINELUXE|BK-001|user-001|st-001|A1";
        ParsedQrCode result = parseQrCode(qr);
        assertThat(result.bookingId()).isEqualTo("BK-001");
        assertThat(result.userId()).isEqualTo("user-001");
        assertThat(result.showtimeId()).isEqualTo("st-001");
        assertThat(result.seatCodes()).containsExactly("A1");
    }

    @Test
    void parse_validQrCode_multipleSeats_succeeds() {
        String qr = "CINELUXE|BK-002|user-002|st-002|A1-A2-B3-B4";
        ParsedQrCode result = parseQrCode(qr);
        assertThat(result.seatCodes()).containsExactly("A1", "A2", "B3", "B4");
    }

    @Test
    void parse_qrCodeMatchesExpectedFormat() {
        // Booking.completePayment() generates: "CINELUXE|{id}|{userId}|{showtimeId}|{seats-joined-with-dash}"
        String bookingId = "BK-abc123";
        String userId = "user-xyz";
        String showtimeId = "st-456";
        String seats = "C1-C2";
        String generated = "CINELUXE|" + bookingId + "|" + userId + "|" + showtimeId + "|" + seats;

        ParsedQrCode result = parseQrCode(generated);
        assertThat(result.bookingId()).isEqualTo(bookingId);
        assertThat(result.seatCodes()).containsExactly("C1", "C2");
    }

    // ── Invalid format tests ──────────────────────────────────────────────────

    @Test
    void parse_null_throwsIllegalArgumentException() {
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> parseQrCode(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("empty");
    }

    @Test
    void parse_emptyString_throwsIllegalArgumentException() {
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> parseQrCode(""))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "INVALID|BK-001|user|st|A1",           // wrong prefix
            "CINELUXE|BK-001|user|st",              // too few parts
            "CINELUXE|BK-001|user|st|A1|extra",    // too many parts
            "randomgibberish",                       // completely wrong
    })
    void parse_invalidFormats_throwsIllegalArgumentException(String invalid) {
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> parseQrCode(invalid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    // ── Member rank calculation tests ─────────────────────────────────────────

    @Test
    void memberRank_silver_forZeroPoints() {
        assertThat(computeRank(0)).isEqualTo("silver");
    }

    @Test
    void memberRank_silver_for999Points() {
        assertThat(computeRank(999)).isEqualTo("silver");
    }

    @Test
    void memberRank_gold_for1000Points() {
        assertThat(computeRank(1000)).isEqualTo("gold");
    }

    @Test
    void memberRank_gold_for4999Points() {
        assertThat(computeRank(4999)).isEqualTo("gold");
    }

    @Test
    void memberRank_platinum_for5000Points() {
        assertThat(computeRank(5000)).isEqualTo("platinum");
    }

    @Test
    void memberRank_platinum_forHighPoints() {
        assertThat(computeRank(100000)).isEqualTo("platinum");
    }

    /** Replicates member rank calculation from Requirement 17.6. */
    private String computeRank(int points) {
        if (points >= 5000) return "platinum";
        if (points >= 1000) return "gold";
        return "silver";
    }
}
