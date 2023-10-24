/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webf/webf.dart';
import 'package:webf_integration_tests/bridge/match_snapshots.dart';
import '../../utils/sleep.dart';

import 'package:stack_trace/stack_trace.dart' as stacktrace;

/// Returns an absolute path to the caller's `.dart` file.
String currentDartFilePath() => stacktrace.Frame.caller(1).uri.path.split('/').sublist(2).join('/');

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    print('=================== CAUGHT FLUTTER ERROR');
    // exit(1);
  };
  runZonedGuarded(() async {
    runApp(MaterialApp(home: FirstRoute(),));
  }, (error, stackTrace) {
    print('Error FROM OUT_SIDE FRAMEWORK ');
    print('--------------------------------');
    print('Error :  $error');
    print('StackTrace :  $stackTrace');
    // exit(1);
  });
}

class FirstRouteElement extends StatefulElement {
  FirstRouteElement(super.widget);

  @override
  FirstRouteState get state => super.state as FirstRouteState;

  @override
  void mount(Element? parent, Object? newSlot) async {
    super.mount(parent, newSlot);

    try {

      await sleep(Duration(seconds: 1));
      Navigator.push(
        this,
        MaterialPageRoute(builder: (context) => SecondRoute(state.controller)),
      );
      await sleep(Duration(seconds: 1));
      Uint8List snapshotBytes = await state.controller.view.document.documentElement!.toBlob();
      await matchImageSnapshotOrError(snapshotBytes, currentDartFilePath());

      Navigator.pop(this);
      await sleep(Duration(seconds: 1));
      Navigator.push(
        this,
        MaterialPageRoute(builder: (context) => SecondRoute(state.controller)),
      );

      await sleep(Duration(seconds: 1));
      Uint8List snapshotBytes2 = await state.controller.view.document.documentElement!.toBlob();
      await matchImageSnapshotOrError(snapshotBytes2, currentDartFilePath());

      Navigator.pop(this);

    } catch (e, stack) {
      print('$e \n $stack');
      // exit(1);
    }
  }
}

class FirstRoute extends StatefulWidget {
  const FirstRoute({super.key});

  @override
  StatefulElement createElement() {
    return FirstRouteElement(this);
  }

  @override
  State<StatefulWidget> createState() {
    return FirstRouteState();
  }
}

class FirstRouteState extends State<FirstRoute> {
  late WebFController controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = WebFController(context);
    controller.preload(WebFBundle.fromUrl('assets:///assets/demo_app/bundle.html'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Route'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Open route'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SecondRoute(controller)),
            );
            // Navigate to second route when tapped.
          },
        ),
      ),
    );
  }
}

class SecondRoute extends StatelessWidget {
  final WebFController controller;

  const SecondRoute(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            children: [
              WebF(
                controller: controller,
              ),
            ],
          ),
        ));
  }
}
