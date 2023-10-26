/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:webf/rendering.dart';
import 'package:webf/webf.dart';
import 'package:webf/gesture.dart';

typedef OnControllerCreated = void Function(WebFController controller);

class WebF extends StatefulWidget {
  // The background color for viewport, default to transparent.
  final Color? background;

  // the width of webFWidget
  final double? viewportWidth;

  // the height of webFWidget
  final double? viewportHeight;

  //  The initial bundle to load.
  final WebFBundle? bundle;

  // The animationController of Flutter Route object.
  // Pass this object to webFWidget to make sure webF execute JavaScripts scripts after route transition animation completed.
  final AnimationController? animationController;

  // The methods of the webFNavigateDelegation help you implement custom behaviors that are triggered
  // during a webf view's process of loading, and completing a navigation request.
  final WebFNavigationDelegate? navigationDelegate;

  // A method channel for receiving messaged from JavaScript code and sending message to JavaScript.
  final WebFMethodChannel? javaScriptChannel;

  // Register the RouteObserver to observer page navigation.
  // This is useful if you wants to pause webf timers and callbacks when webf widget are hidden by page route.
  // https://api.flutter.dev/flutter/widgets/RouteObserver-class.html
  final RouteObserver<ModalRoute<void>>? routeObserver;

  // Trigger when webf controller once created.
  final OnControllerCreated? onControllerCreated;

  final LoadErrorHandler? onLoadError;

  final LoadHandler? onLoad;

  // https://developer.mozilla.org/en-US/docs/Web/API/Document/DOMContentLoaded_event
  final LoadHandler? onDOMContentLoaded;

  final JSErrorHandler? onJSError;

  // Open a service to support Chrome DevTools for debugging.
  final DevToolsService? devToolsService;

  final GestureListener? gestureListener;

  final HttpClientInterceptor? httpClientInterceptor;

  final UriParser? uriParser;

  /// Remote resources (HTML, CSS, JavaScript, Images, and other content loadable via WebFBundle) can be pre-loaded before WebF is mounted in Flutter.
  /// Use this property to reduce loading times when a WebF application attempts to load external resources on pages.
  final List<WebFBundle>? preloadedBundles;

  /// The initial cookies to set.
  final List<Cookie>? initialCookies;

  final WebFController? _controller;

  /// If true the content should size itself to avoid the onscreen keyboard
  /// whose height is defined by the ambient [FlutterView]'s
  /// [FlutterView.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the widget,
  /// the view can be resized to avoid overlapping the keyboard, which prevents
  /// widgets inside the view from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomInsets;

  WebFController? get controller {
    return _controller ?? WebFController.getControllerOfName(shortHash(this));
  }

  // Set webf http cache mode.
  static void setHttpCacheMode(HttpCacheMode mode) {
    HttpCacheController.mode = mode;
    if (kDebugMode) {
      print('WebF http cache mode set to $mode.');
    }
  }

  static bool _isValidCustomElementName(localName) {
    return RegExp(r'^[a-z][.0-9_a-z]*-[\-.0-9_a-z]*$').hasMatch(localName);
  }

  static void defineCustomElement(String tagName, ElementCreator creator) {
    if (!_isValidCustomElementName(tagName)) {
      throw ArgumentError('The element name "$tagName" is not valid.');
    }
    defineElement(tagName.toUpperCase(), creator);
  }

  Future<void> load(WebFBundle bundle) async {
    await controller?.load(bundle);
  }

  Future<void> reload() async {
    await controller?.reload();
  }

