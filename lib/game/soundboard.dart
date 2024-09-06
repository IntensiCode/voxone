import 'dart:async';

import 'package:voxone/core/common.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flutter/foundation.dart';

import 'game_data.dart';
import 'soundboard_soloud.dart' if (dart.library.html) 'soundboard_web.dart';
import 'storage.dart';
// import 'soundboard_mixed.dart' if (dart.library.html) 'soundboard_web.dart';

enum Sound {
  burst_machine_gun,
  collect,
  empty_click,
  explosion_1,
  explosion_2,
  explosion_hollow,
  flamethrower(limit: 1),
  hit_crack,
  hit_metal,
  prisoner_death,
  prisoner_freed,
  prisoner_ouch,
  prisoner_oh_oh,
  shot_assault_rifle,
  shot_assault_rifle_real,
  shot_bazooka,
  shot_machine_gun,
  shot_machine_gun_real,
  shot_nine_mm,
  shot_shotgun,
  shot_shotgun_real,
  shot_smg,
  shot_smg_real,
  ;

  final int? limit;

  const Sound({this.limit});
}

final soundboard = SoundboardImpl();

enum AudioMode {
  music_and_sound,
  music_only,
  silent,
  sound_only,
  ;

  static AudioMode from_name(String name) => AudioMode.values.firstWhere((it) => it.name == name);
}

abstract class Soundboard extends Component {
  Future _save() async => await save_data('soundboard', save_state());

  AudioMode _audio_mode = AudioMode.music_and_sound;

  AudioMode get audio_mode => _audio_mode;

  set audio_mode(AudioMode mode) {
    if (_audio_mode == mode) return;
    _audio_mode = mode;
    logInfo('change audio mode: $mode');
    _update_volumes(mode);
    _save();
    do_update_volume();
  }

  void _update_volumes(AudioMode mode) {
    switch (mode) {
      case AudioMode.music_and_sound:
        _music = 0.4;
        _sound = 0.6;
        _muted = false;
      case AudioMode.music_only:
        _music = 1.0;
        _sound = 0.0;
        _muted = false;
      case AudioMode.silent:
        _music = 0.0;
        _sound = 0.0;
        _muted = true;
      case AudioMode.sound_only:
        _music = 0.0;
        _sound = 1.0;
        _muted = false;
    }
  }

  double _master = 0.5;

  double get master => _master;

  set master(double value) {
    if (_master == value) return;
    _master = value;
    _save();
  }

  double _music = 0.4;

  double get music => _music;

  set music(double value) {
    if (_music == value) return;
    _music = value;
    _save();
    do_update_volume();
  }

  double _sound = 0.6;

  double get sound => _sound;

  set sound(double value) {
    if (_sound == value) return;
    _sound = value;
    _save();
  }

  bool _muted = false;

  bool get muted => _muted;

  set muted(bool value) {
    if (_muted == value) return;
    _muted = value;
    _save();
  }

  // flag used during initialization
  bool _blocked = false;

  // used by [trigger] to play every sound only once per tick
  final _triggered = <Sound>{};

  String? active_music_name;
  (String, bool, Hook?)? pending_music;
  double? fade_out_volume;

  @protected
  double? get active_music_volume;

  set active_music_volume(double? it);

  @protected
  void do_update_volume();

  @protected
  Future do_preload();

  @protected
  Future do_play(Sound sound, double volume_factor);

  @protected
  Future do_preload_one_shot_sample(String filename);

  @protected
  Future<Disposable> do_play_one_shot_sample(
    String filename, {
    required double volume_factor,
    required bool cache,
    required bool loop,
  });

  @protected
  Future do_play_music(String filename, {bool loop = true, Hook? on_end});

  @protected
  void do_stop_active_music();

  void toggleMute() => muted = !muted;

  void clear(String filename) => TODO('nyi'); // FlameAudio.audioCache.clear(filename);

  Future preload() async {
    if (_blocked) {
      logWarn('blocked preload');
      return;
    }
    _blocked = true;
    await do_preload();
    _blocked = false;
    logInfo('preload done');
  }

  void trigger(Sound sound) => _triggered.add(sound);

  Future play(Sound sound, {double volume_factor = 1}) async {
    if (_muted) return;
    if (_blocked) return;
    await do_play(sound, volume_factor);
  }

  Future<void> preload_one_shot(String filename) async => await do_preload_one_shot_sample(filename);

  Future<Disposable> play_one_shot_sample(
    String filename, {
    double volume_factor = 1,
    bool cache = true,
    bool loop = false,
  }) async {
    if (_muted) return Disposable.disposed;
    return await do_play_one_shot_sample(filename, volume_factor: volume_factor, cache: cache, loop: loop);
  }

  Future play_music(String filename, {bool loop = true, Hook? on_end}) async {
    // TODO check is_playing_music, too?
    if (fade_out_volume != null) {
      logInfo('schedule music $filename');
      pending_music = (filename, loop, on_end);
    } else if (active_music_name == filename) {
      logInfo('music already playing: $filename');
    } else {
      logInfo('play music $filename loop=$loop');
      do_stop_active_music();
      active_music_name = filename;
      await do_play_music(filename, loop: loop, on_end: on_end);
    }
  }

  void stop_active_music() {
    logInfo('stop active music $active_music_name');
    fade_out_volume = null;
    active_music_name = null;
    do_stop_active_music();
  }

  void fade_out_music() {
    logInfo('fade out music $active_music_volume');
    fade_out_volume = active_music_volume;
  }

  // Component

  @override
  Future onLoad() async {
    super.onLoad();
    final data = await load_data('soundboard');
    if (data != null) load_state(data);
  }

  @override
  void onMount() {
    super.onMount();
    if (dev) preload();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _fade_music(dt);

    if (_triggered.isEmpty) return;
    _triggered.forEach(play);
    _triggered.clear();
  }

  void _fade_music(double dt) {
    double? fov = fade_out_volume;
    if (fov == null) return;

    fov -= dt;
    if (fov <= 0) {
      stop_active_music();
      fade_out_volume = null;
      final pending = pending_music;
      if (pending != null) {
        pending_music = null;
        play_music(pending.$1, loop: pending.$2, on_end: pending.$3);
      }
    } else {
      active_music_volume = fov;
      fade_out_volume = fov;
    }
  }

  void load_state(Map<String, dynamic> data) {
    logInfo('load soundboard: $data');
    _audio_mode = AudioMode.from_name(data['audio_mode'] ?? audio_mode.name);
    _master = data['master'] ?? _master;
    _music = data['music'] ?? _music;
    _muted = data['muted'] ?? _muted;
    _sound = data['sound'] ?? _sound;
  }

  GameData save_state() => {}
    ..['master'] = _master
    ..['music'] = _music
    ..['muted'] = _muted
    ..['sound'] = _sound
    ..['audio_mode'] = _audio_mode.name;
}
