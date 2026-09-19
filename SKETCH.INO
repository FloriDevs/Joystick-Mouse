const int pinX = A0;
const int pinY = A1;
const int pinSW = 2;

void setup() {
  Serial.begin(9600);
  pinMode(pinSW, INPUT_PULLUP);
}

void loop() {
  int x = analogRead(pinX);
  int y = analogRead(pinY);
  int sw = digitalRead(pinSW);

  Serial.print(x);
  Serial.print(",");
  Serial.print(y);
  Serial.print(",");
  Serial.println(sw);

  delay(20);
}
