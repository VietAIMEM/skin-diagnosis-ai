# SkinAI — On-Device Skin Lesion Analysis AI Chatbot

The project runs entirely on the user's smartphone and does not require a hosting service or custom backend server. Users can use the application solely for local skin lesion image prediction without an internet connection. The chatbot functionality is optional and requires the user to manually provide an LLM API key, such as an OpenRouter API key.

SkinAI is a Flutter application that analyzes skin lesion images **locally on the user's device** using ONNX-based EfficientNet-B0 models. The local models perform the actual image classification, while an optional external LLM API is used to generate a natural-language, conversational explanation of the model's prediction.

The application therefore supports two main usage modes:

* **Image Analysis Mode** — Runs entirely on-device using the bundled ONNX models. No API key, hosting service, or internet connection is required.
* **AI Chatbot Mode** — Uses the local image-analysis result together with the user's conversation and optional profile information to generate an explanation through a user-configured external LLM API such as OpenRouter.

No custom backend server is required for either mode.

---

## Review
<img width="1080" height="2263" alt="1" src="https://github.com/user-attachments/assets/3cbe23ee-125c-4aad-bb9d-a78419fcaef9" />
<img width="1080" height="2133" alt="2" src="https://github.com/user-attachments/assets/85b94bc6-51b5-4f48-bad7-210ea91d0dd8" />

---

## Table of Contents

