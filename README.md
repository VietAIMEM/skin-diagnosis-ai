# SkinAI — On-Device Skin Lesion Analysis AI Chatbot

SkinAI is a Flutter application that analyzes skin lesion images **entirely on-device**
using ONNX EfficientNet-B0 models, then explains the result conversationally through a
user-configured external LLM API (OpenRouter).

No custom backend server is required. The image classification runs locally; the only
external service is the LLM API that turns the structured model prediction into a
natural-language explanation.

---

## Architecture

```
Flutter UI
→ local image preprocessing
→ local ONNX inference
→ structured skin-lesion prediction
→ optional user profile / context
→ prompt builder
→ user's external LLM API
→ chatbot response
```

- **ONNX models** run on the smartphone via `onnxruntime_v2`.
- **LLM API** (OpenRouter, OpenAI-compatible) is the only external AI service.
- All data (profile, chat history, API key) stays on-device.

## Features

- Conversational AI chat interface as the primary screen
- Take a photo or pick an image from the gallery
- Local image preprocessing + ONNX inference (EfficientNet-B0, 224×224)
- 7-class prediction with confidence and detailed probability breakdown
- Model selection: **Smartphone Optimized** (default), **Baseline**, or **Compare Both**
- Diagnosis card + detailed results screen with all class probabilities
- Optional personal profile (age, sex, lesion location) to personalize explanations
- Configurable external LLM provider (OpenRouter), model, and temperature
- API key stored securely with `flutter_secure_storage`
- Local chat history (SQLite) with "Clear Chat History"
- Light/dark theme, English/Vietnamese language preference
- Full medical disclaimer and error handling — works offline for image analysis

## Class Mapping

The models predict one of 7 classes, in this exact order:

| Index | Class  |
|-------|--------|
| 0     | akiec  |
| 1     | bcc    |
| 2     | bkl    |
| 3     | df     |
| 4     | mel    |
| 5     | nv     |
| 6     | vasc   |

## Project Structure

```
appskincancer/
├── mota.md                  # Task specification
├── skincancer.ipynb         # Model training notebook
├── my_app/                  # Flutter application
│   ├── lib/
│   │   ├── app/             # App shell, routing, theme
│   │   ├── models/          # ChatMessage, DiagnosisResult, UserProfile, LlmConfig
│   │   ├── providers/       # Riverpod providers / controllers
│   │   ├── screens/         # Onboarding, chat, diagnosis, settings
│   │   ├── services/
│   │   │   ├── onnx/        # Preprocessing, inference, model manager
│   │   │   ├── llm/         # OpenRouter service, prompt builder
│   │   │   ├── storage/     # Secure storage, preferences, SQLite
│   │   │   └── camera/      # Image acquisition
│   │   ├── widgets/         # Chat bubbles, diagnosis card, confidence bars
│   │   └── utils/
│   ├── assets/models/       # Mobile ONNX models (bundled in the APK)
│   └── test/                # Unit tests
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x (stable)
- Android toolchain (for Android builds)
- An OpenRouter API key (or any OpenAI-compatible provider)

### Run the app

```bash
cd my_app
flutter pub get
flutter run
```

### Build an APK

```bash
cd my_app
flutter build apk --debug
flutter build apk --release
```

The release APK output is located at `my_app/build/app/outputs/flutter-apk/app-release.apk`.

## Configuration

1. Launch the app. On first run, complete (or skip) the optional onboarding.
2. Open **Settings → AI Provider**.
3. Enter your **API key** (stored securely on-device) and choose a **model**.
4. Optionally set the temperature and select the analysis model
   (Smartphone Optimized / Baseline / Compare Both).

Without an API key the app still works: image analysis runs locally, and only the
natural-language explanation requires an internet-connected LLM.

## Testing

```bash
cd my_app
flutter test
```

## Medical Disclaimer

This application is an **AI-assisted image classification tool**. It is **not** a
medical diagnosis. Results can be incorrect, and the AI explanation does not replace
professional examination. Always consult a qualified healthcare professional for any
medical concern. A full disclaimer is available inside the app under
**Settings → Medical Disclaimer**.

## License

All rights reserved. This project is for educational and research purposes only.
