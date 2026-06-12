package com.cineluxe.websocket;

import com.cineluxe.domain.ShowtimeSeat;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.util.List;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class SeatWebSocketHandler extends TextWebSocketHandler {
  private final ObjectMapper objectMapper;
  private final Map<String, Set<WebSocketSession>> sessions = new ConcurrentHashMap<>();

  public SeatWebSocketHandler(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  @Override
  public void afterConnectionEstablished(WebSocketSession session) {
    sessions.computeIfAbsent(showtimeId(session), ignored -> ConcurrentHashMap.newKeySet())
        .add(session);
  }

  @Override
  protected void handleTextMessage(WebSocketSession session, TextMessage message) throws IOException {
    var payload = objectMapper.readValue(message.getPayload(), Map.class);
    if ("ping".equals(payload.get("type"))) {
      session.sendMessage(new TextMessage("{\"type\":\"pong\"}"));
    }
  }

  @Override
  public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
    sessions.getOrDefault(showtimeId(session), Set.of()).remove(session);
  }

  public void broadcast(String showtimeId, ShowtimeSeat seat) {
    var data = new LinkedHashMap<String, Object>();
    data.put("seatCode", seat.getCode());
    data.put("status", seat.getStatus().name());
    if (seat.getHeldByUserId() != null) data.put("userId", seat.getHeldByUserId());
    if (seat.getHoldExpiresAt() != null) data.put("expiresAt", seat.getHoldExpiresAt());
    send(showtimeId, Map.of("type", "seat_update", "data", data));
  }

  public void broadcastAll(String showtimeId, List<ShowtimeSeat> seats) {
    seats.forEach(seat -> broadcast(showtimeId, seat));
  }

  private void send(String showtimeId, Object payload) {
    try {
      var message = new TextMessage(objectMapper.writeValueAsString(payload));
      var showtimeSessions = sessions.get(showtimeId);
      if (showtimeSessions == null) return;
      showtimeSessions.removeIf(session -> {
        try {
          if (!session.isOpen()) return true;
          session.sendMessage(message);
          return false;
        } catch (IOException exception) {
          return true;
        }
      });
    } catch (IOException ignored) {
      // Serialization is deterministic for these DTOs.
    }
  }

  private String showtimeId(WebSocketSession session) {
    var path = session.getUri().getPath().split("/");
    return path[path.length - 2];
  }
}
