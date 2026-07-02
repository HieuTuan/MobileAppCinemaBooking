package com.cineluxe.config;

import com.cineluxe.entity.FoodCombo;
import com.cineluxe.entity.Movie;
import com.cineluxe.entity.ShowtimeSeat;
import com.cineluxe.entity.UserProfile;
import com.cineluxe.repository.FoodComboRepository;
import com.cineluxe.repository.MovieRepository;
import com.cineluxe.repository.ShowtimeSeatRepository;
import com.cineluxe.repository.UserProfileRepository;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SeedDataConfig {

    private static final Logger log = LoggerFactory.getLogger(SeedDataConfig.class);
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    @Bean
    CommandLineRunner seedData(
            ShowtimeSeatRepository seatRepository,
            FoodComboRepository comboRepository,
            MovieRepository movieRepository,
            UserProfileRepository userProfileRepository) {
        return args -> {
            // ── Seed ghế mặc định ──────────────────────────────────────
            if (seatRepository.count() == 0) {
                var seats = new ArrayList<ShowtimeSeat>();
                for (char row = 'A'; row <= 'F'; row++) {
                    for (int column = 1; column <= 10; column++) {
                        var type = row >= 'E' ? "vip" : "standard";
                        seats.add(new ShowtimeSeat(
                                "ST001", row + Integer.toString(column),
                                Character.toString(row), column, type));
                    }
                }
                seatRepository.saveAll(seats);
            }

            // ── Seed combo thức ăn ─────────────────────────────────────
            if (comboRepository.count() == 0) {
                comboRepository.save(new FoodCombo(
                        "CB01", "Bắp nước đôi", "1 bắp lớn và 2 nước", 149_000, "", 100));
                comboRepository.save(new FoodCombo(
                        "CB02", "Combo gia đình", "2 bắp lớn và 4 nước", 279_000, "", 60));
            }

            // Seed default movies when the database is empty.
            if (movieRepository.count() == 0) {
                seedMovie(movieRepository,
                        "MV001",
                        "Skyfall Reborn",
                        "A former pilot returns for one last mission above a city of secrets.",
                        "https://picsum.photos/seed/cineluxe-skyfall/600/900",
                        "https://www.youtube.com/watch?v=YoHD9XEInc0",
                        128,
                        "C13",
                        LocalDate.now().minusDays(12),
                        List.of("Action", "Thriller"),
                        List.of("An Tran", "Minh Le", "Linh Pham"),
                        "Bao Nguyen",
                        4.6);
                seedMovie(movieRepository,
                        "MV002",
                        "The Golden Seat",
                        "A playful heist comedy set inside the busiest cinema in town.",
                        "https://picsum.photos/seed/cineluxe-golden-seat/600/900",
                        "https://www.youtube.com/watch?v=TcMBFSGVi1c",
                        104,
                        "P",
                        LocalDate.now().minusDays(5),
                        List.of("Comedy", "Family"),
                        List.of("Huy Do", "Mai Hoang", "Quan Vu"),
                        "Nhi Tran",
                        4.3);
                seedMovie(movieRepository,
                        "MV003",
                        "Midnight Orbit",
                        "A science crew discovers that their rescue signal is coming from tomorrow.",
                        "https://picsum.photos/seed/cineluxe-midnight-orbit/600/900",
                        "https://www.youtube.com/watch?v=zSWdZVtXT7E",
                        136,
                        "C16",
                        LocalDate.now().plusDays(10),
                        List.of("Sci-Fi", "Drama"),
                        List.of("Khoa Nguyen", "Lan Vo", "Tuan Pham"),
                        "Gia Phan",
                        4.8);
            }

            // ── Seed tài khoản Admin ───────────────────────────────────
            seedUser(userProfileRepository,
                    "seed-admin-001",
                    "Admin",
                    "admin@gmail.com",
                    "admin123",
                    "admin");

            // ── Seed tài khoản Staff ───────────────────────────────────
            seedUser(userProfileRepository,
                    "seed-staff-001",
                    "Staff",
                    "staff@gmail.com",
                    "staff123",
                    "staff");
        };
    }

    private void seedMovie(MovieRepository repo,
                           String id,
                           String title,
                           String description,
                           String posterUrl,
                           String trailerUrl,
                           int durationMinutes,
                           String ageRating,
                           LocalDate releaseDate,
                           List<String> genres,
                           List<String> cast,
                           String director,
                           double rating) {
        var movie = new Movie(id);
        movie.setTitle(title);
        movie.setDescription(description);
        movie.setPosterUrl(posterUrl);
        movie.setTrailerUrl(trailerUrl);
        movie.setDurationMinutes(durationMinutes);
        movie.setAgeRating(ageRating);
        movie.setReleaseDate(releaseDate);
        movie.setGenres(genres);
        movie.setCast(cast);
        movie.setDirector(director);
        movie.setRating(rating);
        repo.save(movie);
    }

    private void seedUser(UserProfileRepository repo,
                          String userId,
                          String fullName,
                          String email,
                          String password,
                          String role) {
        var existingOpt = repo.findByEmailIgnoreCase(email);
        if (existingOpt.isPresent()) {
            var profile = existingOpt.get();
            if (!isValidSha256HashFormat(profile.getPasswordHash())) {
                profile.setPasswordHash(hashPassword(password));
                repo.save(profile);
                log.info("🔄 Updated password hash format for seed user: {}", email);
            } else {
                log.debug("Seed user already exists and has valid hash format: {}", email);
            }
            return;
        }

        var profile = new UserProfile(userId);
        profile.setFullName(fullName);
        profile.setEmail(email.trim().toLowerCase());
        profile.setPasswordHash(hashPassword(password));
        profile.setRole(role);
        profile.setActive(true);
        repo.save(profile);

        log.info("✅ Seeded {} account: {} (password: {})", role, email, password);
    }

    private boolean isValidSha256HashFormat(String storedHash) {
        if (storedHash == null) return false;
        var parts = storedHash.split(":", 2);
        if (parts.length != 2) return false;
        try {
            Base64.getUrlDecoder().decode(parts[0]);
            Base64.getUrlDecoder().decode(parts[1]);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    // ── Password hash (SHA-256 + random salt) ──────────────────────────
    // Phải khớp 100% với AuthController.hashPassword() và passwordMatches()

    private String hashPassword(String password) {
        var salt = new byte[16];
        SECURE_RANDOM.nextBytes(salt);
        var hash = digest(salt, password);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(salt)
                + ":"
                + Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
    }

    private byte[] digest(byte[] salt, String password) {
        try {
            var md = MessageDigest.getInstance("SHA-256");
            md.update(salt);
            return md.digest(password.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is not available", e);
        }
    }
}
