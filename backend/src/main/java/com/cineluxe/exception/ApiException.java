package com.cineluxe.exception;

import java.util.List;
import org.springframework.http.HttpStatus;

public class ApiException extends RuntimeException {
  private final HttpStatus status;
  private final List<String> unavailableSeats;

  public ApiException(HttpStatus status, String message) {
    this(status, message, List.of());
  }

  public ApiException(HttpStatus status, String message, List<String> unavailableSeats) {
    super(message);
    this.status = status;
    this.unavailableSeats = unavailableSeats;
  }

  public HttpStatus getStatus() { return status; }
  public List<String> getUnavailableSeats() { return unavailableSeats; }
}
