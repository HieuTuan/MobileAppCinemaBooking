package com.cineluxe.service.impl;

import com.cineluxe.dto.response.ImageUploadResponse;
import com.cineluxe.service.ImageUploadService;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/**
 * Cloudinary implementation of {@link ImageUploadService} (Task 30.1).
 *
 * <p>Validates:
 * <ul>
 *   <li>File type: JPEG, PNG, WebP only (by MIME type and magic bytes)</li>
 *   <li>File size: max 5 MB</li>
 * </ul>
 * Uploads to Cloudinary folder "cineluxe/movies" with a UUID-based public ID.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ImageUploadServiceImpl implements ImageUploadService {

    private static final long MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB
    private static final long MAX_VIDEO_SIZE_BYTES = 80 * 1024 * 1024; // 80 MB
    private static final double MAX_VIDEO_DURATION_SECONDS = 60.0;

    private static final List<String> ALLOWED_MIME_TYPES = List.of(
            "image/jpeg",
            "image/png",
            "image/webp"
    );

    private static final List<String> ALLOWED_VIDEO_MIME_TYPES = List.of(
            "video/mp4",
            "video/quicktime",
            "video/webm"
    );

    // Magic byte signatures for JPEG, PNG, WebP
    private static final byte[] JPEG_MAGIC = {(byte) 0xFF, (byte) 0xD8};
    private static final byte[] PNG_MAGIC  = {(byte) 0x89, 0x50, 0x4E, 0x47};
    private static final byte[] WEBP_RIFF  = {'R', 'I', 'F', 'F'};
    private static final byte[] WEBP_MARK  = {'W', 'E', 'B', 'P'};

    private final Cloudinary cloudinary;

    @Override
    public ImageUploadResponse upload(MultipartFile file) {
        // 1. Null / empty check
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Tệp không được để trống");
        }

        // 2. Size check
        if (file.getSize() > MAX_SIZE_BYTES) {
            throw new IllegalArgumentException(
                    "Kích thước tệp vượt quá giới hạn 5 MB");
        }

        // 3. MIME type check
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_MIME_TYPES.contains(contentType.toLowerCase())) {
            throw new IllegalArgumentException(
                    "Loại tệp không hợp lệ. Chỉ chấp nhận JPEG, PNG, WebP");
        }

        // 4. Magic-byte validation (prevents MIME spoofing)
        byte[] header = safeReadHeader(file, 12);
        if (!isValidImageMagic(header)) {
            throw new IllegalArgumentException(
                    "Nội dung tệp không khớp với loại ảnh được hỗ trợ");
        }

        // 5. Build unique public_id
        String publicId = "cineluxe/movies/" + UUID.randomUUID();

        // 6. Upload to Cloudinary
        try {
            Map<?, ?> result = cloudinary.uploader().upload(
                    file.getBytes(),
                    ObjectUtils.asMap(
                            "public_id", publicId,
                            "overwrite", false,
                            "resource_type", "image",
                            "access_mode", "public"
                    )
            );

            String cdnUrl    = (String) result.get("secure_url");
            String resPublicId = (String) result.get("public_id");
            long   bytes     = ((Number) result.get("bytes")).longValue();

            log.info("Image uploaded: publicId={}, size={} bytes, url={}", resPublicId, bytes, cdnUrl);

            return new ImageUploadResponse(cdnUrl, resPublicId,
                    file.getOriginalFilename(), bytes);

        } catch (IOException ex) {
            log.error("Cloudinary upload failed", ex);
            throw new RuntimeException("Upload ảnh thất bại, vui lòng thử lại", ex);
        }
    }

    // ── helpers ──────────────────────────────────────────────────

    @Override
    public ImageUploadResponse uploadVideo(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Tệp video không được để trống");
        }

        if (file.getSize() > MAX_VIDEO_SIZE_BYTES) {
            throw new IllegalArgumentException("Video vượt quá giới hạn 80 MB");
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_VIDEO_MIME_TYPES.contains(contentType.toLowerCase())) {
            throw new IllegalArgumentException("Chỉ chấp nhận video MP4, MOV hoặc WebM");
        }

        String publicId = "cineluxe/trailers/" + UUID.randomUUID();

        try {
            Map<?, ?> result = cloudinary.uploader().upload(
                    file.getBytes(),
                    ObjectUtils.asMap(
                            "public_id", publicId,
                            "overwrite", false,
                            "resource_type", "video",
                            "access_mode", "public"
                    )
            );

            String resPublicId = (String) result.get("public_id");
            Object durationValue = result.get("duration");
            double duration = durationValue instanceof Number
                    ? ((Number) durationValue).doubleValue()
                    : 0.0;

            if (duration > MAX_VIDEO_DURATION_SECONDS) {
                cloudinary.uploader().destroy(
                        resPublicId,
                        ObjectUtils.asMap("resource_type", "video")
                );
                throw new IllegalArgumentException("Trailer phải dài tối đa 60 giây");
            }

            String cdnUrl = (String) result.get("secure_url");
            long bytes = ((Number) result.get("bytes")).longValue();

            log.info("Video uploaded: publicId={}, duration={}s, size={} bytes, url={}",
                    resPublicId, duration, bytes, cdnUrl);

            return new ImageUploadResponse(cdnUrl, resPublicId,
                    file.getOriginalFilename(), bytes);

        } catch (IOException ex) {
            log.error("Cloudinary video upload failed", ex);
            throw new RuntimeException("Upload trailer thất bại, vui lòng thử lại", ex);
        }
    }

    private byte[] safeReadHeader(MultipartFile file, int length) {
        try {
            byte[] bytes = file.getBytes();
            int len = Math.min(length, bytes.length);
            byte[] header = new byte[len];
            System.arraycopy(bytes, 0, header, 0, len);
            return header;
        } catch (IOException e) {
            throw new RuntimeException("Không thể đọc tệp", e);
        }
    }

    private boolean isValidImageMagic(byte[] header) {
        if (header.length < 4) return false;
        // JPEG: FF D8
        if (header[0] == JPEG_MAGIC[0] && header[1] == JPEG_MAGIC[1]) return true;
        // PNG: 89 50 4E 47
        if (header[0] == PNG_MAGIC[0] && header[1] == PNG_MAGIC[1]
                && header[2] == PNG_MAGIC[2] && header[3] == PNG_MAGIC[3]) return true;
        // WebP: RIFF....WEBP  (bytes 0-3 = RIFF, bytes 8-11 = WEBP)
        if (header.length >= 12
                && header[0] == WEBP_RIFF[0] && header[1] == WEBP_RIFF[1]
                && header[2] == WEBP_RIFF[2] && header[3] == WEBP_RIFF[3]
                && header[8] == WEBP_MARK[0] && header[9] == WEBP_MARK[1]
                && header[10] == WEBP_MARK[2] && header[11] == WEBP_MARK[3]) {
            return true;
        }
        return false;
    }
}
