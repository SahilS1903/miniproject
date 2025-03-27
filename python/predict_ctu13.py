import pandas as pd
import numpy as np
import joblib
import ipaddress
from sklearn.metrics import accuracy_score
import glob
import sys
import json
import os

def predict(file_path, algorithm_name):
    print(f"🚀 Starting CTU-13 prediction with algorithm: {algorithm_name}")
    print(f"📄 Processing file: {file_path}")
    
    # Get the current directory and project root
    current_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"📂 Current directory: {current_dir}")
    
    # List contents of directories to debug
    print("📂 Available directories in current folder:")
    for item in os.listdir(current_dir):
        if os.path.isdir(os.path.join(current_dir, item)):
            print(f"  - {item}/")
        else:
            print(f"  - {item}")
    
    # Map algorithm name from app to model name
    algorithm_mapping = {
        'random_forest': 'Random Forest',
        'xgboost': 'XGBoost',
        'svm': 'SVM',
        'knn': 'KNN',
        'logistic_regression': 'Logistic Regression'
    }
    
    model_name = algorithm_mapping.get(algorithm_name)
    if not model_name:
        print(f"❌ Unknown algorithm: {algorithm_name}")
        raise ValueError(f"Unknown algorithm: {algorithm_name}")
    
    # Load preprocessing objects
    print("📂 Loading preprocessing objects...")
    preprocessing_dir = os.path.join(current_dir, "ctu_preprocessing")
    
    if not os.path.exists(preprocessing_dir):
        print(f"❌ Directory not found: {preprocessing_dir}")
        print("📂 Attempting to find preprocessing directory...")
        # Try to find preprocessing directory by searching parent folders
        for root, dirs, _ in os.walk(os.path.dirname(current_dir)):
            for dir_name in dirs:
                if dir_name == "ctu_preprocessing":
                    preprocessing_dir = os.path.join(root, dir_name)
                    print(f"✅ Found preprocessing directory: {preprocessing_dir}")
                    break
    
    print(f"📂 Preprocessing directory: {preprocessing_dir}")
    
    if os.path.exists(preprocessing_dir):
        print("📂 Contents of preprocessing directory:")
        for item in os.listdir(preprocessing_dir):
            print(f"  - {item}")
    
    scaler_path = os.path.join(preprocessing_dir, "scaler.pkl")
    feature_columns_path = os.path.join(preprocessing_dir, "feature_columns.pkl")
    
    print(f"🔍 Looking for scaler at: {scaler_path}")
    if not os.path.exists(scaler_path):
        print(f"❌ Scaler file not found: {scaler_path}")
        raise FileNotFoundError(f"Scaler file not found: {scaler_path}")
    
    scaler = joblib.load(scaler_path)
    print("✅ Scaler loaded successfully")
    
    print(f"🔍 Looking for feature columns at: {feature_columns_path}")
    if not os.path.exists(feature_columns_path):
        print(f"❌ Feature columns file not found: {feature_columns_path}")
        raise FileNotFoundError(f"Feature columns file not found: {feature_columns_path}")
    
    feature_columns = joblib.load(feature_columns_path)
    print("✅ Feature columns loaded successfully")

    # Load label encoders
    print("📂 Loading encoders...")
    encoders = {}
    for col in ["Proto", "State"]:
        encoder_path = os.path.join(preprocessing_dir, f"{col}_encoder.pkl")
        print(f"🔍 Looking for {col} encoder at: {encoder_path}")
        if not os.path.exists(encoder_path):
            print(f"❌ Encoder file not found: {encoder_path}")
            raise FileNotFoundError(f"Encoder file not found: {encoder_path}")
        
        encoders[col] = joblib.load(encoder_path)
        print(f"✅ {col} encoder loaded successfully")

    # Load the specific model
    def load_model(model_name):
        models_dir = os.path.join(current_dir, "ctu_models")
        
        if not os.path.exists(models_dir):
            print(f"❌ Models directory not found: {models_dir}")
            print("📂 Attempting to find models directory...")
            # Try to find models directory by searching parent folders
            for root, dirs, _ in os.walk(os.path.dirname(current_dir)):
                for dir_name in dirs:
                    if dir_name == "ctu_models":
                        models_dir = os.path.join(root, dir_name)
                        print(f"✅ Found models directory: {models_dir}")
                        break
        
        print(f"📂 Models directory: {models_dir}")
        
        if os.path.exists(models_dir):
            print("📂 Contents of models directory:")
            for item in os.listdir(models_dir):
                print(f"  - {item}")
        
        pattern = os.path.join(models_dir, f"ctu_{model_name.lower().replace(' ', '_')}_*.pkl")
        print(f"🔍 Looking for model with pattern: {pattern}")
        files = glob.glob(pattern)
        
        if files:
            print(f"✅ Found model file: {files[0]}")
            model_obj = joblib.load(files[0])
            return model_obj["model"] if isinstance(model_obj, dict) and "model" in model_obj else model_obj
        else:
            error_msg = f"No model file found for pattern: {pattern}"
            print(f"❌ {error_msg}")
            raise FileNotFoundError(error_msg)

    # Load the selected model
    print(f"📂 Loading {model_name} model...")
    model = load_model(model_name)
    print("✅ Model loaded successfully")

    # Load input data
    print(f"📂 Loading data from: {file_path}")
    df = pd.read_csv(file_path)
    print(f"✅ Data loaded with shape: {df.shape}")
    
    # Check if the data has a Label column for computing accuracy
    has_actual_labels = 'Label' in df.columns
    
    if has_actual_labels:
        print("👉 Found Label column, will compute accuracy")
        actual_labels = df["Label"].values
        actual_counts = pd.Series(actual_labels).value_counts().sort_index().to_dict()
        print(f"🔢 Actual label counts: {actual_counts}")
        df = df.drop(columns=["Label"])
    else:
        print("👉 No Label column found, will not compute accuracy")
    
    # Process features
    print("🔄 Processing features...")
    # Convert categorical features
    for col in encoders:
        if col in df.columns:
            print(f"👉 Encoding column: {col}")
            df[col] = encoders[col].transform(df[col])

    # Convert IP addresses to numerical
    def ip_to_int(ip):
        try:
            return int(ipaddress.ip_address(ip))
        except ValueError:
            return np.nan

    for col in ["SrcAddr", "DstAddr"]:
        if col in df.columns:
            print(f"👉 Converting IP addresses in column: {col}")
            df[col] = df[col].apply(ip_to_int)

    # Convert hex values
    def hex_to_int(value):
        try:
            return int(value, 16) if isinstance(value, str) and value.startswith("0x") else value
        except ValueError:
            return np.nan

    for col in df.columns:
        df[col] = df[col].apply(hex_to_int)

    # Convert all to numeric, handling missing values
    print("👉 Converting all columns to numeric")
    df = df.apply(pd.to_numeric, errors="coerce")
    df.fillna(df.median(), inplace=True)

    # Select only relevant columns
    missing_cols = [col for col in feature_columns if col not in df.columns]
    if missing_cols:
        print(f"👉 Adding missing columns: {missing_cols}")
        for col in missing_cols:
            df[col] = 0  # Add missing columns with default values
    
    print(f"👉 Selecting {len(feature_columns)} feature columns")
    df = df[feature_columns]

    # Scale features
    print("👉 Scaling features")
    X_scaled = scaler.transform(df)

    # Make predictions
    print("🔮 Making predictions...")
    y_pred = model.predict(X_scaled)
    
    # Count predicted labels
    predicted_counts = pd.Series(y_pred).value_counts().sort_index().to_dict()
    print(f"🔢 Predicted label counts: {predicted_counts}")
    
    # Calculate accuracy if we have actual labels
    accuracy = None
    if has_actual_labels:
        accuracy = float(accuracy_score(actual_labels, y_pred))
        print(f"📊 Accuracy: {accuracy:.4f}")
    
    # Prepare results
    print("📝 Preparing results...")
    result = {
        "predictions": y_pred.tolist(),
        "counts": {str(k): int(v) for k, v in predicted_counts.items()}
    }
    
    if accuracy is not None:
        result["accuracy"] = accuracy
    
    if has_actual_labels:
        result["actual_counts"] = {str(k): int(v) for k, v in actual_counts.items()}
    
    print("✅ Prediction complete!")
    return result

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python predict_ctu13.py <file_path> <algorithm>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    algorithm = sys.argv[2]
    
    try:
        result = predict(file_path, algorithm)
        print(json.dumps(result))
    except Exception as e:
        error_message = f"Error: {str(e)}"
        print(f"❌ {error_message}")
        print(json.dumps({"error": error_message}))
        sys.exit(1) 