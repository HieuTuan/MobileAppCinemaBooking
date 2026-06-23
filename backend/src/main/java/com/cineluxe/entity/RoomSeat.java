package com.cineluxe.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Column;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
    name = "room_seats",
    uniqueConstraints = @UniqueConstraint(columnNames = {"room_id", "seat_code"}),
    indexes = @Index(name = "idx_room_seat_room_id", columnList = "room_id")
)
public class RoomSeat {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "room_id", nullable = false)
    private String roomId;
    @Column(name = "seat_code", nullable = false)
    private String seatCode;
    @Column(name = "seat_row", nullable = false)
    private String seatRow;
    @Column(name = "seat_column", nullable = false)
    private int seatColumn;
    @Column(name = "seat_type", nullable = false)
    private String seatType;

    protected RoomSeat() {}

    public RoomSeat(String roomId, String seatCode, String seatRow, int seatColumn, String seatType) {
        this.roomId = roomId;
        this.seatCode = seatCode;
        this.seatRow = seatRow;
        this.seatColumn = seatColumn;
        this.seatType = seatType;
    }

    public String getRoomId() { return roomId; }
    public String getSeatCode() { return seatCode; }
    public String getSeatRow() { return seatRow; }
    public int getSeatColumn() { return seatColumn; }
    public String getSeatType() { return seatType; }

    public void setSeatType(String seatType) { this.seatType = seatType; }
}
