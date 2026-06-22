package com.cineluxe.repository;

import com.cineluxe.entity.RoomSeat;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomSeatRepository extends JpaRepository<RoomSeat, Long> {
    List<RoomSeat> findByRoomIdOrderBySeatRowAscSeatColumnAsc(String roomId);

    Optional<RoomSeat> findByRoomIdAndSeatCode(String roomId, String seatCode);
}
