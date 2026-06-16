package com.cineluxe.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private final int status;
    private final String message;
    private final T data;

    private ApiResponse(int status, String message, T data) {
        this.status = status;
        this.message = message;
        this.data = data;
    }

    // ── Success helpers ──────────────────────────────────────────

    public static <T> ResponseEntity<ApiResponse<T>> success(T data) {
        return success(HttpStatus.OK.value(), data, "Success");
    }

    public static <T> ResponseEntity<ApiResponse<T>> success(T data, String message) {
        return success(HttpStatus.OK.value(), data, message);
    }

    public static <T> ResponseEntity<ApiResponse<T>> success(int status, T data) {
        return success(status, data, "Success");
    }

    public static <T> ResponseEntity<ApiResponse<T>> success(int status, T data, String message) {
        return ResponseEntity.status(status).body(new ApiResponse<>(status, message, data));
    }

    public static <T> ResponseEntity<ApiResponse<T>> created(T data) {
        return success(HttpStatus.CREATED.value(), data, "Tạo thành công");
    }

    public static <T> ResponseEntity<ApiResponse<T>> created(T data, String message) {
        return success(HttpStatus.CREATED.value(), data, message);
    }

    // ── Error helpers ────────────────────────────────────────────

    public static <T> ResponseEntity<ApiResponse<T>> error(int status, String message) {
        return ResponseEntity.status(status).body(new ApiResponse<>(status, message, null));
    }

    public static ResponseEntity<ApiResponse<List<ValidationError>>> validationError(
            List<ValidationError> errors) {
        return ResponseEntity.badRequest()
                .body(new ApiResponse<>(400, "Dữ liệu không hợp lệ", errors));
    }

    // ── Getters ──────────────────────────────────────────────────

    public int getStatus() { return status; }
    public String getMessage() { return message; }
    public T getData() { return data; }
}