* [Project Status](#project-status)
* [Architecture](#architecture)

  * [Main Components](#main-components)
* [Models](#models)

  * [Model Architecture](#model-architecture)
  * [Available Models](#available-models)
  * [Model Selection](#model-selection)
* [Image Preprocessing](#image-preprocessing)
* [Class Mapping](#class-mapping)
* [Features](#features)

  * [AI Chatbot](#ai-chatbot)
  * [Skin Lesion Image Analysis](#skin-lesion-image-analysis)
  * [Diagnosis Result](#diagnosis-result)
  * [LLM Explanation](#llm-explanation)
* [User Profile](#user-profile)
* [Onboarding](#onboarding)
* [LLM Provider](#llm-provider)
* [Data Flow and Privacy](#data-flow-and-privacy)
* [Offline Behavior](#offline-behavior)
* [Local Storage](#local-storage)

  * [Secure Storage](#secure-storage)
  * [Preferences](#preferences)
  * [SQLite](#sqlite)
* [Settings](#settings)

  * [Personal Information](#personal-information)
  * [AI Provider](#ai-provider)
  * [Diagnosis](#diagnosis)
  * [Application](#application)
  * [About](#about)
* [Language Support](#language-support)
* [Theme](#theme)
* [Medical Disclaimer](#medical-disclaimer)
* [Getting Started](#getting-started)

  * [Prerequisites](#prerequisites)
* [Run the Application](#run-the-application)
* [Build APK](#build-apk)
* [Configuration](#configuration)
* [Testing](#testing)
* [License](#license)

---

## Project Status

SkinAI is designed as a single Flutter application that integrates:

* On-device skin lesion image classification
* Smartphone camera and gallery input
* ONNX model inference
* Conversational AI
* User-configured LLM API
* Optional user profile information
* Local chat history
* Local settings and secure API-key storage

The main Flutter application is located in:

```text
my_app/
```

---

## Architecture

The application follows this architecture:

```text
                    Flutter App
                        │
             ┌──────────┴──────────┐
             │                     │
        Chat Interface        Camera / Gallery
             │                     │
             │                     ▼
             │              Image Preprocessing
             │                     │
             │                     ▼
             │               ONNX Runtime
             │                     │
             │          ┌──────────┴──────────┐
             │          │                     │
             │      Baseline            Smartphone
             │       Model              Augmented Model
             │          │                     │
             │          └──────────┬──────────┘
             │                     │
             │                     ▼
             │             Model Prediction
             │                     │
             │          ┌──────────┴──────────┐
             │          │                     │
             │     User Profile         Model Result
             │          │                     │
             │          └──────────┬──────────┘
             │                     │
             │                     ▼
             │              Prompt Builder
             │                     │
             └─────────────────────┤
                                   ▼
                           External LLM API
                                   │
                                   ▼
                            Chatbot Response
```

### Main components

* **Flutter UI** — chatbot, onboarding, settings, diagnosis results
* **ONNX Runtime** — runs the trained skin lesion models locally
* **Image preprocessing** — converts camera/gallery images into the same input format used during model training
* **Model prediction** — generates the 7-class probability distribution
* **Prompt Builder** — converts model results and optional user context into structured LLM input
* **External LLM API** — generates a conversational explanation
* **Local storage** — stores profile, settings, chat history, and API configuration locally

No custom backend server is required.

---

## Models

The project contains two trained models for mobile deployment:

```text
modelskincancer/
├── baseline_best_mobile.onnx
└── smartphone_augmented_mobile.onnx
```

They are bundled into the Flutter application under:

```text
my_app/assets/models/
```

### Model architecture

The models are based on:

```text
EfficientNet-B0
```

Input:

```text
1 × 3 × 224 × 224
```

Output:

```text
1 × 7
```

The application converts the model output into class probabilities and determines the highest-probability prediction.

### Available models

#### Baseline

```text
baseline_best_mobile.onnx
```

The baseline model trained using the standard training/augmentation pipeline.

#### Smartphone Optimized

```text
smartphone_augmented_mobile.onnx
```

The model trained with additional smartphone-like image augmentation and is the default model used by the application.

### Model selection

The application supports:

* **Smartphone Optimized** — default
* **Baseline**
* **Compare Both**

The comparison mode runs both models independently and displays their respective predictions and probability distributions.

The application does not apply an arbitrary probability-weighting formula between the two models.

---

## Image Preprocessing

The Flutter preprocessing pipeline must reproduce the preprocessing used during model training.

The pipeline is:

```text
Input Image
    ↓
Decode Image
    ↓
Convert to RGB
    ↓
Resize to 224 × 224
    ↓
Normalize
    ↓
Convert HWC → CHW
    ↓
Float32 Tensor
    ↓
ONNX Runtime
```

ImageNet normalization is used:

```text
Mean:
[0.485, 0.456, 0.406]

Std:
[0.229, 0.224, 0.225]
```

For each RGB channel:

```text
normalized = (pixel / 255.0 - mean) / std
```

The final tensor passed to the model is:

```text
[1, 3, 224, 224]
```

The application must preserve the same RGB channel order, image size, normalization, and tensor layout used during model training.

---

## Class Mapping

The models predict seven skin lesion classes in the following exact order:

| Index | Class   |
| ----: | ------- |
|     0 | `akiec` |
|     1 | `bcc`   |
|     2 | `bkl`   |
|     3 | `df`    |
|     4 | `mel`   |
|     5 | `nv`    |
|     6 | `vasc`  |

The mapping must remain consistent between:

* training
* ONNX export
* Flutter inference
* probability display
* LLM prompt generation

---

## Features

### AI Chatbot

The chatbot is the primary interface of the application.

Users can:

* Send normal text messages
* Ask questions about skin lesions
* Continue a conversation after image analysis
* Receive explanations generated by the configured LLM

The chatbot maintains recent conversation context when communicating with the LLM.

---

### Skin Lesion Image Analysis

Users can:

* Take a photo using the smartphone camera
* Select an image from the gallery
* Preview the image before analysis
* Run the trained model locally
* View the predicted class
* View confidence
* View the complete probability distribution

The original image does not need to be uploaded to the LLM.

---

### Diagnosis Result

After local inference, the application displays a diagnosis card containing:

* Image preview
* Predicted class
* Confidence
* Model used
* Probability distribution

Users can open a detailed result screen to inspect all seven classes.

Example:

```text
Prediction
mel

Confidence
82.4%

Probabilities

mel     82.4%
nv       7.1%
bkl      4.1%
bcc      3.1%
vasc     1.3%
akiec    1.2%
df       0.8%
```

---

### LLM Explanation

After local image analysis, the application creates a structured result containing information such as:

```json
{
  "model": "smartphone_augmented",
  "prediction": "mel",
  "confidence": 0.824,
  "probabilities": {
    "akiec": 0.012,
    "bcc": 0.031,
    "bkl": 0.041,
    "df": 0.008,
    "mel": 0.824,
    "nv": 0.071,
    "vasc": 0.013
  }
}
```

This structured information can be combined with:

* Optional user profile
* Recent conversation context

and sent to the user's configured LLM provider.

The LLM then generates a natural-language explanation that appears as a normal chatbot response.

The LLM is **not the image classification model** and must not be treated as the diagnostic authority.

---

## User Profile

The application optionally allows users to provide personal information during onboarding.

Current profile fields include:

* Age
* Sex
* Lesion location

All fields are optional.

Users can:

* Complete the profile during first launch
* Skip the onboarding information
* Add or edit the information later through Settings

The profile is used as contextual information for the LLM explanation and is not automatically used as an unvalidated replacement for the trained image-classification model.

---

## Onboarding

On the first launch, users are presented with an optional onboarding screen.

Users can:

```text
Enter personal information
        ↓
Save
        ↓
Chatbot
```

or:

```text
Skip
  ↓
Chatbot
  ↓
Settings
  ↓
Personal Information
```

The user is never required to provide personal information before using the application.

---

## LLM Provider

The application uses an external LLM API for conversational explanations.

The primary supported provider is:

```text
OpenRouter
```

The user provides their own API key.

The user can configure:

* API key
* LLM model
* Temperature

The application does not contain a hard-coded API key.

The API key is stored locally using:

```text
flutter_secure_storage
```

The key is never intentionally written to application logs.

---

## Data Flow and Privacy

The skin lesion image is processed locally by the ONNX model.

```text
Camera / Gallery
       ↓
Local preprocessing
       ↓
Local ONNX inference
       ↓
Prediction
```

The original image does not need to be sent to the external LLM.

For an LLM request, the application may send information such as:

* Model prediction
* Confidence
* Class probabilities
* Optional user profile information
* Relevant conversation history

This information is sent to the **LLM provider selected and configured by the user**.

Therefore:

* Image inference is performed locally.
* API keys are stored locally.
* User profile data is stored locally.
* Chat history is stored locally.
* LLM requests are sent to the user's configured external provider.

Users should review the privacy policy and data-handling practices of their selected LLM provider.

---

## Offline Behavior

The application can perform image analysis without an internet connection.

Available offline:

* Camera
* Gallery
* Image preprocessing
* ONNX inference
* Prediction
* Confidence/probability display
* Local chat history
* Settings

Internet is required for:

```text
LLM API requests
```

If the device is offline, the application can still display the local model prediction but cannot generate a new LLM explanation.

---

## Local Storage

The application stores data locally on the device.

### Secure Storage

Used for sensitive configuration such as:

```text
LLM API key
```

### Preferences

Used for application settings such as:

```text
Onboarding state
User profile
Selected model
Language
Theme
LLM configuration
```

### SQLite

Used for:

```text
Chat history
```

Users can clear local chat history from Settings.

---

## Settings

The Settings screen provides:

### Personal Information

* Age
* Sex
* Lesion location

### AI Provider

* LLM provider
* API key
* Model
* Temperature

### Diagnosis

* Smartphone Optimized
* Baseline
* Compare Both

### Application

* Language
* Theme
* Clear Chat History

### About

* Medical Disclaimer
* Application information

---

## Language Support

The application supports:

* English
* Vietnamese

The chatbot should respond in the language used by the user.

---

## Theme

The application supports:

* Light theme
* Dark theme
* System theme

---

## Medical Disclaimer

SkinAI is an **AI-assisted image classification and explanation tool**.

It is not a medical diagnosis and must not be used as a replacement for examination by a qualified healthcare professional.

The model prediction may be incorrect. The LLM explanation is based on the model output and available context and may also contain errors.

Users should consult a qualified healthcare professional for medical concerns, especially when a lesion changes in size, shape, color, or appearance, or when they have other concerning symptoms.

A full medical disclaimer is available inside the application under:

```text
Settings → Medical Disclaimer
```

---

## Getting Started

### Prerequisites

* Flutter SDK 3.x or compatible stable version
* Android SDK
* Android Studio / Android toolchain
* A physical Android device or Android emulator
* OpenRouter API key for LLM functionality

The ONNX image-analysis functionality does not require an API key.

---

## Run the Application

```bash
cd my_app
flutter pub get
flutter run
```

---

## Build APK

Debug build:

```bash
cd my_app
flutter build apk --debug
```

Release build:

```bash
cd my_app
flutter build apk --release
```

The release APK is generated at:

```text
my_app/build/app/outputs/flutter-apk/app-release.apk
```

---

## Configuration

After launching the application:

1. Complete or skip the optional onboarding.
2. Open **Settings**.
3. Open **AI Provider**.
4. Configure the LLM provider.
5. Enter your own API key.
6. Select the desired LLM model.
7. Configure the temperature if required.
8. Select the preferred skin-lesion analysis model.

Without an LLM API key, local image analysis remains available.

---

## Testing

Run Flutter tests:

```bash
cd my_app
flutter test
```

Run static analysis:

```bash
flutter analyze
```

Build the Android application:

```bash
flutter build apk --debug
```

Important model tests should verify:

* Image preprocessing
* Tensor shape
* RGB channel ordering
* ImageNet normalization
* ONNX model loading
* ONNX output shape
* Class mapping
* Softmax probability calculation
* Prediction selection
* Prompt generation
* LLM response parsing

Expected ONNX shapes:

```text
Input:
[1, 3, 224, 224]

Output:
[1, 7]
```

---



## License

All rights reserved.

This project is intended for educational and research purposes only.
