#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

const char *ssid = "Bilal";
const char *password = "12345678";
const char *mqttServer = "test.mosquitto.org";  
const int mqttPort = 1883;
const char *mqttClientId = "COAL_PROJECT_2022-CS-196";
const char *outputTopic = "esp32/output_2022-CS-196";
const char *inputTopic = "esp32/input_2022-CS-196";
static unsigned long lastMillis = 0;

WiFiClient espClient;
PubSubClient client(espClient);

#define DHTPIN 5
#define DHTTYPE 11

const char* TemperatureInHumidity = "sensor/DHT11/humidity";
const char* TemperatureInCelcius = "sensor/DHT11/temperature_celcius";


DHT dht(DHTPIN,DHTTYPE);


void setup() {
  Serial.begin(115200);
  Serial2.begin(9600);
  WifiSetup();

  // Configure MQTT
  client.setServer(mqttServer, mqttPort);
  client.setCallback(callBack);
  connectToMQTT();
}

void WifiSetup(){
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.print("WiFi connected with IP address: ");
  Serial.println(WiFi.localIP());
}

void callBack(char* inputTopic, byte* message, unsigned int length) {
  Serial.print("Message arrived on topic: ");
  Serial.print(inputTopic);
  Serial.print(". Message : ");
  String messageTemp;
  char tempPressed;
  
  for (int i = 0; i < length; i++) {
    messageTemp += (char)message[i];
  }
  Serial.println(messageTemp);
  
  Serial.print("Message Sent to UART : ");
}


void loop() 
{
  SensorValues();
  if (WiFi.status() != WL_CONNECTED) 
  {
    WifiSetup();
  }
    

  if(Serial2.available()> 0)
  {
     int Value = Serial.read();
     Serial.print("Message Received through UART  :   ");
     Serial.println(Value);
     String  message = " Sensor Value ";
     message += String(Value);
     const char* mess = message.c_str();
     publishMessage(mess);
  }

  // Handle MQTT events
  if (!client.connected()) {
    connectToMQTT();
  }
  client.loop();

  // Message Publishing on app with delay of 5s
  if (millis() - lastMillis > 5000) {
    
    const char* message = "PROJECT WORKING ";
    publishMessage(message);
    lastMillis = millis();
  }
  
  // Data Sending to FireBase
}

void connectToMQTT() {
  while (!client.connected()) {
    Serial.println("Connecting to MQTT...");
    if (client.connect(mqttClientId)) {
      Serial.println("Connected to MQTT");
      client.subscribe(inputTopic);
    } 
    else {
      Serial.print("Failed with state   :  ");
      Serial.println(client.state());
      delay(2000);
    }
  }
}

void SensorValues()
{
    uint8_t Humidity = dht.readHumidity();
    uint8_t Celcius = dht.readTemperature();
    String mess1 = "Humidity Value : " + String(Humidity);
    String mess2 = "Temperature : " +String(Celcius);
    client.publish(outputTopic,mess1.c_str());
    client.publish(outputTopic, mess2.c_str());
}

void publishMessage(const char* message) {
  if (client.connected()) {
    client.publish(outputTopic, message);
    Serial.print("Message Published :  ");
    Serial.println(message);
  }
}
