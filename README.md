# AmpFin

AmpFin is a music app designed to elevate your listening experience on iPhone and iPad. It seamlessly integrates with your Jellyfin server, bringing your entire music collection to life with a sleek, modern interface and intuitive features.
This app goes beyond just playing music. Dive deep into your library, explore by artist, or discover new favorites with AmpFin's powerful browsing tools.  Whether you're listening at home or on the go, AmpFin keeps you in control with offline playback, seamless integration with Siri and Spotlight, and a beautiful queue system.

## Features:

- **Uninterrupted Listening**: Enjoy online and offline playback. Download playlists and albums for seamless listening on the go, ensuring a great experience even without an internet connection.
- **Time-Synced Lyrics**: Sing along to your favorite songs with perfectly timed lyrics (requires Jellyfin 10.9+).
- **Siri & Spotlight Integration**: Effortlessly control AmpFin with Siri voice commands or access your music library through Spotlight search.
- **Effortless Search & Management**:  Search your library with ease using the intuitive search functionality. Create and manage playlists while online, keeping your music organized and accessible.
- **Beautiful Album Exploration**: Navigate your albums with a stunning interface, making browsing your music collection a delightful experience.
- **Deep Dive into Your Music**: Dive into your music collection and explore by artist. Discover new favorites or create instant mixes of your favorite artist's songs to rediscover your library in a fresh way.
- **Powerful Playback Control**: Create a custom playback queue and view your listening history, giving you complete control over your music journey.
- **Always Up-to-Date Playlists**: Added a track to a downloaded playlist? AmpFin automatically downloads it for you, keeping your music collection seamlessly synchronized.
- **Remote Control Flexibility**: Control AmpFin using another supported Jellyfin client or take control of one, offering flexibility for multi-device music management.
- **Track Your Listens**: AmpFin meticulously tracks your playback activity, accurately reporting start, progress, and stop times to your Jellyfin server. This ensures your listening habits are properly reflected and works seamlessly with plugins like the Listenbrainz integration.
- **Bitrate Settings**: Configure maximum bitrates for cellular and Wi-Fi streaming, as well as downloads.

## Download

<a href="https://apps.apple.com/app/apple-store/id6473753735?pt=126778919&ct=GitHub&mt=8" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1710288000" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;"></a>

The macOS app is still in "alpha". It is more or less a slightly tweaked iPadOS app. A native macOS app is planned. Downloads will be available soon™️

## Screenshots

| Library | Album | Player | Lyrics |
| ------------- | ------------- | ------------- | ------------- |
| <img src="/Screenshots/Library%20(iOS).png?raw=true" alt="Library" width="200"/> | <img src="/Screenshots/Album%20(iOS).png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player%20(iOS).png" alt="Player" width="200"/>  | <img src="/Screenshots/Lyrics%20(iOS).png?raw=true" alt="Lyrics" width="200"/> 
| <img src="/Screenshots/Tracks%20(iPadOS).png?raw=true" alt="Tracks" width="200"/> | <img src="/Screenshots/Album%20(iPadOS).png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Queue%20(iPadOS).png?raw=true" alt="Queue" width="200"/>  | <img src="/Screenshots/Lyrics%20(iPadOS).png?raw=true" alt="Lyrics" width="200"/> 

## Sideload

### Pre-built

Grab the latest release of AmpFin from [here](https://github.com/rasmuslos/AmpFin/releases/latest) and install it using your favorite sideloading tool like SideStore.

> [!WARNING]
> Pre-built versions of AmpFin lack Siri support due to limitations with sideloading tools. These features require a paid developer account or can't be reliably implemented for sideloaded apps. See [this issue](https://github.com/rasmuslos/AmpFin/issues/11) for more information.

Stripping app extensions is highly recommended as they won't function correctly when sideloaded. 

### Build AmpFin Yourself

If you're comfortable with Xcode, you can build AmpFin yourself:

1. Install Xcode on your Mac.
2. In the `Configuration` directory, copy the `Debug.xcconfig.template` file and rename it to `Debug.xcconfig`.
3. Edit `Debug.xcconfig`:
    * Change `DEVELOPMENT_TEAM` to your Apple developer team ID.
    * Set a unique `BUNDLE_ID_PREFIX` (e.g., me.yourname).
4. If you don't have a paid developer account, remove the `ENABLE_ALL_FEATURES` compilation condition to avoid crashes. You can also remove the `DEBUG` flag if you don't intend on further development.
5. Connect your iPhone to your Mac and enable developer mode.
6. Select your iPhone as the run destination in Xcode.
7. Run the application.

> [!NOTE]
> The `DEBUG` configuration is used by default for most builds. To create a release build for distribution (which isn't allowed under the license), you'll need to edit the `Release.xcconfig` file.

## Licensing & Contributing

AmpFin is licensed under the Mozilla Public License Version 2 with the "Common Clause" addition. This means you can modify and contribute to AmpFin, but distributing the application in binary form is not allowed. Compiling for your own use is okay, and pre-built versions are available for sideloading.

### Contributing:

Contributions are welcome! Just fork the repository and open a pull request with your changes. 

* To translate AmpFin, edit `Localizable.xcstrings` in the `iOS` directory and `Localizable.xcstrings` within `Widget Extension` using Xcode.
* To add a new language, include it in the project settings.

### Coding Style:

* Match the existing code style.
* Use a 4 unit grid system for layouts
* Avoid using `padding()` without parameters; it has unpredictable behavior.

## Miscellaneous

- AmpFin is not endorsed by nor associated with Jellyfin
- I generated some parts of this readme using Gemini, sue me
