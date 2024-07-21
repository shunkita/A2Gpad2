#include  <SPI.h>
#define SPI_SS0   5
#define SPI_SS1   21
#define SPI_SCLK  18
#define SPI_MOSI  23
#define SPI_MISO  19
#define BUTTON0   22
#define BUTTON1   32
#define LED       4
#define M_XDIR    2

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define PERIPHERAL_NAME                "Apple II Joystick"
#define SERVICE_UUID                "AF4E5769-F201-46AF-8897-5787719E48EE"
#define CHARACTERISTIC_INPUT_UUID   "DAEF00F5-CB68-4A1F-AB35-16C936FFD272"
//#define CHARACTERISTIC_OUTPUT_UUID  "643954A4-A6CC-455C-825C-499190CE7DB0"

uint8_t wData[2];
uint8_t rData[2];
int8_t user_spi_write( uint8_t sspin, uint8_t *reg_data, uint16_t len){
    int8_t result = 0;
    
    SPI.begin(SPI_SCLK,SPI_MISO,SPI_MOSI,sspin);
    digitalWrite(sspin, LOW);
    SPI.beginTransaction(SPISettings(8000000,MSBFIRST,SPI_MODE0)); 


    for(uint16_t i = 0; i < len; i++){
        SPI.transfer(*reg_data);
        ++reg_data;
    }
    digitalWrite(sspin, HIGH);
    SPI.endTransaction();
    
    return result;
}
int8_t user_spi_read(uint8_t *reg_data, uint16_t len){
    int8_t rslt = 0;

    SPI.beginTransaction(SPISettings(1000000,MSBFIRST,SPI_MODE0)); //設定して開始
    digitalWrite(SPI_SS0, LOW);
   
    for(uint16_t i = 0; i < len; i++){
        *reg_data = SPI.transfer(0x00);
        ++reg_data;
    }
    digitalWrite(SPI_SS0, HIGH);
    SPI.endTransaction();

    return rslt;
}

// Class defines methods called when a device connects and disconnects from the service
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        digitalWrite(LED, HIGH);
        Serial.println("BLE Client Connected");
    }
    void onDisconnect(BLEServer* pServer) {
        BLEDevice::startAdvertising();
        digitalWrite(LED, LOW);
        Serial.println("BLE Client Disconnected");
    }
};

class InputReceivedCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharWriteState) {
        uint8_t *inputValues = pCharWriteState->getData();

        

        switch(inputValues[0]) {
          case 0x00: // button0
            Serial.printf("button0:   %02x %02x\r\n", inputValues[0], inputValues[1]);  
//            outputData[0] = inputValues[0] + inputValues[1];  
            if (inputValues[1] == 0xff) {
              digitalWrite(BUTTON0, HIGH);
            }
            else {
              digitalWrite(BUTTON0, LOW);
            }
            break;
          case 0x01: // button1
            Serial.printf("button1:   %02x %02x\r\n", inputValues[0], inputValues[1]);  
              if (inputValues[1] == 0xff) {
              digitalWrite(BUTTON1, HIGH);
            }
            else {
              digitalWrite(BUTTON1, LOW);
            }
            break;
          
 //           outputData[0] = inputValues[0] - inputValues[1];  
            break;
          case 0x03: // paddle0
             Serial.printf("paddle0:   %02x %02x\r\n", inputValues[0], inputValues[1]); 
            wData[1] = inputValues[1];
            user_spi_write(SPI_SS0, wData, 2);  
          break;
          case 0x04: // paddle1
             Serial.printf("paddle1:   %02x %02x\r\n", inputValues[0], inputValues[1]); 
            wData[1] = inputValues[1];
            user_spi_write(SPI_SS1, wData, 2);  
          break; 
          case 0x07: // mouseX
             Serial.printf("mouseX:   %02x %02x %02x\r\n", inputValues[0], inputValues[1], inputValues[2]); 
           if (inputValues[2] == 0xff) {
              digitalWrite(BUTTON1, HIGH);
            }
            else {
              digitalWrite(BUTTON1, LOW);
            }
            wData[1] = inputValues[1];
            user_spi_write(SPI_SS1, wData, 2);  
          break;                     
          default: // other
            Serial.printf("other:   %02x %02x\r\n", inputValues[0], inputValues[1]); 
             //           outputData[0] = inputValues[0] * inputValues[1];  
        }
        
 //       Serial.printf("Sending response:   %02x\r\n", outputData[0]);  
        
 //       pOutputChar->setValue((uint8_t *)outputData, 1);
 //       pOutputChar->notify();
    }
};

void setup() {
  // put your setup code here, to run once:

  // Use the Arduino serial monitor set to this baud rate to view BLE peripheral logs 
  Serial.begin(115200);
  Serial.println("Begin Setup BLE Service and Characteristics");

  // Configure thes server

  BLEDevice::init(PERIPHERAL_NAME);
  BLEServer *pServer = BLEDevice::createServer();

  // Create the service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a characteristic for the service
  BLECharacteristic *pInputChar = pService->createCharacteristic(
                              CHARACTERISTIC_INPUT_UUID,                                        
                              BLECharacteristic::PROPERTY_WRITE_NR | BLECharacteristic::PROPERTY_WRITE);

//  pOutputChar = pService->createCharacteristic(
//                              CHARACTERISTIC_OUTPUT_UUID,
 //                             BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);

                                      
  // Hook callback to report server events
  pServer->setCallbacks(new ServerCallbacks());
  pInputChar->setCallbacks(new InputReceivedCallbacks());

  // Initial characteristic value
//  outputData[0] = 0x00;
//  pOutputChar->setValue((uint8_t *)outputData, 1);
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);

    pinMode(M_XDIR, OUTPUT);
  digitalWrite(M_XDIR, LOW);
  // Start the service
  pService->start();

  // Advertise the service
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE Service is advertising");

//
//SPI setup
  wData[0] = 0x0;
 pinMode(SPI_SS0,OUTPUT);
  digitalWrite(SPI_SS0, HIGH); //HにしてSS選択を解除
   pinMode(SPI_SS1,OUTPUT);
  digitalWrite(SPI_SS1, HIGH); //HにしてSS選択を解除
  //SPI.begin();
 // SPI.begin(SPI_SCLK,SPI_MISO,SPI_MOSI,SPI_SS0);

 //GPIO setup
  pinMode(BUTTON0, OUTPUT);
  digitalWrite(BUTTON0, LOW);
  pinMode(BUTTON1, OUTPUT);
  digitalWrite(BUTTON1, LOW);
}

void loop() {
  // put your main code here, to run repeatedly:



}
