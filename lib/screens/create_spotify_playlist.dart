import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spartial/objects/song.dart';
import 'package:spartial/services/snackbar.dart';
import 'package:spartial/services/spotify.dart';
import 'package:spartial/widgets/buttons.dart';

/// Screen on which a Spotify playlist can be created from selected Spartial songs.
class CreateSpotifyPlaylistPage extends StatefulWidget {
  // The songs to be put in the playlist.
  final List<Song> selectedSongs;
  const CreateSpotifyPlaylistPage({Key? key, required this.selectedSongs})
      : super(key: key);

  @override
  _CreateSpotifyPlaylistPageState createState() =>
      _CreateSpotifyPlaylistPageState();
}

class _CreateSpotifyPlaylistPageState extends State<CreateSpotifyPlaylistPage> {
  /// Playlist details.
  String title = "Spartial";
  bool isPrivate = false;

  @override
  Widget build(BuildContext context) {
    // Create the title textfield.
    TextFormField titleTextField = TextFormField(
      maxLength: 100,
      initialValue: title,
      cursorColor: Theme.of(context).colorScheme.secondary,
      style: Theme.of(context).textTheme.headline3,
      decoration: InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).highlightColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
      onChanged: (String value) {
        setState(() {
          title = value;
        });
      },
    );

    return SafeArea(
        child: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                // Back button
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).highlightColor,
                    )),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(90.sp, 0, 90.sp, 90.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create Spotify playlist from selection",
                    style: Theme.of(context).textTheme.headline2,
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  Text(
                    "Before creating a Spotify playlist, you must specify the following details.",
                    style: Theme.of(context).textTheme.subtitle1,
                    //textAlign: TextAlign.,
                  ),
                  SizedBox(
                    height: 60.h,
                  ),
                  Text(
                    "Playlist name",
                    style: Theme.of(context).textTheme.subtitle1,
                    maxLines: 1,
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  titleTextField,
                  SizedBox(
                    height: 15.h,
                  ),
                  Row(
                    children: [
                      Text(
                        "Private playlist",
                        style: Theme.of(context).textTheme.subtitle1,
                        maxLines: 1,
                      ),
                      SizedBox(
                        height: 15.h,
                      ),
                      Checkbox(
                        checkColor: Theme.of(context).colorScheme.secondary,
                        fillColor: MaterialStateProperty.all<Color>(
                            Theme.of(context).scaffoldBackgroundColor),
                        value: isPrivate,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              isPrivate = value;
                            });
                          }
                        },
                        side: MaterialStateBorderSide.resolveWith(
                          (states) => BorderSide(
                              width: 1.0,
                              color: Theme.of(context).highlightColor),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 120.h,
                  ),
                  Center(
                    child: SolidRoundedButton(
                        onPressed: () async {
                          // Convert the songs to track uris.
                          List<String> trackUris = List<String>.from(widget
                              .selectedSongs
                              .map((e) => "spotify:track:" + e.id));
                          // Create the Spotify playlist.
                          bool result =
                              await SpotifyWebApi.createSpotifyPlaylist(
                                  trackUris, title, "", isPrivate);
                          // Show snackbar with the result.
                          CustomSnackBar.show(
                              context,
                              result
                                  ? "Created new Spotify playlist!"
                                  : "Failed to create Spotify playlist",
                              result ? null : Colors.red);
                          if (result) {
                            Navigator.pop(context);
                          }
                        },
                        text: "Create Spotify playlist"),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }
}
