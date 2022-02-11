import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom button for inside the context menu.
class ContextMenuButton extends StatefulWidget {
  final Function onPressed;
  final Widget icon;
  final String text;
  const ContextMenuButton(
      {Key? key,
      required this.onPressed,
      required this.icon,
      required this.text})
      : super(key: key);

  @override
  _ContextMenuButtonState createState() => _ContextMenuButtonState();
}

class _ContextMenuButtonState extends State<ContextMenuButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        widget.onPressed();
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            widget.icon,
            SizedBox(
              width: 30.w,
            ),
            Text(
              widget.text,
              style: Theme.of(context).textTheme.headline3,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom solid textbutton with rounded corners.
class SolidRoundedButton extends StatefulWidget {
  final void Function()? onPressed;
  final Color? backGroundColor;
  final String text;
  final bool lineThrough;
  final bool showSpotifyIcon;
  const SolidRoundedButton(
      {Key? key,
      required this.onPressed,
      required this.text,
      this.backGroundColor,
      this.lineThrough = false,
      this.showSpotifyIcon = false})
      : super(key: key);

  @override
  _SolidRoundedButtonState createState() => _SolidRoundedButtonState();
}

class _SolidRoundedButtonState extends State<SolidRoundedButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: widget.onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.showSpotifyIcon
                ? Row(
                    children: [
                      Image.asset(
                        "assets/spotify/Spotify_Icon_RGB_Black.png",
                        height: 60.sp,
                        width: 60.sp,
                      ),
                      SizedBox(
                        width: 20.w,
                      )
                    ],
                  )
                : const SizedBox(),
            Text(
              widget.text,
              style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  decoration: widget.lineThrough
                      ? TextDecoration.lineThrough
                      : TextDecoration.none),
            ),
          ],
        ),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                widget.backGroundColor ?? Theme.of(context).highlightColor),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(
                        color: widget.backGroundColor ??
                            Theme.of(context).highlightColor)))));
  }
}
