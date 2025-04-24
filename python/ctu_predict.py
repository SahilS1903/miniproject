import pandas as pd
import numpy as np
import joblib
import ipaddress
from sklearn.metrics import accuracy_score
import glob
import sys
import json
import os
import traceback

# Force UTF-8 encoding to avoid UnicodeEncodeError
sys.stdout.reconfigure(encoding='utf-8')

# Custom JSON encoder to handle NumPy types
class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        return super(NumpyEncoder, self).default(obj)

# Function to convert integer to IP address
def int_to_ip(integer):
    try:
        if pd.isna(integer):
            return "unknown"
        # Convert to 32-bit integer if needed
        integer = int(integer) & 0xFFFFFFFF
        return str(ipaddress.IPv4Address(integer))
    except Exception:
        return str(integer)

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
    
    try:
        # Verify file exists
        if not os.path.exists(file_path):
            print(f"Error: File not found at path: {file_path}")
            sys.exit(1)
            
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
            print(f"Error: Unknown algorithm: {algorithm}")
            sys.exit(1)
            
        print(f"Using model key: {model_key}")

        # Load preprocessing objects
        preprocessing_dir = os.path.join(script_dir, "ctu_preprocessing")
        print(f"Preprocessing directory: {preprocessing_dir}")
        
        if not os.path.exists(preprocessing_dir):
            print(f"Error: Preprocessing directory not found: {preprocessing_dir}")
            print("Available directories:")
            for item in os.listdir(script_dir):
                if os.path.isdir(os.path.join(script_dir, item)):
                    print(f"  - {item}")
            sys.exit(1)
        
        scaler_path = os.path.join(preprocessing_dir, "scaler.pkl")
        print(f"Loading scaler from: {scaler_path}")
        if not os.path.exists(scaler_path):
            print(f"Error: Scaler file not found: {scaler_path}")
            sys.exit(1)
            
        scaler = joblib.load(scaler_path)
        
        feature_columns_path = os.path.join(preprocessing_dir, "feature_columns.pkl")
        print(f"Loading feature columns from: {feature_columns_path}")
        if not os.path.exists(feature_columns_path):
            print(f"Error: Feature columns file not found: {feature_columns_path}")
            sys.exit(1)
            
        feature_columns = joblib.load(feature_columns_path)

        # Load label encoders
        encoders = {}
        for col in ["Proto", "State"]:
            encoder_path = os.path.join(preprocessing_dir, f"{col}_encoder.pkl")
            print(f"Loading {col} encoder from: {encoder_path}")
            if not os.path.exists(encoder_path):
                print(f"Error: Encoder file not found: {encoder_path}")
                sys.exit(1)
                
            encoders[col] = joblib.load(encoder_path)

        # Load the model
        models_dir = os.path.join(script_dir, "ctu_models")
        print(f"Models directory: {models_dir}")
        
        if not os.path.exists(models_dir):
            print(f"Error: Models directory not found: {models_dir}")
            print("Available directories:")
            for item in os.listdir(script_dir):
                if os.path.isdir(os.path.join(script_dir, item)):
                    print(f"  - {item}")
            sys.exit(1)
        
        model_pattern = os.path.join(models_dir, f"ctu_{model_key}_*.pkl")
        print(f"Looking for model with pattern: {model_pattern}")
        model_files = glob.glob(model_pattern)
        
        if not model_files:
            print(f"Error: No model found for pattern: {model_pattern}")
            print("Available model files:")
            for item in os.listdir(models_dir):
                print(f"  - {item}")
            sys.exit(1)
            
        # Use the first model file found
        model_path = model_files[0]
        print(f"Found model: {model_path}")
        
        try:
            model_obj = joblib.load(model_path)
        except Exception as e:
            print(f"Error loading model: {str(e)}")
            traceback.print_exc()
            sys.exit(1)
        
        # Extract model if it's in a dictionary
        model = model_obj.get("model", model_obj) if isinstance(model_obj, dict) else model_obj
        print("Model loaded successfully")

        # Load test data
        print(f"Loading data from: {file_path}")
        try:
            df = pd.read_csv(file_path)
            print(f"Data loaded with shape: {df.shape}")
        except Exception as e:
            print(f"Error loading CSV file: {str(e)}")
            traceback.print_exc()
            sys.exit(1)
        
        # Print column names for debugging
        print(f"CSV columns: {df.columns.tolist()}")
        
        # Save original IP addresses before conversion
        original_ip_addresses = None
        if "SrcAddr" in df.columns and "DstAddr" in df.columns:
            original_ip_addresses = df[["SrcAddr", "DstAddr"]].copy()
            print("Saved original IP addresses")
        else:
            print("Warning: SrcAddr or DstAddr columns not found in the data")
        
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
                try:
                    df[col] = encoders[col].transform(df[col])
                except Exception as e:
                    print(f"Error encoding column {col}: {str(e)}")
                    print(f"Unique values in {col}: {df[col].unique()}")
                    traceback.print_exc()
                    sys.exit(1)

        # Convert IP addresses to numerical
        for col in ["SrcAddr", "DstAddr"]:
            if col in df.columns:
                print(f"Converting IP addresses in column: {col}")
                try:
                    df[col] = df[col].apply(lambda ip: int(ipaddress.ip_address(ip)) if pd.notna(ip) else np.nan)
                except Exception as e:
                    print(f"Error converting IP addresses in column {col}: {str(e)}")
                    print(f"Sample values in {col}: {df[col].head(5).tolist()}")
                    traceback.print_exc()
                    sys.exit(1)

        # Convert hex values
        for col in df.columns:
            try:
                df[col] = df[col].apply(lambda value: 
                    int(value, 16) if isinstance(value, str) and value.startswith("0x") else value)
            except Exception as e:
                print(f"Error converting hex values in column {col}: {str(e)}")
                print(f"Sample values in {col}: {df[col].head(5).tolist()}")
                traceback.print_exc()
                sys.exit(1)

        # Convert all to numeric, handling missing values
        try:
            df = df.apply(pd.to_numeric, errors="coerce")
            df.fillna(df.median(), inplace=True)
        except Exception as e:
            print(f"Error converting to numeric: {str(e)}")
            traceback.print_exc()
            sys.exit(1)

        # Select only relevant columns
        print(f"Feature columns needed: {feature_columns}")
        missing_cols = [col for col in feature_columns if col not in df.columns]
        if missing_cols:
            print(f"Adding missing columns: {missing_cols}")
            for col in missing_cols:
                df[col] = 0  # Add missing columns with default values
        
        try:
            df = df[feature_columns]
            print(f"Selected {len(feature_columns)} feature columns")
        except Exception as e:
            print(f"Error selecting feature columns: {str(e)}")
            print(f"Available columns: {df.columns.tolist()}")
            traceback.print_exc()
            sys.exit(1)

        # Scale features
        try:
            X_test_scaled = scaler.transform(df)
            print("Features processed and scaled")
        except Exception as e:
            print(f"Error during scaling: {str(e)}")
            print(f"df shape: {df.shape}, expected feature count: {len(feature_columns)}")
            traceback.print_exc()
            sys.exit(1)

        # Make predictions
        print("Making predictions...")
        try:
            y_pred = model.predict(X_test_scaled)
            print(f"Predictions made: {len(y_pred)}")
        except Exception as e:
            print(f"Error during prediction: {str(e)}")
            traceback.print_exc()
            sys.exit(1)
        
        # Count predicted labels
        predicted_counts = pd.Series(y_pred).value_counts().sort_index()
        print(f"Predicted counts:\n{predicted_counts}")
        
        # Get infected IPs (where prediction is 1)
        infected_ips = []
        unique_infected_sources = set()
        if original_ip_addresses is not None:
            infected_indices = [i for i, pred in enumerate(y_pred) if pred == 1]
            for idx in infected_indices:
                if idx < len(original_ip_addresses):
                    src_ip = original_ip_addresses.iloc[idx]["SrcAddr"]
                    dst_ip = original_ip_addresses.iloc[idx]["DstAddr"]
                    # Convert to proper IP format using the int_to_ip function
                    src_ip_str = int_to_ip(src_ip)
                    dst_ip_str = int_to_ip(dst_ip)
                    infected_ips.append({"src": src_ip_str, "dst": dst_ip_str})
                    unique_infected_sources.add(src_ip_str)
        
        # Prepare the results dictionary
        result = {
            "predictions": y_pred.tolist(),
            "counts": {str(k): int(v) for k, v in predicted_counts.to_dict().items()},
            "infected_ips": infected_ips,
            "unique_infected_sources": list(unique_infected_sources)
        }
        
        # Calculate accuracy if we have actual labels
        if has_actual_labels:
            accuracy = accuracy_score(actual_labels, y_pred)
            result["accuracy"] = float(accuracy)
            print(f"Accuracy: {accuracy:.4f}")
            
            # Add actual counts if available
            actual_counts_dict = pd.Series(actual_labels).value_counts().sort_index().to_dict()
            result["actual_counts"] = {str(k): int(v) for k, v in actual_counts_dict.items()}
        
        print(f"Found {len(infected_ips)} infected connections from {len(unique_infected_sources)} unique source IPs")
        print("List of infected source IPs:")
        for ip in sorted(unique_infected_sources):
            print(f"  - {ip}")
        print("Prediction complete!")
        
        # Output JSON result
        json_result = json.dumps(result, cls=NumpyEncoder)
        print(json_result)
        
    except Exception as e:
        print(f"Error: {str(e)}")
        traceback.print_exc()
        error_result = {"error": str(e)}
        print(json.dumps(error_result))
        sys.exit(1)

if __name__ == "__main__":
    main()
