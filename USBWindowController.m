#import "USBWindowController.h"

//#import "rMath.m"

extern int usbstatus;

									 

									 
									 
static NSString *SystemVersion ()
{
	NSString *systemVersion = [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"];    
return systemVersion;
}

@implementation USBWindowController

static NSString *	SystemVersion();
int			SystemNummer;



- (void)Alert:(NSString*)derFehler
{
	NSAlert * DebugAlert=[NSAlert alertWithMessageText:@"Debugger!" 
		defaultButton:NULL 
		alternateButton:NULL 
		otherButton:NULL 
		informativeTextWithFormat:@"Mitteilung: \n%@",derFehler];
		[DebugAlert runModal];

}

- (void)observerMethod:(id)note
{
   NSLog(@"observerMethod userInfo: %@",[[note userInfo]description]);
   NSLog(@"observerMethod note: %@",[note description]);
   
}

void DeviceAdded(void *refCon, io_iterator_t iterator)
{
   NSLog(@"IOWWindowController DeviceAdded");
   NSDictionary* NotDic = [NSDictionary  dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:USBATTACHED],@"usb", nil];
   
   
   NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
   
   [nc postNotificationName:@"usbopen" object:NULL userInfo:NotDic];
   
}
void DeviceRemoved(void *refCon, io_iterator_t iterator)
{
   NSLog(@"IOWWindowController DeviceRemoved");
   NSDictionary* NotDic = [NSDictionary  dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:USBREMOVED],@"usb", nil];
   NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
   //[nc postNotificationName:@"usbopen" object:NULL userInfo:NotDic];
}

- (int)USBOpen
{
   
   int  r;
   
   r = rawhid_open(1, 0x16C1, 0x0481, 0xFFAB, 0x0200);
   if (r <= 0) 
   {
      //NSLog(@"USBOpen: no rawhid device found");
      //[AVR setUSB_Device_Status:0];
   }
   else
   {
      NSLog(@"USBOpen: found rawhid device %d",usbstatus);
      //[AVR setUSB_Device_Status:1];
      const char* manu = get_manu();
      //fprintf(stderr,"manu: %s\n",manu);
      NSString* Manu = [NSString stringWithUTF8String:manu];
      
      const char* prod = get_prod();
      //fprintf(stderr,"prod: %s\n",prod);
      NSString* Prod = [NSString stringWithUTF8String:prod];
      //NSLog(@"Manu: %@ Prod: %@",Manu, Prod);
      NSDictionary* USBDatenDic = [NSDictionary dictionaryWithObjectsAndKeys:Prod,@"prod",Manu,@"manu", nil];
 //     [AVR setUSBDaten:USBDatenDic];
    //  NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
      
    //  [nc postNotificationName:@"usbopen" object:NULL userInfo:NotDic];

      
   }
   usbstatus=r;
   
   return r;
}

- (void)stop_Timer
{
   if (readTimer)
   {
      if ([readTimer isValid])
      {
         //NSLog(@"stopTimer timer inval");
         [readTimer invalidate];
         
      }
      [readTimer release];
      readTimer = NULL;
   }
   
}


- (IBAction)reportReadUSB:(id)sender;
{
   NSLog(@"reportReadUSB");
   Stepperposition = 0;
   [self USB_ReadAktion:NULL];
   
 }

- (IBAction)reportWriteUSB:(id)sender;
{
   NSLog(@"reportWriteUSB");
   Stepperposition = 0;
   
   for (int i=0;i<8;i++)
   {
      NSMutableArray* tempArray = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%d",i+1],   [NSString stringWithFormat:@"%d",i+3],
                                   [NSString stringWithFormat:@"%d",i+4],
                                   [NSString stringWithFormat:@"%d",i+5],
                                   [NSString stringWithFormat:@"%d",i+6],
                                   [NSString stringWithFormat:@"%d",i+7],
                                   [NSString stringWithFormat:@"%d",i+8],
                                   [NSString stringWithFormat:@"%d",i+9],nil];
      [USB_DatenArray addObject:tempArray];
   }
   //NSLog(@"reportWriteUSB_DatenArray: %@",[USB_DatenArray description]);
   [self write_Abschnitt];
}

- (IBAction)reportWriteEEPROM:(id)sender;
{
   NSLog(@"reportWriteEEPROM");
   Stepperposition = 0;
   
   for (int i=0;i<8;i++)
   {
      NSMutableArray* tempArray = [[NSMutableArray alloc]initWithCapacity:0];
      
      for (int k=0;k<PAGESIZE-1;k++)
      {
         [tempArray addObject:[NSString stringWithFormat:@"%d",k+i]];
      }
      
      
      [tempArray addObject:[NSString stringWithFormat:@"%d",0xA0]]; // code
      
      [USB_DatenArray addObject:tempArray];
   }
   //NSLog(@"reportWriteEEPROM: %@",[USB_DatenArray description]);
   [self write_EEPROM];
}



