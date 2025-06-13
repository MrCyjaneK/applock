import 'dart:isolate';

import 'package:applock/generic/challenge/time.dart';
import 'package:applock/generic/state.dart';
import 'package:flutter/foundation.dart';
import 'package:hashcash_dart/hashcash_dart.dart';

const challengeDivider = 250;

enum HashcashChallengeDifficulty { low, high }

class HashcashChallenge implements TimeChallenge {
  HashcashChallenge({required this.difficulty});
  HashcashChallengeDifficulty difficulty;
  final int challengesTotal = challengeDivider;
  late int challengesLeft = challengesTotal;

  @override
  String get name => switch (difficulty) {
        HashcashChallengeDifficulty.low => "Easy CPU challenge",
        HashcashChallengeDifficulty.high => "Difficult CPU challenge",
      };

  @override
  double get progress => 1 - (challengesLeft / challengesTotal);

  @override
  String get status =>
      "App is locked, and suspicious activity was detected. Your device needs to solve CPU-intensive challenge in order to unlock the app. Currently solving: ${challengesTotal - challengesLeft}/$challengesTotal";

  @override
  void start(
      {required VoidCallback successCallback,
      required VoidCallback rebuild,
      required AppLockState state}) async {
    while (challengesLeft > 0) {
      await Isolate.run(() {
        Hashcash.mint('hi@mrcyjanek.net',
            saltChars: 16,
            bits: switch (difficulty) {
              HashcashChallengeDifficulty.low => state.hashcashLow,
              HashcashChallengeDifficulty.high => state.hashcashHigh,
            });
      });
      challengesLeft--;
      rebuild();
    }
    successCallback();
  }

  static Future<void> runBenchmark(AppLockState state) async {
    if (!(state.hashcashHigh == 0 || state.hashcashLow == 0)) return;
    await Future.delayed(Duration(seconds: 5));
    final lowTarget = 2 * 60 * 1000 / challengeDivider;
    final highTarget = 15 * 60 * 1000 / challengeDivider;

    int current = 1;
    while (true) {
      await Future.delayed(Duration.zero);
      final sw = Stopwatch()..start();
      await Isolate.run(() {
        Hashcash.mint('hi@mrcyjanek.net', saltChars: 16, bits: current);
      });
      if (sw.elapsedMilliseconds > lowTarget && state.hashcashLow == 0) {
        state.hashcashLow = current;
      }
      if (sw.elapsedMilliseconds > highTarget && state.hashcashHigh == 0) {
        state.hashcashHigh = current;
        break;
      }
      current++;
    }
    debugPrint("low : ${state.hashcashLow}");
    debugPrint("high: ${state.hashcashHigh}");
    state.save();
  }
}
