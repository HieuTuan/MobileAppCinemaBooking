package com.cineluxe.config;

import com.cineluxe.domain.FoodCombo;
import com.cineluxe.domain.ShowtimeSeat;
import com.cineluxe.repository.FoodComboRepository;
import com.cineluxe.repository.ShowtimeSeatRepository;
import java.util.ArrayList;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SeedDataConfig {
  @Bean
  CommandLineRunner seedData(
      ShowtimeSeatRepository seatRepository,
      FoodComboRepository comboRepository) {
    return args -> {
      if (seatRepository.count() == 0) {
        var seats = new ArrayList<ShowtimeSeat>();
        for (char row = 'A'; row <= 'F'; row++) {
          for (int column = 1; column <= 10; column++) {
            var type = row >= 'E' ? "vip" : "standard";
            seats.add(new ShowtimeSeat(
                "ST001", row + Integer.toString(column), Character.toString(row), column, type));
          }
        }
        seatRepository.saveAll(seats);
      }
      if (comboRepository.count() == 0) {
        comboRepository.save(new FoodCombo(
            "CB01", "Bắp nước đôi", "1 bắp lớn và 2 nước", 149_000, ""));
        comboRepository.save(new FoodCombo(
            "CB02", "Combo gia đình", "2 bắp lớn và 4 nước", 279_000, ""));
      }
    };
  }
}
