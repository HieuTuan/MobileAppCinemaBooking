package com.cineluxe.service;

import com.cineluxe.dto.response.ImageUploadResponse;
import org.springframework.web.multipart.MultipartFile;

/**
 * Service interface for cloud image upload (Task 30.1).
 */
public interface ImageUploadService {

    /**
     * Validates and uploads an image to Cloudinary.
     *
     * @param file the multipart file (JPEG, PNG, or WebP, max 5 MB)
     * @return {@link ImageUploadResponse} with the CDN URL
     */
    ImageUploadResponse upload(MultipartFile file);
}
