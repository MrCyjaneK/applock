import 'dart:convert';
import 'dart:io';

import 'package:android_native_settings_properties/android_native_settings_properties_method_channel.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

enum AppLockPenalty {
  standardLow,
  standardMedium,
  standardHigh,
  tamperLow,
  tamperHigh,
}

class AppLockState {
  AppLockState({
    required this.stateDir,
    required this.password,
    required this.isAppLocked,
    required this.totalSuccess,
    required this.totalFailure,
    required this.totalAppStart,
    required this.lastSuccess,
    required this.lastFailure,
    required this.lastAppStart,
    required this.hashcashLow, // this bits difficulty *challengeDivider adds up to 1 minute
    required this.hashcashHigh, // this bits difficulty *challengeDivider adds up to 15 minutes
  });
  String stateDir;
  String password;
  // 0== -> no, it is not
  // 1<= -> yes it is (increments every time when app is started)
  int isAppLocked;

  Future<AppLockPenalty> penalty() async {
    final settings = MethodChannelAndroidNativeSettingsProperties();
    String adbWifiEnabled = "0";
    String adbEnabled = "0";
    String waitForDebugger = "0";
    String forceNonDebuggableFinalBuildForCompat = "0";
    try {
      adbWifiEnabled = await settings.getOption('adb_wifi_enabled') ?? "0";
    } catch (e) {
      debugPrint("adb_wifi_enabled: $e");
    }
    try {
      adbEnabled = await settings.getOption('adb_enabled') ?? "0";
    } catch (e) {
      debugPrint("adb_enabled: $e");
    }
    try {
      waitForDebugger = await settings.getOption("wait_for_debugger") ?? "0";
    } catch (e) {
      debugPrint("wait_for_debugger: $e");
    }
    try {
      forceNonDebuggableFinalBuildForCompat = await settings
              .getOption("force_non_debuggable_final_build_for_compat") ??
          "0";
    } catch (e) {
      debugPrint("force_non_debuggable_final_build_for_compat: $e");
    }
    final isAdb = (adbWifiEnabled == "1") ||
        (adbEnabled == "1") ||
        (waitForDebugger == "1") ||
        (forceNonDebuggableFinalBuildForCompat == "1");
    if (lastFailure < 5) {
      return isAdb ? AppLockPenalty.tamperLow : AppLockPenalty.standardLow;
    } else if (lastFailure < 10) {
      return isAdb ? AppLockPenalty.tamperLow : AppLockPenalty.standardMedium;
    } else if (lastFailure < 20) {
      return isAdb ? AppLockPenalty.tamperLow : AppLockPenalty.standardHigh;
    } else if (lastFailure < 75) {
      return isAdb ? AppLockPenalty.tamperHigh : AppLockPenalty.tamperLow;
    } else {
      return AppLockPenalty.tamperHigh;
    }
  }

  int totalSuccess;
  int totalFailure;
  int totalAppStart;
  // resets after successful app unlock
  int lastSuccess;
  int lastFailure;
  int lastAppStart;

  int hashcashLow; // this bits difficulty *challengeDivider adds up to 1 minute
  int hashcashHigh; // this bits difficulty *challengeDivider adds up to 15 minutes

  Future<Map<String, dynamic>> toJson() async {
    return {
      "isAppLocked": isAppLocked,
      "totalSuccess": totalSuccess,
      "totalFailure": totalFailure,
      "totalAppStart": totalAppStart,
      "lastSuccess": lastSuccess,
      "lastFailure": lastFailure,
      "lastAppStart": lastAppStart,
      "hashcashLow": hashcashLow,
      "hashcashHigh": hashcashHigh,
    };
  }

  static bool isSaving = false;
  Future<void> save() async {
    if (isSaving) return;
    isSaving = true;
    try {
      File(p.join(stateDir, ".applock-state")).writeAsStringSync(
          JsonEncoder.withIndent('    ').convert(await toJson()));
    } finally {
      isSaving = false;
    }
  }

  static Future<AppLockState> fromStateDirectory(String stateDir) async {
    String password = "";
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      password += "${packageInfo.appName}/";
      password += "${packageInfo.packageName}/";
      password += "${packageInfo.version}/";
      password += "${packageInfo.buildNumber}/";
      packageInfo.buildSignature;
    } catch (e) {
      password += e.runtimeType.toString();
    }
    try {
      final state = File(p.join(stateDir, ".applock-state"));
      Map<String, dynamic> data = {};
      if (state.existsSync()) {
        data = jsonDecode(state.readAsStringSync());
      }
      final stateObj = AppLockState(
        stateDir: stateDir,
        password: password,
        isAppLocked: data["isAppLocked"] ?? 0,
        totalSuccess: data["totalSuccess"] ?? 0,
        totalFailure: data["totalFailure"] ?? 0,
        totalAppStart: data["totalAppStart"] ?? 1,
        lastSuccess: data["lastSuccess"] ?? 0,
        lastFailure: data["lastFailure"] ?? 0,
        lastAppStart: data["lastAppStart"] ?? 0,
        hashcashLow: data["hashcashLow"] ?? 0,
        hashcashHigh: data["hashcashHigh"] ?? 0,
      );
      stateObj.save();
      return stateObj;
    } catch (e) {
      debugPrint(e.toString());
      return AppLockState(
        stateDir: stateDir,
        password: password,
        isAppLocked: 1,
        totalSuccess: 0,
        totalFailure: 0,
        totalAppStart: 1,
        lastSuccess: 0,
        lastFailure: 0,
        lastAppStart: 0,
        hashcashLow: 0,
        hashcashHigh: 0,
      );
    }
  }
}
