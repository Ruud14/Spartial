import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:spartial/services/settings.dart';
import 'package:spartial/services/snackbar.dart';
import 'package:spartial/services/spotify.dart';
import 'package:spartial/services/storage.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:spartial/widgets/dialogs.dart';
import 'package:spartial/widgets/inputs.dart';
import 'package:spartial/widgets/instructions.dart';
import 'package:spartial/wrappers/navigation_wrapper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Screen that shows the user how the app works and lets the user authenticate if they haven't already.
/// This screen is shown when the app is opened for the first time. It can however be manually reopened later.
class IntroductionPage extends StatefulWidget {
  // Wether the settings page has been opened before.
  final bool reopened;
  const IntroductionPage({Key? key, this.reopened = false}) : super(key: key);

  @override
  _IntroductionPageState createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  /// Whether the user is authenticated.
  bool isAuthenticated =
      Storage.spotifyCredentialsStorage.containsKey('SpotifyCredentials');

  /// Whether the skip button is shown.
  bool showSkipButton = false;

  /// wether the first page is shown.
  bool showFirstPage = true;

  /// Runs when leaving the intro screen.
  ///
  /// if this is the first time opening the settings screen:
  /// Sets shownIntroductionScreen to true in storage
  /// and navigates to the NavigationWrapper.
  ///
  /// else: Navigator.pop();
  void onClose({bool openHideNotificationInstructions = false}) {
    if (!widget.reopened) {
      setState(() {
        Settings.setShownIntroductionScreen(true);
      });

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => NavigationWrapper(
                  openHideNotificationInstructions:
                      openHideNotificationInstructions,
                )),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    // Add listener for when the spotifyCredentialsStorage changes.
    // Update isAuthenticated accordingly.
    Storage.spotifyCredentialsStorageStream.addListener(() {
      if (Storage.getSpotifyCredentials() != null) {
        if (!isAuthenticated) {
          setState(() {
            isAuthenticated = true;
            showFirstPage = false;
          });
        }
      }
    });
    super.initState();
  }

  /// Value of the clientID Input field.
  String clientIDInputValue = Settings.clientID();

