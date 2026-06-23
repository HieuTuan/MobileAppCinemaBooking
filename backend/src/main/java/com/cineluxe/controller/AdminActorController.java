package com.cineluxe.controller;

import com.cineluxe.dto.request.CreateActorRequest;
import com.cineluxe.dto.request.UpdateActorRequest;
import com.cineluxe.dto.response.ActorResponse;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.entity.Actor;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.ActorRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/actors")
@RequiredArgsConstructor
@Tag(name = "Admin Actors", description = "Actor CRUD for movie casting")
public class AdminActorController {

    private final ActorRepository actorRepository;

    @GetMapping
    @Operation(summary = "Lấy danh sách diễn viên")
    public ResponseEntity<ApiResponse<java.util.List<ActorResponse>>> listActors() {
        var actors = actorRepository.findByOrderByNameAsc()
                .stream()
                .map(ActorResponse::from)
                .collect(Collectors.toList());
        return ApiResponse.success(actors);
    }

    @PostMapping
    @Operation(summary = "Tạo diễn viên")
    public ResponseEntity<ApiResponse<ActorResponse>> createActor(
            @Valid @RequestBody CreateActorRequest request) {
        var actor = new Actor(UUID.randomUUID().toString());
        actor.setName(request.name().trim());
        actor.setAvatarUrl(clean(request.avatarUrl()));
        actor.setDescription(clean(request.description()));
        actorRepository.save(actor);
        return ApiResponse.created(ActorResponse.from(actor), "Tạo diễn viên thành công");
    }

    @PutMapping("/{id}")
    @Operation(summary = "Cập nhật diễn viên")
    public ResponseEntity<ApiResponse<ActorResponse>> updateActor(
            @PathVariable String id,
            @Valid @RequestBody UpdateActorRequest request) {
        var actor = findActorOrThrow(id);
        if (request.name() != null && !request.name().isBlank()) {
            actor.setName(request.name().trim());
        }
        if (request.avatarUrl() != null) {
            actor.setAvatarUrl(clean(request.avatarUrl()));
        }
        if (request.description() != null) {
            actor.setDescription(clean(request.description()));
        }
        actorRepository.save(actor);
        return ApiResponse.success(ActorResponse.from(actor), "Cập nhật diễn viên thành công");
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Xóa diễn viên")
    public ResponseEntity<ApiResponse<Void>> deleteActor(@PathVariable String id) {
        findActorOrThrow(id);
        actorRepository.deleteById(id);
        return ApiResponse.success(null, "Xóa diễn viên thành công");
    }

    private Actor findActorOrThrow(String id) {
        return actorRepository.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy diễn viên với id: " + id));
    }

    private String clean(String value) {
        return value == null ? "" : value.trim();
    }
}