- (NSDictionary*)datendic
{
      // Array an USB schicken
      NSNotificationCenter* nc=[NSNotificationCenter defaultCenter];
      NSMutableDictionary* SchnittdatenDic=[[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
   
   [SchnittdatenDic setObject:[NSNumber numberWithInt:1] forKey:@"pwm"];
   
   /*
    2013-08-02 09:14:29.023 USB_Stepper[1560:303] USB_DatenArray 0: (
    (
    39,
    1,
    8,
    1,
    34,
    0,
    39,
    0,
    39,
    1,
    8,
    1,
    34,
    0,
    39,
    0,
    0,
    1,
    0,
    0,
    76,
    1
    ),
    (
    217,
    0,
    75,
    0,
    27,
    0,
    79,
    0,
    217,
    0,
    75,
    0,
    27,
    0,
    79,
    0,
    0,
    0,
    0,
    1,
    76,
    1
    ),
    (
    238,
    0,
    37,
    0,
    26,
    0,
    170,
    0,
    238,
    0,
    37,
    0,
    26,
    0,
    170,
    0,
    0,
    2,
    0,
    2,
    76,
    1
    )
    )

    */
   //NSMutableArray* USB_DatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   for (int i=0;i<8;i++)
   {
      NSArray* temparray = [NSArray arrayWithObjects:[NSNumber numberWithInt:i],
                            [NSNumber numberWithInt:2*i],
                            [NSNumber numberWithInt:3*i],
                            [NSNumber numberWithInt:4*i],
                            [NSNumber numberWithInt:5*i],
                            [NSNumber numberWithInt:6*i],
                            [NSNumber numberWithInt:7*i],
                            [NSNumber numberWithInt:8*i],
                            [NSNumber numberWithInt:i],nil];
      [USB_DatenArray addObject:temparray];
   }
   
      [SchnittdatenDic setObject:USB_DatenArray forKey:@"USB_DatenArray"];
      [SchnittdatenDic setObject:[NSNumber numberWithInt:1] forKey:@"cncposition"];
      [SchnittdatenDic setObject:[NSNumber numberWithInt:0] forKey:@"home"]; //
   

   
      [SchnittdatenDic setObject:[NSNumber numberWithInt:0] forKey:@"art"]; //
      NSLog(@"reportUSB_SendArray SchnittdatenDic: %@",[SchnittdatenDic description]);
      
      //   [nc postNotificationName:@"usbschnittdaten" object:self userInfo:SchnittdatenDic];
      //NSLog(@"reportUSB_SendArray delayok: %d",delayok);
      [SchnittdatenDic setObject:[NSNumber numberWithInt:1] forKey:@"delayok"];
      
   return (NSDictionary*)SchnittdatenDic;
}

- (void)send_EEPROMpage:(int)EEPROMpage
{
   
   //EEPROMposition++;
   char*      sendbufferLO = malloc(PAGESIZE);
   char*      sendbufferHI = malloc(PAGESIZE);
   
   int stufe = 0;
   if (EEPROMpage < VEKTORSIZE / PAGESIZE)
   {
      int startposition = EEPROMpage * PAGESIZE;
      for (int pos = 0;pos < PAGESIZE;pos++)
      {
         
         //Wert an Stelle (pos + startposition) in ExpoDatenArray
         int lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:(pos + startposition)]intValue];
         sendbufferLO[pos] = lo;
         
         int hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:(pos + startposition)]intValue];
         sendbufferHI[pos] = hi;
      }
      
      fprintf(stderr,"send_EEPROMpage %d\t%d\t",EEPROMpage, startposition);
      for (int pos = 0;pos < PAGESIZE;pos++)
      {
         int wert = sendbufferHI[pos];
         wert <<= 8;
         wert += sendbufferLO[pos];
         //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
         fprintf(stderr,"\t%d",wert);
         
      }
      fprintf(stderr,"\n");
      
   }
   
   
   
   
   free (sendbufferLO);
   free (sendbufferHI);
   
}


- (void)write_EEPROM
{
	//NSLog(@"write_EEPROM USB_DatenArray anz: %d\n USB_DatenArray: %@",[USB_DatenArray count],[USB_DatenArray description]);
   
   if (Stepperposition < [USB_DatenArray count])
	{
      
 		
      char*      sendbuffer;
      sendbuffer=malloc(EE_PAGESIZE);
      //
      int i;
      
      NSMutableArray* tempUSB_DatenArray=(NSMutableArray*)[USB_DatenArray objectAtIndex:Stepperposition];
      
      NSScanner *theScanner;
      unsigned	  value;
      NSLog(@"write_EEPROM tempUSB_DatenArray count: %d",[tempUSB_DatenArray count]);
      //NSLog(@"loop start");
      //NSDate *anfang = [NSDate date];
      for (i=0;i<[tempUSB_DatenArray count];i++)
      {
         
         int tempWert=[[tempUSB_DatenArray objectAtIndex:i]intValue];
         //           fprintf(stderr,"%d\t",tempWert);
         NSString*  tempHexString=[NSString stringWithFormat:@"%x",tempWert];
         theScanner = [NSScanner scannerWithString:tempHexString];
         if ([theScanner scanHexInt:&value])
         {
            sendbuffer[i] = (char)value;
         }
         else
         {
            NSRunAlertPanel (@"Invalid data format", @"Please only use hex values between 00 and FF.", @"OK", nil, nil);
            //free (sendbuffer);
            return;
         }
         
         //sendbuffer[i]=(char)[[tempUSB_DatenArray objectAtIndex:i]UTF8String];
      }
      
      //sendbuffer[20] = 33;
      sendbuffer[31] = 0xA0;
      //NSLog(@"code: %d",sendbuffer[16]);
      
      
      fprintf(stderr,"write_EEPROM sendbuffer\n");
      for (i=0;i<PAGESIZE;i++ )
      {
         fprintf(stderr,"%X\t",sendbuffer[i] & 0xFF);
         
      }
      fprintf(stderr,"\n");
      
      int senderfolg= rawhid_send(0, sendbuffer, EE_PAGESIZE, 50);
      
      NSLog(@"write_EEPROM erfolg: %d Stepperposition: %d",senderfolg,Stepperposition);
      
      //dauer4 = [dateA timeIntervalSinceNow]*1000;
      //         int senderfolg= rawhid_send(0, newsendbuffer, 32, 50);
      
      //NSLog(@"write_EEPROM senderfolg: %X",senderfolg);
      //NSLog(@"write_EEPROM  Stepperposition: %d ",Stepperposition);
      
      Stepperposition++;
      free (sendbuffer);
      
	}
   else
   {
      NSLog(@"write_Abschnitt >count\n*\n\n");
      //NSLog(@"writeCNCAbschnitt timer inval");
      
      if (readTimer)
      {
         if ([readTimer isValid])
         {
            NSLog(@"write_Abschnitt timer inval");
            [readTimer invalidate];
         }
         [readTimer release];
         readTimer = NULL;
         
      }
      
      
   }
}

