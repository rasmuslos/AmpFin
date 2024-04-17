# AmpFin

Introducing AmpFin, a sleek and intuitive native music client for the Jellyfin media server meticulously crafted for iOS / iPadOS 17, utilizing the power of SwiftUI. AmpFin offers a seamless and intuitive user experience, ensuring optimal performance and functionality.

- **Online & Offline Playback**: Enjoy your favorite tunes anytime, whether you're connected or offline.
- **Explore Artists**: Dive into your music collection effortlessly by browsing through artists.
- **Discover Albums**: Navigate through your albums with ease, enhancing your music exploration.
- **Enjoy your Playlists**: Playlists are fully supported - online & offline
- **Search Your Library**: Quickly find your favorite tracks with our intuitive library search feature.
- **Queue with History**: Take control of your playback experience by creating queues and accessing your listening history.
- **Remote control**: Control AmpFin using another supported Jellyfin client or just take over control of one right inside the app
- **Siri / Spotlight integration**: Play your music using Siri and access your library through Spotlight
- **Automatic updates**: Added a track to a downloaded playlist? AmpFin will download it automatically

## Download

<a href="https://apps.apple.com/de/app/ampfin/id6473753735?itsct=apps_box_badge&amp;itscg=30200" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1710288000" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;"></a>

The macOS app is still in "alpha". It is more or less a slightly tweaked iPadOS app. A native macOS app is planned. Downloads will be available soon™️

## Roadmap

Things to implement before i would consider AmpFin feature complete:

- Shortcuts
- 10.9 & lyrics support
- Update cover images of downloaded items
- Improve downloads by storing their file extension (currently blocked by a migration bug in SwiftData)

### iOS

- CarPlay integration
- Tweak now playing animation
- Widgets (No idea what purpose they could serve but there may be some)

### iPadOS

- Improve search experience

### Planned platforms

- tvOS (not planned until tvOS 18)
- macOS

### Things that are not possible due to a lack of APIs provided by Apple:

- Journal integration
- Now playing widget suggestions
- HomePod (possible but require a centralized server)

## Screenshots

| Library | Album | Player | Queue |
| ------------- | ------------- | ------------- | ------------- |
| <img src="/Screenshots/Library.png?raw=true" alt="Library" width="200"/> | <img src="/Screenshots/Album.png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player.png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/Queue.png?raw=true" alt="Queue" width="200"/> 
| <img src="/Screenshots/Tracks%20(iPad).png?raw=true" alt="Tracks" width="200"/> | <img src="/Screenshots/Album%20(iPad).png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player%20(iPad).png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/Artists%20(iPad).png?raw=true" alt="Artists" width="200"/> 

## Sideload

**Pre built binaries**

Grab the [latest Release](https://github.com/rasmuslos/AmpFin/releases/latest) and install it using your favorite tool like SideStore.

Please not that the pre build binaries lack Siri support because these features either require a paid developer account or cannot be reliably implemented in a way that works with tools like SideStore. For further information see https://github.com/rasmuslos/AmpFin/issues/11

Stripping app extensions is highly recommended, they will not work as intended.

**Build the app yourself**

1. Install Xcode
2. In the `Configuration` directory copy the `Debug.xcconfig.template` file and rename it to `Debug.xcconfig`
3. Change the `DEVELOPMENT_TEAM` to your apple developer team id and `BUNDLE_ID_PREFIX` to a prefix of your liking
4. If you do not have a paid developer account remove the `ENABLE_ALL_FEATURES` compilation condition. Otherwise the app will crash. If you do not intent on developing the app also remove the `DEBUG flag`
5. Connect your iPhone to your Mac & enable developer mode
6. Select your iPhone as the run destination
7. Run the application

Please not that the `DEBUG` configuration is used by default for all builds except archiving and profiling. You have to edit `Release.xcconfig` to update their parameters.

## Licensing & Contributing

AmpFin is licensed under the Mozilla Public License Version 2. Additionally the "Common Clause" applies. This means that you can modify AmpFin, as well as contribute to it, but you are not allowed to distribute the application in binary form. Compiling for your own personal use is not covered by the commons clause and therefore fine. Additionally, prebuilt binaries are available on GitHub for side loading using popular tools like SideStore, etc.

Some notes:

- Try to match the current code style
- All spacing, especially to the sides, should be `20` units. Scrollable items should have a gap of `10` units, non scrollable ones `20`, too. Do not use `padding()` without any parameters, it has "smart" behavior, meaning that the padding is all over the place.
To give a fun example: more or less everything had a padding of `19` units, so most things were _slightly_ of, relative to the toolbar at least.

Distributing your binaries to your friends and family is allowed. The same goes for development builds.

Contributions are welcome, just fork the repository, and open a pull request with your changes. If you want to contribute translations you have to edit `Localizable.xcstrings` in the `iOS` directory, as well as `Localizable.xcstrings` located at `Widget Extension` using Xcode. If you want to add a new language add it in the project settings

## Miscellaneous

AmpFin is not endorsed by nor associated with Jellyfin
