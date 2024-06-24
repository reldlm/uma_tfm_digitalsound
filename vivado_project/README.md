# vivado_project

El proyecto se ha desarrollado utilizando Vivado 2019.1 con la placa Digilent Basys3 como base de desarrollo. Esta placa integra una FPGA de la marca Xilinx modelo  XC7A35T-1CPG236C.

El directorio está compuesto por
 - /cons
 - /ip
 - /src
 - tfm_project.tcl

#### /cons
Directorio que almacena el archivo de restricciones del proyecto Vivado. Este archivo solo se debe modificar en el caso de querer usar otro modelo de FPGA.

#### /ip
Directorio que almacena los archivos Xilinx IP. En este caso, solo se incluye el archivo fuente del Clocking Wizard utilizado en el proyecto.

#### /src
Directorio que almacena los archivos fuente VHDL. Estos archivos implementan los módulos lógicos descritos en la memoria.

#### tfm_project.tcl
Archivo utilizado para generar el proyecto de Vivado.

## Generar el proyecto
Una vez clonado el repositorio, es necesario generar el proyecto de Vivado para poder cargar el hardware en la FPGA. Para ello se utiliza el archivo tfm_project.tcl.

 - Abre la terminal de Vivado ya sea desde la interfaz gráfica o con la que se instala en el ordenador
 - Accede al directorio usando el siguiente comando con tu ruta específica
 ```sh
 cd C:/Users/rodrigo/Documents/Master/TFM/repos/uma_tfm_digitalsound/vivado_project
 ```
 - Genera el proyecto utilizando el siguiente comando
  ```sh
source tfm_project.tcl 
```