- (void)write_Abschnitt
{
	//NSLog(@"writeCNCAbschnitt USB_DatenArray anz: %d\n USB_DatenArray: %@",[USB_DatenArray count],[USB_DatenArray description]);
   
   if (Stepperposition < [USB_DatenArray count])
	{
      NSDate* dateA=[NSDate date];
      
 		
      char*      sendbuffer;
      sendbuffer=malloc(32);
      //
      int i;
      
      NSMutableArray* tempUSB_DatenArray=(NSMutableArray*)[USB_DatenArray objectAtIndex:Stepperposition];
      
      NSScanner *theScanner;
      unsigned	  value;
      //NSLog(@"writeCNCAbschnitt tempUSB_DatenArray count: %d",[tempUSB_DatenArray count]);
      //NSLog(@"loop start");
      //NSDate *anfang = [NSDate date];
      for (i=0;i<[tempUSB_DatenArray count];i++)
      {
         
         int tempWert=[[tempUSB_DatenArray objectAtIndex:i]intValue];
         //           fprintf(stderr,"%d\t",tempWert);
         NSString*  tempHexString=[NSString stringWithFormat:@"%x",tempWert];
         theScanner = [NSScanner scannerWithString:tempHexString];
         if ([theScanner scanHexInt:&value])
         {
            sendbuffer[i] = (char)value;
         }
         else
         {
            NSRunAlertPanel (@"Invalid data format", @"Please only use hex values between 00 and FF.", @"OK", nil, nil);
            //free (sendbuffer);
            return;
         }
         
         //sendbuffer[i]=(char)[[tempUSB_DatenArray objectAtIndex:i]UTF8String];
      }
      
      sendbuffer[20] = 33;
      //NSLog(@"code: %d",sendbuffer[16]);
      
      
      fprintf(stderr,"write_Abschnitt sendbuffer\n%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",
              sendbuffer[0],(sendbuffer[1]& 0x80),sendbuffer[2],(sendbuffer[3]&0x80),
              sendbuffer[4],sendbuffer[5],sendbuffer[6],sendbuffer[7],
              
              sendbuffer[8],sendbuffer[9],sendbuffer[10],sendbuffer[11],
              sendbuffer[12],sendbuffer[13],sendbuffer[14],sendbuffer[15],
              sendbuffer[16],sendbuffer[17],sendbuffer[18],sendbuffer[19],
              sendbuffer[20],sendbuffer[21],sendbuffer[22],sendbuffer[23]);
      
      
      int senderfolg= rawhid_send(0, sendbuffer, 32, 50);
      
      NSLog(@"write_Abschnitt erfolg: %d Stepperposition: %d",senderfolg,Stepperposition);
      //dauer4 = [dateA timeIntervalSinceNow]*1000;
      //         int senderfolg= rawhid_send(0, newsendbuffer, 32, 50);
      
      //NSLog(@"writeCNCAbschnitt senderfolg: %X",senderfolg);
      NSLog(@"write_Abschnitt  Stepperposition: %d ",Stepperposition);
      
      Stepperposition++;
      free (sendbuffer);
      
	}
   else
   {
      NSLog(@"write_Abschnitt >count\n*\n\n");
      //NSLog(@"writeCNCAbschnitt timer inval");
      
      if (readTimer)
      {
         if ([readTimer isValid])
         {
            NSLog(@"write_Abschnitt timer inval");
            [readTimer invalidate];
         }
         [readTimer release];
         readTimer = NULL;
         
      }
      
      
   }
}

