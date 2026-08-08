# TASK: Build a Complete On-Device Skin AI Chatbot Flutter App

You are a senior Flutter/Dart engineer and mobile AI engineer.

Build a complete production-quality Flutter application for Android whose main purpose is to provide an AI chatbot that can analyze skin lesion images using locally deployed ONNX models and then use an external LLM API to explain the model's result conversationally.

The application MUST NOT require or depend on any custom backend server.

The application architecture is:

Flutter UI
→ local image preprocessing
→ local ONNX inference
→ structured skin-lesion prediction
→ combine prediction with optional user profile/context
→ prompt builder
→ user's configured external LLM API
→ chatbot response

The ONNX models must run entirely on the smartphone.

The LLM API is the only external AI service.

---

# 1. CORE REQUIREMENTS

Build one unified chatbot-style application.

The user should NOT feel like they are using a separate "image classification app".

The primary screen is a conversational AI chat interface.

The user can:

1. Chat normally with the AI.
2. Take a photo of a skin lesion.
3. Select an image from the gallery.
4. Run local ONNX inference.
5. See the prediction and confidence.
6. Send the structured prediction to the configured LLM.
7. Receive a natural-language explanation in the chat.
8. Continue discussing the result.
9. Configure personal information later.
10. Configure their own LLM API provider and API key.
11. Select which local ONNX model to use.
12. View detailed model probabilities.
13. Use the app without a backend server.

---

# 2. IMPORTANT ARCHITECTURE RULE

DO NOT create a custom backend.

DO NOT create:

* Node.js backend
* Python FastAPI backend
* Firebase backend
* Supabase backend
* PHP backend
* custom REST server

Everything except the external LLM request must run locally inside Flutter.

Architecture:

```text
                    FLUTTER APP
                         |
        +----------------+----------------+
        |                                 |
     CHAT UI                         CAMERA/GALLERY
        |                                 |
        |                                 v
        |                         IMAGE PREPROCESSING
        |                                 |
        |                                 v
        |                         ONNX RUNTIME
        |                                 |
        |                    +------------+------------+
        |                    |                         |
        |              Baseline ONNX          Smartphone ONNX
        |                    |                         |
        |                    +------------+------------+
        |                                 |
        |                                 v
        |                         MODEL PREDICTION
        |                                 |
        |                   +-------------+-------------+
        |                   |                           |
        |              User Profile              Model Result
        |                   |                           |
        |                   +-------------+-------------+
        |                                 |
        |                                 v
        |                           PROMPT BUILDER
        |                                 |
        +---------------------------------+
                                          |
                                          v
                                  EXTERNAL LLM API
                                          |
                                          v
                                    CHAT RESPONSE
```

---

# 3. ONNX MODELS

The project has two trained ONNX models:

```text
assets/models/baseline_best_mobile.onnx
assets/models/smartphone_augmented_mobile.onnx
```

The models are EfficientNet-B0 models.

Input:

```text
1 × 3 × 224 × 224
```

Output:

```text
1 × 7
```

Classes MUST use this exact order:

```text
akiec
bcc
bkl
df
mel
nv
vasc
```

Create a centralized class mapping.

Example:

```dart
const skinClasses = [
  'akiec',
  'bcc',
  'bkl',
  'df',
  'mel',
  'nv',
  'vasc',
];
```

Do NOT change the order.

---

# 4. IMAGE PREPROCESSING

The Flutter preprocessing pipeline MUST reproduce the training preprocessing.

Required pipeline:

```text
Image
↓
Decode
↓
Convert to RGB
↓
Resize to 224 × 224
↓
Normalize
↓
Convert HWC → CHW
↓
Float32 tensor
↓
ONNX Runtime
```

Use ImageNet normalization:

```text
mean:
0.485
0.456
0.406

std:
0.229
0.224
0.225
```

For every pixel:

```text
normalized = (pixel / 255.0 - mean) / std
```

The final tensor must be:

```text
[1, 3, 224, 224]
```

Do NOT accidentally use:

```text
[1, 224, 224, 3]
```

Do NOT use a different normalization.

Do NOT use grayscale.

Do NOT silently change RGB to BGR.

---

# 5. ONNX INFERENCE SERVICE

Create:

```text
lib/services/onnx/onnx_service.dart
```

Responsibilities:

* Load ONNX model.
* Create ONNX session.
* Preprocess image.
* Run inference.
* Convert output logits to probabilities.
* Find top prediction.
* Return a structured `DiagnosisResult`.

