package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.ImageUploadResponse;
import com.cineluxe.service.ImageUploadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Handles image uploads for the admin panel (Task 30.1).
 *
 * <p>POST /api/admin/upload — accepts a multipart/form-data file,
 * validates type (JPEG/PNG/WebP) and size (&lt;5 MB), uploads to
 * Cloudinary, and returns the public CDN URL.
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Tag(name = "Admin Upload", description = "Image upload endpoint for admin panel")
public class UploadController {

    private final ImageUploadService imageUploadService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(
            summary = "Upload image",
            description = "Accepts JPEG, PNG, or WebP files up to 5 MB. " +
                          "Returns the Cloudinary CDN URL."
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(
                responseCode = "200", description = "Upload successful"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(
                responseCode = "400", description = "Invalid file type or size",
                content = @Content),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(
                responseCode = "500", description = "Upload failed",
                content = @Content)
    })
    public ResponseEntity<ApiResponse<ImageUploadResponse>> uploadImage(
            @Parameter(description = "Image file (JPEG / PNG / WebP, max 5 MB)")
            @RequestParam("file") MultipartFile file) {

        try {
            ImageUploadResponse result = imageUploadService.upload(file);
            return ApiResponse.success(result, "Upload ảnh thành công");
        } catch (IllegalArgumentException ex) {
            return ApiResponse.error(400, ex.getMessage());
        } catch (RuntimeException ex) {
            return ApiResponse.error(500, ex.getMessage());
        }
    }

    @PostMapping(value = "/upload/video", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(
            summary = "Upload trailer video",
            description = "Accepts MP4, MOV, or WebM trailer videos up to 60 seconds."
    )
    public ResponseEntity<ApiResponse<ImageUploadResponse>> uploadVideo(
            @Parameter(description = "Trailer video file (MP4 / MOV / WebM, max 60 seconds)")
            @RequestParam("file") MultipartFile file) {

        try {
            ImageUploadResponse result = imageUploadService.uploadVideo(file);
            return ApiResponse.success(result, "Upload trailer thành công");
        } catch (IllegalArgumentException ex) {
            return ApiResponse.error(400, ex.getMessage());
        } catch (RuntimeException ex) {
            return ApiResponse.error(500, ex.getMessage());
        }
    }
}
