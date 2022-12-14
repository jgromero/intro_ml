library(tidyverse)
library(keras)
set.seed(0)

## -------------------------------------------------------------------------------------
## Cargar y pre-procesar datos

# Cargar MNIST
mnist   <- dataset_mnist()  # incluido en Keras

# Separar datos de entrenamiento y test
x_train <- mnist$train$x
y_train <- mnist$train$y
x_test  <- mnist$test$x
y_test  <- mnist$test$y

dim(x_train) # 60.000 matrices 28x28

image(x_train[1, , ])
title(paste("Category:", y_train[1]))

image(t(x_train[1, 28:1, ]), col = grey(seq(0, 1, length = 256)))
title(paste("Category:", y_train[1]))

# Redimensionar imagenes
x_train <- array_reshape(x_train, c(nrow(x_train), 784))  # 60.000 arrays de 784 elementos
x_test  <- array_reshape(x_test,  c(nrow(x_test),  784))  # 60.000 arrays de 784 elementos

# Reescalar valores de imagenes a [0, 255]
x_train <- x_train / 255
x_test  <- x_test  / 255

# Crear 'one-hot' encoding (codificación binaria)
y_train <- to_categorical(y_train, 10)
y_test  <- to_categorical(y_test,  10)

## -------------------------------------------------------------------------------------
## Crear modelo

# Definir arquitectura
model <- keras_model_sequential() %>%
  layer_dense(units = 256, activation = 'relu', input_shape = c(784)) %>% 
  layer_dense(units = 128, activation = 'relu') %>%
  layer_dense(units = 10, activation  = 'softmax')

summary(model)

# Compilar modelo
model %>% compile(
  loss = 'categorical_crossentropy',
  optimizer = optimizer_rmsprop(),
  metrics = c('accuracy')
)

# Entrenamiento
history <- model %>% 
  fit(
    x_train, y_train, 
    epochs = 20, 
    batch_size = 128, 
    validation_split = 0.2
  )

# Guardar modelo (HDF5)
model %>% save_model_hdf5("minist_rnn.h5")

# Visualizar entrenamiento
plot(history)

## -------------------------------------------------------------------------------------
## Evaluar modelo con datos de validación

# Calcular metrica sobre datos de validación
model %>% evaluate(x_test, y_test)

# Obtener predicciones de clase
predictions <- model %>% 
  predict(x_test) %>% 
  `>`(0.5) %>% 
  k_cast("int32") %>%
  data.matrix()

# Crear matriz de confusión
library(caret)
cm <- confusionMatrix(as.factor(mnist$test$y), as.factor(predictions))
cm_prop <- prop.table(cm$table)
plot(cm$table)
cm$table

library(scales)
cm_tibble <- as_tibble(cm$table)
ggplot(data = cm_tibble) + 
  geom_tile(aes(x=Reference, y=Prediction, fill=n), colour = "white") +
  geom_text(aes(x=Reference, y=Prediction, label=n), colour = "white") +
  scale_fill_continuous(trans = 'reverse') 
