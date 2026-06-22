package com.cineluxe.exception;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Global exception handler providing consistent JSON error responses.
 *
 * <p>Requirements: 30.1–30.6
 * <ul>
 *   <li>30.1: Returns errors with code, message, timestamp, and path.</li>
 *   <li>30.2: Returns 400 with detailed fieldErrors array for validation failures.</li>
 *   <li>30.3: Returns 401 with "Invalid or expired token" for authentication failures.</li>
 *   <li>30.4: Returns 403 with "Insufficient permissions" for authorization failures.</li>
 *   <li>30.5: Returns 404 with identifying message for missing resources.</li>
 *   <li>30.6: Returns 500 and logs full stack trace for server errors.</li>
 * </ul>
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    // ─── Domain exceptions ─────────────────────────────────────────────────────

    @ExceptionHandler(ApiException.class)
    ResponseEntity<Map<String, Object>> handleApi(ApiException ex, HttpServletRequest request) {
        var body = error(ex.getStatus().value(), ex.getMessage(), request.getRequestURI());
        if (!ex.getUnavailableSeats().isEmpty()) {
            body.put("unavailableSeats", ex.getUnavailableSeats());
        }
        return ResponseEntity.status(ex.getStatus()).body(body);
    }

    // ─── Validation ────────────────────────────────────────────────────────────

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<Map<String, Object>> handleValidation(
            MethodArgumentNotValidException ex, HttpServletRequest request) {
        List<Map<String, String>> fieldErrors = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> {
                    var m = new LinkedHashMap<String, String>();
                    m.put("field", fe.getField());
                    m.put("message", fe.getDefaultMessage() != null ? fe.getDefaultMessage() : "Invalid value");
                    return m;
                })
                .collect(Collectors.toList());

        var body = error(400, "Validation failed", request.getRequestURI());
        body.put("fieldErrors", fieldErrors);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    ResponseEntity<Map<String, Object>> handleMissingParam(
            MissingServletRequestParameterException ex, HttpServletRequest request) {
        return ResponseEntity.badRequest().body(
                error(400, "Missing required parameter: " + ex.getParameterName(), request.getRequestURI()));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<Map<String, Object>> handleUnreadable(
            HttpMessageNotReadableException ex, HttpServletRequest request) {
        return ResponseEntity.badRequest().body(
                error(400, "Malformed or missing request body", request.getRequestURI()));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    ResponseEntity<Map<String, Object>> handleMethodNotSupported(
            HttpRequestMethodNotSupportedException ex, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(
                error(405, "Method not allowed: " + ex.getMethod(), request.getRequestURI()));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    ResponseEntity<Map<String, Object>> handleNoResource(
            NoResourceFoundException ex, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                error(404, "Endpoint not found", request.getRequestURI()));
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    ResponseEntity<Map<String, Object>> handleMaxUpload(
            MaxUploadSizeExceededException ex, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).body(
                error(413, "File size exceeds the maximum allowed limit (5MB)", request.getRequestURI()));
    }

    // ─── Catch-all ─────────────────────────────────────────────────────────────

    @ExceptionHandler(Exception.class)
    ResponseEntity<Map<String, Object>> handleGeneric(Exception ex, HttpServletRequest request) {
        // Requirement 30.6: log full stack trace for server errors
        log.error("[GlobalExceptionHandler] Unhandled exception on {} {}: {}",
                request.getMethod(), request.getRequestURI(), ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                error(500, "An unexpected error occurred. Please try again later.", request.getRequestURI()));
    }

    // ─── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Builds a consistent error response body.
     *
     * <p>Fields: code, message, timestamp, path — Requirement 30.1.
     */
    private Map<String, Object> error(int code, String message, String path) {
        var body = new LinkedHashMap<String, Object>();
        body.put("code", code);
        body.put("message", message);
        body.put("timestamp", Instant.now().toString());
        body.put("path", path);
        return body;
    }
}
