How to Install and Run Flutter to Test the App

Installing Flutter

Windows:

Download Flutter SDK: Flutter Installation

Extract the zip file to a directory (e.g., C:\flutter)

Add Flutter to the system path by running this command in PowerShell:

[System.Environment]::SetEnvironmentVariable("Path", $Env:Path + ";C:\\flutter\\bin", [System.EnvironmentVariableTarget]::Machine)

Verify the installation by running:

flutter doctor

Mac:

Install Flutter using Homebrew:

brew install --cask flutter

Verify installation:

flutter doctor

Install Dependencies

Required Tools:

Dart SDK (Included with Flutter)

Android Studio (For Android development and emulator setup)

Xcode (For iOS development and iOS simulator)

Set Up Emulator or Physical Device

Android Emulator:

Open Android Studio

Click on the three dots on the top-right corner

Go to Virtual Device Manager

Click Create Virtual Device

Select a device (e.g., Pixel 9 Pro)

Continue with the default settings

Start the emulator before running the app

iOS Simulator:

Install Xcode from the App Store

Open the simulator with:

open -a Simulator

Clone the Repository

git clone <your-repository-url>
cd playiq

Install Flutter Packages

Run the following command in VS Code, PowerShell, or Terminal:

flutter pub get

Run the App

Start the application with:

flutter run

The app will begin building. This process may take some time. Once completed, the app should launch successfully!
