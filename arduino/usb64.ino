#include <RingBuf.h>

#define PB0 16    // PB0   = C  - Datenleitungen 0 bis 7 - C64 PIN Name <-> ESP32 Pin Nummer
#define PB1 17    // PB1   = D
#define PB2 18    // PB2   = E
#define PB3 19    // PB3   = F
#define PB4 21    // PB4   = H
#define PB5 22    // PB5   = J
#define PB6 23    // PB6   = K
#define PB7 25    // PB7   = L
#define PC2 14    // PC2   = 8  - Signal vom C64 zum NodeMCU - C64 löst PC2 IRQ aus wenn CIA Datenregister gelesen ODER geschrieben wird -
#define PA2 27    // PA2   = M  - Signal vom C64 zum NodeMCU - LOW = NodeMCU darf an den C64 senden - HIGH = C64 sendet gerade zum NodeMCU (Poweron C64 = HIGH)
#define FLAG2 26  // FLAG2 = B  - Signal vom NodeMCU zum C64 - geht kurz von HIGH auf LOW wenn ein Byte am Datenbus für den C64 anliegt - Löst IRQ beim C64 aus (Byte zum Abholen bereit)

#define LED_BUILTIN 2  // LED des ESP an Pin2 angeschlossen

bool inputmode = true;  // from perspective of NodeMCU
bool sending_blocked = false;

RingBuf<uint8_t, 32768> ringb_from_c64;
// RingBuf<uint8_t, 65535> ringb_to_c64;
QueueHandle_t ringb_to_c64;

void ICACHE_RAM_ATTR PA2irq();  // Interruptroutinen cachen - Bugfix ESP32 IDE Fehler ?
void ICACHE_RAM_ATTR PC2irq();
void handshake_flag2();

void task_serial_inbound(void *parameter) {
  while (true) {
    if (Serial.available() > 0 && uxQueueSpacesAvailable(ringb_to_c64) > 0) {  // anything to receive from USB?
      for (int i = 0; i < 256; i++) {  // 256 is default serial hw buffer
        int b = Serial.read();
        if (b == -1) break;
        if( xQueueSendToBack( ringb_to_c64,
                             ( void * ) &b,
                             ( TickType_t ) 100 ) != pdPASS )
        {
            Serial.print("Push fail");
        }
      }
    }
    vTaskDelay( 1 / portTICK_PERIOD_MS);
  }
}

void setup() {

  pinMode(PB0, INPUT);  // Beim Kaltstart erst alle Pins auf Input setzten bis C64 die Kontrolle übernimmt
  pinMode(PB1, INPUT);
  pinMode(PB2, INPUT);
  pinMode(PB3, INPUT);
  pinMode(PB4, INPUT);
  pinMode(PB5, INPUT);
  pinMode(PB6, INPUT);
  pinMode(PB7, INPUT);
  pinMode(PA2, INPUT);           // PA2 Signal sagt dem ESP32 ob er vom C64 lesen soll oder an den C64 senden darf - Signal bei Kaltstart HIGH = ESP soll LESEN
  pinMode(PC2, INPUT_PULLDOWN);  // PC2 Signal vom C64 an den ESP - LOW = Data can be collected
  pinMode(FLAG2, OUTPUT);
  digitalWrite(FLAG2, HIGH);  // FLAG2 signal from the ESP to the C64 - triggers NMI on the C64 = handshake

  pinMode(LED_BUILTIN, OUTPUT);     // LED kann geschrieben werden
  digitalWrite(LED_BUILTIN, HIGH);  // Eingebaute LED auf dem Developer Board einschalten
  Serial.begin(115200);  //250000
  ringb_to_c64 = xQueueCreate( 10, sizeof(byte) );
  if( ringb_to_c64 == NULL ) {
    Serial.print("Q fail");
  }
  attachInterrupt(digitalPinToInterrupt(PA2), PA2irq, CHANGE);  // ESP-IRQ Pins festlegen PA2 C64
  attachInterrupt(digitalPinToInterrupt(PC2), PC2irq, HIGH);    // ESP-IRQ Pins festlegen PC2 C64

//                       (task handler       , name, stack size, args, prio, handle, cpu#);
  xTaskCreatePinnedToCore(&task_serial_inbound, "SerialIn", 10000, NULL, 16, NULL, 1);

  // Waiting for C64 to power on
  for (int i = 0; i < 50; i++) {
    if (digitalRead(PA2) == LOW) {
      delay(50);
    } else {
      i = 50;
      // C64 powered on.
    }
  }
}  // end setup


// $0091	145	Flag	127 = STOP , 223 = C= , 239 = SPACE , 251 = CTRL , 255 = no key pressed
// $00C5	197		Matrix coordinate of last pressed key, 64 = none
// $00C6	198		Number of characters in keyboard buffer
// $00CB	203		Index to keyboard decoding table for currently pressed key, 64 = no key was depressed
// $00F5	245	Pointer	Low byte keyboard decoding table
// $00F6	246	Pointer	High byte keyboard decoding table

