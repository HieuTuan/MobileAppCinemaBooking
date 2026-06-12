# WebSocketClient Usage Example

This document demonstrates how to use the `WebSocketClient` for real-time seat status synchronization.

## Basic Usage

```dart
import 'package:cine_book/websocket/websocket_client.dart';
import 'package:cine_book/websocket/seat_update.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String showtimeId;
  final String jwtToken;
  
  const SeatSelectionScreen({
    required this.showtimeId,
    required this.jwtToken,
  });

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  late WebSocketClient _wsClient;
  StreamSubscription<ConnectionState>? _connectionSubscription;
  StreamSubscription<SeatUpdate>? _seatUpdateSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _wsClient = WebSocketClient();
    
    // Listen to connection state changes
    _connectionSubscription = _wsClient.connectionStateStream.listen((state) {
      switch (state) {
        case ConnectionState.connecting:
          print('Connecting to seat updates...');
          break;
        case ConnectionState.connected:
          print('Connected! Receiving live seat updates');
          break;
        case ConnectionState.disconnected:
          print('Disconnected from seat updates');
          break;
        case ConnectionState.error:
          print('Connection error - attempting to reconnect...');
          break;
      }
    });
    
    // Listen to seat updates
    _seatUpdateSubscription = _wsClient.seatUpdateStream.listen((update) {
      print('Seat update: ${update.seatCode} is now ${update.status}');
      
      // Update UI based on seat status
      setState(() {
        updateSeatInUI(update.seatCode, update.status);
      });
      
      // Show hold expiration for held seats
      if (update.status == SeatStatus.held && update.expiresAt != null) {
        final remainingTime = update.expiresAt!.difference(DateTime.now());
        print('Seat ${update.seatCode} held until ${update.expiresAt}');
      }
    });
    
    // Connect to WebSocket
    _wsClient.connect(widget.showtimeId, widget.jwtToken);
  }

  void updateSeatInUI(String seatCode, SeatStatus status) {
    // Find seat in your state and update its status
    // This will trigger UI rebuild to reflect the new seat state
  }

  @override
  void dispose() {
    // Clean up subscriptions
    _connectionSubscription?.cancel();
    _seatUpdateSubscription?.cancel();
    
    // Disconnect and dispose WebSocket client
    _wsClient.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Seats')),
      body: Column(
        children: [
          // Connection status indicator
          _buildConnectionStatus(),
          
          // Seat map
          Expanded(child: _buildSeatMap()),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return StreamBuilder<ConnectionState>(
      stream: _wsClient.connectionStateStream,
      initialData: _wsClient.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? ConnectionState.disconnected;
        
        Color color;
        IconData icon;
        String message;
        
        switch (state) {
          case ConnectionState.connecting:
            color = Colors.orange;
            icon = Icons.sync;
            message = 'Connecting...';
            break;
          case ConnectionState.connected:
            color = Colors.green;
            icon = Icons.check_circle;
            message = 'Live updates active';
            break;
          case ConnectionState.disconnected:
            color = Colors.grey;
            icon = Icons.cloud_off;
            message = 'Offline';
            break;
          case ConnectionState.error:
            color = Colors.red;
            icon = Icons.error;
            message = 'Connection error';
            break;
        }
        
        return Container(
          padding: EdgeInsets.all(8),
          color: color.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 8),
              Text(message, style: TextStyle(color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeatMap() {
    // Your seat map implementation
    return Center(child: Text('Seat map goes here'));
  }
}
```

## Connection States

The WebSocket client has four connection states:

1. **`disconnected`** - Not connected to the server
2. **`connecting`** - Attempting to establish connection
3. **`connected`** - Successfully connected and receiving updates
4. **`error`** - Connection failed or error occurred

## Seat Status Values

Seat updates include the following status values:

- **`available`** - Seat is free and can be selected
- **`held`** - Seat is temporarily reserved (includes `expiresAt` timestamp)
- **`booked`** - Seat has been confirmed and paid for
- **`selected`** - Current user's local selection (not broadcast)

## Automatic Features

The WebSocketClient automatically handles:

- **Reconnection**: Uses exponential backoff (1s → 2s → 4s → 8s → max 30s)
- **Keepalive**: Sends ping every 30 seconds, expects pong within 5 seconds
- **Stale Connection Detection**: Closes connection if no pong received
- **Error Recovery**: Automatically attempts to reconnect on errors

## Best Practices

1. **Always dispose**: Call `dispose()` in your widget's dispose method
2. **Cancel subscriptions**: Cancel stream subscriptions to prevent memory leaks
3. **Handle all states**: Listen to connection state and provide UI feedback
4. **Show offline indicator**: Inform users when connection is lost
5. **Reconnection UI**: Show reconnection status to keep users informed

## Integration with State Management

```dart
// Example with Provider
class SeatBookingProvider extends ChangeNotifier {
  final WebSocketClient _wsClient = WebSocketClient();
  final Map<String, SeatStatus> _seats = {};
  
  Map<String, SeatStatus> get seats => _seats;
  
  void initialize(String showtimeId, String jwtToken) {
    _wsClient.seatUpdateStream.listen((update) {
      _seats[update.seatCode] = update.status;
      notifyListeners();
    });
    
    _wsClient.connect(showtimeId, jwtToken);
  }
  
  @override
  void dispose() {
    _wsClient.dispose();
    super.dispose();
  }
}
```

## Troubleshooting

### Connection keeps disconnecting
- Check JWT token validity
- Verify network connectivity
- Ensure WebSocket server is running
- Check firewall/proxy settings

### Not receiving seat updates
- Verify WebSocket is connected (check `currentState`)
- Ensure you're subscribed to `seatUpdateStream`
- Check that showtime ID is correct
- Verify JWT token has proper permissions

### Memory leaks
- Always call `dispose()` when done
- Cancel stream subscriptions in dispose
- Don't hold references to disposed clients
