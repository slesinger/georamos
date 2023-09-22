import serial

ser = serial.Serial('/dev/ttyUSB0', 57600)

while True:
    s = ser.read(100)
    for x in s:
        print(hex(x))
        x += 1
        ser.write(x)


ser.close()