Create:

```text
lib/services/onnx/model_manager.dart
```

Responsibilities:

* Manage baseline model.
* Manage smartphone augmented model.
* Cache sessions.
* Dispose sessions properly.
* Allow switching models.

Create:

```text
lib/models/diagnosis_result.dart
```

Suggested structure:

```dart
class DiagnosisResult {
  final String modelName;
  final String predictedClass;
  final double confidence;
  final Map<String, double> probabilities;
  final DateTime timestamp;
}
```

Also include:

* original image path if appropriate
* inference duration
* model version/name
* optional second-model result

---

# 6. MODEL SELECTION

Default model:

```text
smartphone_augmented_mobile.onnx
```

because this app is designed for smartphone-captured images.

Settings should provide:

```text
Analysis Model

● Smartphone Optimized
○ Baseline
○ Compare Both
```

"Compare Both" should run both models and display:

```text
Smartphone Model
mel 82.4%

Baseline Model
mel 78.6%
```

Do not merge the two models into an arbitrary probability formula unless explicitly implemented as a validated method.

---

# 7. IMPORTANT FEATURE EXTRACTION CLARIFICATION

Do NOT send raw EfficientNet feature vectors to the LLM.

The current ONNX models output 7-class predictions.

Therefore the app should construct a structured result:

```json
{
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

This structured prediction is what should be passed to the LLM.

Call this:

```text
Image Analysis Result
```

rather than pretending the current ONNX output is a separate embedding/feature extractor.

---

# 8. ONBOARDING

When the user launches the app for the first time, show onboarding.

Example:

```text
Welcome to SkinAI

I can help you understand
skin lesion image analysis results.

You can optionally provide
some information to personalize
the conversation.

Age
[       ]

Sex
[ Select ]

Lesion Location
[ Select ]

              Continue

           Skip for now
```

The user MUST be able to skip.

Do not force personal information.

If the user skips:

```text
onboardingCompleted = true
```

and open the chatbot.

The user can later configure profile information from:

```text
Settings → Personal Information
```

---

# 9. USER PROFILE

Create:

```text
lib/models/user_profile.dart
```

Initial fields:

```text
age
sex
lesionLocation
```

Use nullable fields.

Example:

```dart
class UserProfile {
  final int? age;
  final String? sex;
  final String? lesionLocation;
}
```

Do NOT require:

```text
lesion_id
image_id
dx
dx_type
```

Those are dataset/training metadata and are not user profile fields.

Make the profile editable later.

---

# 10. MAIN CHAT SCREEN

The main screen must be a modern AI chatbot.

Example layout:

```text
┌──────────────────────────────────────┐
│ SkinAI                           ⚙️ │
├──────────────────────────────────────┤
│                                      │
│ AI                                   │
│ Hello! I can help explain skin       │
│ lesion image analysis results.       │
│                                      │
│                         User         │
│                         Hello        │
│                                      │
│ AI                                   │
│                         How can I    │
│                         help you?    │
│                                      │
│                                      │
├──────────────────────────────────────┤
│ 📷   Type a message...          ➤   │
└──────────────────────────────────────┘
```

Requirements:

* Message bubbles.
* User messages.
* Assistant messages.
* Loading indicator.
* Error messages.
* Scroll-to-bottom.
* Text input.
* Send button.
* Camera/gallery action.
* Image preview.
* Diagnosis result card.
* Markdown rendering for assistant messages if practical.

---

# 11. IMAGE INPUT

When user presses the image button:

Show:

```text
Take Photo
Choose from Gallery
Cancel
```

Use:

```text
camera
image_picker
```

After selecting an image:

```text
Image Preview

[ image ]

Analyze Image
Cancel
```

Do not immediately send the image to the LLM.

First run local ONNX inference.

---

# 12. IMAGE ANALYSIS FLOW

The complete flow must be:

```text
User taps camera
↓
Capture image
↓
Preview image
↓
User taps Analyze
↓
Local preprocessing
↓
ONNX inference
↓
Calculate probabilities
↓
Create DiagnosisResult
↓
Display result card
↓
Generate LLM prompt
↓
Send prompt to external LLM
↓
Receive response
↓
Display response as chat message
```

The image itself does NOT need to be uploaded to the LLM.

The LLM receives the model's structured prediction.

---

# 13. DIAGNOSIS CARD

After inference, insert a special chat card.

Example:

```text
┌───────────────────────────────────┐
│ 🔬 Image Analysis                 │
│                                   │
│ [ IMAGE ]                         │
│                                   │
│ Prediction                       │
│ Melanoma (mel)                   │
│                                   │
│ Confidence                       │
│ ████████████████░░░ 82.4%        │
│                                   │
│ Model                             │
│ Smartphone Optimized              │
│                                   │
│ View Detailed Results →           │
└───────────────────────────────────┘
```

The card should be visually distinct from normal chat bubbles.

---

# 14. DETAILED RESULT SCREEN

Create:

```text
lib/screens/diagnosis/diagnosis_result_screen.dart
```

Show:

```text
Analysis Result