  WebF(
      {Key? key,
      this.viewportWidth,
      this.viewportHeight,
      this.bundle,
      this.onControllerCreated,
      this.onLoad,
      this.onDOMContentLoaded,
      this.navigationDelegate,
      this.javaScriptChannel,
      this.background,
      this.gestureListener,
      this.devToolsService,
      // webf's http client interceptor.
      this.httpClientInterceptor,
      this.uriParser,
      this.routeObserver,
      this.initialCookies,
      this.preloadedBundles,
      WebFController? controller,
      // webf's viewportWidth options only works fine when viewportWidth is equal to window.physicalSize.width / window.devicePixelRatio.
      // Maybe got unexpected error when change to other values, use this at your own risk!
      // We will fixed this on next version released. (v0.6.0)
      // Disable viewportWidth check and no assertion error report.
      bool disableViewportWidthAssertion = false,
      // webf's viewportHeight options only works fine when viewportHeight is equal to window.physicalSize.height / window.devicePixelRatio.
      // Maybe got unexpected error when change to other values, use this at your own risk!
      // We will fixed this on next version release. (v0.6.0)
      // Disable viewportHeight check and no assertion error report.
      bool disableViewportHeightAssertion = false,
      // Callback functions when loading Javascript scripts failed.
      this.onLoadError,
      this.animationController,
      this.onJSError,
      this.resizeToAvoidBottomInsets = true})
      : _controller = controller,
        super(key: key);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<double>('viewportWidth', viewportWidth));
    properties.add(DiagnosticsProperty<double>('viewportHeight', viewportHeight));
  }

  @override
  WebFState createState() => WebFState();
}

class WebFState extends State<WebF> with RouteAware {
  bool _disposed = false;

  final Set<WebFWidgetElementToWidgetAdapter> customElementWidgets = {};

  void onCustomElementWidgetAdd(WebFWidgetElementToWidgetAdapter adapter) {
    Future.microtask(() {
      if (!_disposed) {
        setState(() {
          customElementWidgets.add(adapter);
        });
      }
    });
  }

  void onCustomElementWidgetRemove(WebFWidgetElementToWidgetAdapter adapter) {
    Future.microtask(() {
      if (!_disposed) {
        setState(() {
          customElementWidgets.remove(adapter);
        });
      }
    });
  }

  bool _flutterScreenIsReady = false;

  watchWindowIsReady() {
    FlutterView view = PlatformDispatcher.instance.views.first;

    double viewportWidth = view.physicalSize.width / view.devicePixelRatio;
    double viewportHeight = view.physicalSize.height / view.devicePixelRatio;

    if (viewportWidth == 0.0 && viewportHeight == 0.0) {
      // window.physicalSize are Size.zero when app first loaded. This only happened on Android and iOS physical devices with release build.
      // We should wait for onMetricsChanged when window.physicalSize get updated from Flutter Engine.
      VoidCallback? _ordinaryOnMetricsChanged = PlatformDispatcher.instance.onMetricsChanged;
      PlatformDispatcher.instance.onMetricsChanged = () async {
        if (view.physicalSize == Size.zero) {
          return;
        }
        setState(() {
          _flutterScreenIsReady = true;
        });

        // Should proxy to ordinary window.onMetricsChanged callbacks.
        if (_ordinaryOnMetricsChanged != null) {
          _ordinaryOnMetricsChanged();
          // Recover ordinary callback to window.onMetricsChanged
          PlatformDispatcher.instance.onMetricsChanged = _ordinaryOnMetricsChanged;
        }
      };
    } else {
      _flutterScreenIsReady = true;
    }
  }

  @override
  void initState() {
    super.initState();
    watchWindowIsReady();
  }

