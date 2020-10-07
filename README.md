# EmergencyApp

This application. written in Flutter, completes the following [task](https://github.com/WebClub-NITK/DSC-NITK-Recruitments-2020/blob/master/RECRUITMENT_TASKS_2020.md#task-id-alarming_system_mobile_app)

## Tech Stack

* Flutter                         -> Framework in which the app is built
* Firebase Core                   -> Core files of Firebase plugin
* Firebase Analytics              -> Firebase analytics to analyze user behaviour
* Firebase Auth                   -> Firebase authentication, to enable Google Sign In
* Google Sign In                  -> Google Sign In, authentication provider for Firebase Authentication
* Font Awesome Flutter            -> Font Awesome icons made available in Flutter
* Flutter SpinKit                 -> Flutter plugin of SpinKit, for loading animations 
* Contacts Service                -> Phonebook handler
* Permission Handler              -> Handles permission 
* Multi Select Item               -> Facilitates selection of multiple widgets, for contacts selection
* SQFlite                         -> Local DB provider
* URL Launcher                    -> Launch URLs from within the app, dependency of Flutter SMS
* Path provider                   -> Path provider package for providing path to database
* Flutter SMS                     -> Plugin to facilitate forming a group and sending SMS

## Installation

* Install [flutter](https://flutter.dev/docs/get-started/install)
* Clone repository into your local system.
* After cloning the repo, run the `pub get` in the root directory.
* You can build the apk (or) run the application, but will not be able to test out the feature, since the SHA-1 certificate needs to be registered in Firebase Console(for enabling authentication), and needs to be updated in `google-services.json`.

## Introduction

* The app is written in Flutter and uses the above mentioned packages to implement the functionality.
* The app accepts contacts selected by users and stores them locally, to message them during distress with a message template added by user(locally stored).
* A user must login via a Google Account, to be able to access the features of the app.

## Testing

* To test the app, enable installing applications from unknown sources in an Android phone.
* Download the [apk](app-release.apk).
* On successful download, click on install when prompted.
* On successful installation, open the application, and sign in using a Google account.
* Add contacts from the Add Contacts page, present in the drawer of the home screen.
* Add a template from the Add Template page, present in the drawer of the home screen.
* Click on the floating action button, present in the home screen, to send an SMS with the template stored, to all emergency contacts.
