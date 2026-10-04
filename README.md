# village-tour-sri-lanka
A mobile application for exploring Sri Lankan village tourism, discovering homestays and local experiences, making bookings, communicating with hosts, and navigating village destinations.

## Setup Guide

This guide will help you open and run the **Village Tour Sri Lanka** Flutter application after cloning it from GitHub.

### Prerequisites

Before you begin, ensure you have the following installed on your system:
1. **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (Version 3.13.4 or higher)
2. **[Android Studio](https://developer.android.com/studio)** or **[Visual Studio Code](https://code.visualstudio.com/)** with the Flutter & Dart plugins installed.
3. An Android Emulator, iOS Simulator, or a physical device connected to your machine.

---

### Step-by-Step Instructions

#### 1. Open the Project
1. Open your preferred IDE (VS Code or Android Studio).
2. Go to **File > Open** (or **Open Folder** in VS Code).
3. Navigate to and select the `village-tour-sri-lanka` folder that you just cloned.

#### 2. Install Dependencies
Flutter relies on external packages defined in `pubspec.yaml`. You need to fetch these dependencies before running the app.
* **In VS Code/Android Studio:** Open the `pubspec.yaml` file and click the **Get Packages** or **Pub get** button that appears.
* **Via Terminal:** Alternatively, open your terminal (integrated in your IDE or external), navigate to the root folder of the project, and run:
  ```bash
  flutter pub get
  ```

#### 3. Verify Connected Devices
Ensure you have a device or emulator running to test the app.
In the terminal, run:
```bash
flutter devices
```
You should see your connected emulator or physical phone listed.

#### 4. Run the Application
You are now ready to build and run the app.
* **In VS Code:** Press `F5` or go to the Run and Debug view and click "Run".
* **In Android Studio:** Select your target device from the dropdown menu in the top toolbar and click the green **Run (Play)** button.
* **Via Terminal:** Run the following command:
  ```bash
  flutter run
  ```

---

### Additional Information
* **Firebase Configuration:** The app uses Firebase. The configurations (`firebase_options.dart`) are already included in the repository, meaning the app will connect to the existing Firebase project backend directly.
* **Cloudinary:** The image upload feature uses Cloudinary, and its credentials are also pre-configured in the app services (`cloudinary_service.dart`).
