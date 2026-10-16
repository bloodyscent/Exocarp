
from pathlib import Path
import json

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix


# ============================================================
# EXOCARP - Mango Leaf Disease Detection
# MobileNetV2: Training, Fine-Tuning, Evaluation, and TFLite
# ============================================================

# 1. CONFIGURATION

DATASET_DIR = Path(
    r"C:\FlutterProjects\Exocarp\MangoDataset\process data"
)

OUTPUT_DIR = Path(
    r"C:\FlutterProjects\Exocarp\ai\models"
)

IMAGE_SIZE = (224, 224)
BATCH_SIZE = 16
SEED = 42

INITIAL_EPOCHS = 15
FINE_TUNE_EPOCHS = 10

VALID_EXTENSIONS = {".jpg", ".jpeg", ".png"}

CLASS_NAMES = [
    "Anthracnose",
    "Bacterial Canker",
    "Cutting Weevil",
    "Die Back",
    "Gall Midge",
    "Healthy",
    "Powdery Mildew",
    "Sooty Mould",
]

NUM_CLASSES = len(CLASS_NAMES)

tf.keras.utils.set_random_seed(SEED)


# 2. CHECK ENVIRONMENT AND DATASET

print("=" * 65)
print("EXOCARP - Mango Leaf Disease Detection")
print("=" * 65)
print("TensorFlow:", tf.__version__)
print("Dataset:", DATASET_DIR)
print("Output:", OUTPUT_DIR)
print("Classes:", NUM_CLASSES)
print("Image size:", IMAGE_SIZE)
print()

if not DATASET_DIR.is_dir():
    raise FileNotFoundError(
        f"Dataset directory not found:\n{DATASET_DIR}"
    )

for class_name in CLASS_NAMES:
    if not (DATASET_DIR / class_name).is_dir():
        raise FileNotFoundError(
            f"Missing class folder:\n{DATASET_DIR / class_name}"
        )

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


# 3. COLLECT IMAGE PATHS AND LABELS

image_paths = []
labels = []

print("Image counts by class:")
print("-" * 65)

for class_index, class_name in enumerate(CLASS_NAMES):
    class_dir = DATASET_DIR / class_name

    class_images = sorted(
        p for p in class_dir.rglob("*")
        if p.is_file() and p.suffix.lower() in VALID_EXTENSIONS
    )

    print(f"{class_name}: {len(class_images)}")

    if len(class_images) < 3:
        raise ValueError(
            f"Not enough images for class: {class_name}"
        )

    image_paths.extend(str(p) for p in class_images)
    labels.extend([class_index] * len(class_images))

image_paths = np.asarray(image_paths)
labels = np.asarray(labels, dtype=np.int32)

print("-" * 65)
print("Total images:", len(image_paths))
print()


# 4. SPLIT DATA
#
# Approximately 70% training, 15% validation, 15% testing.
# The test set is held out until final evaluation.
#
# IMPORTANT:
# If the dataset contains multiple augmented copies of the same
# original image, those related images should be grouped together
# before splitting. This script assumes process data contains
# independent images. Verify this if the dataset has duplicates.

train_paths, test_paths, train_labels, test_labels = (
    train_test_split(
        image_paths,
        labels,
        test_size=0.15,
        random_state=SEED,
        stratify=labels,
    )
)

train_paths, val_paths, train_labels, val_labels = (
    train_test_split(
        train_paths,
        train_labels,
        test_size=(15 / 85),
        random_state=SEED,
        stratify=train_labels,
    )
)

print("Data split:")
print(f"Training:   {len(train_paths)}")
print(f"Validation: {len(val_paths)}")
print(f"Testing:    {len(test_paths)}")
print()


# 5. IMAGE LOADING
#
# Input images remain in the 0-255 range here.
# MobileNetV2 preprocessing is embedded in the model below.
# This means the exported TFLite model expects RGB 0-255 inputs.

def load_image(path, label):
    image_bytes = tf.io.read_file(path)

    image = tf.io.decode_image(
        image_bytes,
        channels=3,
        expand_animations=False,
    )

    image.set_shape([None, None, 3])

    image = tf.image.resize(
        image,
        IMAGE_SIZE,
        antialias=True,
    )

    image = tf.cast(image, tf.float32)

    return image, label


# 6. BUILD TF.DATA PIPELINES

