package com.cineluxe.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Simple in-memory API rate limiting filter.
 *
 * <p>Requirements: 31.1, 31.2, 31.3
 * <ul>
 *   <li>31.1: 100 requests/minute per IP for unauthenticated endpoints.</li>
 *   <li>31.2: 500 requests/minute per userId for authenticated endpoints.</li>
 *   <li>31.3: Returns 429 Too Many Requests with Retry-After header when limit exceeded.</li>
 * </ul>
 *
 * <p>Note: This is an in-memory implementation suitable for single-instance deployments.
 * For multi-instance setups, replace with Redis-backed rate limiting (e.g., Bucket4j + Redis).
 */
@Component
@Slf4j
public class RateLimitingFilter extends OncePerRequestFilter {

    private static final int IP_LIMIT_PER_MINUTE = 100;
    private static final int USER_LIMIT_PER_MINUTE = 500;
    private static final long WINDOW_MS = 60_000L; // 1 minute

    private static final String USER_ID_HEADER = "X-User-Id";
    private static final String AUTHORIZATION_HEADER = "Authorization";

    // Map of (key → [requestCount, windowStartMs])
    private final Map<String, long[]> counters = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain chain) throws ServletException, IOException {

        String userId = request.getHeader(USER_ID_HEADER);
        boolean isAuthenticated = userId != null && !userId.isBlank()
                && request.getHeader(AUTHORIZATION_HEADER) != null;

        String key;
        int limit;
        if (isAuthenticated) {
            key = "user:" + userId;
            limit = USER_LIMIT_PER_MINUTE;
        } else {
            key = "ip:" + getClientIp(request);
            limit = IP_LIMIT_PER_MINUTE;
        }

        if (!isAllowed(key, limit)) {
            log.warn("[RateLimit] Limit exceeded for key={}", key);
            response.setStatus(429);
            response.setHeader("Retry-After", "60");
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                    "{\"status\":429,\"message\":\"Too many requests. Please retry after 60 seconds.\","
                            + "\"timestamp\":\"" + java.time.Instant.now() + "\"}"
            );
            return;
        }

        chain.doFilter(request, response);
    }

    private boolean isAllowed(String key, int limit) {
        long now = System.currentTimeMillis();
        long[] state = counters.compute(key, (k, existing) -> {
            if (existing == null || now - existing[1] >= WINDOW_MS) {
                // New window
                return new long[]{1, now};
            }
            existing[0]++;
            return existing;
        });
        return state[0] <= limit;
    }

    private String getClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
