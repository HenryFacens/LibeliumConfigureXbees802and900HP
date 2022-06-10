#include <WaspXBee900HP.h>
#include <WaspSensorAgr_v30.h>
#include <WaspFrame.h>

float radiation;
float value;
//float luxes = 0;
//float leaf = 0;
//float temp = 0;
//float humd  = 0;
//float pres = 0;
float watermark1 = 0;
float anemometer = 0;

// Destination MAC address
//////////////////////////////////////////
//char RX_ADDRESS[] = "0013A200406937A6";
char MESHLIUM_ADDRESS[] = "0013A200414847A0"; 
char RX_ADDRESS[] = "0013A200414847A0";

//char RX_ADDRESS[] = "000000000000FFFF";
//////////////////////////////////////////

// Define the Waspmote ID
char WASPMOTE_ID[] = "XbeeAgriculture3";


// define variable

uint8_t error_send;
uint8_t error_recive;
uint8_t error;

// PAN (Personal Area Network) Identifier
uint8_t  panID[2] = {0x11,0x11}; 

// Define Freq Channel to be set: 
// Center Frequency = 2.405 + (CH - 11d) * 5 MHz
//   Range: 0x0B - 0x1A (XBee)
//   Range: 0x0C - 0x17 (XBee-PRO)
uint8_t  channel = 0x17;



//packetXBee* packet; 

// Variable to store the read soil moisture value
//float soilMoistureValue;
//Variable to store the read temperature value
//float temperatureValue;  
//Variable to store the read humidity value
//float humidityValue;
weatherStationClass anemSensor;
watermarkClass wmSensor1(SOCKET_C);
radiationClass radSensor;
void setup()
{ 
  Agriculture.ON();
  // open USB port
  USB.ON();
   RTC.ON();

  USB.println(F("-------------------------------"));
  USB.println(F("Configure XBee 900HP"));
  USB.println(F("-------------------------------"));

  // init XBee 
  xbee900HP.ON();
  

  /////////////////////////////////////
  // 1. set channel 
  /////////////////////////////////////
  xbee900HP.setChannel( channel );

  // check at commmand execution flag
  if( xbee900HP.error_AT == 0 ) 
  {
    USB.print(F("1. Channel set OK to: 0x"));
    USB.printHex( xbee900HP.channel );
    USB.println();
  }
  else 
  {
    USB.println(F("1. Error calling 'setChannel()'"));
  }


  /////////////////////////////////////
  // 2. set PANID
  /////////////////////////////////////
  xbee900HP.setPAN( panID );

  // check the AT commmand execution flag
  if( xbee900HP.error_AT == 0 ) 
  {
    USB.print(F("2. PAN ID set OK to: 0x"));
    USB.printHex( xbee900HP.PAN_ID[0] ); 
    USB.printHex( xbee900HP.PAN_ID[1] ); 
    USB.println();
  }
  else 
  {
    USB.println(F("2. Error calling 'setPAN()'"));  
  }

 



  /////////////////////////////////////
  // 5. write values to XBee module memory
  /////////////////////////////////////
  xbee900HP.writeValues();

  // check the AT commmand execution flag
  if( xbee900HP.error_AT == 0 ) 
  {
    USB.println(F("5. Changes stored OK"));
  }
  else 
  {
    USB.println(F("5. Error calling 'writeValues()'"));   
  }

  USB.println(F("-------------------------------")); 

  // store Waspmote identifier in EEPROM memory
  frame.setID( WASPMOTE_ID );
//  Agriculture.ON();
}



void loop()
{ 
  error = xbee900HP.setRTCfromMeshlium(MESHLIUM_ADDRESS);
      
  // check flag
  if( error == 0 )
  {
    USB.print(F("SET RTC ok. "));
  }
  else 
  {
    USB.print(F("SET RTC error. "));
  }  
  
  USB.print(F("RTC Time:"));
  USB.println(RTC.getTime());
  
  value = radSensor.readRadiation();  
  radiation = value / 0.0002;
  watermark1 = wmSensor1.readWatermark();
  anemometer = anemSensor.readAnemometer();

  
//luxes = Agriculture.getLuxes(INDOOR);
//leaf = lwSensor.getLeafWetness(); 
//temp = Agriculture.getTemperature();
//humd  = Agriculture.getHumidity();
//pres = Agriculture.getPressure(); 

//  RTC.ON();
//Variable to store the read temperature value
//    temperatureValue=Agriculture.getTemperature(); 
//Variable to store the read humidity value
//    humidityValue=Agriculture.getTemperature();

  // 4.6 Print the result through the USB
//  USB.print(F("Temperature: "));
//  USB.print(temperatureValue);
//  USB.println(F("ยบC"));
//  USB.print(F("Humidity: "));
//  USB.print(humidityValue);
//  USB.println(F("%RH"));
//  USB.println();

  
  ///////////////////////////////////////////
  // 1. Create ASCII frame
  ///////////////////////////////////////////  

  // create new frame
  frame.createFrame(ASCII);  



  USB.println("Sensor de Radiacao Solar");
  frame.addSensor(SENSOR_AGR_PAR, radiation);
  USB.println("Sensor de Marca da agua");
  frame.addSensor(SENSOR_AGR_SOIL_C, watermark1);
  USB.println("Sensor 3000");
  frame.addSensor(SENSOR_AGR_ANE, anemometer);
  
  // add frame fields
  //frame.addSensor(SENSOR_TCB, temperatureValue);
  //frame.addSensor(SENSOR_HUMB, humidityValue);
 // USB.println(humidity);
  //frame.addSensor(SENSOR_HUMB, humidity);
  //USB.println(temperature);
 
  /*USB.println(temp);
  frame.addSensor(SENSOR_AGR_TC, temp);
  USB.println(pres);
  frame.addSensor(SENSOR_AGR_PRES,pres);
  USB.println(humd);
  frame.addSensor(SENSOR_AGR_HUM,humd);
  frame.addSensor(SENSOR_AGR_LW,leaf);
  USB.println(leaf);*/
  //USB.println(humd);
  //frame.addSensor(SENSOR_AGR_SOILTC,humd);
  //USB.println(luxes);
  //frame.addSensor(SENSOR_AGR_LUXES,luxes);
  

  ///////////////////////////////////////////
  // 2. Send packet
  ///////////////////////////////////////////  

  // send XBee packet
  error_send = xbee900HP.send( RX_ADDRESS, frame.buffer, frame.length );   

  error_recive=xbee900HP.receivePacketTimeout(10000);
  USB.println(xbee900HP._payload,xbee900HP._length);
  //check TX flag
  if( error_recive==0 )
  {
     USB.println(F("Something recived"));
     USB.println("PRIMANJE1");
     USB.println(xbee900HP._payload,xbee900HP._length);
     USB.println("PRIMANJE2");
     char *token=NULL;
     token =strtok((char *)xbee900HP._payload, "#");
     token = strtok(NULL, "#");
    
     USB.println("Actuation");
     USB.println(token);
      
      
    
     if(strcmp("on",token)==0)
     {
       USB.println("palim ledicu");
       Utils.setLED(LED1,LED_ON); 
     }
     else if(strcmp("off",token)==0)
    {
       USB.println("gasim ledicu");
       Utils.setLED(LED1,LED_OFF); 
    }else
    {
      USB.println("pogrešna komanda");
    }

  }
  else 
  {
    USB.println(F("reciveing_error"));
  }

  // wait for 0.1 seconds
  delay(100);
  
}
