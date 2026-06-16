package com.cineluxe.exception;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {
  @ExceptionHandler(ApiException.class)
  ResponseEntity<Map<String, Object>> handleApi(ApiException exception) {
    var body = error(exception.getStatus().value(), exception.getMessage());
    if (!exception.getUnavailableSeats().isEmpty()) {
      body.put("unavailableSeats", exception.getUnavailableSeats());
    }
    return ResponseEntity.status(exception.getStatus()).body(body);
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException exception) {
    return ResponseEntity.badRequest().body(error(400, exception.getBindingResult()
        .getAllErrors().get(0).getDefaultMessage()));
  }

  private Map<String, Object> error(int status, String message) {
    var body = new LinkedHashMap<String, Object>();
    body.put("status", status);
    body.put("message", message);
    body.put("timestamp", Instant.now());
    return body;
  }
}
