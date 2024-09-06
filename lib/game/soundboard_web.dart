import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame_audio/flame_audio.dart';

import '../core/common.dart';
import '../util/auto_dispose.dart';
import 'soundboard.dart';

class SoundboardImpl extends Soundboard {
  final _sounds = <Sound, AudioPlayer>{};
  final _max_sounds = <AudioPlayer>[];
  final _last_time = <Object, int>{};

  StreamSubscription? _on_end;

  @override
  double? get active_music_volume => FlameAudio.bgm.audioPlayer.volume;

  @override
  set active_music_volume(double? it) {
    final ap = FlameAudio.bgm.audioPlayer;
    if (ap.source == null || !FlameAudio.bgm.isPlaying) return;
    ap.setVolume(it ?? music);
    // if (it == 0 && ap.state == PlayerState.playing) FlameAudio.bgm.pause();
    // if (it > 0 && ap.state != PlayerState.playing) FlameAudio.bgm.resume();
  }

  @override
  Future do_preload() async {
    if (_sounds.isNotEmpty) return;
    for (final it in Sound.values) {
      try {
        _sounds[it] = await _preload_player('${it.name}.ogg');
      } catch (e) {
        logError('failed loading $it: $e');
      }
    }
  }

  Future<AudioPlayer> _preload_player(String name) async {
    final player = await FlameAudio.play('sound/$name', volume: super.sound);
    player.setReleaseMode(ReleaseMode.stop);
    player.setPlayerMode(PlayerMode.lowLatency);
    player.stop();
    return player;
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

    _max_sounds.removeWhere((it) => it.state != PlayerState.playing);
    if (_max_sounds.length > 10) {
      final fifo = _max_sounds.removeAt(0);
      await fifo.stop();
    }

    if (it.state != PlayerState.stopped) await it.stop();
    await it.setVolume((volume_factor * super.sound).clamp(0, 1));
    await it.resume();
  }

  @override
  Future do_preload_one_shot_sample(String filename) async => await FlameAudio.audioCache.load(filename);

  @override
  Future<Disposable> do_play_one_shot_sample(
    String filename, {
    required double volume_factor,
    required bool cache,
    required bool loop,
  }) async {
    final last_played_at = _last_time[filename] ?? 0;
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (now < last_played_at + 100) return Disposable.disposed;
    _last_time[filename] = now;

    // TODO handle !cache somehow?
    await FlameAudio.audioCache.load(filename);
    final it = await FlameAudio.play(filename, volume: (volume_factor * super.sound).clamp(0, 1));
    it.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
    return Disposable.wrap(() {
      it.setReleaseMode(ReleaseMode.release);
      it.stop();
    });
  }

  @override
  Future do_play_music(String filename, {bool loop = true, Hook? on_end}) async {
    do_stop_active_music();

    logInfo('playing music via audio_players');
    await FlameAudio.bgm.play(filename, volume: music);

    FlameAudio.bgm.audioPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);

    if (on_end != null || !loop) {
      if (_on_end != null) throw 'ensure do_stop_active_music has been called';
      _on_end = FlameAudio.bgm.audioPlayer.onPlayerComplete.listen((_) {
        logInfo('bgm complete');
        if (!loop) do_stop_active_music();
        if (on_end != null) on_end();
      });
    }
  }

  @override
  void do_stop_active_music() async {
    _on_end?.cancel();
    _on_end = null;

    if (!FlameAudio.bgm.isPlaying) return;

    logInfo('stopping active bgm');
    await FlameAudio.bgm.stop();
  }
}
