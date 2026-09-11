from pathlib import Path
import json
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from sklearn.model_selection import train_test_split
from PIL import Image

# ============================================================
# EXOCARP - Mango Leaf Disease Detection
# MobileNetV2 Training Script
# ============================================================

# -----------------------------
# 1. Configuration
# -----------------------------

DATASET_DIR = Path(r"C:\FlutterProjects\exocarp\MangoDataset\process data")
OUTPUT_DIR = Path(r"C:\FlutterProjects\exocarp\ai\models")

IMAGE_SIZE = (224, 224)
BATCH_SIZE = 16
SEED = 42
EPOCHS = 20

# -----------------------------
# 2. Class names
# -----------------------------

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

print("=" * 60)
print("EXOCARP - Mango Leaf Disease Detection")
print("=" * 60)

print(f"Dataset: {DATASET_DIR}")
print(f"Classes: {NUM_CLASSES}")
print(f"Image size: {IMAGE_SIZE}")
print(f"Batch size: {BATCH_SIZE}")
print()

# -----------------------------
# 3. Check dataset
# -----------------------------

if not DATASET_DIR.exists():
    raise FileNotFoundError(
        f"Dataset folder was not found:\n{DATASET_DIR}"
    )

for class_name in CLASS_NAMES:
    class_dir = DATASET_DIR / class_name

    if not class_dir.exists():
        raise FileNotFoundError(
            f"Missing class folder:\n{class_dir}"
        )

# -----------------------------
# 4. Collect image paths
# -----------------------------

image_paths = []
labels = []

valid_extensions = {".jpg", ".jpeg", ".png"}

for class_index, class_name in enumerate(CLASS_NAMES):
    class_dir = DATASET_DIR / class_name

    class_images = [
        path
        for path in class_dir.rglob("*")
        if path.is_file() and path.suffix.lower() in valid_extensions
    ]

    print(f"{class_name}: {len(class_images)} images")

    for image_path in class_images:
        image_paths.append(str(image_path))
        labels.append(class_index)

image_paths = np.array(image_paths)
labels = np.array(labels)

print()
print(f"Total images: {len(image_paths)}")

# -----------------------------
# 5. Split dataset
# -----------------------------
#
# First:
# 85% temporary training data
# 15% test data
#
# Then split the 85%:
# 82.35% training -> approximately 70% total
# 17.65% validation -> approximately 15% total
#
# Final:
# 70% training
# 15% validation
# 15% testing
# -----------------------------

train_paths, test_paths, train_labels, test_labels = train_test_split(
    image_paths,
    labels,
    test_size=0.15,
    random_state=SEED,
    stratify=labels,
)

train_paths, val_paths, train_labels, val_labels = train_test_split(
    train_paths,
    train_labels,
    test_size=(15 / 85),
    random_state=SEED,
    stratify=train_labels,
)

print()
print("Dataset split:")
print(f"Training:   {len(train_paths)} images")
print(f"Validation: {len(val_paths)} images")
print(f"Testing:    {len(test_paths)} images")

# -----------------------------
# 6. Image loading function
# -----------------------------

def load_image(path, label):
    image = tf.io.read_file(path)

    image = tf.image.decode_image(
        image,
        channels=3,
        expand_animations=False,
    )

    image.set_shape([None, None, 3])

    image = tf.image.resize(
        image,
        IMAGE_SIZE,
    )

    image = tf.cast(image, tf.float32)

    return image, label


# -----------------------------
# 7. Create TensorFlow datasets
# -----------------------------

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

# -----------------------------
# 8. Data augmentation
# -----------------------------

data_augmentation = keras.Sequential(
    [
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.1),
        layers.RandomZoom(0.1),
        layers.RandomContrast(0.1),
    ],
    name="data_augmentation",
)

# -----------------------------
# 9. Prepare datasets
# -----------------------------

