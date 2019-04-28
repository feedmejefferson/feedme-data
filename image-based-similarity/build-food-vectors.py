from keras.applications.resnet50 import ResNet50
from keras.preprocessing import image
from keras.applications.resnet50 import preprocess_input, decode_predictions
from keras.models import Model
import numpy as np
import os

base_model = ResNet50(weights='imagenet') 
model = Model(inputs=base_model.input, outputs=base_model.get_layer('avg_pool').output)

directory='../../images/images'
image_names = list(filter(lambda x: x.endswith('.jpg'), os.listdir(directory)))
features = np.zeros((2048,0))

for img_path in image_names:
    img_path = directory + '/' + img_path
    print(img_path)
    img = image.load_img(img_path, target_size=(224, 224))
    x = image.img_to_array(img)
    x = np.expand_dims(x, axis=0)
    x = preprocess_input(x)
    new_features = model.predict(x)
    new_features = np.reshape(new_features,[new_features.size,1])
    features = np.concatenate((features,new_features),axis=1)

np.savetxt('food-vectors.csv', features, delimiter=',', fmt='%10.10f', 
        header=','.join(image_names), comments='')