  @override
  Widget build(BuildContext context) {
    /// Input for the client ID.
    ClientIDInput clientIDInput = ClientIDInput(onChanged: (String value) {
      clientIDInputValue = value;
    });

    /// List of pages between which one can swipe.
    List<PageViewModel> pages = [
      // Start/Auth page
      PageViewModel(
          image: Image.asset(
            'assets/icon/icon2.png',
            height: MediaQuery.of(context).size.width / 2,
            width: MediaQuery.of(context).size.width / 2,
          ),
          title: "Welcome to Spartial!",
          body: "Let's introduce how it works",
          decoration: PageDecoration(
            titleTextStyle: Theme.of(context).textTheme.headline4!,
            bodyTextStyle: Theme.of(context).textTheme.headline3!,
          ),
          footer: Column(
            children: [
              // Authenticate button.
              SolidRoundedButton(
                onPressed: isAuthenticated
                    ? null
                    : () async {
                        // Make sure the specified client id is of correct length.
                        if (clientIDInputValue.length != 32) {
                          CustomSnackBar.show(context, "Invallid client ID");
                        } else {
                          Settings.setClientID(clientIDInputValue);
                          await SpotifyWebApi.authenticate(onNoPremium: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return const NoPremiumDialog();
                                });
                          }, onNotRegisteredInDashboard: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return const NotRegisteredInDashboardDialog();
                                });
                          });
                        }
                      },
                text: "Connect to Spotify",
                lineThrough: isAuthenticated,
                backGroundColor: Theme.of(context).colorScheme.secondary,
                showSpotifyIcon: true,
              ),
              SizedBox(
                height: 60.h,
              ),
              // Show the clientIDInput if the user isn't authenticated.
              // Show 'Swipe to continue' otherwise.
              isAuthenticated
                  ? Text(
                      "Swipe to continue",
                      style: Theme.of(context).textTheme.subtitle1,
                    )
                  : clientIDInput,
            ],
          )),
      // How to add first song page
      PageViewModel(
        titleWidget: Padding(
          padding: EdgeInsets.fromLTRB(0, 90.h, 0, 0),
          child: Column(
            children: [
              Text(
                "How to add your first song",
                style: Theme.of(context).textTheme.headline4!,
              ),
            ],
          ),
        ),
        bodyWidget: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text.rich(
              TextSpan(
                text: "Adding songs to Spartial is really easy, ",
                style: Theme.of(context).textTheme.headline3,
                children: <TextSpan>[
                  TextSpan(
                      text: "just share the song from Spotify to Spartial.",
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.headline3!.fontSize,
                        color: Theme.of(context).textTheme.headline3!.color,
                        fontWeight: FontWeight.bold,
                      )),
                  TextSpan(
                      text:
                          " You can do this by clicking the following buttons in Spotify.",
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.headline3!.fontSize,
                        color: Theme.of(context).textTheme.headline3!.color,
                      )),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 60.h,
            ),
            const HowToAddSongsInstruction(
              showRemark: false,
            ),
            SizedBox(
              height: 60.h,
            ),
            Column(
              children: [
                Text(
                  "After sharing, you land on a page that looks like this. Here you can select the good parts of the song.",
                  style: Theme.of(context).textTheme.headline3,
                  textAlign: TextAlign.center,
                ),
                Image.asset(
                  'assets/selection_example_3.png',
                  width: MediaQuery.of(context).size.width / 2,
                ),
                Text(
                  "Done!",
                  style: Theme.of(context).textTheme.headline3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 20.h,
                ),
                Text(
                  "That's all it takes to add a song to Spartial! The next time the song comes on, Spartial will automatically skip the parts that you don't want to hear.",
                  style: Theme.of(context).textTheme.headline3,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
      // How to remove notification and how to share page
      PageViewModel(
        titleWidget: Padding(
          padding: EdgeInsets.fromLTRB(0, 90.h, 0, 0),
          child: Text(
            "Extra info",
            style: Theme.of(context).textTheme.headline4!,
          ),
        ),
        bodyWidget: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                text:
                    "In order for Spartial to run in the background, Spartial has an ongoing notification.",
                style: Theme.of(context).textTheme.headline3,
                children: <TextSpan>[
                  TextSpan(
                      text: " Luckily, it can be easily hidden.",
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.headline3!.fontSize,
                        color: Theme.of(context).textTheme.headline3!.color,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 60.h,
            ),
            Image.asset(
              'assets/spartial_notification.png',
              width: MediaQuery.of(context).size.width / 3 * 2,
            ),
            SizedBox(
              height: 60.h,
            ),
            SolidRoundedButton(
                onPressed: () {
                  onClose(openHideNotificationInstructions: true);
                },
                text: "Hide notification now"),
            SizedBox(
              height: 120.h,
            ),
            Text(
              "Sharing",
              style: Theme.of(context).textTheme.headline4!,
            ),
            SizedBox(
              height: 30.h,
            ),
            Text(
              "You can share your Spartial songs with friends so they don't have to add all those songs one by one. You can do this by tapping the share button after selecting some songs.",
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 60.h,
            ),
            Image.asset(
              'assets/share_instruction.jpg',
              width: MediaQuery.of(context).size.width / 2,
            ),
          ],
        ),
      ),
    ];
    return SafeArea(
      child: IntroductionScreen(
        isProgress: isAuthenticated,
        dotsDecorator:
            DotsDecorator(activeColor: Theme.of(context).colorScheme.secondary),
        freeze: !isAuthenticated,
        pages: showFirstPage ? pages : pages.sublist(1),
        onDone: onClose,
        onSkip: onClose,
        // Only show the skip button after having passed the second page.
        onChange: (int pageIndex) {
          setState(() {
            if (pageIndex >= (showFirstPage ? 1 : 0)) {
              showSkipButton = true;
            } else {
              showSkipButton = false;
            }
          });
        },
        color: Theme.of(context).colorScheme.secondary,
        done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
        skip: const Text("Skip", style: TextStyle(fontWeight: FontWeight.w600)),
        showNextButton: false,
        showSkipButton: showSkipButton,
      ),
    );
  }
}
