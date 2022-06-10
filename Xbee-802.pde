#include <WaspXBee802.h>
#include <WaspSensorCities_PRO.h>
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
char MESHLIUM_ADDRESS[] = "0013A200416A073B"; 
char RX_ADDRESS[] = "0013A200416A073B";

//char RX_ADDRESS[] = "000000000000FFFF";
//////////////////////////////////////////

// Define the Waspmote ID
char WASPMOTE_ID[] = "Ambiente_BL_A";


// define variable

uint32_t luminosity;
uint8_t error_send;
uint8_t error_recive;
uint8_t error;

// PAN (Personal Area Network) Identifier
uint8_t  panID[2] = {0x33,0x33}; 

// Define Freq Channel to be set: 
// Center Frequency = 2.405 + (CH - 11d) * 5 MHz
//   Range: 0x0B - 0x1A (XBee)
//   Range: 0x0C - 0x17 (XBee-PRO)
uint8_t  channel = 0x17;


//bme
luxesCitiesSensor  luxes(SOCKET_E);
bmeCitiesSensor  bme(SOCKET_A);

//Values

float temperature;
float humidity;
float pressure;

void setup()
{ 
  // open USB port
  USB.ON();
   RTC.ON();

  USB.println(F("-------------------------------"));
  USB.println(F("Configure XBee 802."));
  USB.println(F("-------------------------------"));

  // init XBee 
  xbee802.ON();
  luxes.ON();

  /////////////////////////////////////
  // 1. set channel 
  /////////////////////////////////////
  xbee802.setChannel( channel );

  // check at commmand execution flag
  if( xbee802.error_AT == 0 ) 
  {
    USB.print(F("1. Channel set OK to: 0x"));
    USB.printHex( xbee802.channel );
    USB.println();
  }
  else 
  {
    USB.println(F("1. Error calling 'setChannel()'"));
  }


  /////////////////////////////////////
  // 2. set PANID
  /////////////////////////////////////
  xbee802.setPAN( panID );

  // check the AT commmand execution flag
  if( xbee802.error_AT == 0 ) 
  {
    USB.print(F("2. PAN ID set OK to: 0x"));
    USB.printHex( xbee802.PAN_ID[0] ); 
    USB.printHex( xbee802.PAN_ID[1] ); 
    USB.println();
  }
  else 
  {
    USB.println(F("2. Error calling 'setPAN()'"));  
  }

 



  /////////////////////////////////////
  // 5. write values to XBee module memory
  /////////////////////////////////////
  xbee802.writeValues();

  // check the AT commmand execution flag
  if( xbee802.error_AT == 0 ) 
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
  error = xbee802.setRTCfromMeshlium(MESHLIUM_ADDRESS);
      
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


// definicoes
  temperature = bme.getTemperature();
  humidity = bme.getHumidity();
  pressure = bme.getPressure();
  luminosity = luxes.getLuminosity();
  

  ///////////////////////////////////////////
  // 1. Create ASCII frame
  ///////////////////////////////////////////  

  // create new frame
  frame.createFrame(ASCII);  


  
  USB.println("Temperatura");
  frame.addSensor(SENSOR_CITIES_PRO_TC, temperature);
  USB.println("Humidade");
  frame.addSensor(SENSOR_CITIES_PRO_HUM, humidity);
  USB.println("Pressao");
  frame.addSensor(SENSOR_CITIES_PRO_PRES, pressure);
  USB.println("Lux");
  frame.addSensor(SENSOR_CITIES_PRO_LUXES, luminosity);
  

  ///////////////////////////////////////////
  // 2. Send packet
  ///////////////////////////////////////////  

  // send XBee packet
  error_send = xbee802.send( RX_ADDRESS, frame.buffer, frame.length );   

  error_recive=xbee802.receivePacketTimeout(10000);
  USB.println(xbee802._payload,xbee802._length);
  //check TX flag
  if( error_recive==0 )
  {
     USB.println(F("Something recived"));
     USB.println("PRIMANJE1");
     USB.println(xbee802._payload,xbee802._length);
     USB.println("PRIMANJE2");
     char *token=NULL;
     token =strtok((char *)xbee802._payload, "#");
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
