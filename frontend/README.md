# PoemVision AI - Flutter App

A Flutter mobile application for the PoemVision AI service that transforms images into beautiful poems using AI.

## Project Overview

PoemVision AI is a mobile app that allows users to upload images and generate customized poems based on the image content. The app analyzes the uploaded images and creates personalized poems in various styles.

## Features

- **Image Upload**: Capture photos with the camera or select from the gallery
- **AI-Powered Poem Generation**: Generate poems based on image analysis
- **Multiple Poem Styles**: Choose from various poem types (sonnet, haiku, free verse, etc.)
- **User Authentication**: Register and login to save your creations
- **Poem Gallery**: View your previous poem creations
- **Share Functionality**: Share your poems with friends and family
- **Premium Membership**: Access to additional poem types and features

## Project Structure

```
lib/
├── config/           # App configuration files
│   └── app_router.dart   # Navigation routes with go_router
├── models/           # Data models
│   ├── user.dart         # User model
│   ├── creation.dart     # Poem creation model
│   └── membership.dart   # Membership plan model
├── screens/          # UI screens
│   ├── auth/             # Authentication screens
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── creation/         # Poem creation screens
│   │   └── create_poem_screen.dart
│   ├── gallery/          # Gallery screens
│   └── profile/          # User profile screens
├── services/         # Backend services
│   ├── api_service.dart      # API communication
│   ├── auth_service.dart     # Authentication management
│   └── creation_service.dart # Poem creation functionality
├── utils/            # Utility functions
├── widgets/          # Reusable UI components
└── main.dart         # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Android Studio / Xcode for emulators

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd poemvisionai-flutter
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```

## Development Notes

- The app uses Provider for state management
- Go Router is used for navigation
- Flutter Secure Storage is used for storing authentication tokens
- HTTP package is used for API communication

## API Integration

The app integrates with the PoemVision AI backend API to:
- Authenticate users
- Upload and analyze images
- Generate poems
- Manage user creations

## Future Improvements

- Implement offline mode
- Add more poem customization options
- Add language selection
- Implement advanced sharing features
- Add animations and transitions
