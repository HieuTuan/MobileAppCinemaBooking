package com.cineluxe.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * Response DTO returned after a successful image upload (Task 30.1).
 */
@Getter
@AllArgsConstructor
public class ImageUploadResponse {

    /** The public CDN URL of the uploaded image. */
    private final String url;

    /** The unique public ID (filename) assigned by Cloudinary. */
    private final String publicId;

    /** Original file name sent by the client. */
    private final String originalFilename;

    /** File size in bytes. */
    private final long bytes;
}