void loop() {
    uint8_t databyte = 0;

    if (ringb_from_c64.lockedPop(databyte)) { // send to USB
        Serial.write(databyte);
        // Serial.println(databyte, HEX);
    }

    while (inputmode == false && uxQueueMessagesWaiting(ringb_to_c64) > 0) {  // 256 is default serial hw buffer
      while (sending_blocked == true) {}
      delayMicroseconds(300);  //after PC2 ($dd01 was read) there is code to execute in C64 before it can poll for next FLAG2
      if (xQueueReceive(ringb_to_c64, &databyte, (TickType_t) 100 ) == pdPASS) {
        sendByteToC64(databyte);
        handshake_flag2();  // initiate transfer to C64 by triggering FLAG2
      }
    }
    delay(1);
}

/////// Subs IRQ

void PA2irq() {  // PA2 from the C64 switches the ESP to input or output mode

  if (digitalRead(PA2) == LOW) { // PA2==0 : c64 reads from esp
    pinMode(PB0, OUTPUT);
    pinMode(PB1, OUTPUT);
    pinMode(PB2, OUTPUT);
    pinMode(PB3, OUTPUT);
    pinMode(PB4, OUTPUT);
    pinMode(PB5, OUTPUT);
    pinMode(PB6, OUTPUT);
    pinMode(PB7, OUTPUT);
    // digitalWrite(LED_BUILTIN, LOW);  // Turn off the built-in LED on the developer board
    inputmode = false;
  } else {
    pinMode(PB0, INPUT);
    pinMode(PB1, INPUT);
    pinMode(PB2, INPUT);
    pinMode(PB3, INPUT);
    pinMode(PB4, INPUT);
    pinMode(PB5, INPUT);
    pinMode(PB6, INPUT);
    pinMode(PB7, INPUT);
    inputmode = true;
  }
}

void sendByteToC64(uint8_t databyte) {
  sending_blocked == true;
  if (databyte & (1 << 0))
    GPIO.out_w1ts = (1 << PB0);
  else
    GPIO.out_w1tc = (1 << PB0);
  if (databyte & (1 << 1))
    GPIO.out_w1ts = (1 << PB1);
  else
    GPIO.out_w1tc = (1 << PB1);
  if (databyte & (1 << 2))
    GPIO.out_w1ts = (1 << PB2);
  else
    GPIO.out_w1tc = (1 << PB2);
  if (databyte & (1 << 3))
    GPIO.out_w1ts = (1 << PB3);
  else
    GPIO.out_w1tc = (1 << PB3);
  if (databyte & (1 << 4))
    GPIO.out_w1ts = (1 << PB4);
  else
    GPIO.out_w1tc = (1 << PB4);
  if (databyte & (1 << 5))
    GPIO.out_w1ts = (1 << PB5);
  else
    GPIO.out_w1tc = (1 << PB5);
  if (databyte & (1 << 6))
    GPIO.out_w1ts = (1 << PB6);
  else
    GPIO.out_w1tc = (1 << PB6);
  if (databyte & (1 << 7))
    GPIO.out_w1ts = (1 << PB7);
  else
    GPIO.out_w1tc = (1 << PB7);
}

void handshake_flag2() {
  // delayMicroseconds(20);  //10 is safe, depends on code between lda $dd01 and RTI
  GPIO.out_w1ts = (1 << FLAG2);  // Flag2 flippen um am C64 FLAG IRQ auszulösen - Der holt dann Daten ab oder darf neue Daten an den Bus anlegen
  delayMicroseconds(3);  //=2 let C64 spot the signal; if too low, C64 behaves strangely
  GPIO.out_w1tc = (1 << FLAG2);
  // delayMicroseconds(100);  //too low makes c64 to skip bytes
}

void PC2irq() {          // PC2 IRQ was triggered because C64 has read or written data from the userport
  uint8_t databyte = 0;  // The byte that is read or written on the bus
  if (inputmode == true) {  // C64 completed sending to the ESP32
    databyte = 0;
    if ((GPIO.in >> PB0) & 1)
      databyte |= 1UL << 0;  // Read data lines and save in databyte
    if ((GPIO.in >> PB1) & 1)
      databyte |= 1UL << 1;
    if ((GPIO.in >> PB2) & 1)
      databyte |= 1UL << 2;
    if ((GPIO.in >> PB3) & 1)
      databyte |= 1UL << 3;
    if ((GPIO.in >> PB4) & 1)
      databyte |= 1UL << 4;
    if ((GPIO.in >> PB5) & 1)
      databyte |= 1UL << 5;
    if ((GPIO.in >> PB6) & 1)
      databyte |= 1UL << 6;
    if ((GPIO.in >> PB7) & 1)
      databyte |= 1UL << 7;
    ringb_from_c64.push(databyte);  // Receive byte and add to input
    GPIO.out_w1ts = (1 << FLAG2);  // Flag2 flippen um am C64 FLAG IRQ auszulösen - Der holt dann Daten ab oder darf neue Daten an den Bus anlegen
    delayMicroseconds(2);  //=2 let C64 spot the signal; if too low, C64 behaves strangely
    GPIO.out_w1tc = (1 << FLAG2);
    return;
  }                                 // Inputmode == true: Send data from C64 to ESP

  if (inputmode == false) {            // C64 receives from ESP32 {
    sending_blocked = false;
    return;
  }  // Inputmode false = Receive from ESP
}

