# scripts

Las respuestas al impulso suelen estar codificadas utilizando archivos .wav. Para poder almacenar las respuestas en una FPGA es necesario transformar los archivos .wav en archivos .vhd

Se ha utilizado Matlab R2021a y Python 3.9.10

El directorio está compuesto por:
 - /files
 - wav_to_csv.m
 - csv_to_vhdl.py

#### /files
Directorio que almacena los archivos de respuesta al impulso y el resto de archivos de salida generados por los scripts.

A su vez está dividido en:
 - /IR -> Archivos de respuesta al impulso originales
 - /csv -> Archivos de respuesta al impulso en formato .csv
 - /vhd -> Archivos de respuesta al impulso en formato .vhd


#### wav_to_csv
Script de Matlab encargado de transformar los archivos de respuesta originales .wav en archivos .csv. Para correrlo es necesario abrir el archivo en Matlab R2021a.

El archivo de respuesta al impulso de entrada se establece en la línea 3 del script:

```sh
irFile = './files/IR/3000CStreetGarageStairwell.wav'
```

Y el archivo de salida generado en la línea 18:

```sh
csvwrite('./files/csv/ir_stairwell_44k.csv', timeResponse(1:32768));
```

El valor de rango indica el número de muestras de la respuesta al impulso que se van a incluir en el archivo .csv 

#### csv_to_vhdl.py
Script de Python encargado de transformar los valores de respuesta almacenados en el archivo .csv a un archivo .vhd para su posterior integración en el proyecto general de Vivado.

El archivo de respuesta al impulso de entrada .csv se establece en la línea 6 del script:

```sh
input_csv_file = './files/csv/ir_stairwell_44k.csv'
```

Y el archivo de salida .vhd generado en la línea 7:

```sh
output_vhd_file = './files/vhd/tfm_ir_coeff_buffer.vhd'
```

Este archivo es el que se incluye en el proyecto de Vivado como archivo fuente VHDL.

El resto de parámetros indican:
 - n_rams. Número de bloques de memoria utilizados en paralelo.
 - bits. Tamaño en 2^bits de cada bloque de memoria.
 - values_per_line. Número de valores que aparecen en cada línea del archivo .vhd.
 - ir_d_width. Tamaño de cada dato almacenado en memoria
 - fractional_bits. Número de bits utilizados para la parte fraccionaria de cada valor de respuesta.

```sh
n_rams = 32
bits = 10
values_per_line = 4
ir_d_width = 16
fractional_bits = 15
```

Una vez generado el archivo .vhd, este debe de sustituir el anterior archivo /vivado_project/src/tfm_ir_coeff_buffer.vhd