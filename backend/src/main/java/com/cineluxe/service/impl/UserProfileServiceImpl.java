package com.cineluxe.service.impl;

import com.cineluxe.dto.request.UpdateProfileRequest;
import com.cineluxe.dto.response.UserProfileResponse;
import com.cineluxe.entity.UserProfile;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.UserProfileRepository;
import com.cineluxe.service.UserProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Transactional
public class UserProfileServiceImpl implements UserProfileService {

    private static final Pattern PHONE_PATTERN =
            Pattern.compile("^(0[0-9]{9}|\\+84[0-9]{9})$");

    private final UserProfileRepository userProfileRepository;

    @Override
    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(String userId) {
        var profile = findOrCreate(userId);
        return UserProfileResponse.from(profile);
    }

    @Override
    public UserProfileResponse updateProfile(String userId, UpdateProfileRequest request) {
        var profile = findOrCreate(userId);

        if (request.phone() != null) {
            profile.setPhone(request.phone());
        }

        if (request.birthdate() != null) {
            profile.setBirthdate(request.birthdate());
        }

        if (request.fullName() != null && !request.fullName().isBlank()) {
            profile.setFullName(request.fullName().trim());
        }

        return UserProfileResponse.from(userProfileRepository.save(profile));
    }

    // ─── Private helpers ──────────────────────────────────────────────────
    private UserProfile findOrCreate(String userId) {
        return userProfileRepository.findById(userId)
                .orElseGet(() -> userProfileRepository.save(new UserProfile(userId)));
    }
}