  @override
  Widget build(BuildContext context) {
    if (!_flutterScreenIsReady) {
      return SizedBox(width: 0, height: 0);
    }

    return RepaintBoundary(
      child: WebFContext(
        child: WebFRootRenderObjectWidget(
          widget,
          onCustomElementAttached: onCustomElementWidgetAdd,
          onCustomElementDetached: onCustomElementWidgetRemove,
          children: customElementWidgets.toList(),
          resizeToAvoidBottomInsets: widget.resizeToAvoidBottomInsets,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.routeObserver != null) {
      widget.routeObserver!.subscribe(this, ModalRoute.of(context)!);
    }
  }

  @override
  void didUpdateWidget(WebF oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resizeToAvoidBottomInsets != widget.resizeToAvoidBottomInsets) {
      widget.controller?.resizeToAvoidBottomInsets = widget.resizeToAvoidBottomInsets;
    }
  }

  // Resume call timer and callbacks when webf widget change to visible.
  @override
  void didPopNext() {
    assert(widget.controller != null);
    widget.controller!.resume();
  }

  // Pause all timer and callbacks when webf widget has been invisible.
  @override
  void didPushNext() {
    assert(widget.controller != null);
    widget.controller!.pause();
  }

  @override
  void dispose() {
    if (widget.routeObserver != null) {
      widget.routeObserver!.unsubscribe(this);
    }
    super.dispose();
    _disposed = true;
  }

  @override
  void deactivate() {
    super.deactivate();
  }
}

class WebFContext extends InheritedWidget {
  WebFContext({required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }

  @override
  InheritedElement createElement() {
    return WebFContextInheritElement(this);
  }
}

class WebFContextInheritElement extends InheritedElement {
  WebFContextInheritElement(super.widget);

  WebFController? controller;

  @override
  void unmount() {
    super.unmount();
    controller = null;
  }
}

class WebFRootRenderObjectWidget extends MultiChildRenderObjectWidget {
  final OnCustomElementAttached onCustomElementAttached;
  final OnCustomElementDetached onCustomElementDetached;
  final bool resizeToAvoidBottomInsets;

  // Creates a widget that visually hides its child.
  WebFRootRenderObjectWidget(
    WebF widget, {
    Key? key,
    required List<Widget> children,
    required this.onCustomElementAttached,
    required this.onCustomElementDetached,
    this.resizeToAvoidBottomInsets = true,
  })  : _webfWidget = widget,
        super(key: key, children: children);

  final WebF _webfWidget;

  @override
  RenderObject createRenderObject(BuildContext context) {
    WebFController controller = _webfWidget.controller ??
        WebFController(context,
            name: shortHash(_webfWidget),
            viewportWidth: _webfWidget.viewportWidth,
            viewportHeight: _webfWidget.viewportHeight,
            background: _webfWidget.background,
            bundle: _webfWidget.bundle,
            // Execute entrypoint when mount manually.
            autoExecuteEntrypoint: false,
            externalController: false,
            onLoad: _webfWidget.onLoad,
            onDOMContentLoaded: _webfWidget.onDOMContentLoaded,
            onLoadError: _webfWidget.onLoadError,
            onJSError: _webfWidget.onJSError,
            methodChannel: _webfWidget.javaScriptChannel,
            gestureListener: _webfWidget.gestureListener,
            navigationDelegate: _webfWidget.navigationDelegate,
            devToolsService: _webfWidget.devToolsService,
            httpClientInterceptor: _webfWidget.httpClientInterceptor,
            onCustomElementAttached: onCustomElementAttached,
            onCustomElementDetached: onCustomElementDetached,
            initialCookies: _webfWidget.initialCookies,
            uriParser: _webfWidget.uriParser,
            preloadedBundles: _webfWidget.preloadedBundles,
            resizeToAvoidBottomInsets: resizeToAvoidBottomInsets);

    (context as _WebFRenderObjectElement).controller = controller;

    OnControllerCreated? onControllerCreated = _webfWidget.onControllerCreated;
    if (onControllerCreated != null) {
      onControllerCreated(controller);
    }

    if (controller.entrypoint != _webfWidget.bundle && _webfWidget.bundle != null) {
      controller.entrypoint = _webfWidget.bundle;
    }

    RenderViewportBox root = RenderViewportBox(
        background: _webfWidget.background,
        viewportSize: (_webfWidget.viewportWidth != null && _webfWidget.viewportHeight != null)
            ? Size(_webfWidget.viewportWidth!, _webfWidget.viewportHeight!)
            : null,
        controller: controller);
    controller.view.viewport = root;

    return root;
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    WebFController controller = (context as _WebFRenderObjectElement).controller!;
    if (controller.disposed) return;

    controller.name = shortHash(_webfWidget);

    // Should schedule to the next frame to make sure the RenderViewportBox(WebF's root renderObject) had been layout.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // Sync viewport size to the documentElement.
      controller.view.document.initializeRootElementSize();
    });
  }

