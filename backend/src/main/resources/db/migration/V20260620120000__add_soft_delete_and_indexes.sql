-- Migration: V20260620120000__add_soft_delete_and_indexes.sql
-- Requirements: 32.3, 32.4, 32.5, 32.6, 32.8
--
-- Adds:
-- 1. soft delete (deleted_at) columns to users, bookings (Req 32.8)
-- 2. updated_at timestamps where missing (Req 32.6)
-- 3. Additional performance indexes (Req 32.3)
-- 4. technical_issues table for staff room reporting (Req 27.4)

-- ── Soft delete + updated_at on bookings ─────────────────────────────────────
ALTER TABLE bookings
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;

-- ── Soft delete + updated_at on user_profiles ────────────────────────────────
ALTER TABLE user_profiles
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;

-- ── Performance indexes (Req 32.3) ────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_booking_user_id       ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_booking_showtime_id   ON bookings(showtime_id);
CREATE INDEX IF NOT EXISTS idx_booking_status        ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_user_profile_email    ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_showtime_seat_showtime ON showtime_seat(showtime_id);
CREATE INDEX IF NOT EXISTS idx_showtime_seat_status  ON showtime_seat(status);
CREATE INDEX IF NOT EXISTS idx_showtime_seat_expires ON showtime_seat(hold_expires_at);

-- ── TechnicalIssues table (Req 27.4, 32.1) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS technical_issues (
    id                   BIGSERIAL PRIMARY KEY,
    room_id              VARCHAR(255) NOT NULL,
    staff_id             VARCHAR(255) NOT NULL,
    reason               VARCHAR(255) NOT NULL,
    description          TEXT         NOT NULL,
    status               VARCHAR(100) NOT NULL DEFAULT 'Đã gửi Admin',
    resolution_notes     TEXT,
    resolved_by_staff_id VARCHAR(255),
    created_at           TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP    NOT NULL DEFAULT NOW(),
    resolved_at          TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ti_room_id   ON technical_issues(room_id);
CREATE INDEX IF NOT EXISTS idx_ti_staff_id  ON technical_issues(staff_id);
CREATE INDEX IF NOT EXISTS idx_ti_status    ON technical_issues(status);
