# Firebase Setup Guide

## Step 1: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `healthapp-1476a`
3. Go to **Authentication** → **Sign-in method**
4. Click on **Email/Password**
5. Enable **Email/Password** (first option)
6. Click **Save**

## Step 2: Get Web App Configuration

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps** section
3. If you don't have a web app, click **Add app** → **Web** (</> icon)
4. Register your app with a name (e.g., "Dr Appointment Web")
5. Copy the configuration object

## Step 3: Update Firebase Configuration

Replace the configuration in `lib/main.dart` with your actual web app config:

```dart
await Firebase.initializeApp(
  options: FirebaseOptions(
    apiKey: "your-actual-api-key",
    appId: "1:322698909833:web:your-actual-web-app-id",
    messagingSenderId: "322698909833",
    projectId: "healthapp-1476a",
    storageBucket: "healthapp-1476a.firebasestorage.app",
    authDomain: "healthapp-1476a.firebaseapp.com",
  ),
);
```

## Step 4: Test Authentication

After completing the above steps:
1. Run the app
2. Try logging in with the test accounts:
   - Doctor: `doctor@test.com` / `doctor123`
   - Patient: `patient@test.com` / `patient123`

## Common Issues:

- **400 Error**: Usually means Email/Password auth is not enabled
- **403 Error**: API key restrictions or domain not authorized
- **Network Error**: Check if authDomain is correct

## Quick Fix for Testing:

If you want to test immediately, you can temporarily use the Android app ID:
```dart
appId: "1:322698909833:android:b9824f18916db180eece58",
```
But this is not recommended for production.


