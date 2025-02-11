
# PlayIQ
CSCI 490 Project

How to Install and run flutter to test app

1) Installing flutter

    Windows: 
        1) Download Flutter SDK: https://docs.flutter.dev/get-started/install
        2) Extract the zip file ot a directory
        3) Add flutter to path running this command: [System.Environment]::SetEnvironmentVariable("Path", $Env:Path + ";C:\flutter\bin", [System.EnvironmentVariableTarget]::Machine)
        4) Verify by running: flutter doctor

    Mac:
        1) Install using: brew install --cask flutter
        2) verify: flutter doctor

2) Install Dependencies

    - Dart SDK(Should be included with Flutter)
    - Android Studio (for Android emulator)
    - Xcode (for ios dev)
    Should work for either emulator

3) Set up Emulator/Device
    Android:
        1) Install an Android emulator via Android Studio
            - I clicked on the 3 dots on the top right
                1) Went to virtual Device Manager
                2) Create Virtual Device
                3) Then I picked Pixel 9 Pro
                4) Continued with default settings
                5) Ran emulator before starting actual app
    ios:
        1) Installed Xcode via app store
        2) started it by using open -a Simulator

4) Clone Repo

5) Install Flutter Packages
    1) I ran this all in vsCode (Can be ran in powershell or terminal)
        flutter pub get

6) Run the App
    1) Start the app using:
        flutter run
    Should be building app so it will take some time
    2) App should launch!
