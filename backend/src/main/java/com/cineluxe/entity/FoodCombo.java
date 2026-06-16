package com.cineluxe.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;

@Entity
public class FoodCombo {
  @Id
  private String id;
  private String name;
  private String description;
  private long price;
  private String imageUrl;
  private boolean active;

  protected FoodCombo() {}

  public FoodCombo(String id, String name, String description, long price, String imageUrl) {
    this.id = id;
    this.name = name;
    this.description = description;
    this.price = price;
    this.imageUrl = imageUrl;
    this.active = true;
  }

  public String getId() { return id; }
  public String getName() { return name; }
  public String getDescription() { return description; }
  public long getPrice() { return price; }
  public String getImageUrl() { return imageUrl; }
  public boolean isActive() { return active; }
}
