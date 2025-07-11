# pitx

## Note: This project has yet to be tested on iOS devices as it requires a Mac to build an iOS application. [Learn more](https://docs.flutter.dev/get-started/install/macos/mobile-ios). Either get a hold of a physical Mac or rent one in the cloud.

## Prerequisites

- Flutter
- Android Studio (emulator for Android development). You can also use your own device for testing. [Learn more](https://docs.flutter.dev/platform-integration/android/setup#set-up-devices)
- Supabase account
- Twilio account

## Note: Credentials for all accounts are in MS Teams account self chats

## Setup Steps for Local Testing

1. Clone the repo

```
git clone https://github.com/pitxitojt/pitx-app.git
```

2. Create .env file in root project directory and enter Supabase credentials:

```
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

3. Set up your phone OTP provider (Twilio Verify, Vonage, etc.) in Supabase

4. Install dependencies

```
flutter pub get
```

## To run the app

```
flutter run
```

## To build apk

```
flutter build apk
```

- The generated apk will be located under `build/app/outputs/apk`

## Things to keep in mind

1. The Supabase account is only in free tier. [Limitations of a free account](https://supabase.com/pricing)
2. [Twilio](https://console.twilio.com/) requires account verification before the app is able to send messages to any number. They request documents.
3. [Vonage](https://dashboard.nexmo.com/) is an alternative which does not request documents. However, you would need to top up to be able send to any number (costs minimum of 10 EUR).
4. There are two branches in this repo: `main` and `food`. In `main`, the food quick action redirects to the original **okpo.com/pitx** website as stated in the app guidelines (which can be found in MS Teams chat with Sir Ibarlin). In `food`, it redirects to **pitxfoodstaging.pitx.com.ph**, another project the previous intern was tasked to do. However, this site still needs further testing and pending payment integration.
