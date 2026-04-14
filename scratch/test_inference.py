import tflite_runtime.interpreter as tflite
import numpy as np
import sys
from PIL import Image

def test(image_path):
    interpreter = tflite.Interpreter(model_path="/Volumes/Projects/BEM/2026/cicipscan/assets/models/1.tflite")
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    img = Image.open(image_path).resize((224, 224))
    img_data = np.array(img, dtype=np.float32)
    img_data = np.expand_dims(img_data, axis=0)
    
    # Try different normalizations since Dart uses 0..1 right now
    # Let's try 0..1 and -1..1
    input_0_1 = img_data / 255.0
    
    interpreter.set_tensor(input_details[0]['index'], input_0_1)
    interpreter.invoke()
    output_data_0_1 = interpreter.get_tensor(output_details[0]['index'])
    idx_0_1 = np.argmax(output_data_0_1)
    val_0_1 = output_data_0_1[0][idx_0_1]
    
    input_neg1_1 = (img_data / 127.5) - 1.0
    interpreter.set_tensor(input_details[0]['index'], input_neg1_1)
    interpreter.invoke()
    output_data_neg1_1 = interpreter.get_tensor(output_details[0]['index'])
    idx_neg1_1 = np.argmax(output_data_neg1_1)
    val_neg1_1 = output_data_neg1_1[0][idx_neg1_1]
    
    # Try custom normalization (ImageNet)
    mean = np.array([0.485, 0.456, 0.406]).astype(np.float32)
    std = np.array([0.229, 0.224, 0.225]).astype(np.float32)
    input_imagenet = (input_0_1 - mean) / std
    interpreter.set_tensor(input_details[0]['index'], input_imagenet)
    interpreter.invoke()
    output_imagenet = interpreter.get_tensor(output_details[0]['index'])
    idx_imagenet = np.argmax(output_imagenet)
    val_imagenet = output_imagenet[0][idx_imagenet]

    print(f"Norm 0..1  : Top Index {idx_0_1} ({val_0_1:.4f})")
    print(f"Norm -1..1 : Top Index {idx_neg1_1} ({val_neg1_1:.4f})")
    print(f"Norm ImageN: Top Index {idx_imagenet} ({val_imagenet:.4f})")

try:
    test("/Volumes/Projects/BEM/2026/cicipscan/assets/images/sushi.jpg")
except Exception as e:
    print(f"Error testing tflite: {e}")
