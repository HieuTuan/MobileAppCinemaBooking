package com.cineluxe.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Column;
import jakarta.persistence.Table;

@Entity
@Table(name = "rooms", indexes = {
    @Index(name = "idx_room_theater_id", columnList = "theater_id"),
    @Index(name = "idx_room_status", columnList = "status")
})
public class Room {
    @Id
    private String id;
    @Column(name = "theater_id", nullable = false)
    private String theaterId;
    @Column(nullable = false)
    private String name;
    private int capacity;
    @Column(name = "screen_type", nullable = false)
    private String screenType;
    @Column(nullable = false)
    private String status;

    protected Room() {}

    public Room(String id, String theaterId, String name, int capacity, String screenType) {
        this.id = id;
        this.theaterId = theaterId;
        this.name = name;
        this.capacity = capacity;
        this.screenType = screenType;
        this.status = "ready";
    }

    public String getId() { return id; }
    public String getTheaterId() { return theaterId; }
    public String getName() { return name; }
    public int getCapacity() { return capacity; }
    public String getScreenType() { return screenType; }
    public String getStatus() { return status; }

    public void setStatus(String status) { this.status = status; }
}
