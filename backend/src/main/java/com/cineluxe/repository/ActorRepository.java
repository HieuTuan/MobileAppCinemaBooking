package com.cineluxe.repository;

import com.cineluxe.entity.Actor;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ActorRepository extends JpaRepository<Actor, String> {
    List<Actor> findByOrderByNameAsc();
}