Image

Top Prediction
mel
Melanoma
82.4%

All Predictions

mel   ████████████████ 82.4%
nv    ██                7.1%
bkl   █                  4.1%
bcc   █                  3.1%
vasc  ▏                  1.3%
akiec ▏                  1.2%
df    ▏                  0.8%

Model
EfficientNet-B0

Input
224 × 224

Model
Smartphone Augmented
```

Sort probabilities descending for display, but preserve the original class mapping internally.

---

# 15. LLM API CONFIGURATION

The user must provide their own API key.

Do NOT hard-code an API key.

Do NOT include your own API key.

Create:

```text
lib/models/llm_config.dart
lib/services/llm/llm_service.dart
lib/services/llm/openrouter_service.dart
```

Settings screen:

```text
AI Provider

Provider
[ OpenRouter ]

API Key
[ ••••••••••••••• ]

Model
[ model name ]

Temperature
[ 0.2 ]

Save
```

Use a provider abstraction so additional OpenAI-compatible providers can be added later.

Example:

```dart
abstract class LlmService {
  Future<String> sendMessage({
    required List<ChatMessage> messages,
  });
}
```

Implement:

```text
OpenRouterService
```

first.

Use HTTP HTTPS requests.

Do not create a custom backend proxy.

---

# 16. API KEY STORAGE

Use:

```text
flutter_secure_storage
```

for:

```text
API key
```

Do NOT store API keys in:

```text
SharedPreferences
```

Do NOT write the API key to logs.

Do NOT display the full API key.

Mask it in UI.

---

# 17. OPENROUTER

Implement OpenRouter as an OpenAI-compatible HTTP provider.

The service should:

* Read API key from secure storage.
* Read model name from settings.
* Build request.
* Send HTTPS request.
* Parse response.
* Handle HTTP errors.
* Handle timeout.
* Handle invalid API key.
* Handle rate limits.
* Handle no internet.
* Return clean error messages.

Do not assume a particular OpenRouter model is permanently available.

Make model name configurable.

Default model may be a placeholder or a commonly available model, but the user must be able to change it.

---

# 18. PROMPT BUILDER

Create:

```text
lib/services/llm/prompt_builder.dart
```

The LLM must be instructed that it is an explanation assistant, NOT the diagnostic authority.

Example system prompt:

```text
You are an AI assistant that explains the output
of a skin lesion image classification model.

You are NOT a doctor and must NOT claim that the
user definitely has a disease.

The classification model provides probabilistic
predictions only.

Your responsibilities:

1. Explain the model's predicted class in simple language.
2. Explain the confidence/probability.
3. Mention relevant alternative classes when useful.
4. Explain that image classification cannot replace
   professional medical examination.
5. Avoid definitive diagnosis.
6. Recommend professional dermatological evaluation
   when appropriate.
7. Be concise, calm, and understandable.
8. Never invent medical facts that are not supported
   by the provided information.
```

Then dynamically add:

```text
User profile:
Age: ...
Sex: ...
Lesion location: ...

Image analysis:
Model: ...
Prediction: ...
Confidence: ...

Class probabilities:
...
```

---

# 19. CHAT CONTEXT

The chatbot should maintain conversation context.

Example:

```text
User:
I have noticed this lesion for three months.

Assistant:
Has it changed in size or color?

User:
Yes, it became larger.

User:
[uploads image]

System:
Image analysis result = mel, confidence 82.4%

Assistant:
Based on the image classification model...
```

The LLM request should contain recent relevant conversation history.

Do not send unlimited history.

Implement a reasonable context limit.

---

# 20. CHAT MESSAGE MODEL

Create:

```text
lib/models/chat_message.dart
```

Support:

```text
user
assistant
system
image_analysis
```

Example:

```dart
enum MessageRole {
  user,
  assistant,
  system,
  imageAnalysis,
}
```

Messages should support:

```text
text
timestamp
optional imagePath
optional diagnosisResult
```

---

# 21. LOCAL CHAT HISTORY

The app should work without a backend.

Store chat history locally.

Prefer:

```text
SQLite
```

or a simple local persistence layer if the project is initially kept small.

Do not upload chat history to any custom server.

Provide:

```text
Settings
→ Clear Chat History
```

with confirmation.

---

# 22. SETTINGS

Create a modern settings screen:

```text
Settings

