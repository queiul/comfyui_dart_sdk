import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Class to handle WebSocket connections with ComfyUI and fetch generated images.
class ComfySocket {
  final Uri url;
  final WebSocketChannel _channel;
  final Stream<dynamic> broadcastStream;
  final String clientId;
  bool _isConnected = false;

  ComfySocket._(this.url, this.clientId, this._channel)
      : broadcastStream = _channel.stream.asBroadcastStream() {
    _isConnected = true;
  }

  static String _ensureWebSocketUrl(String url) {
    if (url.startsWith("http://")) return "ws://${url.substring(7)}";
    if (url.startsWith("https://")) return "wss://${url.substring(8)}";
    return url;
  }

  /// Establishes a WebSocket connection with the given URL and client ID.
  static ComfySocket connect(String url, String clientId) {
    final validUrl = _ensureWebSocketUrl(
        "${url.endsWith('/') ? url : '$url/'}ws?clientId=$clientId");
    final uri = Uri.parse(validUrl);
    final channel = WebSocketChannel.connect(uri);

    return ComfySocket._(uri, clientId, channel);
  }

  /// Attempts to reconnect to the WebSocket with exponential backoff strategy.
  Future<void> _scheduleReconnect() async {
    int attempt = 1;
    const maxDelay = Duration(seconds: 10);

    while (!_isConnected) {
      final delay = Duration(seconds: attempt);
      await Future.delayed(delay);

      print('Attempting reconnection #$attempt...');
      try {
        _isConnected = true;
      } catch (_) {
        _isConnected = false;
      }

      attempt =
          (attempt < maxDelay.inSeconds) ? attempt * 2 : maxDelay.inSeconds;
    }
  }

  /// Stream that monitors the WebSocket connection status and messages.
  Stream<String> connectionListener() async* {
    await for (final message in broadcastStream) {
      if (message == 'disconnected') {
        _isConnected = false;
        yield 'disconnected';
        await _scheduleReconnect();
      } else {
        yield message.toString();
      }
    }
  }

  /// Fetches the images generated for a given `promptId`.
  Stream<Uint8List> getImages(String promptId) async* {
    bool generationComplete = false;

    await for (final message in broadcastStream) {
      if (message is Uint8List) {
        yield message.sublist(8); // Trim binary header if any
      } else if (message is String) {
        final Map<String, dynamic> parsedMessage = jsonDecode(message);

        if (parsedMessage['type'] == 'progress' &&
            parsedMessage['data']['prompt_id'] == promptId &&
            parsedMessage['data']['value'] == parsedMessage['data']['max']) {
          generationComplete = true;
        }

        if (parsedMessage['type'] == 'execution_interrupted') {
          break; // Stop on execution interrupt
        }

        if (generationComplete && parsedMessage['type'] == 'status') {
          final status = parsedMessage['data']['status'];
          if (status != null) break;
        }
      }
    }
  }

  /// Closes the WebSocket connection.
  Future<void> close() async {
    await _channel.sink.close();
    _isConnected = false;
  }
}
