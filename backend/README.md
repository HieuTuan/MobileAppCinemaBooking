# CineLuxe Spring Boot API

Run locally:

```powershell
cd backend
mvn spring-boot:run
```

Flutter Android emulator defaults:

- REST: `http://10.0.2.2:8080`
- WebSocket: `ws://10.0.2.2:8080/ws/showtimes/{showtimeId}/seats?token=...`

The current slice implements seat state retrieval, pessimistically locked seat
holds, automatic hold expiry, real-time seat broadcasts, food combos, and
booking creation.