PROFILE
────────────────────────
Personal Information
Age / Sex / Lesion Location
                         >

AI
────────────────────────
LLM Provider              OpenRouter
API Key                   ••••••••
Model                     ...
                         >

DIAGNOSIS
────────────────────────
Analysis Model
Smartphone Optimized     >

Compare Models            OFF

APP
────────────────────────
Language                  English
Theme                     System

DATA
────────────────────────
Clear Chat History

ABOUT
────────────────────────
About SkinAI
Medical Disclaimer
```

---

# 23. MODEL SETTINGS

Allow:

```text
Smartphone Optimized
Baseline
Compare Both
```

Persist the selected option locally.

Default:

```text
Smartphone Optimized
```

---

# 24. MEDICAL DISCLAIMER

The app must clearly communicate that:

* This is an AI-assisted image classification tool.
* It is not a medical diagnosis.
* Results can be incorrect.
* Users should consult a qualified healthcare professional.
* The AI explanation does not replace professional examination.

Show a short disclaimer during onboarding and make the full disclaimer available from Settings.

Do not use alarming language.

---

# 25. ERROR HANDLING

Implement robust error handling.

Cases:

```text
No API key
↓
"Please configure your LLM API key in Settings."

Invalid API key
↓
"Your API key appears to be invalid."

No internet
↓
"Internet connection is required for AI chat,
but image analysis can still run locally."

ONNX model loading failure
↓
"Unable to load the local analysis model."

Invalid image
↓
"Unable to process this image."

LLM timeout
↓
"The AI service took too long to respond."

Rate limit
↓
"The selected AI provider is temporarily rate-limited."

Unexpected response
↓
"Unable to parse the AI response."
```

Never expose raw stack traces to users.

Log technical details only in debug mode.

---

# 26. OFFLINE BEHAVIOR

The app should still allow:

```text
Camera
Gallery
Image preprocessing
ONNX inference
Prediction
Detailed result
Chat history
Settings
```

without internet.

Only:

```text
LLM response
```

requires internet.

If the user analyzes an image offline:

```text
Image Analysis
Prediction: mel
Confidence: 82.4%

AI explanation unavailable offline.
Connect to the internet to ask the configured LLM.
```

---

# 27. SECURITY

Follow these rules:

* Never hard-code API keys.
* Never log API keys.
* Use HTTPS.
* Store API keys in secure storage.
* Do not send the original image to the LLM unless explicitly implemented later.
* Do not create a backend.
* Keep user profile local.
* Keep chat history local.
* Provide clear privacy information.
* Allow clearing local data.

---

# 28. PROJECT STRUCTURE

Use this architecture:

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
│
├── models/
│   ├── user_profile.dart
│   ├── chat_message.dart
│   ├── diagnosis_result.dart
│   └── llm_config.dart
│
├── screens/
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   │
│   ├── chat/
│   │   └── chat_screen.dart
│   │
│   ├── diagnosis/
│   │   ├── image_preview_screen.dart
│   │   └── diagnosis_result_screen.dart
│   │
│   └── settings/
│       ├── settings_screen.dart
│       ├── profile_screen.dart
│       └── llm_settings_screen.dart
│
├── services/
│   ├── onnx/
│   │   ├── onnx_service.dart
│   │   ├── image_preprocessor.dart
│   │   └── model_manager.dart
│   │
│   ├── llm/
│   │   ├── llm_service.dart
│   │   ├── openrouter_service.dart
│   │   └── prompt_builder.dart
│   │
│   ├── storage/
│   │   ├── secure_storage_service.dart
│   │   ├── preferences_service.dart
│   │   └── chat_database.dart
│   │
│   └── camera/
│       └── image_service.dart
│
├── widgets/
│   ├── chat_bubble.dart
│   ├── diagnosis_card.dart
│   ├── confidence_bar.dart
│   ├── image_message.dart
│   └── loading_indicator.dart
│
└── utils/
    ├── constants.dart
    ├── extensions.dart
    └── error_handler.dart

assets/
└── models/
    ├── baseline_best_mobile.onnx
    └── smartphone_augmented_mobile.onnx
```

