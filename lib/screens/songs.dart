import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spartial/objects/song.dart';
import 'package:spartial/screens/create_spotify_playlist.dart';
import 'package:spartial/screens/settings.dart';
import 'package:spartial/screens/song_cotext_menu.dart';
import 'package:spartial/services/converters.dart';
import 'package:spartial/services/snackbar.dart';
import 'package:spartial/services/storage.dart';
import 'package:spartial/widgets/dialogs.dart';
import 'package:spartial/widgets/instructions.dart';
import 'package:spartial/widgets/loading_indicator.dart';
import 'package:spartial/widgets/multi_slider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:spartial/widgets/scroll_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spartial/services/settings.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Main page
/// Lists all the stored songs.
class SongsPage extends StatefulWidget {
  const SongsPage({Key? key}) : super(key: key);

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  /// List of songs that are currently selected.
  List<Song> selectedSongs = [];

  /// List of songs selected before 'all songs' was checked.
  /// This is used for when the checkbox is unchecked later.
  List<Song> selectedSongsBeforeSelectingAll = [];

  /// Whether the 'all songs' checkbox is checked during selection.
  bool selectAllSongs = false;

  /// Whether the user is currently searching.
  bool isSearching = false;

  /// String typed in the search bar.
  String searchString = "";

  /// Song that is currently being held down.
  /// Used to color the held song differently.
  Song? heldSong;

  /// Minimal loading time for the songs list (in miliseconds)
  /// This makes the loading more smoothe instead of choppy.
  int minLoadingMS = 500;

  /// Determines whether the next songs list load should be done async or not.
  /// The songs list should not be loaded async when selecting songs, that's why this is needed.
  bool useAsyncLoad = true;

