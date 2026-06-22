package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.service.DataPrivacyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

import static com.cineluxe.dto.response.ApiResponse.success;

/**
 * Data privacy controller for GDPR/privacy compliance.
 *
 * <p>Requirements: 45.4, 45.5, 39.4
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Tag(name = "Data Privacy", description = "User data export and account deletion endpoints")
public class DataPrivacyController {

    private final DataPrivacyService dataPrivacyService;

    @Operation(
            summary = "Export user data",
            description = "Export all personal data for a user in JSON format. "
                    + "Requirement 45.4: GDPR right to data portability."
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "User data exported successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "User not found")
    })
    @GetMapping("/{userId}/data-export")
    public ResponseEntity<ApiResponse<Map<String, Object>>> exportUserData(
            @Parameter(description = "User ID") @PathVariable String userId) {
        return success(dataPrivacyService.exportUserData(userId));
    }

    @Operation(
            summary = "Delete user account",
            description = "Permanently delete a user account and anonymize PII in historical records. "
                    + "Requirement 45.5: GDPR right to erasure. "
                    + "Soft-deletes the profile; PII is fully purged within 30 days."
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Account deletion initiated"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "User not found"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "User has active bookings")
    })
    @DeleteMapping("/{userId}")
    public ResponseEntity<ApiResponse<Map<String, String>>> deleteUserAccount(
            @Parameter(description = "User ID") @PathVariable String userId) {
        dataPrivacyService.deleteUserAccount(userId);
        return success(Map.of(
                "status", "deleted",
                "message", "Account deletion initiated. All PII will be removed within 30 days."
        ));
    }
}
