package com.cineluxe.repository;

import com.cineluxe.entity.Room;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repository cho Room entity.
 * Dùng trong BookingServiceImpl để lấy tên phòng thực tế khi tạo booking (R5 — Req 9.1).
 * Dùng trong AdminRoomController để liệt kê phòng chiếu.
 */
public interface RoomRepository extends JpaRepository<Room, String> {

    /** Lấy tất cả phòng, sắp xếp theo tên tăng dần — dùng trong AdminRoomController. */
    List<Room> findAllByOrderByNameAsc();
}
