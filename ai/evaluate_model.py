import os
import json
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt

from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    confusion_matrix,
    classification_report,
    ConfusionMatrixDisplay,
)

# =========================
# SETTINGS
# =========================

DATASET_DIR = r"C:\FlutterProjects\exocarp\MangoDataset\process data"
MODEL_PATH = r"C:\FlutterProjects\exocarp\ai\models\exocarp_mango_disease_model.keras"
OUTPUT_DIR = r"C:\FlutterProjects\exocarp\ai\models"

IMG_SIZE = (224, 224)
SEED = 42
TEST_SIZE = 0.15
VAL_SIZE = 0.15

# =========================
# CLASS NAMES
# =========================

class_names = [
    "Anthracnose",
    "Bacterial Canker",
    "Cutting Weevil",
    "Die Back",
    "Gall Midge",
    "Healthy",
    "Powdery Mildew",
    "Sooty Mould",
]

# =========================
# COLLECT IMAGE FILES
# =========================

image_paths = []
labels = []

for class_index, class_name in enumerate(class_names):
    class_dir = os.path.join(DATASET_DIR, class_name)

    for filename in os.listdir(class_dir):
        if filename.lower().endswith((".jpg", ".jpeg", ".png")):
            image_paths.append(os.path.join(class_dir, filename))
            labels.append(class_index)

image_paths = np.array(image_paths)
labels = np.array(labels)

print(f"Total images: {len(image_paths)}")

# =========================
# RECREATE SAME SPLIT
# =========================

train_paths, test_paths, train_labels, test_labels = train_test_split(
    image_paths,
    labels,
    test_size=TEST_SIZE,
    random_state=SEED,
    stratify=labels,
)

train_paths, val_paths, train_labels, val_labels = train_test_split(
    train_paths,
    train_labels,
    test_size=VAL_SIZE / (1 - TEST_SIZE),
    random_state=SEED,
    stratify=train_labels,
)

print(f"Training images:   {len(train_paths)}")
print(f"Validation images: {len(val_paths)}")
print(f"Test images:       {len(test_paths)}")

# =========================
# LOAD TEST IMAGES
# =========================

def load_image(path):
    image = tf.keras.utils.load_img(
        path,
        target_size=IMG_SIZE,
    )

    image = tf.keras.utils.img_to_array(image)
    

    return image


print("\nLoading test images...")

X_test = np.array([load_image(path) for path in test_paths])
y_test = test_labels

print("Test images loaded.")

# =========================
# LOAD MODEL
# =========================

print("\nLoading trained model...")

model = tf.keras.models.load_model(MODEL_PATH)

print("Model loaded.")

# =========================
# PREDICTIONS
# =========================

print("\nRunning predictions...")

predictions = model.predict(
    X_test,
    batch_size=16,
    verbose=1,
)

y_pred = np.argmax(predictions, axis=1)

# =========================
# OVERALL ACCURACY
# =========================

accuracy = np.mean(y_pred == y_test)

print("\n==============================")
print("MODEL EVALUATION RESULTS")
print("==============================")

print(f"\nTest Accuracy: {accuracy * 100:.2f}%")

# =========================
# CLASSIFICATION REPORT
# =========================

report = classification_report(
    y_test,
    y_pred,
    target_names=class_names,
    output_dict=True,
    zero_division=0,
)

print("\nClassification Report:")
print(
    classification_report(
        y_test,
        y_pred,
        target_names=class_names,
        zero_division=0,
    )
)

# =========================
# SAVE CLASSIFICATION REPORT
# =========================

report_path = os.path.join(
    OUTPUT_DIR,
    "classification_report.csv",
)

import pandas as pd

report_df = pd.DataFrame(report).transpose()
report_df.to_csv(report_path)

print(f"\nClassification report saved to:")
print(report_path)

# =========================
# CONFUSION MATRIX
# =========================

cm = confusion_matrix(
    y_test,
    y_pred,
)

plt.figure(figsize=(10, 8))

disp = ConfusionMatrixDisplay(
    confusion_matrix=cm,
    display_labels=class_names,
)

disp.plot(
    xticks_rotation=45,
    values_format="d",
)

plt.title("EXOCARP Mango Leaf Disease Detection - Confusion Matrix")
plt.tight_layout()

cm_path = os.path.join(
    OUTPUT_DIR,
    "confusion_matrix.png",
)

plt.savefig(
    cm_path,
    dpi=300,
    bbox_inches="tight",
)

plt.close()

print(f"Confusion matrix saved to:")
print(cm_path)

# =========================
# SAVE JSON RESULTS
# =========================

results = {
    "test_accuracy": float(accuracy),
    "test_accuracy_percent": float(accuracy * 100),
    "test_images": int(len(y_test)),
    "classes": class_names,
    "classification_report": report,
}

json_path = os.path.join(
    OUTPUT_DIR,
    "evaluation_results.json",
)

with open(json_path, "w") as f:
    json.dump(results, f, indent=4)

print(f"Evaluation results saved to:")
print(json_path)

print("\n==============================")
print("EVALUATION COMPLETE")
print("==============================")