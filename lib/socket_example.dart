import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_reconnection_guide/models/socket_response.dart';
import 'package:socket_reconnection_guide/utils/socket_service.dart';

class SocketExample extends StatefulWidget {
  const SocketExample({super.key});

  @override
  State<SocketExample> createState() => _SocketExampleState();
}

class _SocketExampleState extends State<SocketExample> {
  final _socketService = SocketService();
  final List<SocketResponse> _responses = [];
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _socketService.closeChannel();
    _channelSubscription?.cancel();
    super.dispose();
  }

  void connectWebSocket({int retrySeconds = 1}) async {
    try {
      await _socketService.init();
      setState(() {
        _responses.add(
          SocketResponse.fromJSON(
            SocketEventType.connected,
            'Socket connected successfully!',
          ),
        );
      });
      final channel = _socketService.channel;

      await _channelSubscription?.cancel();
      _channelSubscription = channel?.stream.listen(
        (event) {
          retrySeconds = 1; // Reset retrySeconds on successful response
          if (event == null || event.toString().isEmpty) return;
          final socketResponse = SocketResponse.fromJSON(
              SocketEventType.response, event.toString());
          setState(() {
            _responses.add(socketResponse);
          });
        },
        onDone: () async {
          setState(() {
            _responses.add(
              SocketResponse(
                type: SocketEventType.done,
                message: 'Reconnecting... ($retrySeconds seconds)',
              ),
            );
          });
          await channel.sink.close();
          // Reconnect if connection is closed
          handleReconnect(retrySeconds);
        },
        cancelOnError: true, // Cancel subscription on error
      );
    } catch (e) {
      setState(() {
        _responses.add(
          SocketResponse(
            type: SocketEventType.error,
            message: 'Reconnecting... ($retrySeconds seconds)',
          ),
        );
      });
      // Reconnect if any error is thrown
      handleReconnect(retrySeconds);
    }
  }

  void handleReconnect(int delaySeconds) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      // Implemented an exponential backoff strategy
      final nextRetrySeconds = (delaySeconds * 2).clamp(1, 64);
      // Call the connectWebSocket function again with updated retrySeconds
      connectWebSocket(retrySeconds: nextRetrySeconds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 25, left: 16, right: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Socket Responses: ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _responses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _responses.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final response = _responses[index];
                        Color labelColor = Colors.green;

                        if (response.type == SocketEventType.error) {
                          labelColor = Colors.red;
                        } else if (response.type == SocketEventType.done) {
                          labelColor = Colors.orange;
                        }

                        return RichText(
                            text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: "${response.type.name.toUpperCase()}: ",
                              style: TextStyle(
                                color: labelColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: response.message,
                            ),
                          ],
                        ));
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
