import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

// THIS FILE IS A MODIFIED VERSION OF https://pub.dev/packages/flutter_multi_slider source code
// I HAD TO MODIFY IT BECAUSE IT DIDN'T HAVE ALL FUNCTIONALITY THAT I NEEDED.
// I added things like:
// - Times at the start and end of slider
// - Different color for selected and unselected sliders.

/// Used in [ValueRangePainterCallback] as parameter.
/// Every range between the edges of [MultiSlider] generate an [ValueRange].
/// Do NOT be mistaken with discrete intervals made by [divisions]!
class ValueRange {
  const ValueRange(
    this.start,
    this.end,
    this.index,
    this.isFirst,
    this.isLast,
  );

  final double start;
  final double end;
  final int index;
  final bool isFirst;
  final bool isLast;

  bool contains(double x) => x >= start && x <= end;
}

typedef ValueRangePainterCallback = bool Function(dynamic valueRange);

bool defaultValueRangePainterCallback(rangeOrIndex) {
  if (rangeOrIndex.runtimeType == ValueRange) {
    return rangeOrIndex.index % 2 == 1;
  } else if (rangeOrIndex.runtimeType == int) {
    return rangeOrIndex % 2 == 1;
  } else {
    return false;
  }
}

class MultiSlider extends StatefulWidget {
  MultiSlider({
    required this.values,
    required this.onChanged,
    this.max = 1,
    this.min = 0,
    this.labelDisplacement = 10,
    this.onChangeStart,
    this.onChangeEnd,
    this.color,
    this.horizontalPadding = 26.0,
    this.height = 45,
    this.divisions,
    this.valueRangePainterCallback = defaultValueRangePainterCallback,
    this.showStartAndEndTime = true,
    this.thumbThickness = 10,
    this.paintLineCenter = false,
    this.lastSelectedInputIndex,
    this.lastSelectedInputIndexChangedCallback,
    Key? key,
  })  : assert(divisions == null || divisions > 0),
        assert(max - min >= 0),
        range = max - min,
        super(key: key) {
    final valuesCopy = [...values]..sort();

    for (int index = 0; index < valuesCopy.length; index++) {
      assert(
        valuesCopy[index] == values[index],
        'MultiSlider: values must be in ascending order!',
      );
    }
    assert(
      values.first >= min && values.last <= max,
      'MultiSlider: At least one value is outside of min/max boundaries!',
    );
  }

  // Added functionallity
  final double thumbThickness;
  final bool paintLineCenter;
  final bool showStartAndEndTime;
  int? lastSelectedInputIndex;
  final Function? lastSelectedInputIndexChangedCallback;
  final int labelDisplacement;

  /// [MultiSlider] maximum value.
  final double max;

  /// [MultiSlider] minimum value.
  final double min;

  /// Difference between [max] and [min]. Must be positive!
  final double range;

  /// [MultiSlider] vertical dimension. Used by [GestureDetector] and [CustomPainter].
  final double height;

  /// Empty space between the [MultiSlider] bar and the end of [GestureDetector] zone.
  final double horizontalPadding;

  /// Bar and indicators active color.
  final Color? color;

  /// List of ordered values which will be changed by user gestures with this widget.
  final List<double> values;

  /// Callback for every user slide gesture.
  final ValueChanged<List<double>>? onChanged;

  /// Callback for every time user click on this widget.
  final ValueChanged<List<double>>? onChangeStart;

  /// Callback for every time user stop click/slide on this widget.
  final ValueChanged<List<double>>? onChangeEnd;

  /// Number of divisions for discrete Slider.
  final int? divisions;

  /// Used to decide how a line between values or the boundaries should be painted.
  /// Returns [bool] and pass an [dynamic] object as parameter.
  final ValueRangePainterCallback? valueRangePainterCallback;

  @override
  _MultiSliderState createState() => _MultiSliderState();
}

