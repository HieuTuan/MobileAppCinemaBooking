package com.cineluxe.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI 3.0 configuration for the Cinema Booking API.
 *
 * <p>Requirements: 47.1–47.5, 38.1
 * <ul>
 *   <li>47.1: SpringDoc OpenAPI 3.0 configuration.</li>
 *   <li>47.2: @Operation, @Parameter, @ApiResponse annotations on all controllers.</li>
 *   <li>47.3: Swagger UI hosted at /api-docs (swagger-ui.html).</li>
 *   <li>47.4: Example requests and responses for each endpoint.</li>
 *   <li>47.5: All error codes and their meanings documented.</li>
 * </ul>
 *
 * <p>API Versioning (Req 47.6, 47.7):
 * - All endpoints use the /api prefix (existing routing).
 * - For v1 versioning, endpoints are accessible at /api/* (current) and will be
 *   migrated to /api/v1/* in the next major version with a deprecation period of
 *   2 minor versions for backward compatibility.
 */
@Configuration
public class OpenApiConfig {

    @Value("${server.port:8080}")
    private int serverPort;

    @Bean
    public OpenAPI cinemaBookingOpenAPI() {
        final String securitySchemeName = "bearerAuth";

        return new OpenAPI()
                .info(new Info()
                        .title("CineLuxe Cinema Booking API")
                        .description("""
                                RESTful API for the CineLuxe Cinema Booking platform.
                                
                                ## Authentication
                                Most endpoints require a Bearer JWT token in the Authorization header.
                                Staff endpoints also accept an X-Staff-Id header.
                                
                                ## Error Codes
                                | Code | Meaning |
                                |------|---------|
                                | 400  | Validation failed or bad request |
                                | 401  | Invalid or expired token |
                                | 403  | Insufficient permissions |
                                | 404  | Resource not found |
                                | 409  | Conflict (e.g., seat already held, ticket already validated) |
                                | 429  | Rate limit exceeded — see Retry-After header |
                                | 500  | Internal server error |
                                
                                ## Versioning
                                Current version: **v1.0.0**. Backward compatibility guaranteed for 2 minor versions.
                                """)
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("CineLuxe Development Team")
                                .email("support@cineluxe.com")
                                .url("https://cineluxe.com"))
                        .license(new License()
                                .name("MIT License")
                                .url("https://opensource.org/licenses/MIT")))
                .servers(List.of(
                        new Server()
                                .url("http://localhost:" + serverPort)
                                .description("Development Server"),
                        new Server()
                                .url("https://api.cineluxe.com")
                                .description("Production Server")))
                .addSecurityItem(new SecurityRequirement().addList(securitySchemeName))
                .components(new Components()
                        .addSecuritySchemes(securitySchemeName,
                                new SecurityScheme()
                                        .name(securitySchemeName)
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("Enter the JWT token obtained from the authentication endpoint.")));
    }
}
