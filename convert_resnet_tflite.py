import tensorflow as tf
import os

OUTPUT_DIR = "forcp"
os.makedirs(OUTPUT_DIR, exist_ok=True)

print(" Loading ResNet50 (without top layers)...")
resnet_model = tf.keras.applications.ResNet50(
    include_top=False,
    weights="imagenet",
    pooling="avg",
    input_shape=(224, 224, 3)
)

h5_path = os.path.join(OUTPUT_DIR, "resnet_feature_extractor.h5")
resnet_model.save(h5_path)
print(f" Saved Keras model: {h5_path}")

converter = tf.lite.TFLiteConverter.from_keras_model(resnet_model)
tflite_model = converter.convert()

tflite_path = os.path.join(OUTPUT_DIR, "resnet_feature_extractor.tflite")
with open(tflite_path, "wb") as f:
    f.write(tflite_model)

print(f" Saved TFLite model: {tflite_path}")
