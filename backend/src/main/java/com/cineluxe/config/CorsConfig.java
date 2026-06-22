package com.cineluxe.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.List;

/**
 * CORS configuration allowing only trusted origins.
 *
 * <p>Requirements: 31.7
 * Implements CORS policy allowing only configured frontend origins.
 * In production, replace "*" with specific allowed origins via environment variable.
 */
@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        var config = new CorsConfiguration();

        // Read allowed origins from environment; default to localhost for dev
        String allowedOriginsEnv = System.getenv("CORS_ALLOWED_ORIGINS");
        if (allowedOriginsEnv != null && !allowedOriginsEnv.isBlank()) {
            config.setAllowedOrigins(List.of(allowedOriginsEnv.split(",")));
        } else {
            config.setAllowedOriginPatterns(List.of(
                    "http://localhost:*",
                    "http://127.0.0.1:*",
                    "http://10.0.2.2:*"
            ));
        }
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of(
                "Authorization", "Content-Type", "Accept", "X-User-Id", "X-Staff-Id", "Accept-Language"
        ));
        config.setExposedHeaders(List.of("Retry-After", "X-Total-Count"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}
