import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:spartial/objects/song.dart';
import 'package:spartial/screens/loading.dart';
import 'package:spartial/screens/reauthenticate.dart';
import 'package:spartial/services/spotify.dart';
import 'package:spartial/services/storage.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:spartial/widgets/multi_slider.dart';
import 'package:spartial/wrappers/navigation_wrapper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oauth2/src/authorization_exception.dart';

/// Screen on which:
/// - songs can be added to Spartial.
/// - The time ranges of stored songs can be changed.
class AddSongScreen extends StatefulWidget {
  /// The id of the track to pass to the spotify web api.
  final String trackID;

  /// The initials song, Is null when adding a new song. Is not null when editing.
  final Song? initialSong;

  /// Whether or not a allready stored song has been shared to Spartial.
  final bool sharedStoredSong;
  const AddSongScreen(
      {Key? key,
      required this.trackID,
      this.initialSong,
      this.sharedStoredSong = false})
      : super(key: key);

  @override
  _AddSongScreenState createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  /// Maximum number of time ranges per song.
  final int maxNumberOfTimeRanges = 10;

  /// Minimal number of seconds between two slider ends
  /// in order for a new slider to fit in between.
  final int minNumberOfFreeSeconds = 10;

  /// Wether the song cover overlay should be shown when sliding.
  final bool showOverlay = true;

  /// List of current slider values.
  List<int> sliderValues = [];

  /// Text shown as an overlay ontop of the song cover when sliding.
  String coverOverlayText = "0:00";

  /// Whether the overlay is currently visible.
  bool coverOverlayIsVisible = false;

  /// Whether the overlay is currently fading in/out.
  bool isAnimating = false;

  /// The index (in sliderValues) of the slider knob that was last selected.
  int lastSelectedSliderInputIndex = 0;

  /// Status of authentication. (This decides which screen is shown)
  /// - 'processing' := Still checking credentials/getting song data.
  /// - 'success' := Successfully got the song data from the web api.
  /// - 'failed' := Song data could not be retrieved (most likely because of no internet).
  String authenticationStatus = 'processing';

  /// The currently edited/added song.
  Song? song;

  /// The slider.
  late MultiSlider slider;

  /// Whether or not a time range can be added.
  bool canAddTimeRange() {
    // Only allow adding sliders when there is more than 10 seconds of free space.
    // And there are less than maxNumberOfTimeRanges time ranges.
    return (getBiggestSliderGap()[1] > minNumberOfFreeSeconds &&
        sliderValues.length < maxNumberOfTimeRanges);
  }

  /// Whether or not a time range can be removed.
  bool canRemoveTimeRange() {
    // Only allow removing time ranges when there are more than 2.
    return (sliderValues.length > 2);
  }

