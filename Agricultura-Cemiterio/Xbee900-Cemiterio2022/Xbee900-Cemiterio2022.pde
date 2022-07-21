#include <WaspXBee900HP.h>
#include <WaspSensorAgr_v30.h>
#include <WaspFrame.h>

float radiation;
float value;
uint32_t luxes;
float leaf = 0;
float temp = 0;
float humd  = 0;
float pres = 0;
float watermark1 = 0;
float anemometer;
float pluviometer1; //mm in current hour 
float pluviometer2; //mm in previous hour
float pluviometer3; //mm in last 24 hours
int vane;
int pendingPulses;
char nodeID[] = "node_WS";



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
  weatherStationClass anemSensor;
  watermarkClass wmSensor1(SOCKET_C);
  watermarkClass wmSensor2(SOCKET_C);
  watermarkClass wmSensor3(SOCKET_C);
  radiationClass radSensor;
  weatherStationClass weather;
  leafWetnessClass lwSensor;


void anemometerw(){
  // Turn on the USB and print a start message
  USB.ON();
  USB.println(F("Start program"));

  // Turn on the sensor board
  Agriculture.ON();
  
  USB.print(F("Time:"));
  RTC.ON();
  USB.println(RTC.getTime());  
 
}

void execution()
{
  /////////////////////////////////////////////
  // 1. Enter sleep mode
  /////////////////////////////////////////////
  Agriculture.sleepAgr("00:00:00:10", RTC_ABSOLUTE, RTC_ALM1_MODE5, SENSOR_ON, SENS_AGR_PLUVIOMETER);
  
  /////////////////////////////////////////////
  // 2.1. check pluviometer interruption
  /////////////////////////////////////////////
  if( intFlag & PLV_INT)
  {
    USB.println(F("+++ PLV interruption +++"));

    pendingPulses = intArray[PLV_POS];

    USB.print(F("Number of pending pulses:"));
    USB.println( pendingPulses );

    for(int i=0 ; i<pendingPulses; i++)
    {
      // Enter pulse information inside class structure
      weather.storePulse();

      // decrease number of pulses
      intArray[PLV_POS]--;
    }
    // Clear flag
    intFlag &= ~(PLV_INT); 
  }
  
  /////////////////////////////////////////////
  // 2.2. check RTC interruption
  /////////////////////////////////////////////
  if(intFlag & RTC_INT)
  {
    USB.println(F("+++ RTC interruption +++"));
    
    // switch on sensor board
    Agriculture.ON();
    
    RTC.ON();
    USB.print(F("Time:"));
    USB.println(RTC.getTime());    
        
    // measure sensors
    measureSensors();
    
    // Clear flag
    intFlag &= ~(RTC_INT); 
  }  
}


/*******************************************************************
 *
 *  measureSensors
 *
 *  This function reads from the sensors of the Weather Station and 
 *  then creates a new Waspmote Frame with the sensor fields in order 
 *  to prepare this information to be sent
 *
 *******************************************************************/
