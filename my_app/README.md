# SkinAI Flutter App

SkinAI is a Flutter mobile application for on-device skin lesion image analysis and AI-assisted conversational explanations.

The application runs directly on the user's smartphone and does not require a custom backend server or hosting service.

Skin lesion image classification is performed locally using bundled ONNX models. An external LLM API, such as OpenRouter, is optional and is only required for the AI chatbot functionality.

---

## Table of Contents

* [Overview](#overview)
* [Features](#features)
* [Architecture](#architecture)
* [Requirements](#requirements)
* [Installation](#installation)
* [Run the Application](#run-the-application)
* [Build APK](#build-apk)
* [AI Provider Configuration](#ai-provider-configuration)
* [Skin Lesion Analysis](#skin-lesion-analysis)
* [Model Configuration](#model-configuration)
* [Local Storage](#local-storage)
* [Offline Mode](#offline-mode)
* [Project Structure](#project-structure)
* [Testing](#testing)
* [Privacy](#privacy)
* [Medical Disclaimer](#medical-disclaimer)
* [License](#license)

---

## Overview

The Flutter application provides two main functions:

### Image Analysis

Users can take a photo or select an existing image from the gallery. The image is processed and analyzed locally on the device using ONNX Runtime.

No internet connection or LLM API key is required for image prediction.

### AI Chatbot

Users can optionally configure their own LLM API key and use the chatbot to:

* Ask questions about skin lesions
* Discuss image-analysis results
* Receive natural-language explanations
* Continue conversations using previous context

The LLM does not perform the image classification itself. The local ONNX model produces the classification result, which is then provided as structured context to the configured LLM.

---

## Features

* Flutter-based Android application
* On-device skin lesion image classification
* Camera image capture
* Gallery image selection
* ONNX Runtime inference
* EfficientNet-B0-based classification
* Seven-class skin lesion classification
* Confidence and probability display
* Baseline and smartphone-optimized models
* Model comparison
* AI chatbot
* User-configured LLM API
* OpenRouter integration
* Secure API-key storage
* Optional user profile
* Local chat history
* SQLite storage
* English and Vietnamese language support
* Light and dark themes
* Offline image analysis
* Medical disclaimer

---

## Architecture

```text
                    Flutter Application
                            │
             ┌──────────────┴──────────────┐
             │                             │
        Chat Interface              Camera / Gallery
             │                             │
             │                             ▼
             │                    Image Preprocessing
             │                             │
             │                             ▼
             │                       ONNX Runtime
             │                             │
             │                  ┌──────────┴──────────┐
             │                  │                     │
             │              Baseline           Smartphone
             │               Model             Optimized
             │                                     Model
             │                  │                     │
             │                  └──────────┬──────────┘
             │                             │
             │                             ▼
             │                     Model Prediction
             │                             │
             │                  ┌──────────┴──────────┐
             │                  │                     │
             │             User Profile         Prediction
             │                  │                     │
             │                  └──────────┬──────────┘
             │                             │
             │                             ▼
             │                       Prompt Builder
             │                             │
             └─────────────────────────────┤
                                           ▼
                                  External LLM API
                                           │
                                           ▼
                                    Chatbot Response
```

The complete application runs inside this Flutter project.

No custom backend server is required.

---

## Requirements

Before running the application, install:

* Flutter SDK 3.x or compatible stable version
* Dart SDK included with Flutter
* Android SDK
* Android Studio
* Android SDK Platform Tools
* Android device or Android emulator

Verify the Flutter environment:

```bash
flutter doctor
```

---

## Installation

Clone the repository and enter the Flutter project:

```bash
cd my_app
```

Install dependencies:

```bash
flutter pub get
```

Check the project:

```bash
flutter analyze
```

---

## Run the Application

Connect an Android device or start an Android emulator.

Check available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

For a specific device:

```bash
flutter run -d <device-id>
```

---

## Build APK

### Debug APK

```bash
flutter build apk --debug
```

### Release APK

```bash
flutter build apk --release
```

The release APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The debug APK will be generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

---

## AI Provider Configuration

The AI chatbot is optional.

Users must provide their own LLM API key to use the chatbot functionality.

### OpenRouter

Open the application and go to:

```text
Settings
    ↓
AI Provider
```

Configure:

* API key
* LLM model
* Temperature

The API key is stored locally using secure storage.

The application does not contain a hard-coded API key.

### Without an API Key

The application can still perform:

```text
Camera / Gallery
        ↓
Image Preprocessing
        ↓
ONNX Inference
        ↓
Prediction
        ↓
Confidence / Probabilities
```

Only the conversational LLM functionality requires an external API.

---

## Skin Lesion Analysis

The image-analysis pipeline is:

```text
Camera / Gallery
        ↓
Image Decode
        ↓
RGB Conversion
        ↓
Resize
        ↓
Normalization
        ↓
Tensor Conversion
        ↓
ONNX Runtime
        ↓
Model Prediction
        ↓
Probability Distribution
```

The models use an input size of:

```text
224 × 224
```

The input tensor is:

```text
[1, 3, 224, 224]
```

The model produces seven output classes.

### Class Mapping

| Index | Class   |
| ----: | ------- |
|     0 | `akiec` |
|     1 | `bcc`   |
|     2 | `bkl`   |
|     3 | `df`    |
|     4 | `mel`   |
|     5 | `nv`    |
|     6 | `vasc`  |

The application displays:

* Predicted class
* Confidence
* Probability for each class
* Selected model
* Image preview

---

## Model Configuration

The application contains two mobile ONNX models:

```text
assets/models/
├── baseline_best_mobile.onnx
└── smartphone_augmented_mobile.onnx
```

### Baseline

```text
baseline_best_mobile.onnx
```

The baseline model provides the standard classification result.

### Smartphone Optimized

```text
smartphone_augmented_mobile.onnx
```

The smartphone-optimized model is designed to improve robustness for images captured using smartphone cameras.

It is the default model used by the application.

### Model Selection

Users can select:

* **Smartphone Optimized**
* **Baseline**
* **Compare Both**

When **Compare Both** is selected, the application runs both models independently and displays their results.

---

## Local Storage

The application stores user data locally on the device.

### Secure Storage

Sensitive information such as the LLM API key is stored using:

```text
flutter_secure_storage
```

### Preferences

Application preferences include:

* Onboarding status
* User profile
* Selected model
* Language
* Theme
* LLM configuration

### SQLite

SQLite is used for local chat history.

Users can clear their stored conversation history from Settings.

---

## Offline Mode

The skin lesion image-analysis functionality works without an internet connection.

Available offline:

* Camera
* Gallery
* Image preprocessing
* ONNX inference
* Model prediction
* Confidence
* Probability distribution
* Local settings
* Local chat history

Internet access is required only when the application needs to communicate with the configured external LLM API.

---

## Project Structure

```text
my_app/
│
├── android/
├── ios/
├── lib/
│   ├── app/
│   │   ├── app.dart
│   │   ├── routes.dart
│   │   └── theme.dart
│   │
│   ├── models/
│   │   ├── chat_message.dart
│   │   ├── diagnosis_result.dart
│   │   ├── user_profile.dart
│   │   └── llm_config.dart
│   │
│   ├── providers/
│   │   └── ...
│   │
│   ├── screens/
│   │   ├── onboarding/
│   │   ├── chat/
│   │   ├── diagnosis/
│   │   └── settings/
│   │
│   ├── services/
│   │   ├── onnx/
│   │   ├── llm/
│   │   ├── storage/
│   │   └── camera/
│   │
│   ├── widgets/
│   │   ├── chat_bubble.dart
│   │   ├── diagnosis_card.dart
│   │   ├── confidence_bar.dart
│   │   └── image_message.dart
│   │
│   └── utils/
│
├── assets/
│   └── models/
│       ├── baseline_best_mobile.onnx
│       └── smartphone_augmented_mobile.onnx
│
├── test/
├── pubspec.yaml
└── README.md
```

---

## Testing

Run unit and widget tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

Check formatting:

```bash
dart format .
```

The model-related tests should verify:

* ONNX model loading
* Image preprocessing
* RGB channel ordering
* Image normalization
* Tensor shape
* Model output shape
* Class mapping
* Probability calculation
* Prediction selection

The LLM-related tests should verify:

* API configuration
* API-key handling
* Prompt generation
* Request construction
* Response parsing
* Error handling

---

## Privacy

Skin lesion images are processed locally by the bundled ONNX models.

The original image does not need to be uploaded to the external LLM.

When the chatbot is used, the application may send the following information to the user's configured LLM provider:

* Model prediction
* Confidence
* Class probabilities
* Optional user profile information
* Relevant conversation context

The API key is stored locally using secure storage.

Users should review the privacy policy and data-handling practices of their selected LLM provider before using an external LLM service.

---

## Medical Disclaimer

SkinAI is an **AI-assisted image classification and explanation tool**.

It is not a medical diagnosis and must not be used as a replacement for professional medical examination.

Model predictions may be incorrect, and the LLM-generated explanation may also contain errors.

Users should consult a qualified healthcare professional for medical concerns.

The application provides a full medical disclaimer under:

```text
Settings → Medical Disclaimer
```

---

## License

All rights reserved.

This project is intended for educational and research purposes only.
