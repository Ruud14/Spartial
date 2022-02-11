


# Spartial ([Spartial.app](https://spartial.app))

####  Mobile app that lets you automatically skip parts of Spotify songs.
Works great for skipping song intros, outros, or other song parts that you specify.

### How it works
Songs can be added to Spartial by sharing them from Spotify to Spartial. Then, in Spartial, you are asked to select the part(s) of the song that you like. After doing so, that selection is saved and the next time you're listening to that song on Spotify, Spartial will automatically skip the parts that you didn't select. 


<p float="left">
	<img src="https://i2.paste.pics/7790475acd183e183725d0ae04833334.png" alt="drawing" width="200"/>
	<img src="https://i2.paste.pics/a73e2f3242add3d8073722a2c6927441.png" alt="drawing" width="200"/>
	<img src="https://i2.paste.pics/67b1fb145052f4e65c5763c6c1059f6f.png" alt="drawing" width="200"/>
	<img src="https://i2.paste.pics/5851051cc90f55e5d799c1b8dc7c8a18.png" alt="drawing" width="200"/>
</p>


###  How to install
- #### Option 1: From .apk or .ipa:
This app is not available in the App store or Play store, please read [About the app](https://spartial.app/about) to find out why. Thus, you'll have to install the app by means of its [.apk](https://github.com/Ruud14/Spartial/releases/download/Android/Spartial.apk) or .ipa (might come soon) file. 

- ####  Option 2: From source code
Building the app from the source code is also possible. Besides the fact that I expect you to know how to [build a flutter app from source](https://docs.flutter.dev/deployment/android#build-an-apk), the setup process differs in a couple of ways, one of which is:
-- You'll have to create your own custom SHA1 fingerprint and put that in the Spotify developer dashboard (see [here](https://spartial.app/setup)) instead of the one I provided. [This](https://stackoverflow.com/questions/51845559/generate-sha-1-for-flutter-react-native-android-native-app) might help you generate your SHA1 fingerprint.

###  How to set up
After installing the app, you'll need a client ID to continue.
This client ID can be obtained in two ways described [here](https://spartial.app/setup).


### Battery optimization
Spartial needs to stay active even when the app isn't open. This is only possible when battery optimization has been disabled. Otherwise, the OS will kill the app when it is idle. 

### Foreground Notification
As mentioned before, Spartial needs to stay active even when the app isn't open. This is possible using a [foreground task](https://developer.android.com/guide/components/foreground-services). This foreground task has an ongoing notification. **This notification can be disabled. Instructions on how to do this can be found in the app** by going to *Settings > Hide Spartial notification*.

### About the app
I initially started this project for personal use only. (That's why this repo has so few [commits](https://github.com/Ruud14/Spartial/commits/master)) However, I soon realized that more people had requested Spartial's functionality as a native Spotify feature.  
This led to me researching about whether I could publish this app in the App Store and Play Store (Without having to manually enter the client ID). To my disappointment, this wasn't possible due to restrictions in the Spotify developer policy.  
However, I still wanted to publish my work, even if it's just for educational purpose.

### Report a bug / Request a feature
Found a bug? Please report it [here](https://github.com/Ruud14/Spartial/issues).



### NOTES: 
- This app is currently only available on Android, iOS might come soon.
- This app is for educational purpose only!
