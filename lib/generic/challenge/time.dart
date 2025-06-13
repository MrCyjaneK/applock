import 'dart:async';
import 'dart:math';

import 'package:applock/generic/challenge/hashcash.dart';
import 'package:applock/generic/state.dart';
import 'package:flutter/foundation.dart';

class TimeChallenge {
  TimeChallenge({
    required int timeTotal,
  }) : _timeTotal = timeTotal;
  final int _timeTotal;
  late int _timeLeft = _timeTotal;
  double get progress => 1 - (_timeLeft / _timeTotal);

  String get name => "🔐 ${(_timeLeft / 60).floor()}m${_timeLeft % 60}s";
  String get status =>
      "App is locked, please wait ${(_timeLeft / 60).floor()}m${_timeLeft % 60}s\n$_extra";

  String get _extra =>
      (_extraPenalty == 0) ? "" : "Do not close the app during challenge";

  int _extraPenalty = 0;

  void start({
    required VoidCallback successCallback,
    required VoidCallback rebuild,
    required AppLockState state,
  }) async {
    while (_timeLeft > 0) {
      rebuild();

      final sw = Stopwatch()..start();
      await Future.delayed(Duration(seconds: 1));
      sw.stop();

      final elapsed = sw.elapsed;
      final actualElapsedSeconds = elapsed.inMilliseconds / 1000.0;

      if (actualElapsedSeconds < 0.9 || actualElapsedSeconds > 1.1) {
        _timeLeft =
            min(_timeTotal, _timeLeft + elapsed.inSeconds + _extraPenalty);
        _extraPenalty++;
      } else {
        _timeLeft--;
      }
    }
    successCallback();
  }

  static TimeChallenge get(AppLockPenalty penalty) => switch (penalty) {
        AppLockPenalty.standardLow => TimeChallenge(timeTotal: 30),
        AppLockPenalty.standardMedium => TimeChallenge(timeTotal: 2 * 60),
        AppLockPenalty.standardHigh => TimeChallenge(timeTotal: 10 * 60),
        AppLockPenalty.tamperLow =>
          HashcashChallenge(difficulty: HashcashChallengeDifficulty.low),
        AppLockPenalty.tamperHigh =>
          HashcashChallenge(difficulty: HashcashChallengeDifficulty.high),
      };
}
