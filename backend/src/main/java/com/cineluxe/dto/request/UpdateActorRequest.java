package com.cineluxe.dto.request;

import jakarta.validation.constraints.Size;

public record UpdateActorRequest(
        @Size(max = 160, message = "Tên diễn viên tối đa 160 ký tự")
        String name,

        String avatarUrl,

        @Size(max = 1200, message = "Mô tả tối đa 1200 ký tự")
        String description
) {}