- (void)read_USB:(NSTimer*) inTimer
{
	char        buffer[32]={};
	int	 		result = 0;
	NSData*		dataRead;
	int         reportSize=32;
   
   if (Stepperposition ==0)//< [USB_DatenArray count])
   {
      //     [self stop_Timer];
      //     return;
   }
	//NSLog(@"read_USB A");
   
   result = rawhid_recv(0, buffer, 32, 50);
   
   //NSLog(@"read_USB rawhid_recv: %d",result);
   dataRead = [NSData dataWithBytes:buffer length:reportSize];
   
   //NSLog(@"ignoreDuplicates: %d",ignoreDuplicates);
   //NSLog(@"lastValueRead: %@",[lastValueRead description]);
   
   //NSLog(@"result: %d dataRead: %@",result,[dataRead description]);
   if ([dataRead isEqualTo:lastValueRead])
   {
      //NSLog(@"read_USB Daten identisch");
   }
   else
   {
      //NSLog(@"result: %d dataRead: %@",result,[dataRead description]);
      [self setLastValueRead:dataRead];
      int abschnittfertig=(UInt8)buffer[0];     // code fuer Art des Pakets
      //NSLog(@"read_USB AbschnittFertig: %d",abschnittfertig);
      if (buffer[0])
      {
        // [USB_DataFeld setStringValue:[dataRead description]];
      }
      if (abschnittfertig==0)
      {
         //   return;
      }
      //NSDate* dateA=[NSDate date];
           
      
      int i=0;
      //NSLog(@"read_USB AbschnittFertig buffer:");
      //fprintf(stderr,"data:\t");
      if (!(buffer[3] == lastdata0))
      {
         if (buffer[3])
         {
         lastdata0 = buffer[3];
         //fprintf(stderr,"%d\t%d\n",(buffer[3]& 0xFF),(buffer[4]& 0xFF));
         }
      }
      
      if (buffer[0])
      {
      for (i=0;i<2;i++)
      {
         UInt8 wertL = (UInt8)buffer[2*i];
         UInt8 wertH = ((UInt8)buffer[2*i+1]);
         int wert = wertL | (wertH<<8);
          //int wert = wertL + (wertH );
       //  fprintf(stderr,"%d\t%d\t%d\t",wertL,wertH,(wert));
         //fprintf(stderr,"%d\t",(buffer[i]& 0xFF));
        // fprintf(stderr," | ");
      }
      //fprintf(stderr,"\n");
      }
      
      if (buffer[8])
      {
         
         //int kan0 = (UInt8)buffer[8] | ((UInt8)buffer[9]<<8);
         //int adc0H = (UInt8)buffer[6];
         //int adc0 = adc0L | (adc0H<<8);

         //fprintf(stderr,"%d\t%d\t%d\t",(buffer[9]& 0xFF),(buffer[8]& 0xFF),kan0);
         //fprintf(stderr,"%d\t",kan0);
         
      }
      
      //fprintf(stderr,"\n");

      
      if ((UInt8)buffer[0]>0)
      {
         /*
         for (i=0; i<16;i++)
         {
            //int zahlenwert = [[NSNumber numberWithInt:(UInt8)buffer[i]]intValue];
            int zahlenwert = (UInt8)buffer[i];
            char b = buffer[i];
            if (i==0)
            {
               fprintf(stderr,"%d * ",i);
            }
            fprintf(stderr,"\t%d",zahlenwert);
            
            //NSLog(@"i: %d char: %x data: %d",i,buffer[i],[[NSNumber numberWithInt:(UInt8)buffer[i]]intValue]);
         }
          
         int adc = (UInt8)buffer[5] | ((UInt8)buffer[6]<<8) ;
         fprintf(stderr,"\t%d",adc);
         fprintf(stderr,"\n");
          */
      }
      
      
      int runde = (UInt8)buffer[4];
      if (runde)
      {
         [rundeFeld setIntValue:runde];
      }
      
      int adc0L = (UInt8)buffer[5];
      int adc0H = (UInt8)buffer[6];
      int adc0 = adc0L | (adc0H<<8);
      
      //NSLog(@"adc0L: %d adc0H: %d adc0: %d",adc0L,adc0H,adc0);
      if (adc0L)
      {
         [ADC_DataFeld setIntValue:adc0];
         [ADC_Level setIntValue:adc0];
      }
      
      
      int pot0L = (UInt8)buffer[0];
      int pot0H = (UInt8)buffer[1];
      
      int pot0 = pot0L | (pot0H<<8);
      if (pot0L)
      {
         //NSLog(@"pot0L: %d pot0H: %d\n",pot0L,pot0H);
         //fprintf(stderr,"\t%d\t%d\t%d\n",pot0L,pot0H,pot0);
         [Pot0_Level setIntValue:pot0];
         [Pot0_Slider setIntValue:pot0];

         [Pot0_DataFeld setIntValue:pot0];
         //[Vertikalbalken setLevel:pot0/4096.0*255];
         [Vertikalbalken setLevel:(pot0-1000)/1000.0*255];

      }

      int pot1L = (UInt8)buffer[2];
      int pot1H = (UInt8)buffer[3];
      int pot1 = pot1L | (pot1H<<8);
      if (pot1L)
      {
         //pot1 >>=1;
         [Pot1_Level setIntValue:pot1];
         [Pot1_Slider setIntValue:pot1];
         [Pot1_DataFeld setIntValue:pot1];
      }
      if (pot0L && pot1L)
      {
         //fprintf(stderr,"\t%d\t%d\n",pot0,pot1);
      }
      
            
      //      NSMutableDictionary* NotificationDic=[[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
      
      //NSLog(@"**");
      //NSNumber* curr_num=[NSNumber numberWithInt:(UInt8)buffer[1]];
      
      NSNumber* AbschnittFertig=[NSNumber numberWithInt:(UInt8)buffer[0]];
      
      //NSLog(@"**read_USB   buffer 0 %d",(UInt8)buffer[0]);
      
      
      //    if ([AbschnittFertig intValue] >= 0xA0) // Code fuer Fertig: AD
      {
         // verschoben von oben
         NSMutableDictionary* NotificationDic=[[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
         
         NSNumber* Abschnittnummer=[NSNumber numberWithInt:(UInt8)buffer[5]];
         //NSLog(@"**readUSB   buffer 5 %d",(UInt8)buffer[5]);
         
         [NotificationDic setObject:Abschnittnummer forKey:@"inposition"];
         NSNotificationCenter* nc=[NSNotificationCenter defaultCenter];
         //         [nc postNotificationName:@"usbread" object:self userInfo:NotificationDic];
         
      }
      
      anzDaten++;
      
   }
}

/*******************************************************************/
// CNC
/*******************************************************************/
- (void)USB_ReadAktion:(NSNotification*)note
{
   //NSLog(@"USB_ReadAktion usbstatus: %d usb_present: %d",usbstatus,usb_present());
   int antwort=0;
   int delayok=0;
   
   /*
    int usb_da=usb_present();
    //NSLog(@"usb_da: %d",usb_da);
    
    const char* manu = get_manu();
    //fprintf(stderr,"manu: %s\n",manu);
    NSString* Manu = [NSString stringWithUTF8String:manu];
    
    const char* prod = get_prod();
    //fprintf(stderr,"prod: %s\n",prod);
    NSString* Prod = [NSString stringWithUTF8String:prod];
    //NSLog(@"Manu: %@ Prod: %@",Manu, Prod);
    */
   if (usbstatus == 0)
   {
      NSAlert *Warnung = [[[NSAlert alloc] init] autorelease];
      [Warnung addButtonWithTitle:@"Einstecken und einschalten"];
      [Warnung addButtonWithTitle:@"Zurueck"];
      //	[Warnung addButtonWithTitle:@""];
      //[Warnung addButtonWithTitle:@"Abbrechen"];
      [Warnung setMessageText:[NSString stringWithFormat:@"%@",@"CNC Schnitt starten"]];
      
      NSString* s1=@"USB ist noch nicht eingesteckt.";
      NSString* s2=@"";
      NSString* InformationString=[NSString stringWithFormat:@"%@\n%@",s1,s2];
      [Warnung setInformativeText:InformationString];
      [Warnung setAlertStyle:NSWarningAlertStyle];
      
      antwort=[Warnung runModal];
      
      // return;
      // NSLog(@"antwort: %d",antwort);
      switch (antwort)
      {
         case NSAlertFirstButtonReturn: // Einschalten
         {
            [self USBOpen];
         }break;
            
         case NSAlertSecondButtonReturn: // Ignorieren
         {
            return;
         }break;
            
         case NSAlertThirdButtonReturn: // Abbrechen
         {
            return;
         }break;
      }
      
   }
	//NSLog(@"USB_ReadAktion note: %@",[[note userInfo]description]);
   pwm = 77;
   
   if ([[note userInfo]objectForKey:@"pwm"])
   {
      pwm = [[[note userInfo]objectForKey:@"pwm"]intValue];
      //NSLog(@"USB_ReadAktion pwm: %d",pwm);
   }
   
   
//   if ([[note userInfo]objectForKey:@"USB_DatenArray"])
   {
      
      
      Stepperposition=1;
      
      
      if ([USB_DatenArray count])
      {
      if (sizeof(newsendbuffer))
      {
         free(newsendbuffer);
      }
      newsendbuffer=malloc(32);
      
      NSMutableArray* tempUSB_DatenArray=(NSMutableArray*)[USB_DatenArray objectAtIndex:Stepperposition];
      //[tempUSB_DatenArray addObject:[NSNumber numberWithInt:[AVR pwm]]];
      NSScanner *theScanner;
      unsigned	  value;
      //NSLog(@"USB_ReadAktion tempUSB_DatenArray count: %d",[tempUSB_DatenArray count]);
      //NSLog(@"tempUSB_DatenArray object 20: %d",[[tempUSB_DatenArray objectAtIndex:20]intValue]);
      //NSLog(@"loop start");
      int i=0;
      for (i=0;i<[tempUSB_DatenArray count];i++)
      {
         //NSLog(@"i: %d tempString: %@",i,tempString);
         int tempWert=[[tempUSB_DatenArray objectAtIndex:i]intValue];
         //           fprintf(stderr,"%d\t",tempWert);
         NSString*  tempHexString=[NSString stringWithFormat:@"%x",tempWert];
         
         //theScanner = [NSScanner scannerWithString:[[tempUSB_DatenArray objectAtIndex:i]stringValue]];
         theScanner = [NSScanner scannerWithString:tempHexString];
         if ([theScanner scanHexInt:&value])
         {
            newsendbuffer[i] = (char)value;
            //NSLog(@"writeCNCAbschnitt: index: %d	string: %@	hexstring: %@ value: %X	buffer: %x",i,tempString,tempHexString, value,sendbuffer[i]);
            //NSLog(@"writeCNC i: %d	Hexstring: %@ value: %d",i,tempHexString,value);
         }
         else
         {
            NSRunAlertPanel (@"Invalid data format", @"Please only use hex values between 00 and FF.", @"OK", nil, nil);
            return;
         }
      }
      
      
      
      [self write_Abschnitt];
      } // if count
      
      //NSLog(@"USB_ReadAktion Start Timer");
      
      // home ist 1 wenn homebutton gedrŸckt ist
      NSMutableDictionary* timerDic =[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"home", nil];
      
      
      if (readTimer)
      {
         if ([readTimer isValid])
         {
            NSLog(@"USB_ReadAktion laufender timer inval");
            [readTimer invalidate];
            
         }
         [readTimer release];
         readTimer = NULL;
         
      }
      
      readTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                    target:self
                                                  selector:@selector(read_USB:)
                                                  userInfo:timerDic repeats:YES]retain];
      
   }
}