  /// Checks if there are any newer versions of the app.
  void checkForUpdates() async {
    // Get the version number of the newest app.
    var response = await http.get(Uri.parse('https://spartial.app/version'));
    if (response.statusCode == 200) {
      String html = response.body;
      List<String> newestVersionNumbers =
          html.split("</body>")[0].split("<body>")[1].trim().split(".");
      // Compare that number to the current version number.
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      List<String> currentVersionNumbers = packageInfo.version.split(".");
      bool newVersionAvailable = false;
      for (int i = 0; i < newestVersionNumbers.length; i++) {
        int newV = int.parse(newestVersionNumbers[i]);
        int curV = int.parse(currentVersionNumbers[i]);
        // No difference in version number.
        if (newV == curV) {
          continue;
          // There is a new version.
        } else if (newV > curV) {
          newVersionAvailable = true;
          break;
          // Our version is newer.
        } else if (newV < curV) {
          break;
        }
      }

      // Show update dialog informing the user that an update is available.
      if (newVersionAvailable) {
        showDialog(
            context: context,
            builder: (context) {
              // Create a blurry background behind the dialog.
              return const UpdateAvailableDialog();
            });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Check for updates if Settings.checkForUpdates
    if (Settings.checkForUpdates()) {
      checkForUpdates();
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScene that doesn't allow going back to the add_songs screen.
    return WillPopScope(
      onWillPop: () async {
        // Stop searching and selecting when pressing the back button.
        if (isSearching || selectedSongs.isNotEmpty) {
          isSearching = false;
          selectedSongs.clear();
          return false;
        } else {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          return false;
        }
      },
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            body: ValueListenableBuilder<Box<Song>>(
              valueListenable: Storage.songStorageStream,
              builder: (context, box, _) {
                List<Song> songs = box.values.toList().cast<Song>();
                songs = sortSongs(songs);
                return Column(
                  children: [
                    selectedSongs.isNotEmpty
                        ? generateSelectionTopBar(songs)
                        : generateDefaultTopBar(songs),
                    songs.isEmpty
                        ? generateNoSongsAddedScreen()
                        : Expanded(
                            // use futurebuilder to load songs async.
                            child: useAsyncLoad
                                ? FutureBuilder(
                                    future: generateSongsListAsync(songs),
                                    builder: (context,
                                        AsyncSnapshot<Widget> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        return snapshot.data!;
                                      } else {
                                        return CustomLoadingIndicator(
                                            size: 90.sp);
                                      }
                                    })
                                : generateSongsList(songs),
                          )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Returns songs sorted based on 'sortBy' and 'sortAscending'.
  List<Song> sortSongs(List<Song> songs) {
    String sortBy = Settings.sortBy();
    bool sortAscending = Settings.sortAscending();
    if (sortBy == "title") {
      songs
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return List<Song>.from(sortAscending ? songs : songs.reversed);
    } else if (sortBy == "artist") {
      songs.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      return List<Song>.from(sortAscending ? songs : songs.reversed);
    } else if (sortBy == "date") {
      songs.sort((a, b) => a.added.compareTo(b.added));
      return List<Song>.from(sortAscending ? songs : songs.reversed);
    } else if (sortBy == "duration") {
      songs.sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
      return List<Song>.from(sortAscending ? songs : songs.reversed);
    } else {
      return songs;
    }
  }

  /// Generates the list of songs together with all the scrolling stuff.
  Widget generateSongsList(List<Song> songs) {
    // List that is appended to the songs list.
    // Contains extra info depending on the songs list.
    List extraInfoList = ((songs.length < 10 || isSearching)
        ? [
            Padding(
              padding: EdgeInsets.all(120.sp),
              child: Text(
                isSearching
                    ? "No (other) songs found related to '$searchString' 😔"
                    : "It is looking quite empty over here, go ahead and add some more songs 😉",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).highlightColor.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
              ),
            )
          ]
        : []);

    Widget songsList = RawScrollbar(
        thumbColor: Theme.of(context).highlightColor.withOpacity(0.5),
        radius: const Radius.circular(20),
        child: CustomScrollIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500), () {});
            },
            child: ListView.builder(
              itemBuilder: (context, index) {
                // Show extra info
                if (index > songs.length - 1) {
                  return extraInfoList[index - songs.length];
                } else if (isSearching) {
                  if (songs[index]
                          .name
                          .toLowerCase()
                          .contains(searchString.toLowerCase()) ||
                      songs[index]
                          .artist
                          .toLowerCase()
                          .contains(searchString.toLowerCase())) {
                    return generateSongTile(songs[index]);
                  } else {
                    return const SizedBox();
                  }
                } else {
                  return generateSongTile(songs[index]);
                }
              },
              itemCount: songs.length + extraInfoList.length,
            )));
    useAsyncLoad = true;
    return songsList;
  }

  /// Async version of generateSongsList so it can be used together with a
  /// future builder to prevent lag when searching/loading.
  /// We can't always use this version however, since it doesn't work when selecting songs.
  Future<Widget> generateSongsListAsync(List<Song> songs,
      {bool extraDelay = true}) async {
    DateTime startTime = DateTime.now();
    // Create the songs list.
    Widget songsList = generateSongsList(songs);

    // Make the loading duration take at least minLoadingMS miliseconds.
    if (extraDelay) {
      DateTime endTime = DateTime.now();
      int timeDifferenceMS = endTime.difference(startTime).inMilliseconds;
      if (timeDifferenceMS < minLoadingMS) {
        await Future.delayed(
            Duration(milliseconds: minLoadingMS - timeDifferenceMS));
      }
    }
    return songsList;
  }

  /// Shows the SongContextMenuScreen.
  void showContextMenu(Song song) async {
    bool? deletedSong = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SongContextMenuScreen(song: song)),
    );
    if (deletedSong != null && deletedSong) {
      CustomSnackBar.show(context, "Removed '${song.name} - ${song.artist}'");
    }
  }

  /// Generates a song tile for a song.
  Widget generateSongTile(Song song) {
    return Padding(
      padding: EdgeInsets.fromLTRB(51.w, 6.h, 0, 6.h),
      child: GestureDetector(
        child: Container(
          color: selectedSongs.contains(song)
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
              : (heldSong == song
                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                  : Colors.transparent),
          child: Padding(
            padding: EdgeInsets.all(18.sp),
            child: Row(
              children: [
                // Only show the check infront of the tile when the tile is selected.
                selectedSongs.contains(song)
                    ? Checkbox(
                        checkColor: Theme.of(context).colorScheme.secondary,
                        value: true,
                        onChanged: null,
                      )
                    : const SizedBox(),
                // Song cover.
                Image.network(
                  song.imageReference!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  width: 180.sp,
                  height: 180.sp,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 180.sp,
                      height: 180.sp,
                      child: const Center(
                        child: Icon(
                          Icons.signal_wifi_connected_no_internet_4,
                          color: Colors.red,
                        ),
                      ),
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
                  onPressed: () {
                    showContextMenu(song);
                  },
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).highlightColor,
                  ),
                )
              ],
            ),
          ),
        ),
        // Allow selecting items.
        onLongPress: () {
          useAsyncLoad = false;
          setState(() {
            if (!selectedSongs.contains(song)) {
              selectedSongs.add(song);
            }
            heldSong = null;
          });
        },
        // Hold animation.
        onTapDown: (details) {
          useAsyncLoad = false;
          setState(() {
            heldSong = song;
            useAsyncLoad = false;
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                heldSong = null;
                useAsyncLoad = false;
              });
            }
          });
        },
        onTapUp: (details) {
          setState(() {
            heldSong = null;
            useAsyncLoad = false;
          });
        },
        onTap: () {
          // Select this item by a single tap whenever another item has already been selected.
          if (selectedSongs.isNotEmpty) {
            setState(() {
              useAsyncLoad = false;
              if (selectedSongs.contains(song)) {
                selectedSongs.remove(song);
                selectAllSongs = false;
              } else {
                selectedSongs.add(song);
              }
            });
          } else {
            showContextMenu(song);
          }
        },
      ),
    );
  }

  /// Generates the default top bar,
  /// containing the amount of songs in the list and button to go the the settings.
  Widget generateDefaultTopBar(List<Song> songs) {
    // Create the search bar.
    TextFormField searchBar = TextFormField(
      autofocus: true,
      maxLength: 100,
      initialValue: searchString,
      cursorColor: Theme.of(context).colorScheme.secondary,
      style: Theme.of(context).textTheme.headline3,
      decoration: InputDecoration(
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
          hintStyle: Theme.of(context).textTheme.subtitle1,
          focusColor: Colors.white,
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.secondary)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).highlightColor)),
          hintText: 'Song tile or artist',
          counterText: ''),
      onChanged: (String value) {
        setState(() {
          searchString = value;
        });
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        isSearching
            // Back button
            ? Container(
                width: 240.w,
                child: IconButton(
                    onPressed: () {
                      setState(() {
                        isSearching = false;
                      });
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).highlightColor,
                    )),
              )
            // Sort button
            : songs.isNotEmpty
                ? Container(
                    width: 240.w,
                    child: IconButton(
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return createSortingOptionsList();
                            },
                          );
                        },
                        icon: Icon(
                          Icons.sort_rounded,
                          color: Theme.of(context).highlightColor,
                        )),
                  )
                : SizedBox(
                    width: 240.w,
                  ),
        // Song counter / search bar
        Center(
          child: isSearching
              ? Container(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 15.h),
                  width: MediaQuery.of(context).size.width / 2,
                  child: searchBar,
                )
              : Text(
                  "${songs.length}/${Settings.getSongStorageCapacity()}",
                  style: Theme.of(context).textTheme.caption,
                ),
        ),

        Row(
          children: [
            // Search button.
            // Only show when songs have been added.
            songs.isNotEmpty
                ? Container(
                    height: 105.h,
                    width: 120.w,
                    child: IconButton(
                        highlightColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        padding: EdgeInsets.zero,
                        iconSize: 90.sp,
                        onPressed: () {
                          setState(() {
                            isSearching = !isSearching;
                          });
                        },
                        icon: Icon(
                          Icons.search_outlined,
                          color: Theme.of(context).highlightColor,
                        )),
                  )
                : SizedBox(
                    height: 105.h,
                    width: 120.w,
                  ),
            // Settings button
            Container(
              height: 105.h,
              width: 120.w,
              child: IconButton(
                  highlightColor: Theme.of(context).scaffoldBackgroundColor,
                  padding: EdgeInsets.zero,
                  iconSize: 90.sp,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettinsPage()),
                    );
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.settings_outlined,
                    color: Theme.of(context).highlightColor,
                  )),
            ),
          ],
        )
      ],
    );
  }

  /// Generates the top bar for when selecting songs.
  /// Contains buttons for removal and selecting all songs at once.
  Widget generateSelectionTopBar(List<Song> songs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Back button
            IconButton(
                onPressed: () {
                  useAsyncLoad = false;
                  setState(() {
                    selectedSongs.clear();
                    selectedSongsBeforeSelectingAll.clear();
                  });
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).highlightColor,
                )),
            // Select-all Checkbox
            Theme(
              data: ThemeData(
                primarySwatch: Colors.green,
                unselectedWidgetColor: Theme.of(context).highlightColor,
              ),
              child: Checkbox(
                  value: selectAllSongs,
                  onChanged: (value) {
                    if (value != null) {
                      useAsyncLoad = false;
                      setState(() {
                        selectAllSongs = value;
                        if (value == true) {
                          selectedSongsBeforeSelectingAll =
                              List.from(selectedSongs);
                          selectedSongs = List.from(songs);
                        } else {
                          selectedSongs =
                              List.from(selectedSongsBeforeSelectingAll);
                        }
                      });
                    }
                  }),
            ),
            Text(
              "Select All",
              style: Theme.of(context).textTheme.subtitle1,
            )
          ],
        ),
        // Selected amount text
        Text(
          "${selectedSongs.length.toString()}/${songs.length}",
          style: Theme.of(context).textTheme.headline2,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Remove button
              IconButton(
                onPressed: () {
                  showRemoveDialog();
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).highlightColor,
                ),
              ),
              // Share button
              IconButton(
                onPressed: () {
                  Share.share(Converters.songsToShareUrl(selectedSongs));
                },
                icon: Icon(
                  Icons.share,
                  color: Theme.of(context).highlightColor,
                ),
              ),
              // Create spotify playlist
              IconButton(
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CreateSpotifyPlaylistPage(
                            selectedSongs: selectedSongs,
                          )));
                },
                icon: Icon(
                  Icons.playlist_add,
                  color: Theme.of(context).highlightColor,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  /// Generates the screen that should be shown when there are no songs added yet.
  Widget generateNoSongsAddedScreen() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(60.sp),
          child: const SingleChildScrollView(child: HowToAddSongsInstruction()),
        ),
      ),
    );
  }

  /// Creates a list of sorting options for in the bottom sheet.
  Widget createSortingOptionsList() {
    return Container(
      height: 500.h,
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(30.sp),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
                  Text(
                    "Sort by",
                    style: Theme.of(context).textTheme.headline2,
                  ),
                ] +
                List.generate(
                  Settings.sortingOptions.length,
                  (index) => createBottomSheetButton(
                      List<String>.from(Settings.sortingOptions.keys)[index],
                      List<String>.from(Settings.sortingOptions.values)[index]),
                ),
          ),
        ),
      ),
    );
  }

  /// Creates a button for in the sorting bottom sheet based on 'name' and 'text'
  Widget createBottomSheetButton(String name, String text) {
    return Padding(
      padding: EdgeInsets.all(24.sp),
      child: GestureDetector(
        onTap: () async {
          setState(() {
            if (Settings.sortBy() == name) {
              Settings.setSortAscending(!Settings.sortAscending());
            } else {
              Settings.setSortBy(name);
            }
          });
          Navigator.pop(context);
        },
        child: Container(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.headline3,
              ),
              Settings.sortBy() == name
                  ? Icon(
                      !Settings.sortAscending()
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Theme.of(context).colorScheme.secondary,
                    )
                  : const SizedBox()
            ],
          ),
        ),
      ),
    );
  }

  /// Shows deletion confirmation dialog.
  void showRemoveDialog() {
    showDialog(
        context: context,
        builder: (context) {
          // Create a blurry background behind the dialog.
          return RemoveSongsDialog(
              selectedSongs: selectedSongs,
              onDelete: () {
                setState(() {
                  Storage.deleteSongs(selectedSongs);
                });
                int noDeletedSongs = selectedSongs.length;

                String snackBarMessage =
                    "Removed $noDeletedSongs song${noDeletedSongs == 1 ? "" : "s"}.";
                CustomSnackBar.show(context, snackBarMessage);
                selectedSongs.clear();
                selectedSongsBeforeSelectingAll.clear();

                Navigator.pop(context);
              });
        });
  }
}