class _MultiSliderState extends State<MultiSlider> {
  double? _maxWidth;
  int? _selectedInputIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sliderTheme = SliderTheme.of(context);
    final bool isDisabled = widget.onChanged == null || widget.range == 0;
    //_lastSelectedInputIndex = widget.lastSelectedInputIndex;
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        _maxWidth = constraints.maxWidth;
        return GestureDetector(
          child: Container(
            constraints: constraints,
            width: double.infinity,
            height: widget.height,
            child: CustomPaint(
              painter: _MultiSliderPainter(
                valueRangePainterCallback: widget.valueRangePainterCallback ??
                    _defaultDivisionPainterCallback,
                divisions: widget.divisions,
                isDisabled: isDisabled,
                labelDisplacement: widget.labelDisplacement,
                showStartAndEndTime: widget.showStartAndEndTime,
                activeTrackColor: widget.color ??
                    sliderTheme.activeTrackColor ??
                    theme.colorScheme.primary,
                inactiveTrackColor: widget.color?.withOpacity(0.24) ??
                    sliderTheme.inactiveTrackColor ??
                    theme.colorScheme.primary.withOpacity(0.24),
                disabledActiveTrackColor:
                    sliderTheme.disabledActiveTrackColor ??
                        theme.colorScheme.onSurface.withOpacity(0.40),
                disabledInactiveTrackColor:
                    sliderTheme.disabledInactiveTrackColor ??
                        theme.colorScheme.onSurface.withOpacity(0.12),
                selectedInputIndex: _selectedInputIndex,
                lastSelectedInputIndex: widget.lastSelectedInputIndex ?? 0,
                max: widget.max,
                nonPixelPositionValues: widget.values,
                values:
                    widget.values.map(_convertValueToPixelPosition).toList(),
                horizontalPadding: widget.horizontalPadding,
                thumbThickness: widget.thumbThickness,
                paintLineCenter: widget.paintLineCenter,
              ),
            ),
          ),
          onPanStart: isDisabled ? null : _handleOnChangeStart,
          onPanUpdate: isDisabled ? null : _handleOnChanged,
          onPanEnd: isDisabled ? null : _handleOnChangeEnd,
        );
      },
    );
  }

  void _setSelectedInputIndex(int? index) {
    _selectedInputIndex = index;
    if (index != null) {
      widget.lastSelectedInputIndex = index;
      if (widget.lastSelectedInputIndexChangedCallback != null) {
        widget.lastSelectedInputIndexChangedCallback!(index);
      }
    }
  }

  void _handleOnChangeStart(DragStartDetails details) {
    double valuePosition = _convertPixelPositionToValue(
      details.localPosition.dx,
    );

    int index = _findNearestValueIndex(valuePosition);

    setState(() => _setSelectedInputIndex(index));

    final updatedValues = updateInternalValues(details.localPosition.dx);
    widget.onChanged!(updatedValues);
    if (widget.onChangeStart != null) widget.onChangeStart!(updatedValues);
  }

  void _handleOnChanged(DragUpdateDetails details) {
    widget.onChanged!(updateInternalValues(details.localPosition.dx));
  }

  void _handleOnChangeEnd(DragEndDetails details) {
    setState(() => _setSelectedInputIndex(null));

    if (widget.onChangeEnd != null) widget.onChangeEnd!(widget.values);
  }

  double _convertValueToPixelPosition(double value) {
    return (value - widget.min) *
            (_maxWidth! - 2 * widget.horizontalPadding) /
            (widget.range) +
        widget.horizontalPadding;
  }

  double _convertPixelPositionToValue(double pixelPosition) {
    final value = (pixelPosition - widget.horizontalPadding) *
            (widget.range) /
            (_maxWidth! - 2 * widget.horizontalPadding) +
        widget.min;

    return value;
  }

  List<double> updateInternalValues(double xPosition) {
    if (_selectedInputIndex == null) return widget.values;

    List<double> copiedValues = [...widget.values];

    double convertedPosition = _convertPixelPositionToValue(xPosition);

    copiedValues[_selectedInputIndex!] = convertedPosition.clamp(
      _calculateInnerBound(),
      _calculateOuterBound(),
    );

    if (widget.divisions != null) {
      return copiedValues
          .map<double>(
            (value) => _getDiscreteValue(
              value,
              widget.min,
              widget.max,
              widget.divisions!,
            ),
          )
          .toList();
    }
    return copiedValues;
  }

  double _calculateInnerBound() {
    return _selectedInputIndex == 0
        ? widget.min
        : widget.values[_selectedInputIndex! - 1];
  }

  double _calculateOuterBound() {
    return _selectedInputIndex == widget.values.length - 1
        ? widget.max
        : widget.values[_selectedInputIndex! + 1];
  }

  int _findNearestValueIndex(double convertedPosition) {
    if (widget.values.length == 1) return 0;

    List<double> differences = widget.values
        .map<double>((double value) => (value - convertedPosition).abs())
        .toList();
    double minDifference = differences.reduce(
      (previousValue, value) => value < previousValue ? value : previousValue,
    );

    int minDifferenceFirstIndex = differences.indexOf(minDifference);
    int minDifferenceLastIndex = differences.lastIndexOf(minDifference);

    bool hasCollision = minDifferenceLastIndex != minDifferenceFirstIndex;

    if (hasCollision &&
        (convertedPosition > widget.values[minDifferenceFirstIndex])) {
      return minDifferenceLastIndex;
    }
    return minDifferenceFirstIndex;
  }

  bool _defaultDivisionPainterCallback(dynamic division) =>
      !division.isFirst && !division.isLast;
}

