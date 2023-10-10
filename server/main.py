import serial

ser = serial.Serial('/dev/ttyUSB0', 250000, timeout=0.02)

while True:

    s = ser.read(100)
    for x in s:
    #    if x != 0x30:
        print("Growser mode")
        bResponse = []
        # bResponse.append(int(0x05).to_bytes(1,'big'))
        # bResponse.append(int(0x08).to_bytes(1,'big'))
        bResponse.append(int(x).to_bytes(1,'big'))
        bResponse.append(int(x).to_bytes(1,'big'))
        bResponse.append(int(x).to_bytes(1,'big'))
        # bResponse.append(int(0x0c).to_bytes(1,'big'))
        # bResponse.append(int(0x09).to_bytes(1,'big'))
        # bResponse.append(int(0x0b).to_bytes(1,'big'))
        # bResponse.append(int(0x20).to_bytes(1,'big'))
        ser.write(b"".join(bResponse))
        ser.flush()
        print(hex(x))
#tohle funguje jen v synchronim modu, ne pres ISR.
# lda $dd0d vrati %10010001, coz jsou tyto flagy:
#TA
#FLG
#IR
#%00000100 ignor input mode
# 400 activity,  402 restore,  403 input isr, 405 key press, 406 byte received
"""
SDR neberu
    .label PORTA = base       port A PA2 na bitu 2 (pocitano od 0) $c3=11000011
    .label PORTB = base + 1   port B zde je paralelni 8 bit port
    .label DIRA = base + 2    data direction register A
    .label DIRB = base + 3    data direction register B 1=output (C64 will send to esp on PoartA), 0=input
    .label TIA = base + 4
    .label TIB = base + 6
    .label SDR = base + c
    .label ICR = base + d
    .label CRA = base + e
    .label CRB = base + f

400 - activity loop
402 - not port nmi , e.g. RESTORE
403 - NMI v input rezimu
406 - byl zavolan flagISR
407 - stav dd00 (PA2)



start_isr:
7f > dd0d stop all interrupts
318,319  NMI vector
0 > dd03  input to c64
set   %00000100 > dd02    // direction of PortA r/w for PA2;  
clear %11111011 > dd00    // set PA2 to low to signal we're ready to receive, 0=read from ESP, 1=write to ESP
lda dd0d                  // clear interrupt flags by reading
sta %10010000 > dd0d      // enable FLAG pin as interrupt source


"""
ser.close()