/*" Invoked when the nib file including the window has been loaded. "*/
- (void) awakeFromNib
{
   
   uint8_t a=0;
   mausistdown=0;
   anzrepeat=0;
   int listcount=0;
   struct Abschnitt *first;
   // LinkedList
   first=NULL;
   
 // 

	
	uint8_t zahl=244;
	char string[3];
	uint8_t l,h;                             // schleifenzŠhler
	//NSLog(@"zahl: %d   hex: %02X ",zahl, zahl);
	
	
	//  string[4]='\0';                       // String Terminator
	string[2]='\0';                       // String Terminator
	l=(zahl % 16);
	if (l<10)
		string[1]=l +'0';  
	else
	{
		l%=10;
		string[1]=l + 'A'; 
		
	}
	zahl /=16;
	h= zahl % 16;
	if (h<10)
		string[0]=h +'0';  
	else
	{
		h%=10;
		string[0]=h + 'A'; 
	}
   
   EEPROMposition = 0;
   
   //int aa=(15625& 0x00FF)>>8;
   //int bb = 15625& 0x00FF;
   //NSLog(@"aa: %d bb: %d",aa,bb);
	
   Math = [[rMath alloc]init];
   
   ExpoDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   float delta = 0;
   for (int k=0;k<4;k++)
   {
      
      NSArray* dataArray = [Math expoArrayMitStufe:k];
      [ExpoDatenArray addObject:dataArray];
      
      
	}
   
    for (int stufe=0;stufe<4;stufe++)
    {
       fprintf(stderr,"%d\t",stufe);
       for (int pos=0;pos<VEKTORSIZE;pos++)
       {
         int lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]intValue];
         int hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]intValue];
          int wert = hi;
          wert <<= 8;
          wert += lo;
          //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
          fprintf(stderr,"\t%d",wert);
       }
       fprintf(stderr,"\n");

    }
   
   [self send_EEPROMpage:0];
   
   
   
	NSImage* myImage = [NSImage imageNamed: @"USB"];
	[NSApp setApplicationIconImage: myImage];
	
	
	
	NSString* SysVersion=SystemVersion();
	NSArray* VersionArray=[SysVersion componentsSeparatedByString:@"."];
	SystemNummer=[[VersionArray objectAtIndex:1]intValue];
	NSLog(@"SystemVersion: %@",SysVersion);
	
	dumpCounter=0;
	
   lastValueRead = [[NSData alloc]init];
   
	logEntries = [[NSMutableArray alloc] init];
	[logTable setTarget:self];
	[logTable setDoubleAction:@selector(logTableDoubleClicked)];
   
   halt=0;
	
	NSNotificationCenter * nc;
	nc=[NSNotificationCenter defaultCenter];
