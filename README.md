# Botnet Detection App

A Flutter application for analyzing network traffic datasets to detect botnet activity using various machine learning algorithms.

## Features

- Support for multiple datasets (CTU-13 and IOT-23)
- Multiple machine learning algorithms:
  - Random Forest
  - XGBoost
  - SVM
  - KNN
  - Logistic Regression
- Interactive visualization of prediction results
- Cross-platform support (Desktop, Mobile, and Web)

## Application Structure

### Dart/Flutter Files

- `lib/main.dart`: Main entry point for the application
- `lib/screens/dataset_selection_screen.dart`: Screen for selecting the dataset
- `lib/screens/ml_modules_screen.dart`: Screen for selecting algorithms and files
- `lib/screens/comparison_graph_screen.dart`: Results visualization screen
- `lib/theme/app_theme.dart`: Application theme styles

### Python Backend Files

- `python/predict_ctu13.py`: Prediction script for CTU-13 dataset
- `python/predict_iot23.py`: Prediction script for IOT-23 dataset
- `python/preprocessing/`: Contains preprocessing objects (scalers, encoders)
- `python/models/`: Contains trained models

### Web Implementation Files

- `web/index.html`: Main HTML file with JavaScript for web processing

## How to Use

1. Launch the application
2. Select a dataset (CTU-13 or IOT-23)
3. Select a CSV file with network traffic data to analyze
4. Choose a machine learning algorithm
5. Run the analysis to see prediction results

## Implementation Notes

### Dataset-Specific Processing

The application uses different prediction scripts for each dataset:

- CTU-13: Uses `predict_ctu13.py` with specialized preprocessing
- IOT-23: Uses `predict_iot23.py` with specialized preprocessing

### Web Platform

On web platforms, the application:

- Uses JavaScript interop to process CSV data
- Provides simulated results for demonstration purposes

## Development

### Running the app

For desktop development:

```bash
flutter run
```

For web development:

```bash
flutter run -d chrome
```

### Adding New Models

To add new machine learning models:

1. Train the model using your dataset
2. Save the model in the `python/models/` directory following the naming convention:
   - `ctu_[algorithm_name]_[accuracy].pkl` for CTU-13 models
   - `iot_[algorithm_name]_[accuracy].pkl` for IOT-23 models
3. Update the relevant prediction scripts if needed

## Troubleshooting

- If you encounter issues with model loading, ensure that the preprocessing files match those used during model training
- For web deployment issues, check JavaScript interop implementation in `index.html`