train_dataset = tf.data.Dataset.from_tensor_slices(
    (train_paths, train_labels)
)

val_dataset = tf.data.Dataset.from_tensor_slices(
    (val_paths, val_labels)
)

test_dataset = tf.data.Dataset.from_tensor_slices(
    (test_paths, test_labels)
)

train_dataset = train_dataset.map(
    load_image,
    num_parallel_calls=tf.data.AUTOTUNE,
)

val_dataset = val_dataset.map(
    load_image,
    num_parallel_calls=tf.data.AUTOTUNE,
)

test_dataset = test_dataset.map(
    load_image,
    num_parallel_calls=tf.data.AUTOTUNE,
)


# 7. DATA AUGMENTATION
#
# Applied only during training, not validation or testing.

data_augmentation = keras.Sequential(
    [
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.08),
        layers.RandomZoom(0.10),
        layers.RandomContrast(0.10),
    ],
    name="data_augmentation",
)


# 8. BATCH AND PREFETCH

train_dataset = (
    train_dataset
    .shuffle(
        buffer_size=len(train_paths),
        seed=SEED,
        reshuffle_each_iteration=True,
    )
    .batch(BATCH_SIZE)
    .prefetch(tf.data.AUTOTUNE)
)

val_dataset = (
    val_dataset
    .batch(BATCH_SIZE)
    .prefetch(tf.data.AUTOTUNE)
)

test_dataset = (
    test_dataset
    .batch(BATCH_SIZE)
    .prefetch(tf.data.AUTOTUNE)
)


# 9. BUILD MOBILENETV2

print("Building MobileNetV2...")

base_model = keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights="imagenet",
)

# Stage 1: freeze the pretrained feature extractor.
base_model.trainable = False

inputs = keras.Input(
    shape=(224, 224, 3),
    name="mango_leaf_image",
)

x = data_augmentation(inputs)

# Keep this preprocessing inside the model so that both
# Keras and TFLite models receive the same input format.
x = keras.applications.mobilenet_v2.preprocess_input(x)

x = base_model(x, training=False)

x = layers.GlobalAveragePooling2D()(x)

x = layers.Dropout(0.30)(x)

outputs = layers.Dense(
    NUM_CLASSES,
    activation="softmax",
    name="disease_prediction",
)(x)

model = keras.Model(
    inputs=inputs,
    outputs=outputs,
    name="EXOCARP_MobileNetV2",
)

model.summary()


# 10. MODEL PATHS

best_model_path = OUTPUT_DIR / "exocarp_best.keras"

keras_model_path = (
    OUTPUT_DIR / "exocarp_mango_disease_model.keras"
)

tflite_path = (
    OUTPUT_DIR / "exocarp_mango_disease_model.tflite"
)

class_names_path = OUTPUT_DIR / "class_names.json"


# 11. CALLBACKS
#
# Save the best validation model across both training stages.
# Early stopping restores the best weights for the current stage.

callbacks = [
    keras.callbacks.ModelCheckpoint(
        filepath=str(best_model_path),
        monitor="val_accuracy",
        save_best_only=True,
        mode="max",
        verbose=1,
    ),
    keras.callbacks.EarlyStopping(
        monitor="val_loss",
        patience=4,
        restore_best_weights=True,
        verbose=1,
    ),
    keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.2,
        patience=2,
        min_lr=0.000001,
        verbose=1,
    ),
]


# 12. STAGE 1: TRAIN CLASSIFICATION HEAD

print()
print("=" * 65)
print("STAGE 1: TRAINING CLASSIFICATION LAYERS")
print("=" * 65)

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.001),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

history_stage_1 = model.fit(
    train_dataset,
    validation_data=val_dataset,
    epochs=INITIAL_EPOCHS,
    callbacks=callbacks,
)


# 13. STAGE 2: FINE-TUNE TOP MOBILENETV2 LAYERS

print()
print("=" * 65)
print("STAGE 2: FINE-TUNING MOBILENETV2")
print("=" * 65)

base_model.trainable = True

# Freeze most of the pretrained model and fine-tune only
# its later layers. Keep Batch Normalization layers frozen
# for more stable fine-tuning on this dataset.

fine_tune_from = max(0, len(base_model.layers) - 30)

for layer in base_model.layers[:fine_tune_from]:
    layer.trainable = False

for layer in base_model.layers[fine_tune_from:]:
    if isinstance(layer, layers.BatchNormalization):
        layer.trainable = False

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.00001),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

