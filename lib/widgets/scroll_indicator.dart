import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:spartial/widgets/loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom scroll indicator that is shown when pulling down on the songs screen.
class CustomScrollIndicator extends StatefulWidget {
  final Widget child;
  final Function onRefresh;
  const CustomScrollIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _CustomScrollIndicatorState createState() => _CustomScrollIndicatorState();
}

class _CustomScrollIndicatorState extends State<CustomScrollIndicator>
    with SingleTickerProviderStateMixin {
  static final double _indicatorSize = 90.sp;
  final _helper = IndicatorStateHelper();

  ScrollDirection prevScrollDirection = ScrollDirection.idle;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      offsetToArmed: _indicatorSize,
      onRefresh: () async {
        await widget.onRefresh();
      },
      child: widget.child,
      completeStateDuration: null,
      builder: (
        BuildContext context,
        Widget child,
        IndicatorController controller,
      ) {
        return Stack(
          children: <Widget>[
            AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, Widget? _) {
                _helper.update(controller.state);

                if (controller.scrollingDirection == ScrollDirection.reverse &&
                    prevScrollDirection == ScrollDirection.forward) {
                  try {
                    controller.stopDrag();
                  } on StateError {}
                }

                prevScrollDirection = controller.scrollingDirection;

                final containerHeight = controller.value * _indicatorSize;

                return !(_helper.isLoading || _helper.isArmed)
                    ? const SizedBox()
                    : Container(
                        alignment: Alignment.center,
                        height: containerHeight * 2,
                        child: OverflowBox(
                          maxHeight: 40,
                          minHeight: 40,
                          maxWidth: 40,
                          minWidth: 40,
                          alignment: Alignment.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            alignment: Alignment.center,
                            child: CustomLoadingIndicator(
                              size: _indicatorSize,
                            ),
                          ),
                        ),
                      );
              },
            ),
            AnimatedBuilder(
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0.0, controller.value * _indicatorSize * 2),
                  child: child,
                );
              },
              animation: controller,
            ),
          ],
        );
      },
    );
  }
}