// CNC
    /*
	[nc addObserver:self
			 selector:@selector(CNCAktion:)
				  name:@"CNCaktion"
				object:nil];
	*/

   [nc addObserver:self
			 selector:@selector(USBOpen)
				  name:@"usbopen"
				object:nil];
   
   [nc addObserver:self
          selector:@selector(windowClosing:)
              name:NSWindowWillCloseNotification
            object:nil];

   [Vertikalbalken setLevel:144];
   [Vertikalbalken setNeedsDisplay:YES];

	lastDataRead=[[NSData alloc]init];
	
   // Einfuegen
   //	[self readPList];
	
	//[self showAVR:NULL];
		//[AVR setProfilPlan:NULL];
	//	[self showADWandler:NULL];	

   
   // End Einfuegen
   
   
   [self showWindow:NULL];
   
   // Menu aktivieren
	//[[FileMenu itemWithTag:1005]setTarget :AVR];
	//[ProfilMenu setTarget :AVR];
	//[[ProfilMenu itemWithTag:5001]setAction:@selector(readProfil:)];
	
	

	// 
	//
	USB_DatenArray=[[[NSMutableArray alloc]initWithCapacity:0]retain];
   
    
   schliessencounter=0;	// Zaehlt FensterschliessenAktionen
    
    ignoreDuplicates=1;
   
	int  r;
   
   r = [self USBOpen];
   
   if (usbstatus==0)
   {
      NSAlert *Warnung = [[[NSAlert alloc] init] autorelease];
      [Warnung addButtonWithTitle:@"Einstecken und einschalten"];
      [Warnung addButtonWithTitle:@"Weiter"];
      //	[Warnung addButtonWithTitle:@""];
      //[Warnung addButtonWithTitle:@"Abbrechen"];
      [Warnung setMessageText:[NSString stringWithFormat:@"%@",@"CNC-Programm starten"]];
      
      NSString* s1=@"USB ist noch nicht eingesteckt.";
      NSString* s2=@"";
      NSString* InformationString=[NSString stringWithFormat:@"%@\n%@",s1,s2];
      [Warnung setInformativeText:InformationString];
      [Warnung setAlertStyle:NSWarningAlertStyle];
      
      int antwort=[Warnung runModal];
      
      // return;
      // NSLog(@"antwort: %d",antwort);
      switch (antwort)
      {
         case NSAlertFirstButtonReturn: // Einschalten
         {
            [self USBOpen];
            /*
             int  r;
             
             r = rawhid_open(1, 0x16C0, 0x0480, 0xFFAB, 0x0200);
             if (r <= 0) 
             {
             NSLog(@"USBAktion: no rawhid device found");
             [AVR setUSB_Device_Status:0];
             return;
             }
             else
             {
             
             NSLog(@"USBAktion: found rawhid device %d",usbstatus);
             [AVR setUSB_Device_Status:1];
             }
             usbstatus=r;
             */
         }break;
            
         case NSAlertSecondButtonReturn: // Ignorieren
         {
            return;
         }break;
            
         case NSAlertThirdButtonReturn: // Abbrechen
         {
            return;
         }break;
      }
 
   }
   /*
	r = rawhid_open(1, 0x16C0, 0x0480, 0xFFAB, 0x0200);
	if (r <= 0) 
    {
        NSLog(@"no rawhid device found");
       //printf("no rawhid device found\n");
       [AVR setUSB_Device_Status:0];
       usbstatus=0;
       //USBStatus=0;
	}
   else
   {
      NSLog(@"awake found rawhid device");
      [AVR setUSB_Device_Status:1];
      usbstatus=1;
      //USBStatus=1;
      [self StepperstromEinschalten:1];
   }
   */
   
   const char* manu = get_manu();
   //fprintf(stderr,"manu: %s\n",manu);
   NSString* Manu = [NSString stringWithUTF8String:manu];
   
   const char* prod = get_prod();
   //fprintf(stderr,"prod: %s\n",prod);
   NSString* Prod = [NSString stringWithUTF8String:prod];
   NSLog(@"Manu: %@ Prod: %@",Manu, Prod);
   
   NSDictionary* USBDatenDic = [NSDictionary dictionaryWithObjectsAndKeys:Prod,@"prod",Manu,@"manu", nil];
   //[AVR setUSBDaten:USBDatenDic];

   
   //
   // von http://stackoverflow.com/questions/9918429/how-to-know-when-a-hid-usb-bluetooth-device-is-connected-in-cocoa
   
   IONotificationPortRef notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
   CFRunLoopAddSource(CFRunLoopGetCurrent(), 
                      IONotificationPortGetRunLoopSource(notificationPort), 
                      kCFRunLoopDefaultMode);
   
   CFMutableDictionaryRef matchingDict2 = IOServiceMatching(kIOUSBDeviceClassName);
   CFRetain(matchingDict2); // Need to use it twice and IOServiceAddMatchingNotification() consumes a reference
   
   
   io_iterator_t portIterator = 0;
   // Register for notifications when a serial port is added to the system
   kern_return_t result = IOServiceAddMatchingNotification(notificationPort,
                                                           kIOPublishNotification,
                                                           matchingDict2,
                                                           DeviceAdded,
                                                           self,           
                                                           &portIterator);
   while (IOIteratorNext(portIterator)) {}; // Run out the iterator or notifications won't start (you can also use it to iterate the available devices).
   
   // Also register for removal notifications
   IONotificationPortRef terminationNotificationPort = IONotificationPortCreate(kIOMasterPortDefault);
   CFRunLoopAddSource(CFRunLoopGetCurrent(),
                      IONotificationPortGetRunLoopSource(terminationNotificationPort),
                      kCFRunLoopDefaultMode);
   result = IOServiceAddMatchingNotification(terminationNotificationPort,
                                             kIOTerminatedNotification,
                                             matchingDict2,
                                             DeviceRemoved,
                                             self,         // refCon/contextInfo
                                             &portIterator);
   
   while (IOIteratorNext(portIterator)) {}; // Run out the iterator or notifications won't start (you can also use it to iterate the available devices).
   
   //
   NSRect Balkenrect = [Vertikalbalken frame];
   //[Vertikalbalken initWithFrame:Balkenrect];
   //[Vertikalbalken setLevel:177];
   [Vertikalbalken setNeedsDisplay:YES];
}

