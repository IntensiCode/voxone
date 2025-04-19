import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/util/auto_dispose.dart';

class PlatformAudioSystem extends AudioSystem {
  late final SoLoud soloud;

  final _sounds = <Sound, AudioSource>{};
  final _one_shots = <String, Future<AudioSource>>{};
  (AudioSource, SoundHandle)? _active_music;
  final _last_time = <Object, int>{};

  @override
  Future onLoad() async {
    super.onLoad();
    soloud = SoLoud.instance;
    await soloud.init();
    logInfo('soloud initialized');
  }

  @override
  double? get active_music_volume {
    final active = _active_music;
    if (active == null) return null;
    return soloud.getVolume(active.$2);
  }

  @override
  set active_music_volume(double? it) {
    final active = _active_music;
    if (active == null) return;
    if (it == null || it == 0) {
      soloud.setVolume(active.$2, 0);
      final paused = soloud.getPause(active.$2);
      if (!paused) soloud.pauseSwitch(active.$2);
    } else {
      soloud.setVolume(active.$2, it * master);
      final paused = soloud.getPause(active.$2);
      if (paused) soloud.pauseSwitch(active.$2);
    }
  }

  @override
  Future do_preload() async {
    if (_sounds.isNotEmpty) return;
    for (final it in Sound.values) {
      try {
        _sounds[it] = await soloud.loadAsset('assets/audio/sound/${it.name}.ogg');
      } catch (e) {
        logError('failed loading $it: $e');
      }
    }
  }

  @override
  void do_update_volume() {
    logInfo('update volume $music');
    active_music_volume = music;
  }

  @override
  Future do_play(Sound sound, double volume_factor) async {
    final it = _sounds[sound];
    if (it == null) {
      logError('null sound: $sound');
      preload();
      return;
    }

    final last_played_at = _last_time[sound] ?? 0;
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (now < last_played_at + 100) return;
    _last_time[sound] = now;

    final volume = (volume_factor * super.sound * super.master).clamp(0.0, 1.0);
    await soloud.play(it, volume: volume);
  }

  @override
  Future do_preload_one_shot_sample(String filename) async =>
      await _one_shots.putIfAbsent(filename, () => soloud.loadAsset('assets/audio/$filename'));

  final _queued = <(String, double, bool, bool, Function(Disposable))>[];

  SoundHandle? _active_one_shot;

  @override
  Future<Disposable> do_play_one_shot_sample(
    String filename, {
    required double volume_factor,
    required bool cache,
    required bool loop,
  }) async {
    if (_queued.any((it) => it.$1 == filename)) return Disposable.disposed;

    Disposable? late;
    if (_active_one_shot != null) {
      final it = (filename, volume_factor, cache, loop, (it) => late = it);
      _queued.add(it);
      return Disposable.wrap(() {
        late?.dispose();
        _queued.remove(it);
      });
    }

    final last_played_at = _last_time[filename] ?? 0;
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (now < last_played_at + 100) return Disposable.disposed;
    _last_time[filename] = now;

    final source = _one_shots.putIfAbsent(filename, () => soloud.loadAsset('assets/audio/$filename'));
    final volume = (volume_factor * super.sound * super.master).clamp(0.0, volume_factor * master);
    final active = await source;
    final handle = await soloud.play(active, volume: volume, looping: loop);

    _active_one_shot = handle;

    active.allInstancesFinished.listen((it) async {
      if (_active_one_shot != handle) return;
      _active_one_shot = null;
      if (_queued.isNotEmpty) {
        final (filename, volume_factor, cache, loop, hook) = _queued.removeAt(0);
        final it = await do_play_one_shot_sample(filename, volume_factor: volume_factor, cache: cache, loop: loop);
        hook(it);
      }
    });

    return Disposable.wrap(() => soloud.stop(handle));
  }

  @override
  Future do_play_music(String filename, {bool loop = true, Hook? on_end}) async {
    try {
      await _do_play_music(filename, loop: loop, on_end: on_end);
    } catch (e) {
      logError('failed playing $filename: $e');
      await Future.delayed(const Duration(seconds: 1));
      await _do_play_music(filename, loop: loop, on_end: on_end);
    }
  }

  Future _do_play_music(String filename, {bool loop = true, Hook? on_end}) async {
    do_stop_active_music();

    // because of the async-ness, double check no other music started by now:
    if (_active_music != null) return;

    await Future.delayed(const Duration(milliseconds: 100));

    final source = await soloud.loadAsset('assets/audio/$filename');
    final volume = (super.music * super.master).clamp(0.0, 1.0);
    final handle = await soloud.play(source, volume: volume, looping: loop);
    _active_music = (source, handle);

    logInfo('playing music via soloud: $filename');

    if (on_end != null) source.allInstancesFinished.listen((_) => on_end());
  }

  @override
  void do_stop_active_music() async {
    final active = _active_music;
    if (active == null) return;

    logInfo('stopping active music');

    _active_music = null;
    await soloud.stop(active.$2);
    await soloud.disposeSource(active.$1);
  }
}
