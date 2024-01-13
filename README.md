# AmpFin
Introducing AmpFin, a sleek and intuitive native music client for the Jellyfin media server meticulously crafted for iOS 17, utilizing the power of SwiftUI. AmpFin offers a seamless and intuitive user experience, ensuring optimal performance and functionality.

- **Online & Offline Playback**: Enjoy your favorite tunes anytime, whether you're connected or offline.
- **Explore Artists**: Dive into your music collection effortlessly by browsing through artists.
- **Discover Albums**: Navigate through your albums with ease, enhancing your music exploration.
- **Enjoy your Playlists**: Playlists are fully supported - online & offline
- **Search Your Library**: Quickly find your favorite tracks with our intuitive library search feature.
- **Queue with History**: Take control of your playback experience by creating queues and accessing your listening history.
- **Remote control**: Control AmpFin using another supported Jellyfin client or just take over control of one right inside the app
- **Siri / Spotlight integration**: Play your music using Siri and access your library through Spotlight
- **Automatic updates**: Updated a playlist / album? AmpFin will detect changes and update your downloaded items accordingly

## Roadmap

- tvOS application

## Screenshots

| Library | Album | Player | Queue |
| ------------- | ------------- | ------------- | ------------- |
| <img src="/Screenshots/Library.png?raw=true" alt="Library" width="200"/> | <img src="/Screenshots/Album.png?raw=true" alt="Album" width="200"/> | <img src="/Screenshots/Player.png?raw=true" alt="Player" width="200"/>  | <img src="/Screenshots/Queue.png?raw=true" alt="Queue" width="200"/> 

## Building the app yourself

**Install using your favorite Side loading tool**

Download and install the latest release \
*Please strip app extensions (widgets, siri support, ...), they will not work as intented see https://github.com/rasmuslos/AmpFin/issues/11*

**Build the app yourself**

1. Install Xcode
2. Change the bundle identifier
3. Connect your iPhone to your Mac
4. Enable developer mode
5. Select your iPhone as the target
6. Run the application

## Thanks to

Oskar Groth & João Gabriel: Great (https://cindori.com/developer/animated-gradient-2)[article] on fluid gradients in SwiftUI
Nuke: Much better LazyImage that SwiftUI
Starscream: Great WebSocket library for swift
UIImageColor (Felix Herrman Fork): Working Version for iOS 17 
