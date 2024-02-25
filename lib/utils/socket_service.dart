import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  SocketService._();

  static final SocketService _instance =
      SocketService._(); // Singleton instance
  factory SocketService() => _instance;

  WebSocketChannel? _channel;
  Timer? _timer;

  WebSocketChannel? get channel => _channel;

  Future<void> init() async {
    final wsUri = Uri.parse(
      "wss://echo.websocket.org",
    ); // Enter your websocket URL
    _channel = IOWebSocketChannel.connect(
      wsUri,
      connectTimeout: const Duration(seconds: 30),
    );
    await _channel?.ready;
    ping();
  }

  void ping() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final message = json.encode({'message': 'ping'});
      try {
        _channel?.sink.add(message);
      } catch (e) {
        // If sink is closed, cancel the timer
        timer.cancel();
      }
    });
  }

  Future<void> closeChannel() async {
    _timer?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }
}