train_dataset = (
    train_dataset
    .shuffle(
        buffer_size=len(train_paths),
        seed=SEED,
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

# -----------------------------
# 10. Build MobileNetV2 model
# -----------------------------

print()
print("Building MobileNetV2 model...")

base_model = tf.keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights="imagenet",
)

# Freeze pretrained layers initially
base_model.trainable = False

inputs = keras.Input(
    shape=(224, 224, 3),
    name="mango_leaf_image",
)

x = data_augmentation(inputs)

x = tf.keras.applications.mobilenet_v2.preprocess_input(x)

x = base_model(
    x,
    training=False,
)

x = layers.GlobalAveragePooling2D()(x)

x = layers.Dropout(0.2)(x)

outputs = layers.Dense(
    NUM_CLASSES,
    activation="softmax",
    name="disease_prediction",
)(x)

model = keras.Model(
    inputs,
    outputs,
    name="EXOCARP_MobileNetV2",
)

# -----------------------------
# 11. Compile model
# -----------------------------

model.compile(
    optimizer=keras.optimizers.Adam(
        learning_rate=0.001
    ),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

model.summary()

# -----------------------------
# 12. Create output directory
# -----------------------------

OUTPUT_DIR.mkdir(
    parents=True,
    exist_ok=True,
)

# -----------------------------
# 13. Training callbacks
# -----------------------------

best_model_path = OUTPUT_DIR / "exocarp_best.keras"

callbacks = [
    keras.callbacks.ModelCheckpoint(
        filepath=str(best_model_path),
        monitor="val_accuracy",
        save_best_only=True,
        mode="max",
        verbose=1,
    ),

    keras.callbacks.EarlyStopping(
        monitor="val_accuracy",
        patience=5,
        restore_best_weights=True,
        mode="max",
        verbose=1,
    ),

    keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.2,
        patience=2,
        min_lr=0.00001,
        verbose=1,
    ),
]

# -----------------------------
# 14. Train model
# -----------------------------

print()
print("=" * 60)
print("STARTING TRAINING")
print("=" * 60)

history = model.fit(
    train_dataset,
    validation_data=val_dataset,
    epochs=EPOCHS,
    callbacks=callbacks,
)

# -----------------------------
# 15. Evaluate on test dataset
# -----------------------------

print()
print("=" * 60)
print("EVALUATING MODEL")
print("=" * 60)

test_loss, test_accuracy = model.evaluate(
    test_dataset,
    verbose=1,
)

print()
print(f"Test Loss:     {test_loss:.4f}")
print(f"Test Accuracy: {test_accuracy * 100:.2f}%")

# -----------------------------
# 16. Save final Keras model
# -----------------------------

keras_model_path = OUTPUT_DIR / "exocarp_mango_disease_model.keras"

model.save(
    keras_model_path
)

print()
print(f"Keras model saved to:")
print(keras_model_path)

# -----------------------------
# 17. Save class names
# -----------------------------

class_names_path = OUTPUT_DIR / "class_names.json"

with open(
    class_names_path,
    "w",
    encoding="utf-8",
) as file:
    json.dump(
        CLASS_NAMES,
        file,
        indent=4,
    )

print()
print(f"Class names saved to:")
print(class_names_path)

# -----------------------------
# 18. Convert to TensorFlow Lite
# -----------------------------

print()
print("=" * 60)
print("CONVERTING TO TENSORFLOW LITE")
print("=" * 60)

converter = tf.lite.TFLiteConverter.from_keras_model(model)

tflite_model = converter.convert()

tflite_path = OUTPUT_DIR / "exocarp_mango_disease_model.tflite"

with open(
    tflite_path,
    "wb",
) as file:
    file.write(tflite_model)

print()
print(f"TFLite model saved to:")
print(tflite_path)

# -----------------------------
# 19. Final information
# -----------------------------

print()
print("=" * 60)
print("TRAINING COMPLETE")
print("=" * 60)

print(f"Training images:   {len(train_paths)}")
print(f"Validation images: {len(val_paths)}")
print(f"Testing images:    {len(test_paths)}")
print(f"Test accuracy:     {test_accuracy * 100:.2f}%")

print()
print("Files created:")
print(f"- {best_model_path.name}")
print(f"- {keras_model_path.name}")
print(f"- {tflite_path.name}")
print(f"- {class_names_path.name}")

print()
print("EXOCARP AI model is ready for Flutter integration.")