  /// Shows the cover image overaly.
  void showCoverOverlay() async {
    isAnimating = true;
    setState(() {
      coverOverlayIsVisible = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    // Check if the user hasn't quickly navigated to another page.
    if (mounted) {
      setState(() {
        coverOverlayIsVisible = false;
      });
    }
    isAnimating = false;
  }

  /// Creates the slider.
  void generateSlider() {
    // Generate the initial slider values if there aren't any.
    if (sliderValues.isEmpty) {
      var initialSliderStartTime = (song!.durationSeconds * 1 / 6).floor();
      var initialSliderEndTime = (song!.durationSeconds * 5 / 6).floor();
      sliderValues = [initialSliderStartTime, initialSliderEndTime];
    }
    // Create the slider instance.
    slider = MultiSlider(
      values: List<double>.from(((sliderValues).map((e) => e.toDouble()))),
      onChanged: (values) {
        setState(() {
          // Set the slidervalues to the new values.
          sliderValues = List<int>.from(((values).map((e) => e.floor())));
          // Generate the Text to put ontop of the cover image.
          int secs = (values[lastSelectedSliderInputIndex]).floor();
          final int mins = (secs / 60).floor();
          secs -= mins * 60;
          String secsString = secs.toString().length == 1
              ? "0" + secs.toString()
              : secs.toString();
          coverOverlayText = "$mins:$secsString";
        });
        // Show the cover image overlay.
        if (!isAnimating) {
          if (showOverlay) {
            showCoverOverlay();
          }
        }
      },
      divisions: song!.durationSeconds,
      min: 0,
      max: (song!.durationSeconds).toDouble(),
      height: 120.sp,
      thumbThickness: 18.sp,
      horizontalPadding: 40.sp,
      lastSelectedInputIndex: lastSelectedSliderInputIndex,
      lastSelectedInputIndexChangedCallback: (int value) {
        lastSelectedSliderInputIndex = value;
      },
    );
  }

  /// Calculates the index (in sliderValues)
  /// of the where a new slider pair must be inserted and the space available there.
  /// Returns List<int>[index, space].
  List<int> getBiggestSliderGap() {
    int biggest = 0;
    int biggestIndex = 8;
    List<int> sliderValuesWithStartAndEnd =
        [0] + sliderValues + [song!.durationSeconds];
    for (int i = 0; i < sliderValuesWithStartAndEnd.length; i++) {
      if (i % 2 == 0) {
        int space =
            sliderValuesWithStartAndEnd[i + 1] - sliderValuesWithStartAndEnd[i];
        if (space >= biggest) {
          biggest = space;
          biggestIndex = i;
        }
      }
    }
    return [biggestIndex, biggest];
  }

  /// Adds a new pair or slider knobs to the mutliSlider if possible.
  void addSliderToMultiSlider() {
    /// Get info about where to insert the slider.
    List biggestSliderGapInfo = getBiggestSliderGap();
    int insertIndex = biggestSliderGapInfo[0];
    int insertSpace = biggestSliderGapInfo[1];

    // Check if a time range can be added.
    if (canAddTimeRange()) {
      setState(() {
        // Let the newly added slider be the selected slider.
        lastSelectedSliderInputIndex = insertIndex;
        sliderValues.insertAll(
            insertIndex,
            insertIndex == 0
                ? [0, (insertSpace * (4 / 5)).floor()]
                : [
                    (sliderValues[insertIndex - 1] + insertSpace * (1 / 5))
                        .floor(),
                    (sliderValues[insertIndex - 1] + insertSpace * (4 / 5))
                        .floor(),
                  ]);
      });
    }
  }

  /// Removes the currently selected slider from the multiSlider if possible.
  void removeSliderFromMultiSlider() {
    // Check if there is a slider that can be removed.
    if (canRemoveTimeRange()) {
      setState(() {
        // Decide which indices to remove from sliderValues
        // based on the index of the last selected slider.
        if (slider.valueRangePainterCallback!(lastSelectedSliderInputIndex)) {
          sliderValues.removeAt(lastSelectedSliderInputIndex);
          sliderValues.removeAt(lastSelectedSliderInputIndex - 1);
        } else {
          sliderValues.removeAt(lastSelectedSliderInputIndex);
          sliderValues.removeAt(lastSelectedSliderInputIndex);
        }
        lastSelectedSliderInputIndex = 0;
      });
    }
  }

  /// Gets data about the song from the Spotify web api.
  void getSong() async {
    try {
      song = await SpotifyWebApi.getSong(widget.trackID);
      setState(() {
        authenticationStatus = 'success';
      });
      // Handle no internet connection.
    } on SocketException {
      setState(() {
        authenticationStatus = 'failed';
      });
      // Handle expired token.
    } on AuthorizationException {
      Storage.deleteSpotifyCredentials();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ReauthenticatePage()));
    }
  }

