import pandas as pd
import numpy as np
import joblib
import ipaddress
from sklearn.metrics import accuracy_score
import glob
import sys
import json
import os

# Force UTF-8 encoding to avoid UnicodeEncodeError
sys.stdout.reconfigure(encoding='utf-8')

# Main function to process files and generate predictions
def main():
    if len(sys.argv) < 3:
        print("Usage: python ctu_predict.py <file_path> <algorithm>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    algorithm = sys.argv[2]
    
    print("Processing CTU-13 data...")
    print(f"File: {file_path}")
    print(f"Algorithm: {algorithm}")
    
    # Get current script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Script directory: {script_dir}")
    
    # Mapping from app algorithm keys to model names
    algorithm_mapping = {
        'random_forest': 'random_forest',
        'xgboost': 'xgboost',
        'svm': 'svm',
        'knn': 'knn',
        'logistic_regression': 'logistic_regression'
    }
    
    model_key = algorithm_mapping.get(algorithm.lower())
    if not model_key:
        print(f"❌ Unknown algorithm: {algorithm}")
        sys.exit(1)
        
    # Remove the emoji from this print statement
    print(f"Using model key: {model_key}")

    try:
        # Load preprocessing objects
        preprocessing_dir = os.path.join(script_dir, "ctu_preprocessing")
        print(f"Preprocessing directory: {preprocessing_dir}")
        
        scaler_path = os.path.join(preprocessing_dir, "scaler.pkl")
        print(f"Loading scaler from: {scaler_path}")
        scaler = joblib.load(scaler_path)
        
        feature_columns_path = os.path.join(preprocessing_dir, "feature_columns.pkl")
        print(f"Loading feature columns from: {feature_columns_path}")
        feature_columns = joblib.load(feature_columns_path)

        # Load label encoders
        encoders = {}
        for col in ["Proto", "State"]:
            encoder_path = os.path.join(preprocessing_dir, f"{col}_encoder.pkl")
            print(f"Loading {col} encoder from: {encoder_path}")
            encoders[col] = joblib.load(encoder_path)

        # Load the model
        models_dir = os.path.join(script_dir, "ctu_models")
        print(f"Models directory: {models_dir}")
        
        model_pattern = os.path.join(models_dir, f"ctu_{model_key}_*.pkl")
        print(f"Looking for model with pattern: {model_pattern}")
        model_files = glob.glob(model_pattern)
        
        if not model_files:
            print(f"No model found for pattern: {model_pattern}")
            sys.exit(1)
            
        # Use the first model file found
        model_path = model_files[0]
        print(f"Found model: {model_path}")
        model_obj = joblib.load(model_path)
        
        # Extract model if it's in a dictionary
        model = model_obj.get("model", model_obj) if isinstance(model_obj, dict) else model_obj
        print("Model loaded successfully")

        # Load test data
        print(f"Loading data from: {file_path}")
        df = pd.read_csv(file_path)
        print(f"Data loaded with shape: {df.shape}")
        
        # Check if the data has a Label column for computing accuracy
        has_actual_labels = 'Label' in df.columns
        actual_labels = None
        
        if has_actual_labels:
            print("Found Label column, will compute accuracy")
            actual_labels = df["Label"].values
            actual_counts = pd.Series(actual_labels).value_counts().sort_index()
            print(f"Actual Label Counts:\n{actual_counts}")
            df = df.drop(columns=["Label"])
        else:
            print("No Label column found, will not compute accuracy")
        
        # Process features
        print("Processing features...")
        # Convert categorical features
        for col in encoders:
            if col in df.columns:
                print(f"Encoding column: {col}")
                df[col] = encoders[col].transform(df[col])

        # Convert IP addresses to numerical
        for col in ["SrcAddr", "DstAddr"]:
            if col in df.columns:
                print(f"Converting IP addresses in column: {col}")
                df[col] = df[col].apply(lambda ip: int(ipaddress.ip_address(ip)) if pd.notna(ip) else np.nan)

        # Convert hex values
        for col in df.columns:
            df[col] = df[col].apply(lambda value: 
                int(value, 16) if isinstance(value, str) and value.startswith("0x") else value)

        # Convert all to numeric, handling missing values
        df = df.apply(pd.to_numeric, errors="coerce")
        df.fillna(df.median(), inplace=True)

        # Select only relevant columns
        missing_cols = [col for col in feature_columns if col not in df.columns]
        if missing_cols:
            print(f"Adding missing columns: {missing_cols}")
            for col in missing_cols:
                df[col] = 0  # Add missing columns with default values
        
        df = df[feature_columns]
        print(f"Selected {len(feature_columns)} feature columns")

        # Scale features
        X_test_scaled = scaler.transform(df)
        print("Features processed and scaled")

        # Make predictions
        print("Making predictions...")
        y_pred = model.predict(X_test_scaled)
        
        # Count predicted labels
        predicted_counts = pd.Series(y_pred).value_counts().sort_index()
        print(f"Predicted counts:\n{predicted_counts}")
        
        # Prepare the results dictionary
        result = {
            "predictions": y_pred.tolist(),
            "counts": predicted_counts.to_dict()
        }
        
        # Calculate accuracy if we have actual labels
        if has_actual_labels:
            accuracy = accuracy_score(actual_labels, y_pred)
            result["accuracy"] = float(accuracy)
            print(f"Accuracy: {accuracy:.4f}")
            
            # Add actual counts if available
            actual_counts_dict = pd.Series(actual_labels).value_counts().sort_index().to_dict()
            result["actual_counts"] = actual_counts_dict
        
        # Convert numeric keys to strings for JSON serialization
        result["counts"] = {str(k): int(v) for k, v in result["counts"].items()}
        if "actual_counts" in result:
            result["actual_counts"] = {str(k): int(v) for k, v in result["actual_counts"].items()}
        
        print("Prediction complete!")
        
        # Output JSON result
        json_result = json.dumps(result)
        print(json_result)
        
    except Exception as e:
        print(f"Error: {str(e)}")
        error_result = {"error": str(e)}
        print(json.dumps(error_result))
        sys.exit(1)

if __name__ == "__main__":
    main()