class _MultiSliderPainter extends CustomPainter {
  final double thumbThickness;
  final bool paintLineCenter;
  final bool showStartAndEndTime;
  final List<double> values;
  final List<double> nonPixelPositionValues;
  final int? selectedInputIndex;
  final double horizontalPadding;
  final Paint activeTrackColorPaint;
  final Paint bigCircleColorPaint;
  final Paint inactiveTrackColorPaint;
  final Paint lastSelectedColorPaint;
  final int labelDisplacement;
  final int? divisions;
  int lastSelectedInputIndex = 0;
  final double max;
  final ValueRangePainterCallback valueRangePainterCallback;

  _MultiSliderPainter({
    required bool isDisabled,
    required Color activeTrackColor,
    required Color inactiveTrackColor,
    required Color disabledActiveTrackColor,
    required Color disabledInactiveTrackColor,
    required this.labelDisplacement,
    required this.values,
    required this.nonPixelPositionValues,
    required this.selectedInputIndex,
    required this.horizontalPadding,
    required this.divisions,
    required this.valueRangePainterCallback,
    required this.thumbThickness,
    required this.paintLineCenter,
    required this.showStartAndEndTime,
    required this.lastSelectedInputIndex,
    required this.max,
  })  : activeTrackColorPaint = _paintFromColor(
          isDisabled
              ? disabledActiveTrackColor
              : activeTrackColor.withOpacity(0.50),
          true,
        ),
        inactiveTrackColorPaint = _paintFromColor(
          isDisabled ? disabledInactiveTrackColor : inactiveTrackColor,
        ),
        bigCircleColorPaint = _paintFromColor(
          activeTrackColor.withOpacity(0.20),
        ),
        lastSelectedColorPaint = _paintFromColor(
          isDisabled ? disabledActiveTrackColor : activeTrackColor,
        );