  @override
  _WebFRenderObjectElement createElement() {
    return _WebFRenderObjectElement(this);
  }
}

class _WebFRenderObjectElement extends MultiChildRenderObjectElement {
  _WebFRenderObjectElement(WebFRootRenderObjectWidget widget) : super(widget);

  WebFController? controller;

  @override
  void unmount() {
    super.unmount();
    if (controller?.externalController == true) {
      controller?.pause();
    } else {
      controller?.dispose();
    }
    controller = null;
  }

  @override
  void mount(Element? parent, Object? newSlot) async {
    super.mount(parent, newSlot);
    assert(parent is WebFContextInheritElement);
    assert(this.controller != null);
    WebFController controller = this.controller!;
    (parent as WebFContextInheritElement).controller = controller;

    if (controller.entrypoint == null) {
      throw FlutterError('Consider providing a WebFBundle resource as the entry point for WebF');
    }

    if (controller.mode == WebFLoadingMode.standard && controller.mountedAndEvaluated && controller.entrypointChanged) {
      await controller.unload();
    }

    RenderViewportBox rootRenderObject = renderObject as RenderViewportBox;
    if (!controller.view.firstLoad) {
      rootRenderObject.insert(controller.view.getRootRenderObject()!);
      controller.resume();
    }

    // Sync element state.
    flushUICommand(controller.view);

    // Should schedule to the next frame to make sure the RenderViewportBox(WebF's root renderObject) had been layout.
    try {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (controller.mountedAndEvaluated) {
          return;
        }
        // Sync viewport size to the documentElement.
        controller.view.document.initializeRootElementSize();
        // Starting to flush ui commands every frames.
        controller.view.flushPendingCommandsPerFrame();

        // Bundle could be executed before mount to the flutter tree.
        if (controller.mode == WebFLoadingMode.standard) {
          await controller.executeEntrypoint(animationController: widget._webfWidget.animationController);
        } else if (controller.mode == WebFLoadingMode.preloading) {
          assert(controller.entrypoint!.isResolved);
          // Mount when preloading not complete
          if (controller.preloadStatus != PreloadingStatus.done) {
            await controller.preloadCompleter.future;
          }

          assert(controller.entrypoint!.isDataObtained);
          if (controller.view.document.unfinishedPreloadResources == 0 && controller.entrypoint!.isHTML) {
            List<VoidCallback> pendingScriptCallbacks = controller.view.document.pendingPreloadingScriptCallbacks;
            for (int i = 0; i < pendingScriptCallbacks.length; i ++) {
              pendingScriptCallbacks[i]();
            }
          } else if (controller.entrypoint!.isJavascript || controller.entrypoint!.isBytecode) {
            await controller.evaluateEntrypoint();
          }
        } else if (controller.mode == WebFLoadingMode.preRendering) {
          // Mount when preloading not complete
          if (controller.preRenderingStatus != PreRenderingStatus.done) {
            await controller.preRenderingCompleter.future;
          }

          controller.module.resumeAnimationFrame();

          HTMLElement rootElement = controller.view.document.documentElement as HTMLElement;
          rootElement.flushPendingStylePropertiesForWholeTree();

          controller.view.resumeAnimationTimeline();

          controller.dispatchDOMContentLoadedEvent();
          controller.dispatchWindowLoadEvent();
        }

        controller.mountedAndEvaluated = true;
      });
    } catch (e, s) {
      print(s);
    }
  }

  // RenderObjects created by webf are manager by webf itself. There are no needs to operate renderObjects on _WebFRenderObjectElement.
  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {}

  @override
  void moveRenderObjectChild(RenderObject child, Object? oldSlot, Object? newSlot) {}

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {}

  @override
  WebFRootRenderObjectWidget get widget => super.widget as WebFRootRenderObjectWidget;
}
