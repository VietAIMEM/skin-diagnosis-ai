/// Central class mapping. The order MUST match the training order:
/// 0 = akiec, 1 = bcc, 2 = bkl, 3 = df, 4 = mel, 5 = nv, 6 = vasc.
/// See class_mapping.json in modelskincancer.
const List<String> skinClasses = [
  'akiec',
  'bcc',
  'bkl',
  'df',
  'mel',
  'nv',
  'vasc',
];

const Map<String, String> skinClassDisplayNames = {
  'akiec': 'Actinic keratosis',
  'bcc': 'Basal cell carcinoma',
  'bkl': 'Benign keratosis-like lesion',
  'df': 'Dermatofibroma',
  'mel': 'Melanoma',
  'nv': 'Melanocytic nevus',
  'vasc': 'Vascular lesion',
};

/// Names used in the asset bundle.
const String assetBaselineModel = 'assets/models/baseline_best_mobile.onnx';
const String assetSmartphoneModel =
    'assets/models/smartphone_augmented_mobile.onnx';

const List<String> modelAssetPaths = [
  assetBaselineModel,
  assetSmartphoneModel,
];

/// Human readable model identifiers.
const String modelIdSmartphone = 'smartphone_augmented_mobile';
const String modelIdBaseline = 'baseline_best_mobile';

const String defaultModelId = modelIdSmartphone;

/// Model selection options.
enum AnalysisModelOption {
  smartphone,
  baseline,
  compareBoth,
}

const String kOnboardingCompleted = 'onboardingCompleted';
const String kAnalysisModelOption = 'analysisModelOption';
const String kLlmModel = 'llmModel';
const String kLlmTemperature = 'llmTemperature';
const String kThemeMode = 'themeMode';
const String kLanguage = 'language';

const String defaultLlmModel = 'openai/gpt-4o-mini';
const double defaultLlmTemperature = 0.2;

const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

/// Input tensor layout expected by the ONNX models.
const int modelInputChannels = 3;
const int modelInputSize = 224;

/// ImageNet normalization constants used during training.
const List<double> imageNetMean = [0.485, 0.456, 0.406];
const List<double> imageNetStd = [0.229, 0.224, 0.225];

const String appName = 'SkinAI';

/// Reference used to avoid spreading constant in multiple places.
const double kMaxConfidence = 1.0;

/// Cap on how many chat messages are sent to the LLM (context window).
const int maxChatHistoryMessages = 20;

const List<String> sexOptions = ['Female', 'Male', 'Prefer not to say'];
const List<String> lesionLocationOptions = [
  'Face',
  'Scalp',
  'Neck',
  'Chest',
  'Back',
  'Abdomen',
  'Arm',
  'Hand',
  'Leg',
  'Foot',
  'Other',
];
