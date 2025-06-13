import 'package:applock/generic/applock.dart';
import 'package:applock/generic/state.dart';
import 'package:flutter/material.dart';

abstract class AppLock {
  static final AppLock instance = () {
    return GenericAppLock();
  }();

  AppLockState? state;

  Future<void> registerAppStart(ThemeData color, VoidCallback successCallback);
  Future<void> enableTimelock(ThemeData color, VoidCallback successCallback);
  Future<void> fail(ThemeData color, VoidCallback successCallback);
  Future<void> success();
}