- (void) windowClosing:(NSNotification*)note
{
   NSLog(@"windowClosing: titel: %@",[[note object]title]);
   
}

- (void) dealloc
{
	NSLog(@"dealloc");
    [logEntries release];
    [lastValueRead release];
	[lastDataRead release];
    [super dealloc];
}


- (void) setLastValueRead:(NSData*) inData
{
   [inData retain];
   [lastValueRead release];
   lastValueRead = inData;
	
}






- (void)readPList
{
   
   return;
   
   
   // Anpassen
   
   
	BOOL USBDatenDa=NO;
	BOOL istOrdner;
	NSFileManager *Filemanager = [NSFileManager defaultManager];
	NSString* USBPfad=[[NSHomeDirectory() stringByAppendingFormat:@"%@%@",@"/Documents",@"/CNCDaten"]retain];
	USBDatenDa= ([Filemanager fileExistsAtPath:USBPfad isDirectory:&istOrdner]&&istOrdner);
	//NSLog(@"mountedVolume:    USBPfad: %@",USBPfad);	
	if (USBDatenDa)
	{
		
		//NSLog(@"awake: tempPListDic: %@",[tempPListDic description]);
		
		NSString* PListName=@"CNC.plist";
		NSString* PListPfad;
		//NSLog(@"\n\n");
		PListPfad=[USBPfad stringByAppendingPathComponent:PListName];
		NSLog(@"awake: PListPfad: %@ ",PListPfad);
		if (PListPfad)		
		{
			NSMutableDictionary* tempPListDic;//=[[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
			if ([Filemanager fileExistsAtPath:PListPfad])
			{
				tempPListDic=[NSMutableDictionary dictionaryWithContentsOfFile:PListPfad];
				NSLog(@"awake: tempPListDic: %@",[tempPListDic description]);

				if ([tempPListDic objectForKey:@"koordinatentabelle"])
				{
					//NSArray* PListKoordTabelle=[tempPListDic objectForKey:@"koordinatentabelle"];
               //NSLog(@"awake: PListKoordTabelle: %@",[PListKoordTabelle description]);
            }
			}
			
		}
		//	NSLog(@"PListOK: %d",PListOK);
		
	}//USBDatenDa
   [USBPfad release];
}