void measureSensors()
{  

  USB.println(F("------------- Measurement process ------------------"));
  
  /////////////////////////////////////////////////////
  // 1. Reading sensors
  ///////////////////////////////////////////////////// 

  // Read the anemometer sensor 
  anemometer = weather.readAnemometer();
  
  // Read the pluviometer sensor 
  pluviometer1 = weather.readPluviometerCurrent();
  pluviometer2 = weather.readPluviometerHour();
  pluviometer3 = weather.readPluviometerDay();
  
  /////////////////////////////////////////////////////
  // 2. USB: Print the weather values through the USB
  /////////////////////////////////////////////////////
  
  // Print the accumulated rainfall
  USB.print(F("Current hour accumulated rainfall (mm/h): "));
  USB.println( pluviometer1 );

  // Print the accumulated rainfall
  USB.print(F("Previous hour accumulated rainfall (mm/h): "));
  USB.println( pluviometer2 );

  // Print the accumulated rainfall
  USB.print(F("Last 24h accumulated rainfall (mm/day): "));
  USB.println( pluviometer3 );
  
  // Print the anemometer value
  USB.print(F("Anemometer: "));
  USB.print(anemometer);
  USB.println(F("km/h"));
    
  // Print the vane value
  char vane_str[10] = {0};
  switch(weather.readVaneDirection())
  {
  case  SENS_AGR_VANE_N   :  snprintf( vane_str, sizeof(vane_str), "N" );
                             break;
  case  SENS_AGR_VANE_NNE :  snprintf( vane_str, sizeof(vane_str), "NNE" );
                             break;  
  case  SENS_AGR_VANE_NE  :  snprintf( vane_str, sizeof(vane_str), "NE" );
                             break;    
  case  SENS_AGR_VANE_ENE :  snprintf( vane_str, sizeof(vane_str), "ENE" );
                             break;      
  case  SENS_AGR_VANE_E   :  snprintf( vane_str, sizeof(vane_str), "E" );
                             break;    
  case  SENS_AGR_VANE_ESE :  snprintf( vane_str, sizeof(vane_str), "ESE" );
                             break;  
  case  SENS_AGR_VANE_SE  :  snprintf( vane_str, sizeof(vane_str), "SE" );
                             break;    
  case  SENS_AGR_VANE_SSE :  snprintf( vane_str, sizeof(vane_str), "SSE" );
                             break;   
  case  SENS_AGR_VANE_S   :  snprintf( vane_str, sizeof(vane_str), "S" );
                             break; 
  case  SENS_AGR_VANE_SSW :  snprintf( vane_str, sizeof(vane_str), "SSW" );
                             break; 
  case  SENS_AGR_VANE_SW  :  snprintf( vane_str, sizeof(vane_str), "SW" );
                             break;  
  case  SENS_AGR_VANE_WSW :  snprintf( vane_str, sizeof(vane_str), "WSW" );
                             break; 
  case  SENS_AGR_VANE_W   :  snprintf( vane_str, sizeof(vane_str), "W" );
                             break;   
  case  SENS_AGR_VANE_WNW :  snprintf( vane_str, sizeof(vane_str), "WNW" );
                             break; 
  case  SENS_AGR_VANE_NW  :  snprintf( vane_str, sizeof(vane_str), "WN" );
                             break;
  case  SENS_AGR_VANE_NNW :  snprintf( vane_str, sizeof(vane_str), "NNW" );
                             break;  
  default                 :  snprintf( vane_str, sizeof(vane_str), "error" );
                             break;    
  }

  USB.println( vane_str );
  frame.addSensor(SENSOR_AGR_WV,vane_str);
  USB.println(F("----------------------------------------------------\n"));  
}

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
  temp = Agriculture.getTemperature();
  humd = Agriculture.getHumidity();
  pres = Agriculture.getPressure();

  
  luxes = Agriculture.getLuxes(INDOOR);
  leaf = lwSensor.getLeafWetness();
  temp = Agriculture.getTemperature();
  humd  = Agriculture.getHumidity();
  pres = Agriculture.getPressure(); 
  
  ///////////////////////////////////////////
  // 1. Create ASCII frame
  ///////////////////////////////////////////  

  // create new frame
  frame.createFrame(ASCII);  



  USB.println("Sensor de Radiacao Solar");
  USB.println(radiation);
  frame.addSensor(SENSOR_AGR_PAR, radiation);
  USB.println("Sensor de Marca da agua");
  USB.println(watermark1);
  frame.addSensor(SENSOR_AGR_SOIL_C, watermark1);
  USB.println("Sensor 3000");
  USB.println(anemometer);
  frame.addSensor(SENSOR_AGR_ANE, anemometer);
  USB.println("Temperatura C:");
  USB.println(temp);
  frame.addSensor(SENSOR_AGR_TC,temp);
  USB.println("Umidade");
  USB.println(humd);
  frame.addSensor(SENSOR_AGR_HUM,humd);
  USB.println("Pressao");
  USB.println(pres);
  frame.addSensor(SENSOR_AGR_PRES,pres);
  USB.println("Luz");
  USB.println(luxes);
  frame.addSensor(SENSOR_AGR_LUXES,luxes);
 
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

