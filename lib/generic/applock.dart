import 'dart:async';

import 'package:applock/applock.dart';
import 'package:applock/generic/challenge/hashcash.dart';
import 'package:applock/generic/state.dart';
import 'package:applock/generic/timelock_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class GenericAppLock implements AppLock {
  GenericAppLock();

  @override
  AppLockState? state;

  @override
  Future<void> fail(ThemeData theme, VoidCallback callback) async {
    state!.totalFailure++;
    state!.lastFailure++;
    state!.lastSuccess = 0;
    if (state!.lastFailure > 5) {
      return enableTimelock(theme, callback);
    }
    state!.save();
  }

  @override
  Future<void> success() async {
    state!.isAppLocked = 0;
    state!.lastFailure = 0;
    state!.lastSuccess = 1;
    state!.totalSuccess++;
    state!.save();
  }

  @override
  Future<void> registerAppStart(
      ThemeData color, VoidCallback successCallback) async {
    WidgetsFlutterBinding.ensureInitialized();
    final dir = await getApplicationSupportDirectory();
    state = await AppLockState.fromStateDirectory(p.join(dir.path));
    state!.totalAppStart++;
    state!.lastAppStart++;
    if (state!.isAppLocked != 0) {
      state!.isAppLocked++;
    }
    if (state!.lastFailure == 5) {
      state!.isAppLocked++;
    }
    state!.save();
    unawaited(() {
      HashcashChallenge.runBenchmark(state!);
    }());
    if (state!.isAppLocked == 0) {
      successCallback();
      return;
    }
    runApp(TimelockApp(
      color: color,
      successCallback: successCallback,
      penalty: await state!.penalty(),
      state: state!,
    ));
  }

  @override
  Future<void> enableTimelock(
      ThemeData color, VoidCallback successCallback) async {
    WidgetsFlutterBinding.ensureInitialized();
    final dir = await getApplicationSupportDirectory();
    state = await AppLockState.fromStateDirectory(dir.path);
    if (state!.isAppLocked == 0) {
      state!.isAppLocked = 1;
    }
    state!.save();
    runApp(TimelockApp(
      color: color,
      successCallback: successCallback,
      penalty: await state!.penalty(),
      state: state!,
    ));
  }
}
