
import json
import sys
from pathlib import Path

import numpy as np
import tensorflow as tf
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MODEL_DIR = ROOT / "ai" / "models"

KERAS_PATH = MODEL_DIR / "exocarp_mango_disease_model.keras"
TFLITE_PATH = MODEL_DIR / "exocarp_mango_disease_model.tflite"
CLASSES_PATH = MODEL_DIR / "class_names.json"

IMAGE_SIZE = 224


def load_image(image_path):
    image = Image.open(image_path).convert("RGB")
    image = image.resize(
        (IMAGE_SIZE, IMAGE_SIZE),
        Image.Resampling.BILINEAR,
    )
    return np.expand_dims(
        np.asarray(image, dtype=np.float32),
        axis=0,
    )


def print_predictions(title, scores, class_names):
    scores = np.asarray(scores).reshape(-1)

    print(f"\n{title}")

    for index in np.argsort(scores)[::-1]:
        print(
            f"{class_names[index]}: "
            f"{scores[index] * 100:.2f}%"
        )

    print(f"Highest prediction: {class_names[int(np.argmax(scores))]}")


def main():
    if len(sys.argv) < 2:
        print(
            'Usage: python ai\\diagnose_model.py '
            '"C:\\path\\to\\your\\anthracnose_image.jpg"'
        )
        return

    image_path = Path(sys.argv[1])

    if not image_path.is_file():
        print(f"Image not found: {image_path}")
        return

    for path in (KERAS_PATH, TFLITE_PATH, CLASSES_PATH):
        if not path.is_file():
            print(f"Required file not found: {path}")
            return

    with open(CLASSES_PATH, "r", encoding="utf-8") as file:
        class_names = json.load(file)

    image_input = load_image(image_path)

    keras_model = tf.keras.models.load_model(KERAS_PATH)

    keras_output = keras_model.predict(
        image_input,
        verbose=0,
    )

    interpreter = tf.lite.Interpreter(
        model_path=str(TFLITE_PATH)
    )
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print("TFLite input:", input_details[0]["shape"])
    print("TFLite input type:", input_details[0]["dtype"])
    print("TFLite output:", output_details[0]["shape"])
    print("Image:", image_path)

    interpreter.set_tensor(
        input_details[0]["index"],
        image_input.astype(input_details[0]["dtype"]),
    )

    interpreter.invoke()

    tflite_output = interpreter.get_tensor(
        output_details[0]["index"]
    )

    print_predictions(
        "KERAS MODEL",
        keras_output,
        class_names,
    )

    print_predictions(
        "TFLITE MODEL",
        tflite_output,
        class_names,
    )

    difference = np.max(
        np.abs(
            np.asarray(keras_output).reshape(-1)
            - np.asarray(tflite_output).reshape(-1)
        )
    )

    print(f"\nMaximum output difference: {difference:.8f}")


if __name__ == "__main__":
    main()
