# Installation instructions for Kateri: October 2024

## Dependencies
- cocoapods ~= 1.15
- flutter ~= 3.3
- xcode - currently running on xcode 16
- Rosetta 2

## Installation instructions (macos)
 NB: Kateri doesn't work on the most recent flutter versions, so an older verion is used

### Installing flutter
- Navigate to the [Flutter SDK archive](https://docs.flutter.dev/release/archive)
- select macOS Stable channel
- download version 3.3.0 (arm64)
- run the following command to creat a directory in the home directory:
```
mkdir ~/development
```
- Unzip flutter
- Run the following command:
```
mv Downloads/flutter ~/development
```
- Add the following line to your .zshrc file uing ```nano ./zshrc```:
```
export PATH=~/development/flutter/bin:$PATH
```
- Run ```source ~/.zshrc```

### XCode setup
- Download latest XCode using the App Store 
- Install xcode and move it to your applications folder if necessary
- Click xcode menu select settings and from the components menu "get" iOS 
- Run the following and agrree to the license
```
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
```

### Install cocoapods
- Run the following (install brew if you have not alread following instructions here: [install brew](https://brew.sh)
```
brew install cocoapods
```
### Checking flutter Installation
- run ```flutter doctor```
- Errors and warnings in Android and Chrome are fine

### Installing Kateri
- enter the Kateri directory
- run the following:
```
flutter build macos
```

# Kateri setup
- To run the app run the following command in terminal from the kateri directory:
```
./build/macos/Build/Products/Release/kateri.app/Contents/MacOS/kateri
```
- .ace files can then be opened and viewed in the app

## Automatically running Kateri from other scripts
- create a simple shell script (e.g. "kateri.sh") containing the following (modified to be your path to the kateri folder):
```
#! /bin/sh
exec ${HOME}/kateri/build/macos/Build/Products/Release/kateri.app/Contents/MacOS/kateri "$@"
```
- run ```sudo chmod 755 'kateri.sh'``` on the script to allow you to run it
- Add it to your PATH variable by running ```nano ~/.zshrc``` and adding the following where "path/to" is replaced with the path to you kateri.sh script
```
export PATH=path/to/kateri.sh:$PATH
```
- Run ```source ~/.zshrc```
