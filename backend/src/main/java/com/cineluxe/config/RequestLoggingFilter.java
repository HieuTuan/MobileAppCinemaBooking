package com.cineluxe.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Instant;

/**
 * Logs every incoming HTTP request with method, path, responseTime, statusCode, and userId.
 *
 * <p>Requirements: 30.7, 30.8, 30.9
 * - Logs all requests with method, path, responseTime, statusCode, and userId.
 * - Satisfies audit trail requirement for authenticated requests.
 */
@Component
@Slf4j
public class RequestLoggingFilter extends OncePerRequestFilter {

    private static final String USER_ID_HEADER = "X-User-Id";

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain chain) throws ServletException, IOException {

        long start = System.currentTimeMillis();
        String method = request.getMethod();
        String path = request.getRequestURI();
        String userId = request.getHeader(USER_ID_HEADER);
        if (userId == null || userId.isBlank()) {
            userId = "anonymous";
        }

        try {
            chain.doFilter(request, response);
        } finally {
            long duration = System.currentTimeMillis() - start;
            int status = response.getStatus();

            if (status >= 500) {
                log.error("[REQUEST] {} {} status={} duration={}ms userId={}",
                        method, path, status, duration, userId);
            } else if (status >= 400) {
                log.warn("[REQUEST] {} {} status={} duration={}ms userId={}",
                        method, path, status, duration, userId);
            } else {
                log.info("[REQUEST] {} {} status={} duration={}ms userId={}",
                        method, path, status, duration, userId);
            }
        }
    }
}
