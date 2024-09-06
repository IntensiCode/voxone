import 'dart:async';
import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flutter/foundation.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';

import '../core/common.dart';
import '../util/auto_dispose.dart';
import 'soundboard.dart';

class _PlayState {
  _PlayState(this.sample, {this.loop = false, this.paused = false, required this.volume});

  final Float32List sample;
  int sample_pos = 0;

  bool loop;
  bool paused;
  Hook? on_end;

  double volume;
}

class SoundboardImpl extends Soundboard {
  AudioStream? _stream;
  final _samples = <Sound, Float32List>{};
  final _last_time = <Sound, int>{};
  final _one_shot_cache = <String, Future<Float32List>>{};
  final _play_state = <_PlayState>[];
  _PlayState? _active_music;

  @override
  double? get active_music_volume => _active_music?.volume;

  @override
  set active_music_volume(double? it) {
    _active_music?.volume = it ?? music;
    _active_music?.paused = _active_music?.volume == 0;
  }

  @override
  Future do_preload() async {
    if (_samples.isEmpty) await _make_samples();
  }

  Future _make_samples() async {
    for (final it in Sound.values) {
      _samples[it] = await _make_sample('audio/sound/${it.name}.raw');
    }
  }

  Future<Float32List> _make_sample(String fileName) async {
    final bytes = await game.assets.readBinaryFile(fileName);
    final data = Float32List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      data[i] = ((bytes[i] / 128) - 1);
    }
    return data;
  }

  @override
  void do_update_volume() {
    logInfo('update volume $music');
    active_music_volume = music;
  }

  @override
  Future do_play(Sound sound, double volume_factor) async {
    if (_samples.isEmpty) preload();

    final last_played_at = _last_time[sound] ?? 0;
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (now < last_played_at + 100) return;
    _last_time[sound] = now;

    _play_state.add(_PlayState(_samples[sound]!, volume: volume_factor * super.sound));
  }

  @override
  Future do_preload_one_shot_sample(String filename) async =>
      await (_one_shot_cache[filename] ??= _load_one_shot(filename));

  @override
  Future<Disposable> do_play_one_shot_sample(
    String filename, {
    required double volume_factor,
    required bool cache,
    required bool loop,
  }) async {
    final data = _one_shot_cache[filename] ??= _load_one_shot(filename);
    if (!cache) _one_shot_cache.remove(filename);
    final playing = _PlayState(await data, volume: volume_factor * sound, loop: loop);
    _play_state.add(playing);
    return Disposable.wrap(() => _play_state.remove(playing));
  }

  Future<Float32List> _load_one_shot(String filename) async {
    if (filename.endsWith('.ogg')) filename = filename.replaceFirst('.ogg', '');
    logVerbose('load sample $filename');
    return _make_sample('audio/$filename.raw');
  }

  @override
  Future do_play_music(String filename, {bool loop = true, Hook? on_end}) async {
    logInfo('play music via mp_audio_stream');

    do_stop_active_music();

    final raw_name = '${filename.replaceFirst('.ogg', '').replaceFirst('.mp3', '')}.raw';
    final data = await _make_sample('audio/$raw_name');
    _active_music = _PlayState(data, loop: loop, volume: music);
    _active_music!.on_end = on_end;
    _play_state.add(_active_music!);
  }

  @override
  void do_stop_active_music() {
    _play_state.remove(_active_music);
    _active_music = null;
  }

  // Component

  @override
  Future onLoad() async {
    super.onLoad();
    _init_audio_stream();
  }

  // Implementation

  void _init_audio_stream() {
    if (_stream != null) return;
    _stream = getAudioStream();
    final result = _stream!.init(
      bufferMilliSec: 500,
      waitingBufferMilliSec: 100,
      channels: 1,
      sampleRate: 11025,
    );
    logVerbose('audio mixing stream started: $result');
    _stream!.resume();
    _mix_stream();
  }

  void _mix_stream() async {
    const hz = 25;
    const rate = 11025;
    const step = rate ~/ hz;
    final mixed = Float32List(step);
    logInfo('mixing at $hz hz - frame step $step - buffer bytes ${mixed.length}');

    Timer.periodic(const Duration(milliseconds: 1000 ~/ hz), (t) {
      mixed.fillRange(0, mixed.length, 0);
      if (_play_state.isEmpty || muted) {
        _stream!.push(mixed);
        return;
      }

      for (final it in _play_state) {
        if (it.paused) continue;

        final data = it.sample;
        final start = it.sample_pos;
        final end = min(start + step, data.length);
        for (int i = start; i < end; i++) {
          final at = i - start;
          mixed[at] += data[i] * it.volume;
        }
        if (end == data.length) {
          it.on_end?.call();
          it.sample_pos = it.loop ? 0 : -1;
        } else {
          it.sample_pos = end;
        }
      }

      double? compress;
      for (int i = 0; i < mixed.length; i++) {
        final v = mixed[i];
        // limit before compression
        if (v.abs() > 1) compress = max(compress ?? 0, v.abs());
        // apply master for absolute limit
        mixed[i] = v * master;
      }

      if (compress != null) {
        logInfo('need compression: $compress');
        for (int i = 0; i < mixed.length; i++) {
          mixed[i] /= compress;
        }
      }

      _stream!.push(mixed);

      _play_state.removeWhere((e) => e.sample_pos == -1);
    });
  }
}
