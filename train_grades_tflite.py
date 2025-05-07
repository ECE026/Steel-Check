import os
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns
import matplotlib.pyplot as plt
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.utils import to_categorical

DATA_PATH = "corrosion_grades_augmented.npz"
CSV_PATH = "corrosion_dataset_index.csv"
OUTPUT_DIR = "forcp"
os.makedirs(OUTPUT_DIR, exist_ok=True)

data = np.load(DATA_PATH, allow_pickle=True)
X = data["X"]
Y = data["Y"]
classes = data["classes"]
filenames = data["filenames"]
print("Loaded grade augmented data:", X.shape)

le = LabelEncoder()
Y_encoded = le.fit_transform(Y)
Y_cat = to_categorical(Y_encoded)

indices = np.arange(len(X))

X_train, X_test, Y_train, Y_test, idx_train, idx_test = train_test_split(
    X, Y_cat, indices, test_size=0.2, random_state=42, stratify=Y_encoded
)

train_records = pd.DataFrame({
    "image_path": filenames[idx_train],
    "label": le.inverse_transform(np.argmax(Y_train, axis=1))
})
test_records = pd.DataFrame({
    "image_path": filenames[idx_test],
    "label": le.inverse_transform(np.argmax(Y_test, axis=1))
})

train_records.to_csv(os.path.join(OUTPUT_DIR, "grade_training_set.csv"), index=False)
test_records.to_csv(os.path.join(OUTPUT_DIR, "grade_testing_set.csv"), index=False)
print("Saved CSV subsets for training and testing sets.")

model = Sequential([
    Dense(512, activation='relu', input_shape=(2048,)),
    Dropout(0.3),
    Dense(256, activation='relu'),
    Dropout(0.3),
    Dense(len(classes), activation='softmax')
])

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

model.fit(X_train, Y_train, epochs=25, batch_size=32, validation_data=(X_test, Y_test))

Y_pred = model.predict(X_test)
Y_pred_labels = np.argmax(Y_pred, axis=1)
Y_test_labels = np.argmax(Y_test, axis=1)

print("\nCorrosion Grade Classification Report:")
print(classification_report(Y_test_labels, Y_pred_labels, target_names=classes))

cm = confusion_matrix(Y_test_labels, Y_pred_labels)
sns.heatmap(cm, annot=True, fmt='d', cmap='Greens', xticklabels=classes, yticklabels=classes)
plt.title("Confusion Matrix: Corrosion Grade")
plt.xlabel("Predicted")
plt.ylabel("True")
plt.show()

h5_path = os.path.join(OUTPUT_DIR, "grades_classifier_keras.h5")
model.save(h5_path)
print(f" Saved Keras model: {h5_path}")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

tflite_path = os.path.join(OUTPUT_DIR, "grades_classifier_keras.tflite")
with open(tflite_path, "wb") as f:
    f.write(tflite_model)

print(f" Saved TFLite model: {tflite_path}")

label_path = os.path.join(OUTPUT_DIR, "grades_labels.txt")
with open(label_path, "w") as f:
    for label in classes:
        f.write(label + "\n")
print(f" Saved label list: {label_path}")