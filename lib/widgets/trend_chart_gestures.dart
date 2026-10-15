import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// 차트 안에서는 모든 방향의 드래그와 핀치를 우선합니다.
/// 페이지 스크롤은 차트 바깥에서 시작합니다.
class TrendChartGestures extends StatelessWidget {
  final Widget child;
  final GestureScaleStartCallback onStart;
  final GestureScaleUpdateCallback onUpdate;
  final ValueChanged<Offset> onSelect;
  final VoidCallback onEnd;
  final VoidCallback? onDoubleTap;
  final ValueChanged<double> onScroll;

  const TrendChartGestures({
    super.key,
    required this.child,
    required this.onStart,
    required this.onUpdate,
    required this.onSelect,
    required this.onEnd,
    this.onDoubleTap,
    required this.onScroll,
  });

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerSignal: (event) {
      if (event is PointerScrollEvent &&
          event.scrollDelta.dy.isFinite &&
          event.scrollDelta.dy != 0) {
        // 부모 페이지가 동시에 스크롤되지 않도록 이 패널이 휠 이벤트를 처리합니다.
        GestureBinding.instance.pointerSignalResolver.register(event, (_) {
          onScroll(event.scrollDelta.dy);
        });
      }
    },
    child: RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        _ChartScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_ChartScaleGestureRecognizer>(
              () => _ChartScaleGestureRecognizer(debugOwner: this),
              (recognizer) =>
                  recognizer
                    ..gestureSettings = MediaQuery.gestureSettingsOf(context)
                    ..dragStartBehavior = DragStartBehavior.start
                    ..onStart = onStart
                    ..onUpdate = onUpdate
                    ..onEnd = (_) => onEnd(),
            ),
        if (onDoubleTap != null)
          DoubleTapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
                () => DoubleTapGestureRecognizer(debugOwner: this),
                (recognizer) =>
                    recognizer
                      ..gestureSettings = MediaQuery.gestureSettingsOf(context)
                      ..onDoubleTap = onDoubleTap,
              ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(debugOwner: this),
              (recognizer) =>
                  recognizer
                    ..gestureSettings = MediaQuery.gestureSettingsOf(context)
                    ..onTapUp = (details) => onSelect(details.localPosition),
            ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(debugOwner: this),
              (recognizer) {
                recognizer
                  ..gestureSettings = MediaQuery.gestureSettingsOf(context)
                  ..onLongPressStart = (details) {
                    onSelect(details.localPosition);
                  }
                  ..onLongPressMoveUpdate = (details) {
                    onSelect(details.localPosition);
                  };
              },
            ),
      },
      child: child,
    ),
  );
}

// 한 손가락은 이동 허용 오차를 넘을 때, 두 손가락은 두 번째 터치 때
// 차트가 제스처를 소유합니다. 핀치 전의 평행 이동이 페이지 스크롤로
// 인식되지 않도록 하되, 한 손가락 탭과 길게 누르기는 유지합니다.
class _ChartScaleGestureRecognizer extends ScaleGestureRecognizer {
  _ChartScaleGestureRecognizer({super.debugOwner});
  final _origins = <int, Offset>{};
  bool _accepted = false;
  @override
  void addAllowedPointer(PointerDownEvent event) {
    _origins[event.pointer] = event.localPosition;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_accepted && _origins.length == 1 && event is PointerMoveEvent) {
      final origin = _origins[event.pointer];
      if (origin != null &&
          (event.localPosition - origin).distance >
              computeHitSlop(event.kind, gestureSettings)) {
        resolve(GestureDisposition.accepted);
      }
    }
    super.handleEvent(event);
    // super가 두 번째 포인터 위치와 중심점을 갱신한 뒤 수락합니다.
    // 이미 드래그 중에 추가된 포인터도 부모 Scrollable에 넘기지 않습니다.
    if (event is PointerDownEvent && (_origins.length >= 2 || _accepted)) {
      resolve(GestureDisposition.accepted);
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _origins.remove(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
    super.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    _origins.remove(pointer);
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    super.didStopTrackingLastPointer(pointer);
    _origins.clear();
    _accepted = false;
  }
}
