package com.cineluxe.repository;

import com.cineluxe.entity.FoodCombo;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodComboRepository extends JpaRepository<FoodCombo, String> {
  List<FoodCombo> findByActiveTrue();
}
