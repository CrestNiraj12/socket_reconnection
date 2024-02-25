enum SocketEventType {
  connected,
  done,
  error,
  response,
}

class SocketResponse {
  SocketResponse({
    required this.message,
    required this.type,
  });

  final String message;
  final SocketEventType type;

  static SocketResponse fromJSON(SocketEventType type, String event) {
    return SocketResponse(type: type, message: event);
  }
}