- (void)savePListAktion:(NSNotification*)note
{
   return;
   
   
   // aktion anpassen
   
   
	BOOL USBDatenDa=NO;
	BOOL istOrdner;
	NSFileManager *Filemanager = [NSFileManager defaultManager];
	NSString* USBPfad=[[NSHomeDirectory() stringByAppendingFormat:@"%@%@",@"/Documents",@"/CNCDaten"]retain];
   NSURL* USBURL=[NSURL fileURLWithPath:USBPfad];
	USBDatenDa= ([Filemanager fileExistsAtPath:USBPfad isDirectory:&istOrdner]&&istOrdner);
	//NSLog(@"mountedVolume:    USBPfad: %@",USBPfad );	
	if (USBDatenDa)
	{
		;
	}
	else
	{
		//BOOL OrdnerOK=[Filemanager createDirectoryAtPath:USBPfad attributes:NULL];
		BOOL OrdnerOK=[Filemanager createDirectoryAtURL:USBURL withIntermediateDirectories:NO attributes:nil error:nil];		//Datenordner ist noch leer
		
	}
	//	NSLog(@"savePListAktion: PListDic: %@",[PListDic description]);
	//	NSLog(@"savePListAktion: PListDic: Testarray:  %@",[[PListDic objectForKey:@"testarray"]description]);
	NSString* PListName=@"CNC.plist";
	
	NSString* PListPfad;
	//NSLog(@"\n\n");
	//NSLog(@"savePListAktion: SndCalcPfad: %@ ",SndCalcPfad);
	PListPfad=[USBPfad stringByAppendingPathComponent:PListName];
   NSURL* PListURL = [NSURL fileURLWithPath:PListPfad];
	//	NSLog(@"savePListAktion: PListPfad: %@ ",PListPfad);
	
   if (PListPfad)
	{
		//NSLog(@"savePListAktion: PListPfad: %@ ",PListPfad);
		
      
      
     
		NSMutableDictionary* tempPListDic;//=[[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
		NSFileManager *Filemanager=[NSFileManager defaultManager];
		if ([Filemanager fileExistsAtPath:PListPfad])
		{
			tempPListDic=[NSMutableDictionary dictionaryWithContentsOfFile:PListPfad];
			//NSLog(@"savePListAktion: vorhandener PListDic: %@",[tempPListDic description]);
		}
		
		else
		{
			tempPListDic=[[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
			//NSLog(@"savePListAktion: neuer PListDic");
		}
		//[tempPListDic setObject:[NSNumber numberWithInt:AnzahlAufgaben] forKey:@"anzahlaufgaben"];
		//[tempPListDic setObject:[NSNumber numberWithInt:MaximalZeit] forKey:@"zeit"];

 		
//		BOOL PListOK=[tempPListDic writeToURL:PListURL atomically:YES];
		
	}
	//	NSLog(@"PListOK: %d",PListOK);
	[USBPfad release];
	//[tempUserInfo release];
}

- (BOOL)windowShouldClose:(id)sender
{
	NSLog(@"windowShouldClose");
/*	
	NSNotificationCenter* nc=[NSNotificationCenter defaultCenter];
	NSMutableDictionary* BeendenDic=[[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];

	[nc postNotificationName:@"IOWarriorBeenden" object:self userInfo:BeendenDic];

*/
	
	return YES;
}

- (BOOL)windowWillClose:(id)sender
{
	NSLog(@"windowWillClose schliessencounter: %d",schliessencounter);
   /*
    NSNotificationCenter* nc=[NSNotificationCenter defaultCenter];
    NSMutableDictionary* BeendenDic=[[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
    
    [nc postNotificationName:@"IOWarriorBeenden" object:self userInfo:BeendenDic];
    
    */
	[NSApp terminate:self];
	return YES;
}


- (BOOL)Beenden
{
	NSLog(@"Beenden");
//   if (schliessencounter ==0)
   {
      //NSLog(@"Beenden savePListAktion");
      [self savePListAktion:NULL];
   }
	return YES;
}

- (void) FensterSchliessenAktion:(NSNotification*)note
{
   //NSLog(@"FensterSchliessenAktion note: %@ titel: %@ schliessencounter: %d",[note description],[[note object]title],schliessencounter);
   //NSLog(@"FensterSchliessenAktion contextInfo: %@",[[note contextInfo]description]);
	if (schliessencounter)
	{
		return;
	}
	NSLog(@"Fenster Schliessen");
		
   if ([[[note object]title]length] && ![[[note object]title]isEqualToString:@"Print"]) // nicht bei Printdialog
   {
      schliessencounter++;
      NSLog(@"hat Title");
      
      // "New Folder" wird bei 10.6.8 als Titel von open zurueckgegeben. Deshalb ausschliessen(iBook schwarz)
      
      if (!([[[note object]title]isEqualToString:@"CNC-Eingabe"]||[[[note object]title]isEqualToString:@"New Folder"]))
      {
         if ([self Beenden])
         {
            [NSApp terminate:self];
         }
      }
      else
      {
         NSLog(@"Nicht beenden");
      }
   }
   
}


- (void)BeendenAktion:(NSNotification*)note
{
NSLog(@"BeendenAktion");
[self terminate:self];
}


- (IBAction)terminate:(id)sender
{
	BOOL OK=[self Beenden];
	NSLog(@"terminate: OK: %d",OK);
	if (OK)
	{
      
		[NSApp terminate:self];
		
	}
	


}


@end
