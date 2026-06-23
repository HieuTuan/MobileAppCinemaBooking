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
  private int quantity;
  private boolean active;

  protected FoodCombo() {}

  public FoodCombo(String id, String name, String description, long price, String imageUrl) {
    this.id = id;
    this.name = name;
    this.description = description;
    this.price = price;
    this.imageUrl = imageUrl;
    this.quantity = 0;
    this.active = true;
  }

  public FoodCombo(String id, String name, String description, long price, String imageUrl, int quantity) {
    this(id, name, description, price, imageUrl);
    this.quantity = quantity;
  }

  public String getId() { return id; }
  public String getName() { return name; }
  public String getDescription() { return description; }
  public long getPrice() { return price; }
  public String getImageUrl() { return imageUrl; }
  public int getQuantity() { return quantity; }
  public boolean isActive() { return active; }

  // Setters (required for admin CRUD – R20)
  public void setName(String name)               { this.name = name; }
  public void setDescription(String description) { this.description = description; }
  public void setPrice(long price)               { this.price = price; }
  public void setImageUrl(String imageUrl)       { this.imageUrl = imageUrl; }
  public void setQuantity(int quantity)          { this.quantity = quantity; }
  public void setActive(boolean active)          { this.active = active; }
}