  @override
  void paint(Canvas canvas, Size size) {
    final double halfHeight = size.height / 2;
    final canvasStart = horizontalPadding;
    final canvasEnd = size.width - horizontalPadding;
    List<ValueRange> _makeRanges(
      List<double> innerValues,
      double start,
      double end,
    ) {
      final values = <double>[
        start,
        ...innerValues
            .map<double>(divisions == null
                ? (v) => v
                : (v) => _getDiscreteValue(v, start, end, divisions!))
            .toList(),
        end
      ];
      return List<ValueRange>.generate(
        values.length - 1,
        (index) => ValueRange(
          values[index],
          values[index + 1],
          index,
          index == 0,
          index == values.length - 2,
        ),
      );
    }

    final valueRanges = _makeRanges(values, canvasStart, canvasEnd);

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(valueRanges.first.start, halfHeight),
        radius: valueRangePainterCallback(valueRanges.first) ? 3 : 2,
      ),
      math.pi / 2,
      math.pi,
      true,
      valueRangePainterCallback(valueRanges.first)
          ? activeTrackColorPaint
          : inactiveTrackColorPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(valueRanges.last.end, halfHeight),
        radius: valueRangePainterCallback(valueRanges.last) ? 3 : 2,
      ),
      -math.pi / 2,
      math.pi,
      true,
      valueRangePainterCallback(valueRanges.last)
          ? activeTrackColorPaint
          : inactiveTrackColorPaint,
    );

    // Calculate which slider index is part of the same slider as the currently selected knob.
    late int otherlastSelectedSliderIndex;
    if (valueRangePainterCallback(valueRanges[lastSelectedInputIndex])) {
      // i is the first one of a range.
      otherlastSelectedSliderIndex = lastSelectedInputIndex - 1;
    } else {
      // i is the second one of the range.
      otherlastSelectedSliderIndex = lastSelectedInputIndex + 1;
    }

    // Draw the lines between two knobs.
    for (ValueRange valueRange in valueRanges) {
      canvas.drawLine(
        Offset(valueRange.start, halfHeight),
        Offset(valueRange.end, halfHeight),
        valueRangePainterCallback(valueRange)
            ? (valueRange.index == lastSelectedInputIndex ||
                    valueRange.index == otherlastSelectedSliderIndex)
                ? lastSelectedColorPaint
                : activeTrackColorPaint
            : inactiveTrackColorPaint,
      );
    }

    if (divisions != null) {
      final divisionsList = List<double>.generate(
          divisions! + 1,
          (index) =>
              canvasStart + index * (canvasEnd - canvasStart) / divisions!);

      if (paintLineCenter) {
        for (double x in divisionsList) {
          final valueRange = valueRanges.firstWhere(
            (valueRange) => valueRange.contains(x),
          );

          canvas.drawCircle(
            Offset(x, halfHeight),
            1,
            _paintFromColor(valueRangePainterCallback(valueRange)
                ? Colors.white.withOpacity(0.5)
                : activeTrackColorPaint.color.withOpacity(0.5)),
          );
        }
      }
    }

    final _textPainter = TextPainter(textDirection: TextDirection.ltr);
    // Draw the start and end time of the timeline if showStartAndEndTime == true.
    if (showStartAndEndTime) {
      // Paint "0:00" at the start of the slider.

      _textPainter.text = TextSpan(
          text: "0:00",
          style: TextStyle(color: activeTrackColorPaint.color, fontSize: 10));
      _textPainter.layout(
        minWidth: 0,
        maxWidth: double.maxFinite,
      );
      _textPainter.paint(
          canvas, Offset(-10 + horizontalPadding, halfHeight - 20));
      // Paint the lenght of the song at the end of the slider.

      int secs = max.toInt();
      final int mins = (secs / 60).floor();
      secs -= mins * 60;
      String secsString =
          secs.toString().length == 1 ? "0" + secs.toString() : secs.toString();

      _textPainter.text = TextSpan(
          text: "$mins:$secsString",
          style: TextStyle(color: activeTrackColorPaint.color, fontSize: 10));
      _textPainter.layout(
        minWidth: 0,
        maxWidth: double.maxFinite,
      );
      _textPainter.paint(
          canvas, Offset(size.width - 10 - horizontalPadding, halfHeight - 20));
    }

    for (int i = 0; i < values.length; i++) {
      double x = divisions == null
          ? values[i]
          : _getDiscreteValue(values[i], canvasStart, canvasEnd, divisions!);

      canvas.drawCircle(
        Offset(x, halfHeight),
        thumbThickness,
        _paintFromColor(Colors.grey),
      );

      // Draw the slider knobs
      canvas.drawCircle(
        Offset(x, halfHeight),
        thumbThickness,
        // Give the last selected slider a different color.
        (lastSelectedInputIndex == i || i == otherlastSelectedSliderIndex)
            ? lastSelectedColorPaint
            : activeTrackColorPaint,
      );

      // Add text to the slider knobs
      int secs = nonPixelPositionValues[i].floor();
      final int mins = (secs / 60).floor();
      secs -= mins * 60;
      String secsString =
          secs.toString().length == 1 ? "0" + secs.toString() : secs.toString();

      _textPainter.text = TextSpan(
          text: "$mins:$secsString",
          style: TextStyle(
              color: (lastSelectedInputIndex == i ||
                      i == otherlastSelectedSliderIndex)
                  ? lastSelectedColorPaint.color
                  : activeTrackColorPaint.color,
              fontSize: 10));
      _textPainter.layout(
        minWidth: 0,
        maxWidth: double.maxFinite,
      );
      _textPainter.paint(
          canvas, Offset(x - 10, halfHeight + labelDisplacement));

      // Draw the drag shadow
      if (selectedInputIndex == i) {
        canvas.drawCircle(
          Offset(x, halfHeight),
          10,
          bigCircleColorPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  static Paint _paintFromColor(Color color, [bool active = false]) {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..strokeWidth = active ? 2 : 2
      ..isAntiAlias = true;
  }
}

double _getDiscreteValue(
  double value,
  double start,
  double end,
  int divisions,
) {
  final k = (end - start) / divisions;
  return start + ((value - start) / k).roundToDouble() * k;
}