history_stage_2 = model.fit(
    train_dataset,
    validation_data=val_dataset,
    epochs=FINE_TUNE_EPOCHS,
    callbacks=callbacks,
)


# 14. LOAD BEST VALIDATION MODEL

print()
print("Loading best model based on validation accuracy...")

model = keras.models.load_model(best_model_path)


# 15. FINAL TEST EVALUATION
#
# The test set is used only after training and model selection.

print()
print("=" * 65)
print("FINAL TEST EVALUATION")
print("=" * 65)

test_loss, test_accuracy = model.evaluate(
    test_dataset,
    verbose=1,
)

print(f"\nTest loss: {test_loss:.4f}")
print(f"Test accuracy: {test_accuracy * 100:.2f}%")


# 16. CLASSIFICATION REPORT

print()
print("=" * 65)
print("PER-CLASS PRECISION, RECALL, AND F1-SCORE")
print("=" * 65)

probabilities = model.predict(
    test_dataset,
    verbose=1,
)

predicted_labels = np.argmax(probabilities, axis=1)

report = classification_report(
    test_labels,
    predicted_labels,
    labels=list(range(NUM_CLASSES)),
    target_names=CLASS_NAMES,
    digits=4,
    zero_division=0,
)

print(report)

report_path = OUTPUT_DIR / "classification_report.txt"

with open(report_path, "w", encoding="utf-8") as file:
    file.write(f"Test loss: {test_loss:.4f}\n")
    file.write(f"Test accuracy: {test_accuracy * 100:.2f}%\n\n")
    file.write(report)


# 17. CONFUSION MATRIX

matrix = confusion_matrix(
    test_labels,
    predicted_labels,
    labels=list(range(NUM_CLASSES)),
)

print("Confusion matrix: actual classes are rows; predictions are columns.")
print("Class order:")
for index, name in enumerate(CLASS_NAMES):
    print(f"{index}: {name}")

print(matrix)

matrix_path = OUTPUT_DIR / "confusion_matrix.csv"

np.savetxt(
    matrix_path,
    matrix,
    delimiter=",",
    fmt="%d",
)

with open(
    OUTPUT_DIR / "confusion_matrix_classes.json",
    "w",
    encoding="utf-8",
) as file:
    json.dump(CLASS_NAMES, file, indent=4)


# 18. SAVE FINAL KERAS MODEL

model.save(keras_model_path)

print(f"\nKeras model saved:\n{keras_model_path}")


# 19. SAVE CLASS NAMES IN THE EXACT OUTPUT ORDER

with open(
    class_names_path,
    "w",
    encoding="utf-8",
) as file:
    json.dump(CLASS_NAMES, file, indent=4)

print(f"Class names saved:\n{class_names_path}")


# 20. CONVERT TO TENSORFLOW LITE

print()
print("=" * 65)
print("CONVERTING TO TENSORFLOW LITE")
print("=" * 65)

converter = tf.lite.TFLiteConverter.from_keras_model(model)

tflite_model = converter.convert()

with open(tflite_path, "wb") as file:
    file.write(tflite_model)

print(f"TFLite model saved:\n{tflite_path}")


# 21. VERIFY TFLITE INPUT AND OUTPUT SHAPES

interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("\nTFLite input details:")
for detail in input_details:
    print("Shape:", detail["shape"])
    print("Type:", detail["dtype"])

print("\nTFLite output details:")
for detail in output_details:
    print("Shape:", detail["shape"])
    print("Type:", detail["dtype"])


# 22. FINAL SUMMARY

print()
print("=" * 65)
print("EXOCARP TRAINING COMPLETE")
print("=" * 65)

print(f"Total images: {len(image_paths)}")
print(f"Training images: {len(train_paths)}")
print(f"Validation images: {len(val_paths)}")
print(f"Testing images: {len(test_paths)}")
print(f"Test accuracy: {test_accuracy * 100:.2f}%")

print("\nOutput files:")
print(f"- {best_model_path}")
print(f"- {keras_model_path}")
print(f"- {tflite_path}")
print(f"- {class_names_path}")
print(f"- {report_path}")
print(f"- {matrix_path}")

print(
    "\nIMPORTANT: Review the test metrics and check for duplicate "
    "or related images across dataset splits before treating the "
    "reported accuracy as a real-world estimate."
)
