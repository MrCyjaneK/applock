# applock

> Prevent user from opening app as penalty.

## Features

Prevent user from using the app for certain amount of time. Designed to be used in scenarios when app is ran in a fully offline scenario, assuming the app has been ran at least once in a trusted enviorment.

## Who is it for?

- Apps that is ran in airgap scenario without network access
- Assumes that attacker has non-root code execution/physical access to device
- Scenarios that doesn't rely on external OS state, only assumes that app files are intact.

## Usage

In your `pubspec.yaml`

```yaml
dependencies:
  applock:
    git:
      url: https://github.com/mrcyjanek/applock
      ref: master
```

Move `runApp` call into separate function (`$main` in our example), instead of `runApp` call `await AppLock.instance.registerAppStart(appTheme, $main);`

Then, in scenario where user failed to authenticate call following function, after 5 calls to this functions app will lock itself:

```dart
await AppLock.instance.fail(appTheme, $main);
```

and whenever user inputs correct password:

```dart
await AppLock.instance.success();
```

## Penalty levels

There are multiple penalty levels in app, and each of these get activated depending on the number of failures

### Standard

Forces user to wait while app is awaiting Future.delayed in a loop, very light CPU usage. If at any point app detects that future took over 10% more/less than the time it will invalidate the challenge.

- AppLockPenalty.standardLow => TimeChallenge(timeTotal: 30),
- AppLockPenalty.standardMedium => TimeChallenge(timeTotal: 2 * 60),
- AppLockPenalty.standardHigh => TimeChallenge(timeTotal: 10 * 60),

### Tamper

Forces user to wait while app is computing CPU-intensive task (on a single core) that takes on estimate 2 minutes for low and 15 minutes for high difficulty, preventing any time manipulation from being effective, as time is calculated in most wasteful way imaginable.

- AppLockPenalty.tamperLow => HashcashChallenge(difficulty: HashcashChallengeDifficulty.low),
- AppLockPenalty.tamperHigh => HashcashChallenge(difficulty: HashcashChallengeDifficulty.high),

App usually prefer normal time-based wait, unless app is under the risk of being debuggable (adb is enabled, or few other flags for android), then it will skip time-based penalty and go straight to CPU tasks.