---

# 29. STATE MANAGEMENT

Use a clean state management solution.

Prefer:

```text
Riverpod
```

if compatible with the project.

Create providers/controllers for:

```text
UserProfile
Chat
ONNX Model
LLM Configuration
Settings
```

Avoid putting all application logic directly inside widgets.

Widgets should remain primarily UI-focused.

---

# 30. UI DESIGN

The app should look modern and professional.

Style:

* clean medical AI aesthetic
* rounded cards
* subtle shadows
* readable typography
* light/dark theme support
* responsive layouts
* modern chat bubbles
* smooth loading animations
* clear diagnosis cards

Do NOT make it look like a generic Flutter counter app.

Avoid excessive gradients.

Avoid excessive colors.

Use color semantics carefully:

* neutral for normal UI
* informational blue/teal
* warning colors only when appropriate
* do not use red simply because a class is medically serious

---

# 31. ACCESSIBILITY

Support:

* readable text
* adequate contrast
* semantic labels
* touch targets at least approximately 44×44
* text scaling where practical

---

# 32. ANDROID REQUIREMENTS

The target is Android.

Configure:

* camera permission
* gallery/photo permission as required by Android version
* internet permission
* ONNX native dependencies correctly
* release build compatibility

Test:

```text
flutter run
flutter build apk --debug
```

and if possible:

```text
flutter build apk --release
```

---

# 33. DEPENDENCIES

Choose stable packages compatible with the current Flutter SDK.

Likely dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter

  image_picker:
  camera:
  onnxruntime:
  dio:
  flutter_secure_storage:
  shared_preferences:
  riverpod:
  flutter_riverpod:
  uuid:
```

Add other packages only when actually necessary.

Do not add unnecessary dependencies.

Before using a package, verify that its API is compatible with the installed/current version.

---

# 34. ONNX ASSET LOADING

Make sure both ONNX files are declared in:

```yaml
flutter:
  assets:
    - assets/models/baseline_best_mobile.onnx
    - assets/models/smartphone_augmented_mobile.onnx
```

Load them correctly from Flutter assets.

Do not assume they exist in the Android filesystem directly.

Copy/extract them into a usable local path if required by the ONNX package.

Handle initialization asynchronously.

Show a loading state while the model is being prepared.

---

# 35. FIRST-RUN EXPERIENCE

The app startup flow should be:

```text
Launch
 ↓
Initialize local storage
 ↓
Check onboarding
 ↓
If first launch:
    Onboarding
 ↓
Chat screen
 ↓
Initialize ONNX model lazily
```

Do not block the entire UI unnecessarily while loading both models.

Prefer lazy loading.

Load the selected model first.

Load the second model only when comparison is requested.

---

# 36. CHAT STARTER MESSAGE

Use a friendly initial assistant message:

```text
Hello! I'm SkinAI.

I can help you understand the results of an
AI-based skin lesion image analysis.

