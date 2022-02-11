import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spartial/objects/song.dart';
import 'package:spartial/screens/loading.dart';
import 'package:spartial/screens/reauthenticate.dart';
import 'package:spartial/services/converters.dart';
import 'package:spartial/services/settings.dart';
import 'package:spartial/services/snackbar.dart';
import 'package:spartial/services/storage.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:spartial/widgets/multi_slider.dart';
import 'package:spartial/widgets/scroll_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oauth2/src/authorization_exception.dart';
import 'package:spartial/screens/settings.dart';
import 'package:spartial/wrappers/navigation_wrapper.dart';

/// Screen that is shown when importing Spartial songs.
class ImportSongsPage extends StatefulWidget {
  /// The uri that contains all the data about the songs to be added.
  final String sharedUri;
  const ImportSongsPage({Key? key, required this.sharedUri}) : super(key: key);

  @override
  _ImportSongsPageState createState() => _ImportSongsPageState();
}

class _ImportSongsPageState extends State<ImportSongsPage> {
  /// List of songs to be added.
  List<Song> songs = [];

  /// List of songs that are deselected (not selected for importing).
  List<Song> deselectedSongs = [];

  /// Gets the songs based on the URIs in the shared url.
  void getSongs() async {
    try {
      songs = await Converters.urlToSongs(widget.sharedUri);

      /// Handle token expired exception.
    } on AuthorizationException {
      Storage.deleteSpotifyCredentials();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ReauthenticatePage()));
    }

    setState(() {});
  }

  @override
  void initState() {
    getSongs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: songs.isEmpty
          // Show the loading screen when the songs haven't loaded yet.
          ? const LoadingScreen()
          // Show the import screen otherwise.
          : SafeArea(
              child: Scaffold(
                  body: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(30.sp, 30.sp, 30.sp, 90.sp),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            "Importing songs",
                            style: Theme.of(context).textTheme.headline2,
                          ),
                          Text(
                            "Select all the songs you want to import.",
                            style: Theme.of(context).textTheme.subtitle1,
                          )
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        RawScrollbar(
                          thumbColor:
                              Theme.of(context).highlightColor.withOpacity(0.5),
                          radius: const Radius.circular(20),
                          child: CustomScrollIndicator(
                            onRefresh: () async {
                              await Future.delayed(
                                  const Duration(milliseconds: 500), () {});
                            },
                            // Create the list of songs.
                            child: ListView(
                              children: List.generate(
                                    songs.length,
                                    (index) {
                                      return generateSongTile(songs[index]);
                                    },
                                  ) +
                                  [SizedBox(height: 150.h)],
                            ),
                          ),
                        ),
                        generateImportButtonBar()
                      ],
                    ),
                  )
                ],
              )),
            ),
    );
  }

  /// Generates a song tile for a song.
  Widget generateSongTile(Song song) {
    return Padding(
      padding: EdgeInsets.fromLTRB(51.w, 6.h, 0, 6.h),
      child: GestureDetector(
        child: Container(
          color: deselectedSongs.contains(song)
              ? Colors.red.withOpacity(0.2)
              : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.all(18.sp),
            child: Row(
              children: [
                // Only show the check infront of the tile when the song is selected.
                Checkbox(
                  checkColor: Theme.of(context).colorScheme.secondary,
                  value: !deselectedSongs.contains(song),
                  onChanged: null,
                ),

                // Song cover.
                Image.network(
                  song.imageReference!,
                  fit: BoxFit.contain,
                  width: 180.sp,
                  height: 180.sp,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.signal_wifi_connected_no_internet_4,
                      color: Colors.red,
                    );
                  },
                ),
                SizedBox(
                  width: 30.h,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Song title
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          song.name,
                          style: Theme.of(context).textTheme.headline2,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ),
                      // Artist
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          song.artist,
                          style: Theme.of(context).textTheme.subtitle1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ),
                      SizedBox(
                        height: 15.h,
                      ),
                      // Range slider.
                      MultiSlider(
                        values: List<double>.from(
                            ((song.timeRanges).map((e) => e.toDouble()))),
                        divisions: song.durationSeconds,
                        onChanged: null,
                        min: 0,
                        max: song.durationSeconds.toDouble(),
                        height: 5,
                        thumbThickness: 12.sp,
                        horizontalPadding: 0,
                        labelDisplacement: 5,
                        showStartAndEndTime: false,
                      ),
                      SizedBox(
                        height: 30.h,
                      )
                    ],
                  ),
                ),
                // Three dots button.
                IconButton(
                  highlightColor: Theme.of(context).scaffoldBackgroundColor,
                  onPressed: null,
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).highlightColor,
                  ),
                )
              ],
            ),
          ),
        ),
        // (De)select the song when tapping on it.
        onTap: () {
          setState(() {
            if (deselectedSongs.contains(song)) {
              deselectedSongs.remove(song);
            } else {
              deselectedSongs.add(song);
            }
          });
        },
      ),
    );
  }

  /// Generates the bar at the bottom with the "import selected songs" button.
  Widget generateImportButtonBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            width: MediaQuery.of(context).size.width / 10 * 9,
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2),
            child: Padding(
              padding: EdgeInsets.all(30.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SolidRoundedButton(
                      onPressed: () {
                        // Remove all deselected songs
                        List<Song> songsToAdd = [];
                        for (Song s in songs) {
                          if (!deselectedSongs.contains(s)) {
                            songsToAdd.add(s);
                          }
                        }
                        // Check if the storage capacity limit isn't exceeded.
                        int storageSizeAfterImport =
                            songsToAdd.length + Storage.songStorage.keys.length;
                        if (storageSizeAfterImport >
                            Settings.getSongStorageCapacity()) {
                          showStorageCapExeededDialog(
                              songsToAdd, storageSizeAfterImport);
                        } else {
                          // Check if there are songs that are already stored.
                          List<Song> duplicateSongs = [];
                          for (Song s in songsToAdd) {
                            if (Storage.songStorage.containsKey(s.id)) {
                              duplicateSongs.add(s);
                            }
                          }
                          if (duplicateSongs.isNotEmpty) {
                            showDuplicateSongsDialog(
                                songsToAdd, duplicateSongs);
                          } else {
                            Storage.addSongs(songsToAdd);
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) =>
                                    const NavigationWrapper(
                                  checkShared: false,
                                ),
                              ),
                            );
                            CustomSnackBar.show(context,
                                "Successfully imported ${songsToAdd.length == 1 ? songsToAdd[0].name + " - " + songsToAdd[0].artist : songsToAdd.length.toString() + " songs!"}");
                          }
                        }
                      },
                      backGroundColor: Theme.of(context).colorScheme.secondary,
                      text: "Import selected songs"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows dialog that tells that some of the songs about to be imported
  /// will override songs that are already stored.
  void showDuplicateSongsDialog(
      List<Song> songsToBeAdded, List<Song> duplicateSongs) {
    showDialog(
        context: context,
        builder: (context) {
          // Create a blurry background behind the dialog.
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                "You've already stored some of these songs",
                style: Theme.of(context).textTheme.headline2,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "You've already stored the following songs:",
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  SizedBox(
                    height: 30.h,
                  ),
                  Container(
                    width: double.maxFinite,
                    height: 300.h,
                    child: ListView(
                        shrinkWrap: true,
                        children: List.generate(
                            duplicateSongs.length,
                            (index) => SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(duplicateSongs[index].name),
                                      const Text(" - "),
                                      Text(duplicateSongs[index].artist)
                                    ],
                                  ),
                                ))),
                  ),
                  SizedBox(
                    height: 30.h,
                  ),
                  Text(
                    "Do you want to override the ones you've already stored, or only add the new ones?",
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    // Add all songs.
                    Storage.addSongs(songsToBeAdded);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const NavigationWrapper(
                          checkShared: false,
                        ),
                      ),
                    );
                  },
                  child: const Text('Override'),
                ),
                TextButton(
                    onPressed: () {
                      // Only add new songs.
                      List<Song> songsToBeAddedWithoutDuplicates = [];
                      for (Song s in songsToBeAdded) {
                        if (!duplicateSongs.contains(s)) {
                          songsToBeAddedWithoutDuplicates.add(s);
                        }
                      }
                      Storage.addSongs(songsToBeAddedWithoutDuplicates);
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const NavigationWrapper(
                            checkShared: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('Only add new songs')),
              ],
            ),
          );
        });
  }

  /// Shows dialog that tells that the storage limit will be exceeded.
  void showStorageCapExeededDialog(
      List<Song> songsToBeAdded, int storageSizeAfterImport) {
    showDialog(
        context: context,
        builder: (context) {
          // Create a blurry background behind the dialog.
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                "Not enough storage capacity",
                style: Theme.of(context).textTheme.headline2,
              ),
              content: Text(
                "You don't have enough storage capacity to add ${songsToBeAdded.length == 1 ? "this song." : ("these " + songsToBeAdded.length.toString() + " songs.")} "
                "Deselect ${storageSizeAfterImport - Settings.getSongStorageCapacity()} more songs or consider expanding the storage.",
                style: Theme.of(context).textTheme.subtitle1,
              ),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const SettinsPage(
                          highlightStorage: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Expand storage'),
                )
              ],
            ),
          );
        });
  }
}
