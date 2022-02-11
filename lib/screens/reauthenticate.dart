import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spartial/services/foreground_task.dart';
import 'package:spartial/services/settings.dart';
import 'package:spartial/services/snackbar.dart';
import 'package:spartial/services/spotify.dart';
import 'package:spartial/services/storage.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:spartial/widgets/dialogs.dart';
import 'package:spartial/widgets/inputs.dart';
import 'package:spartial/wrappers/navigation_wrapper.dart';

/// Screen on which the user can reauthenticate.
/// Is shown when the user logs out or the Spotify refresh token has expired.
class ReauthenticatePage extends StatefulWidget {
  const ReauthenticatePage({Key? key}) : super(key: key);

  @override
  _ReauthenticatePageState createState() => _ReauthenticatePageState();
}

class _ReauthenticatePageState extends State<ReauthenticatePage> {
  /// Value of the clientIDInput.
  String clientIDInputValue = Settings.clientID();

  /// Restarts the foreground task if it is running.
  /// Does nothing othwerwise.
  void restartForegroundTaskIfRunning() async {
    if (await ForegroundTask.isRunningService()) {
      ForegroundTask.restart();
    }
  }

  @override
  void initState() {
    // Add listener for when the spotifyCredentialsStorage changes.
    // Update isAuthenticated accordingly.
    Storage.spotifyCredentialsStorageStream.addListener(() {
      if (Storage.getSpotifyCredentials() != null) {
        // Navigate to NavigationWrapper.
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const NavigationWrapper(),
          ),
        );
        // Restart the foreground task if it is running.
        // If it is not running then the foreground task will be started from NavigationWrapper.
        restartForegroundTaskIfRunning();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// Input for the client ID.
    ClientIDInput clientIDInput = ClientIDInput(onChanged: (String value) {
      clientIDInputValue = value;
    });

    return WillPopScope(
      // Prevent going to the previous page.
      onWillPop: () async {
        return false;
      },
      child: SafeArea(
          child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(60.sp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Spotify login expired.",
                    style: Theme.of(context).textTheme.headline2,
                  ),
                  SizedBox(
                    height: 30.h,
                  ),
                  Text(
                    "Your login has expired, reauthenticate to continue.",
                    style: Theme.of(context).textTheme.subtitle1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 60.h,
                  ),
                  Image.asset(
                    'assets/icon/icon2.png',
                    height: MediaQuery.of(context).size.width / 2,
                    width: MediaQuery.of(context).size.width / 2,
                  ),
                  SizedBox(
                    height: 120.h,
                  ),
                  // Reauthenticate button.
                  SolidRoundedButton(
                    onPressed: () async {
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
                    backGroundColor: Theme.of(context).colorScheme.secondary,
                    showSpotifyIcon: true,
                  ),
                  SizedBox(
                    height: 60.h,
                  ),
                  clientIDInput,
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}
