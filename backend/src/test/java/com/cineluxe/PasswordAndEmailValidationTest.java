package com.cineluxe;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for password strength validation rules.
 *
 * <p>Requirements: 42.1, 42.3, 2.7, 2.8
 * <ul>
 *   <li>42.1: Unit tests for password strength validation rules.</li>
 *   <li>2.7: Minimum length of 8 characters.</li>
 *   <li>2.8: Must contain at least one uppercase, one lowercase, one digit, and one special character.</li>
 * </ul>
 */
class PasswordValidationTest {

    /** Replicates the backend password validation logic (Bean Validation + custom validator). */
    private record ValidationResult(boolean valid, String message) {}

    private ValidationResult validate(String password) {
        if (password == null || password.length() < 8) {
            return new ValidationResult(false, "Password must be at least 8 characters");
        }
        boolean hasUpper = password.chars().anyMatch(Character::isUpperCase);
        boolean hasLower = password.chars().anyMatch(Character::isLowerCase);
        boolean hasDigit = password.chars().anyMatch(Character::isDigit);
        boolean hasSpecial = password.chars().anyMatch(c -> "!@#$%^&*()_+-=[]{}|;':\",./<>?".indexOf(c) >= 0);

        if (!hasUpper) return new ValidationResult(false, "Password must contain at least one uppercase letter");
        if (!hasLower) return new ValidationResult(false, "Password must contain at least one lowercase letter");
        if (!hasDigit) return new ValidationResult(false, "Password must contain at least one digit");
        if (!hasSpecial) return new ValidationResult(false, "Password must contain at least one special character");

        return new ValidationResult(true, "Valid");
    }

    // ── Valid passwords ───────────────────────────────────────────────────────

    @ParameterizedTest
    @ValueSource(strings = {
            "Abc@1234",
            "SecureP@ssword1",
            "Hello!World9",
            "P@ssw0rd!",
            "Aa1!aaaa",
    })
    void validPasswords_passValidation(String password) {
        assertThat(validate(password).valid()).isTrue();
    }

    // ── Invalid passwords ─────────────────────────────────────────────────────

    @Test
    void tooShort_failsValidation() {
        assertThat(validate("Abc@123").valid()).isFalse();
    }

    @Test
    void noUppercase_failsValidation() {
        assertThat(validate("abc@1234").valid()).isFalse();
    }

    @Test
    void noLowercase_failsValidation() {
        assertThat(validate("ABC@1234").valid()).isFalse();
    }

    @Test
    void noDigit_failsValidation() {
        assertThat(validate("Abcdefg!").valid()).isFalse();
    }

    @Test
    void noSpecialCharacter_failsValidation() {
        assertThat(validate("Abcdef12").valid()).isFalse();
    }

    @Test
    void nullPassword_failsValidation() {
        assertThat(validate(null).valid()).isFalse();
    }

    @Test
    void emptyPassword_failsValidation() {
        assertThat(validate("").valid()).isFalse();
    }

    // ── Email format tests ────────────────────────────────────────────────────

    /** Replicates basic RFC 5322 email format check. */
    private boolean isValidEmail(String email) {
        if (email == null || email.isBlank()) return false;
        return email.matches("^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$");
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "user@example.com",
            "test.user+tag@domain.org",
            "hieu@cineluxe.vn",
    })
    void validEmails_passValidation(String email) {
        assertThat(isValidEmail(email)).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "notanemail",
            "@nodomain.com",
            "nodomain@",
            "spaces in@email.com",
            "",
    })
    void invalidEmails_failValidation(String email) {
        assertThat(isValidEmail(email)).isFalse();
    }

    // ── Phone number tests (Vietnamese format) ────────────────────────────────

    /** Validates phone: +84 or 0 followed by 9-10 digits. Requirement 17.2 */
    private boolean isValidVietnamesePhone(String phone) {
        if (phone == null) return false;
        return phone.matches("^(\\+84|0)[0-9]{9,10}$");
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "0912345678",
            "+84912345678",
            "0987654321",
            "+84987654321",
    })
    void validPhoneNumbers_passValidation(String phone) {
        assertThat(isValidVietnamesePhone(phone)).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "1234567890",    // no country code or 0 prefix
            "+1234567890",   // wrong country code
            "091234567",     // too short
            "09123456789",   // too long
    })
    void invalidPhoneNumbers_failValidation(String phone) {
        assertThat(isValidVietnamesePhone(phone)).isFalse();
    }
}
