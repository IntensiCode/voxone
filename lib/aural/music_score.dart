import 'package:dart_minilog/dart_minilog.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/on_message.dart';

final music_score = MusicScore();

class MusicScore extends AutoDisposeComponent {
  String? _target_score;

  String? _current_score;

  @override
  onLoad() {
    onMessage<ScreenShowing>((it) {
      final score = _target_score_for(it.screen);
      if (score == null) return;

      if (_target_score == score) return;
      _target_score = score;
      logInfo('target screen: ${it.screen} => score: $_target_score');
    });
    onMessage<ShowInfoText>((it) {
      if (it.text == 'Capital Ship Approaching') {
        _target_score = 'music/voxone_ingame_1.ogg';
      }
    });
  }

  String? _target_score_for(Screen screen) => switch (screen) {
        Screen.title => 'music/voxone_title.ogg',
        Screen.stage1 => 'music/voxone_background_1.ogg',
        Screen.stage2 => 'music/voxone_background_1.ogg',
        Screen.stage3 => 'music/voxone_background_1.ogg',
        _ => null,
      };

  @override
  void update(double dt) {
    super.update(dt);
    if (_current_score == _target_score) {
      return;
    } else if (_current_score == null && _target_score != null) {
      if (audio.fade_out_volume == null) {
        logInfo('play music $_target_score');
        audio.play_music(_target_score!);
        _current_score = _target_score;
      }
    } else if (_current_score != null) {
      logInfo('fade out music $_current_score');
      audio.fade_out_music();
      _current_score = null;
    }
  }
}
