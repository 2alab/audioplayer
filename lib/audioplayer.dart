import 'dart:async';

import 'package:flutter/services.dart';

enum AudioPlayerState {
  END,
  STOPPED,
  PLAYING,
  BUFFERING,
}

const MethodChannel _channel = const MethodChannel('ru.aalab/radioplayer');

class AudioPlayer {
  final StreamController<AudioPlayerState> _playerStateController =
      new StreamController.broadcast();

  AudioPlayerState _state = AudioPlayerState.STOPPED;

  AudioPlayer() {
    _channel.setMethodCallHandler(_audioPlayerStateChange);
  }

  Future<void> play(String url, {bool isLocal: false}) async =>
      await _channel.invokeMethod('play', {'url': url});

  Future<void> stop() async => await _channel.invokeMethod('stop');

  Future<void> mute(bool muted) async =>
      await _channel.invokeMethod('mute', muted);

  Stream<AudioPlayerState> get onPlayerStateChanged =>
      _playerStateController.stream;

  AudioPlayerState get state => _state;

  Future<void> _audioPlayerStateChange(MethodCall call) async {
    switch (call.method) {
      case "audio.onBuffering":
        assert(_state == AudioPlayerState.BUFFERING);
        _playerStateController.add(AudioPlayerState.BUFFERING);
        break;
      case "audio.onPlay":
        _state = AudioPlayerState.PLAYING;
        _playerStateController.add(AudioPlayerState.PLAYING);
        break;
      case "audio.onStop":
        _state = AudioPlayerState.STOPPED;
        _playerStateController.add(AudioPlayerState.STOPPED);
        break;
      case "audio.onEnded":
        _state = AudioPlayerState.END;
        _playerStateController.add(AudioPlayerState.END);
        break;
      default:
        throw new ArgumentError('Unknown method ${call.method} ');
    }
  }
}
