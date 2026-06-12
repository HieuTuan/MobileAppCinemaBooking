package com.cineluxe;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class CinemaBookingApplication {
  public static void main(String[] args) {
    SpringApplication.run(CinemaBookingApplication.class, args);
  }
}
