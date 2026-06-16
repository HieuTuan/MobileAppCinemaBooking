package com.cineluxe.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

  @Value("${server.port:8080}")
  private int serverPort;

  @Bean
  public OpenAPI cinemaBookingOpenAPI() {
    return new OpenAPI()
        .info(new Info()
            .title("Cinema Booking API")
            .description("REST API for Cinema Booking Application - Mobile App Cinema Booking")
            .version("1.0.0")
            .contact(new Contact()
                .name("CineLuxe Team")
                .email("support@cineluxe.com"))
            .license(new License()
                .name("MIT License")
                .url("https://opensource.org/licenses/MIT")))
        .servers(List.of(
            new Server()
                .url("http://localhost:" + serverPort)
                .description("Development Server")));
  }
}
