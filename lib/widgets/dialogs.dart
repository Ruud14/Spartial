import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:spartial/objects/song.dart';
import 'package:spartial/services/logger.dart';

/// Confirmation dialog for when removing songs.
class RemoveSongsDialog extends StatelessWidget {
  final List<Song> selectedSongs;
  final Function onDelete;
  const RemoveSongsDialog(
      {Key? key, required this.selectedSongs, required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          selectedSongs.length == 1
              ? "Are you sure you want to remove '${selectedSongs[0].name}' ?"
              : "Are you sure you want to remove these ${selectedSongs.length} songs?",
          style: Theme.of(context).textTheme.headline2,
        ),
        content: selectedSongs.length == 1
            ? const SizedBox()
            : Container(
                width: double.maxFinite,
                child: ListView(
                    shrinkWrap: true,
                    children: List.generate(
                        selectedSongs.length,
                        (index) => SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(selectedSongs[index].name),
                                  const Text(" - "),
                                  Text(selectedSongs[index].artist)
                                ],
                              ),
                            ))),
              ),
        actions: <Widget>[
          TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel')),
          TextButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.secondary)),
            onPressed: () {
              onDelete();
            },
            child: const Text('Remove'),
          )
        ],
      ),
    );
  }
}

/// Dialog that shows the user that they must have Spotify premium.
class NoPremiumDialog extends StatelessWidget {
  const NoPremiumDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a blurry background behind the dialog.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Premium Required",
          style: Theme.of(context).textTheme.headline2,
        ),
        content: Text(
          "Unfortunately Spotify premium is required for Spartial to work. Free users can't change the timeline of a playing song, neither can Spartial :(",
          style: Theme.of(context).textTheme.subtitle1,
        ),
        actions: <Widget>[
          TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Ok')),
        ],
      ),
    );
  }
}

/// Dialog that shows the user that they are not registered in the spotify dashboard.
class NotRegisteredInDashboardDialog extends StatelessWidget {
  const NotRegisteredInDashboardDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a blurry background behind the dialog.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "No permission/wrong client ID",
          style: Theme.of(context).textTheme.headline2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "If you're using the client ID from someone else then he/she has not put you on their whitelist. If you're using this app for yourself then you should create your own client ID.",
              style: Theme.of(context).textTheme.subtitle1,
            ),
            TextButton(
                onPressed: () async {
                  try {
                    await launch("https://spartial.app/setup");
                  } on Exception catch (e) {
                    Logger.error(e);
                  }
                },
                child: Text(
                  "Find out how to create your client ID",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      decoration: TextDecoration.underline),
                ))
          ],
        ),
        actions: <Widget>[
          TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Ok')),
        ],
      ),
    );
  }
}

/// Dialog for informing the user that there is new version of the app.
class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a blurry background behind the dialog.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Update available!",
          style: Theme.of(context).textTheme.headline2,
        ),
        content: Text(
          "A new version of Spartial has been released!",
          style: Theme.of(context).textTheme.subtitle1,
        ),
        actions: <Widget>[
          TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Later")),
          TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary)),
              onPressed: () async {
                try {
                  await launch("https://spartial.app/");
                } on Exception catch (e) {
                  Logger.error(e);
                }
                Navigator.pop(context);
              },
              child: const Text("Check it out now!")),
        ],
      ),
    );
  }
}
