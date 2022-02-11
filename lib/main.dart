import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:spartial/objects/settings.dart';
import 'package:spartial/objects/song.dart';
import 'objects/spotify_credentials.dart';
import 'wrappers/navigation_wrapper.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  // Initialize Hive
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Register adapters in Hive
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(SettingsObjectAdapter());
  Hive.registerAdapter(SpotifyCredentialsAdapter());
  await Hive.openBox<Song>('songs');
  await Hive.openBox<SettingsObject>('settings');
  await Hive.openBox<SpotifyCredentials>('SpotifyCredentials');
  runApp(const Spartial());
}

class Spartial extends StatelessWidget {
  const Spartial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1080, 1920),
      builder: () => MaterialApp(
        title: 'Spartial',
        // Create the app theme data.
        theme: ThemeData(
            bottomAppBarColor: Colors.black,
            highlightColor: Colors.white,
            // colorScheme.secondary: Colors.green,
            // Replacement for colorScheme.secondary
            colorScheme: ColorScheme.fromSwatch().copyWith(
              secondary: Colors.green,
            ),

            /// Background color.
            scaffoldBackgroundColor: Colors.black,
            sliderTheme: SliderThemeData(
              thumbColor: Colors.white,
              disabledThumbColor: Colors.white,
              overlayShape: RoundSliderThumbShape(enabledThumbRadius: 15.sp),
              disabledInactiveTrackColor: Colors.grey[900],
              disabledActiveTrackColor: Colors.white.withOpacity(0.7),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey[900],
              trackHeight: 6.sp,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.sp),
              rangeThumbShape:
                  RoundRangeSliderThumbShape(enabledThumbRadius: 9.sp),
            ),
            textTheme: TextTheme(
              /// Theme for text inside appbar
              caption: TextStyle(
                  fontSize: 45.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w300),

              /// Current scroll time text (that is ontop of the song cover)
              headline1: TextStyle(fontSize: 300.sp, color: Colors.white),
              headline2: TextStyle(fontSize: 60.sp, color: Colors.white),
              headline3: TextStyle(fontSize: 45.sp, color: Colors.white),

              /// Bold version of headline 2
              headline4: TextStyle(
                  fontSize: 60.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              subtitle1: TextStyle(
                  fontSize: 45.sp,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300),
              subtitle2: TextStyle(
                  fontSize: 36.sp,
                  color: Colors.grey,
                  fontWeight: FontWeight.w200),

              /// Subtitle 2 but with underline.
              headline6: TextStyle(
                  fontSize: 36.sp,
                  color: Colors.grey,
                  fontWeight: FontWeight.w200,
                  decoration: TextDecoration.underline),
              // Default text style
              bodyText2: TextStyle(fontSize: 42.sp),
            )),
        home: const WithForegroundTask(child: NavigationWrapper()),
      ),
    );
  }
}
