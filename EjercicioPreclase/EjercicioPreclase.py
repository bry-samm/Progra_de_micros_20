import serial

# Crear comunicación serial con el Arduino (COM10)
com_arduino = serial.Serial(port='COM10', baudrate=9600, timeout=0.1)

while True:
    ingreso = input("Ingrese el estado de la led 1 (ON) / 2 (OFF): ")  # Pedir al usuario
    com_arduino.write(bytes(ingreso, 'utf-8'))  # Enviar el número '1' o '2'
    retorno = com_arduino.readline()
    print(retorno)
