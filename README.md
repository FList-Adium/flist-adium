# F-List Adium
**Version:** 1.7  
**Minimum Adium Version:** 1.5.9

This plugin is made for use with Adium, a multi-protocol IM client for Mac OS X. You can find it [here](http://www.adium.im).

## Version History
### 1.7.2

+ Removed EGOCache; incompatible with 10.6
+ Fixed some memory management issues with 10.6
+ Added a search field to filter Room List

### 1.7.1

+ Fixed /bottle and /roll commands

### 1.7

+ Reimplemented icon-loading code (uses EGOCache, throttled)
+ Fixed bug where outgoing advertisements wouldn't be shown in the chat window, even if they successfully sent.

### 1.6

+ Updated Websocket code to be compliant with Hybi websockets.
+ Removed deprecated WSH handshake.
+ Disabled chatroom icon loading code.

### 1.5.3

+ Fixed a bug where newlines wouldn't be sent in outgoing messages.

### 1.5.2

+ Internal bugfixes

### 1.5.1

+ Fixed a bugs with the Join Chat view/Room Browser.

### 1.5

+ Added Room Browser
+ Re-added status sync.

### 1.4

+ Updated for 1.5.6
+ Fixed compatibility with 10.6 (disabled autolayout on xib files)
+ Added status integration.

### 1.0 - 1.3

+ Initial versions done by Maou.

## Known Issues

+ Links to channels within chats don't work. This is done via a Pidgin-specific API in the Pidgin plugin, and I'm not sure how to do something like it in Adium. You can still join the channel by finding it in the list of channels for the Join Channel window.

## Installation
Open the plugin bundle. Adium should automatically open and install it for you.

## Building
The build system is fairly straightforward. What you'll need:

+ Xcode 4+ (only the latest version is ever tested, though)
+ A copy of the Adium source
+ Adium!

First, you have to build a Release copy of Adium. To do this, open up the Adium Xcode project and click `Product > Build For > Archiving`. You can also do the regular build if you desire.

That should get the necessary Adium frameworks built for the plugin to link against. From there, open up the F-List Plugin Xcode project. Click on the 'F-list' project and go to the Target's build settings as shown:

![Build Settings](https://github.com/FList-Adium/flist-adium/raw/master/doc/screenops.png)

Alter the variable shown at the bottom (ADIUM) to point to the location of the Adium source directory (which will have a symlink to the build directory containing the frameworks).

From there, it's as simple as building. It's suggested to build for release when you plan on releasing a plugin, and additionally, it's recommended you use a Debug build of Adium for debugging the plugin.

The plugin is located by default in a 'Derived Objects' directory within the Libraries folder. To get the plugin once built, scroll to the bottom of the Project Explorer and find the plugin under 'Products'. Right click it, and click 'Show in Finder'. This will reveal the plugin (usually the Debug version). To get to the release version, press Command-Up to go to the parent directory, then go into the Release folder to find the plugin.

## Credits

Uses [EGOCache](https://github.com/enormego/EGOCache) for avatar data caching.

Libpurple code is from [flist-pidgin](https://code.google.com/p/flist-pidgin/).

Websocket code is an edited version of [libwsclient](https://github.com/payden/libwsclient).
