package com.cineluxe.service;

import com.cineluxe.dto.request.UpdateProfileRequest;
import com.cineluxe.dto.response.UserProfileResponse;

public interface UserProfileService {

    UserProfileResponse getProfile(String userId);

    UserProfileResponse updateProfile(String userId, UpdateProfileRequest request);
}
