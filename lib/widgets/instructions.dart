import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget that explains how to add songs to Spartial
class HowToAddSongsInstruction extends StatefulWidget {
  // Whether the "Looks like you haven't added any songs yet" and "Enjoy!" remarks are shown.
  final bool showRemark;
  const HowToAddSongsInstruction({Key? key, this.showRemark = true})
      : super(key: key);

  @override
  _HowToAddSongsInstructionState createState() =>
      _HowToAddSongsInstructionState();
}

class _HowToAddSongsInstructionState extends State<HowToAddSongsInstruction> {
  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.showRemark
              ? Column(
                  children: [
                    Text(
                      "Looks like you haven't added any songs yet",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headline2,
                    ),
                    SizedBox(
                      height: 60.h,
                    ),
                    Text(
                      "Adding songs to Spartial is really easy, you just share the song from Spotify to Spartial. You can do this by clicking the following buttons in Spotify.",
                      style: Theme.of(context).textTheme.subtitle1,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 120.h,
                    ),
                  ],
                )
              : const SizedBox(),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Share button remake.
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 100.w,
                    width: 100.w,
                    child: Icon(
                      Icons.share_outlined,
                      size: 100.w,
                      color: Theme.of(context).highlightColor.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(
                    height: 20.w,
                  ),
                  Text(
                    "Share",
                    style: TextStyle(
                        color: Theme.of(context).highlightColor,
                        fontSize: 30.sp,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
              Icon(
                Icons.arrow_right_outlined,
                color: Theme.of(context).highlightColor.withOpacity(0.5),
              ),
              // More button remake
              Padding(
                padding: EdgeInsets.all(24.sp),
                child: Column(
                  children: [
                    Container(
                      height: 100.w,
                      width: 100.w,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).highlightColor),
                      child: Icon(
                        Icons.more_horiz_sharp,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    SizedBox(
                      height: 15.h,
                    ),
                    Text(
                      "More",
                      style: TextStyle(
                          color: Theme.of(context).highlightColor,
                          fontSize: 30.sp,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              Icon(
                Icons.arrow_right_outlined,
                color: Theme.of(context).highlightColor.withOpacity(0.5),
              ),
              Padding(
                  padding: EdgeInsets.all(24.sp),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/icon/icon2.png',
                        height: 100.w,
                        width: 100.w,
                      ),
                      SizedBox(
                        height: 15.h,
                      ),
                      Text(
                        "Spartial",
                        style: TextStyle(
                            color: Theme.of(context).highlightColor,
                            fontSize: 30.sp,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  )),
            ],
          ),
          SizedBox(
            height: widget.showRemark ? 120.h : 0,
          ),
          widget.showRemark
              ? Text(
                  "Enjoy!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.subtitle1,
                )
              : const SizedBox(),
        ]);
  }
}
