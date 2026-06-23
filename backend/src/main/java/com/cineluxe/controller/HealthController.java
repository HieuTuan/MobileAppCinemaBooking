package com.cineluxe.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Health and readiness endpoints for load balancer and operations monitoring.
 *
 * <p>Requirements: 30.10, 43.4
 * <ul>
 *   <li>GET /health — returns status "up" or "down" with database connectivity.</li>
 *   <li>GET /ready  — returns 200 when ready to accept traffic, 503 otherwise.</li>
 * </ul>
 */
@RestController
@RequestMapping
@RequiredArgsConstructor
@Tag(name = "Health", description = "Health check and readiness endpoints")
public class HealthController {

    @Autowired(required = false)
    private JdbcTemplate jdbcTemplate;

    @Operation(
            summary = "Health check",
            description = "Returns the service status (up/down) and database connectivity."
    )
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", "up");
        body.put("timestamp", Instant.now());

        boolean dbOk = checkDatabase();
        body.put("database", dbOk ? "connected" : "disconnected");

        if (!dbOk) {
            body.put("status", "degraded");
            return ResponseEntity.status(503).body(body);
        }
        return ResponseEntity.ok(body);
    }

    @Operation(
            summary = "Readiness probe",
            description = "Returns 200 when the service is ready to handle requests, 503 otherwise."
    )
    @GetMapping("/ready")
    public ResponseEntity<Map<String, Object>> ready() {
        Map<String, Object> body = new LinkedHashMap<>();
        boolean dbOk = checkDatabase();
        if (dbOk) {
            body.put("ready", true);
            return ResponseEntity.ok(body);
        }
        body.put("ready", false);
        body.put("reason", "database not available");
        return ResponseEntity.status(503).body(body);
    }

    private boolean checkDatabase() {
        if (jdbcTemplate == null) return false;
        try {
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