You can ask me questions or take a photo
of a skin lesion to begin an analysis.
```

Do not claim:

```text
I can diagnose your skin cancer.
```

---

# 37. IMAGE ANALYSIS CHAT FLOW

When the user analyzes an image:

Add a user message:

```text
[Image]
Analyze this image
```

Then show:

```text
Analyzing image...
```

Then:

```text
Image Analysis
Prediction: ...
Confidence: ...
```

Then:

```text
AI is preparing an explanation...
```

Then call LLM.

Then display assistant response.

The entire process should feel like one continuous conversation.

---

# 38. LLM RESPONSE STYLE

The LLM should answer in the same language as the user's latest message.

If the user speaks Vietnamese:

```text
Respond in Vietnamese.
```

If English:

```text
Respond in English.
```

Do not force English.

The LLM should be:

* concise
* understandable
* medically cautious
* conversational
* non-alarming

---

# 39. MODEL OUTPUT HANDLING

Do not assume the ONNX output is already probabilities.

Implement:

```text
logits
↓
softmax
↓
probabilities
```

unless runtime inspection proves the model already outputs probabilities.

Verify this experimentally.

Use numerically stable softmax.

Example:

```dart
double softmax(...)
```

Then:

```text
argmax(probabilities)
```

determines the predicted class.

---

# 40. TESTING

Create unit tests for:

```text
Image preprocessing
Softmax
Class mapping
DiagnosisResult
Prompt builder
User profile serialization
LLM response parsing
```

At minimum verify:

```text
input tensor shape = [1, 3, 224, 224]
output shape = [1, 7]
```

Verify class order:

```text
0 = akiec
1 = bcc
2 = bkl
3 = df
4 = mel
5 = nv
6 = vasc
```

---

# 41. ONNX VALIDATION

Before integrating UI, create a simple debug/test path that:

1. Loads the ONNX model.
2. Loads a test image.
3. Runs preprocessing.
4. Runs inference.
5. Prints:

```text
Model
Input shape
Output shape
All logits
All probabilities
Predicted class
Confidence
Inference time
```

This is important for verifying that Flutter preprocessing matches the training pipeline.

---

# 42. DO NOT FABRICATE MODEL PERFORMANCE

Do NOT display fake accuracy/F1/AUC values inside the app.

Do NOT invent medical statistics.

The app should display only actual inference output.

If model evaluation metrics are eventually added, they must come from the actual training/evaluation results.

---

# 43. DO NOT IMPLEMENT CLINICAL FUSION ARBITRARILY

The training notebook may contain clinical metadata experiments.

Do not invent a new formula such as:

```text
final = image_probability * 0.7 + age_score * 0.3
```

unless explicitly requested.

The initial production app should use:

```text
ONNX image prediction
+
optional user context
→ LLM explanation
```

The user profile is contextual information for the LLM, not an unvalidated classifier fusion mechanism.

---

# 44. FUTURE-READY DESIGN

Design the architecture so that later features can be added:

```text
Grad-CAM
Model comparison
Multiple LLM providers
OpenAI-compatible providers
Gemini
Local LLM
Voice input
Text-to-speech
Export diagnosis report
PDF report
Multiple user profiles
Cloud synchronization
```

Do not implement these unless required now.

Keep the architecture extensible.

---

# 45. DEVELOPMENT WORKFLOW

Work in this order:

## Step 1

Inspect the existing Flutter project.

If there is no Flutter project:

```bash
flutter create skin_ai
```

Do not overwrite an existing project without checking it first.

## Step 2

Create the architecture.

## Step 3

Add dependencies.

## Step 4

Add ONNX model assets.

## Step 5

Implement image preprocessing.

## Step 6

Implement ONNX inference.

## Step 7

Test ONNX independently.

## Step 8

Implement onboarding.

## Step 9

Implement chat UI.

## Step 10

Implement image analysis inside chat.

## Step 11

Implement settings.

## Step 12

Implement secure LLM configuration.

## Step 13

Implement OpenRouter service.

## Step 14

Implement prompt builder.

## Step 15

Connect diagnosis result → LLM → chat.

## Step 16

Implement local chat history.

## Step 17

Implement error handling.

## Step 18

Build and test Android APK.

---

# 46. AGENT RULES

You are responsible for actually implementing the application.

Do not merely describe the code.

Create/edit the required files.

Do not stop after creating a plan.

After implementation:

1. Run `flutter analyze`.
2. Fix errors.
3. Run tests if available.
4. Run `flutter build apk --debug`.
5. Fix build errors.
6. Verify assets.
7. Verify Android permissions.
8. Verify ONNX initialization.
9. Verify the app launches.

If a dependency API has changed, inspect the installed package/API and adapt the code instead of guessing.

Do not use deprecated APIs when a stable replacement exists.

Do not leave TODO placeholders for core functionality.

Do not fake ONNX inference.

Do not fake LLM responses.

Do not hard-code API keys.

---

# 47. EXPECTED FINAL RESULT

At the end, the application should have this complete flow:

```text
FIRST LAUNCH
     ↓
ONBOARDING
     ↓
Optional:
Age / Sex / Lesion Location
     ↓
CHATBOT
     ↓
User can chat normally
     ↓
User taps 📷
     ↓
Camera / Gallery
     ↓
Image Preview
     ↓
Analyze
     ↓
LOCAL ONNX
     ↓
EfficientNet-B0
     ↓
7-class prediction
     ↓
Diagnosis Card
     ↓
Structured Result
     ↓
User Profile + Conversation Context
     ↓
Prompt Builder
     ↓
User-configured OpenRouter API
     ↓
LLM
     ↓
AI Explanation
     ↓
Chat Message
     ↓
User can continue asking questions
```

The final application must feel like a single coherent AI assistant rather than separate screens for "classification" and "chatbot".

The ONNX model is the actual image-analysis engine.

The external LLM is the conversational explanation engine.

Flutter is the application layer.

No custom backend is required.
