import 'package:applock/assets.dart';
import 'package:applock/generic/challenge/time.dart';
import 'package:applock/generic/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TimelockApp extends StatelessWidget {
  const TimelockApp({
    super.key,
    required this.color,
    required this.successCallback,
    required this.penalty,
    required this.state,
  });

  final ThemeData color;
  final VoidCallback successCallback;
  final AppLockPenalty penalty;
  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: color,
      home: TimelockScreen(
        penalty: penalty,
        successCallback: successCallback,
        state: state,
      ),
    );
  }
}

class TimelockScreen extends StatefulWidget {
  const TimelockScreen({
    super.key,
    required this.state,
    required this.penalty,
    required this.successCallback,
  });

  final AppLockPenalty penalty; // in seconds
  final VoidCallback successCallback;
  final AppLockState state;

  @override
  State<TimelockScreen> createState() => _TimelockScreenState();
}

class _TimelockScreenState extends State<TimelockScreen> {
  late final challenge = TimeChallenge.get(widget.penalty);

  @override
  void initState() {
    challenge.start(
        successCallback: widget.successCallback,
        rebuild: () {
          setState(() {});
        },
        state: widget.state);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double progress = challenge.progress;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Authentication Failed"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.maxFinite,
                  child: SvgPicture.string(
                    cpuLogoSvg,
                  ),
                ),
              ),
              Text(
                challenge.name,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall!
                    .copyWith(fontSize: 24),
              ),
              SizedBox(height: 24),
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: LinearProgressIndicator(
                    value: progress,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                challenge.status,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
