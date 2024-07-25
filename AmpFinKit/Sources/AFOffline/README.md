#  AFOffline

This package is responsible for everything offline:

- Caching actions until the device is online again
- Downloading and keeping track of items on device

All public methods work on the thread they are executed on and will block it. No `async` operations occur, so everything stays on the same thread.  