  @override
  void initState() {
    super.initState();
    // Get the song if no initial song has been provided.
    if (widget.initialSong == null) {
      getSong();
    } else {
      // Set the song to the initial song.
      song = widget.initialSong;
      // & Change the slider values accordingly.
      sliderValues = song!.timeRanges;
      authenticationStatus = 'success';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen when waiting for authentication.
    if (authenticationStatus == 'processing') {
      return const LoadingScreen();
      // Show the song add screen when the authentication was successfull.
    } else if (authenticationStatus == 'success') {
      generateSlider();
      // Change the funtionallity of the divices back button
      // based on whether we're editing or adding a song.
      return WillPopScope(
        onWillPop: () async {
          if (widget.initialSong != null) {
            if (widget.sharedStoredSong) {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              return false;
            } else {
              return true;
            }
          } else {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            return false;
          }
        },
        child: SafeArea(
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.fromLTRB(100.w, 0, 100.w, 0),
              child: Column(
                children: [
                  // Back button.
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      IconButton(
                        highlightColor: Theme.of(context).scaffoldBackgroundColor,
                        onPressed: () {
                          Navigator.pop(context);
                        }, 
                        icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).highlightColor,)
                      ),
                    ],
                  ),
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/spotify/Spotify_Logo_RGB_White.png",
                            height: 70.sp,
                          ),
                          // Overlay the song cover with the slider text.
                          Stack(
                            children: [
                              // Cover image
                              Image.network(
                                song!.imageReference!,
                                height: 1000.sp,
                                width: 1000.sp,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 1000.sp,
                                    height: 1000.sp,
                                    child: Center(
                                      child: Icon(
                                        Icons.signal_wifi_connected_no_internet_4,
                                        color: Colors.red,
                                        size: 300.sp,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              AnimatedOpacity(
                                opacity: coverOverlayIsVisible ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Container(
                                  width: 1000.sp,
                                  height: 1000.sp,
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  child: Center(
                                    child: Text(
                                      coverOverlayText,
                                      maxLines: 1,
                                      style: Theme.of(context).textTheme.headline1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Track name
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              song!.name,
                              style: Theme.of(context).textTheme.headline2,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                            ),
                          ),
                          SizedBox(height: 15.h),
                          // Artist name
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              song!.artist,
                              style: Theme.of(context).textTheme.subtitle1,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                            ),
                          ),
                          SizedBox(
                            height: 60.h,
                          ),
                          // Slider
                          slider,
                          SizedBox(
                            height: 60.h,
                          ),
                          // Show message when adding an already added song.
                          widget.sharedStoredSong
                              ? Container(
                                  padding: EdgeInsets.all(15.sp),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.3),
                                  child: Center(
                                    child: Text(
                                      "You've already added this song before 😉",
                                      style: Theme.of(context).textTheme.subtitle1,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          SizedBox(height: 30.h),
                          // Row for +, - and save buttons.
                          generateButtonRow(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Show a failed/rety screen if no connection could be established with the api.
    } else {
      return generateRetryScreen();
    }
  }

  /// Generates the row with the  +, Save, - Buttons.
  Widget generateButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // + button.
        SizedBox(
          height: 90.h,
          child: TextButton(
              onPressed: canAddTimeRange() ? addSliderToMultiSlider : null,
              child: Icon(
                Icons.add,
                color: Theme.of(context).highlightColor,
                size: 45.sp,
              ),
              style: ButtonStyle(
                  shape: MaterialStateProperty.all<CircleBorder>(CircleBorder(
                      side: BorderSide(
                          color: Theme.of(context)
                              .highlightColor
                              .withOpacity(canAddTimeRange() ? 1 : 0.5)))))),
        ),
        // 'Save Song'/'Save Changes' button.
        SolidRoundedButton(
            onPressed: () async {
              song!.timeRanges = sliderValues;
              // If we're adding a new song:
              // Save the song and quit the app, back to spotify.
              if (widget.initialSong == null) {
                Storage.addSong(song!);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NavigationWrapper(
                            checkShared: false,
                          )),
                );
                FlutterForegroundTask.minimizeApp();
              }
              // If we're editing a stored song:
              else {
                Storage.updateSong(song!);
                // If the song that we're editing was shared.
                if (widget.sharedStoredSong) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NavigationWrapper(
                              checkShared: false,
                            )),
                  );
                  FlutterForegroundTask.minimizeApp();
                } else {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              }
            },
            text: (widget.initialSong == null ? "Save Song" : "Save Changes")),
        // - button.
        SizedBox(
          height: 90.h,
          child: TextButton(
              onPressed:
                  canRemoveTimeRange() ? removeSliderFromMultiSlider : null,
              child: Icon(Icons.remove,
                  color: Theme.of(context).highlightColor, size: 45.sp),
              style: ButtonStyle(
                  shape: MaterialStateProperty.all<CircleBorder>(CircleBorder(
                      side: BorderSide(
                          color: Theme.of(context)
                              .highlightColor
                              .withOpacity(canRemoveTimeRange() ? 1 : 0.5)))))),
        )
      ],
    );
  }

  /// Generates the failed/retry screen.
  /// This screen shows when no connection with the web api can be established
  /// (due to no internet for example)
  Widget generateRetryScreen() {
    return SafeArea(
      child: Scaffold(
          body: Center(
        child: Padding(
          padding: EdgeInsets.all(60.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Authentication or getting song data failed, retry",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline2,
              ),
              SizedBox(
                height: 60.sp,
              ),
              Text(
                "Make sure you are connected to the internet.",
                style: Theme.of(context).textTheme.subtitle1,
              ),
              SizedBox(
                height: 60.sp,
              ),
              // Button for retrying.
              SolidRoundedButton(
                  onPressed: () {
                    setState(() {
                      authenticationStatus = 'processing';
                    });
                    getSong();
                  },
                  text: "Retry")
            ],
          ),
        ),
      )),
    );
  }
}
