import 'package:flutter/material.dart';
import 'package:spartial/objects/song.dart';
import 'package:spartial/screens/add_song.dart';
import 'package:spartial/services/snackbar.dart';
import 'package:spartial/services/spotify.dart';
import 'package:spartial/services/storage.dart';
import 'package:spartial/widgets/buttons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Screen that shows actions that can be performed on a song.
/// Is shown when tapping on a song on the songs list.
class SongContextMenuScreen extends StatefulWidget {
  /// The song it's all about.
  final Song song;
  const SongContextMenuScreen({Key? key, required this.song}) : super(key: key);

  @override
  _SongContextMenuScreenState createState() => _SongContextMenuScreenState();
}

class _SongContextMenuScreenState extends State<SongContextMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Padding(
        padding: EdgeInsets.fromLTRB(90.sp, 20.sp, 90.sp, 90.sp),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  "assets/spotify/Spotify_Logo_RGB_White.png",
                  height: 70.sp,
                ),
                // Song cover
                Padding(
                  padding: EdgeInsets.fromLTRB(60.w, 60.h, 60.w, 0),
                  child: Image.network(
                    widget.song.imageReference!,
                    width: 900.sp,
                    height: 900.sp,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.signal_wifi_connected_no_internet_4,
                        color: Colors.red,
                        size: 900.sp,
                      );
                    },
                  ),
                ),
                // Song title
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    widget.song.name,
                    style: Theme.of(context).textTheme.headline2,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
                SizedBox(height: 15.h),
                // Artist
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    widget.song.artist,
                    style: Theme.of(context).textTheme.subtitle1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
                SizedBox(
                  height: 60.h,
                ),
                // Actions
                Container(
                  width: 800.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ContextMenuButton(
                        text: "Remove from Spartial",
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).highlightColor,
                        ),
                        onPressed: () {
                          Storage.deleteSong(widget.song);
                          Navigator.pop(context, true);
                        },
                      ),
                      ContextMenuButton(
                        text: "Play on Spotify",
                        icon: Image.asset(
                          "assets/spotify/Spotify_Icon_RGB_White.png",
                          height: 70.sp,
                          width: 70.sp,
                        ),
                        onPressed: () {
                          try {
                            SpotifyWebApi.playInSpotify(widget.song.id);
                          } on Exception {
                            CustomSnackBar.show(
                                context, "Could not open Spotify", Colors.red);
                          }
                        },
                      ),
                      ContextMenuButton(
                        text: "Change times",
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Theme.of(context).highlightColor,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddSongScreen(
                                      initialSong: widget.song,
                                      trackID: widget.song.id,
                                    )),
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      )),
    );
  }
}
