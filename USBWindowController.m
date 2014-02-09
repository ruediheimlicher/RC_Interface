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

- (IBAction)reportUSB:(id)sender
{
   if ([sender state])
   {
      [self startRead];
      
   }
   else
   {
      [self stopRead];
   }
}

- (IBAction)reportReadUSB:(id)sender;
{
   NSLog(@"reportReadUSB");
   Dataposition = 0;
   // home ist 1 wenn homebutton gedrückt ist
   NSMutableDictionary* timerDic =[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"home", nil];
   
   
   if (readTimer)
   {
      if ([readTimer isValid])
      {
         //NSLog(@"USB_Aktion laufender timer inval");
         [readTimer invalidate];
         
      }
      [readTimer release];
      readTimer = NULL;
      
   }
   NSLog(@"start Timer");
   readTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(read_USB:)
                                               userInfo:timerDic repeats:YES]retain];
   

   
   
 }

- (void)startRead
{
   //NSLog(@"startRead");
   Dataposition = 0;
   // home ist 1 wenn homebutton gedrückt ist
   NSMutableDictionary* timerDic =[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"home", nil];
   
   
   if (readTimer)
   {
      if ([readTimer isValid])
      {
         NSLog(@"startRead laufender timer inval");
         [readTimer invalidate];
         
      }
      [readTimer release];
      readTimer = NULL;
      
   }
   if (usbstatus)
   {
   
   readTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(read_USB:)
                                               userInfo:timerDic repeats:YES]retain];

   }
}


- (void)stopRead
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

- (IBAction)reportWriteTask:(id)sender
{
   
   int taskwahl = [[Taskwahl selectedCell]tag];
   NSLog(@"reportWriteTask: task: %d ",taskwahl);
   [self sendTask:taskwahl];
}


- (IBAction)reportWriteUSB:(id)sender;
{
   NSLog(@"reportWriteUSB");
   Dataposition = 0;
   [USB_DatenArray removeAllObjects];
   
   for (int i=0;i<8;i++)
   {
      NSMutableArray* tempArray = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%d",0xA2],
                                   [NSString stringWithFormat:@"%d",i+3],
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
   [self USB_Aktion:NULL]; // Antwort lesen
}

- (IBAction)reportRead_1_Byte:(id)sender
{
 //  [EE_taskmark setBackgroundColor:[NSColor redColor]];
 //  [EE_taskmark setStringValue:@" "];

   // D4
   NSLog(@"\n***");
   NSLog(@"reportRead_1_Byte");
   Dataposition = 0;
   usbtask = EEPROM_READ_TASK;
   [USB_DatenArray removeAllObjects];
   // Request einrichten
   NSMutableArray* codeArray = [[NSMutableArray alloc]initWithCapacity:USB_DATENBREITE];
   [codeArray addObject:[NSString stringWithFormat:@"%d",0xD4]];
   int EE_Startadresse = [EE_StartadresseFeld intValue];
   uint8 lo = EE_Startadresse & 0x00FF;
   uint8 hi = (EE_Startadresse & 0xFF00)>>8;
   
   [EE_DataFeld setStringValue:@""];
   [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%X",lo]];
   [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%X",hi]];
   
 
   
   fprintf(stderr,"Adresse: \t%d\t%d \thex \t%2X\t%2X\n",lo,hi, lo, hi);
   [codeArray addObject:[NSString stringWithFormat:@"%d",lo]]; // LO von Startadresse
   [codeArray addObject:[NSString stringWithFormat:@"%d",hi]]; // HI von Startadresse

   [USB_DatenArray addObject:codeArray];
   [self write_EEPROM];
   //[self USB_Aktion:NULL]; // Antwort lesen
   [EE_StartadresseFeld setIntValue:EE_Startadresse+1];


}

- (IBAction)reportRead_EEPROM_page:(id)sender
{
   // D4
   NSLog(@"\n***");
   NSLog(@"reportRead_EEPROM_page");
   Dataposition = 0;
   usbtask = EEPROM_READ_TASK;
   int startadresse = [EE_StartadresseFeld intValue];
   for (int i=startadresse;i< USB_DATENBREITE;i++)
   {
       
      [USB_DatenArray removeAllObjects];
      // Request einrichten
      NSMutableArray* codeArray = [[NSMutableArray alloc]initWithCapacity:USB_DATENBREITE];
      [codeArray addObject:[NSString stringWithFormat:@"%d",0xDA]];
      int EE_Startadresse = i;
      uint8 lo = EE_Startadresse & 0x00FF;
      uint8 hi = (EE_Startadresse & 0xFF00)>>8;
      
      [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%X",lo]];
      [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%X",hi]];
      
      fprintf(stderr,"Adresse: \t%d\t%d \thex \t%2X\t%2X\n",lo,hi, lo, hi);
      [codeArray addObject:[NSString stringWithFormat:@"%d",lo]]; // LO von Startadresse
      [codeArray addObject:[NSString stringWithFormat:@"%d",hi]]; // HI von Startadresse
      
      [USB_DatenArray addObject:codeArray];
      [self write_EEPROM];
   }
   //[self USB_Aktion:NULL]; // Antwort lesen
   
   
   
}


- (IBAction)reportWrite_1_Byte:(id)sender
{
   [EE_taskmark setBackgroundColor:[NSColor redColor]];
   [EE_taskmark setStringValue:@" "];
   eepromwritestatus |= (1<<EEPROM_WRITE_BUSY_BIT );
   eepromwritestatus &= ~(1<<EEPROM_WRITE_OK_BIT );

   // C4
   NSLog(@"\n***");
   NSLog(@"reportWrite_1_Byte");
   usbtask = EEPROM_WRITE_TASK;
   
   
    int EE_Startadresse = [EE_StartadresseFeld intValue];
   uint8 lo = EE_Startadresse & 0x00FF;
   uint8 hi = (EE_Startadresse & 0xFF00)>>8;
   
   int stufe = 1;
   uint8 data= [[[EEDatenArray objectAtIndex: stufe ]objectAtIndex:EE_Startadresse]intValue];

   
   //data = 0x14;
    
 //  [EE_DataFeld setIntValue: data];
   
    //reportWrite_1_Bytefprintf(stderr,"\n");
   fprintf(stderr,"data:\t%d\n",data);
 
   [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%X",lo]];
   [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%X",hi]];
   
   int EE_Data = [EE_DataFeld intValue];
   if (EE_Data == 0)
   {
      NSBeep();
      [EE_StartadresseFeld setIntValue:1];
   }
   
   NSLog(@"reportWrite_1_Byte Data: %X ",EE_Data);
   
    
   //[EE_datahi setStringValue:[NSString stringWithFormat:@"%X",datahi]];
   [EE_datalo setStringValue:[NSString stringWithFormat:@"%X",data]];

   uint8_t*      bytebuffer;
   bytebuffer=malloc(USB_DATENBREITE);
   
   bytebuffer[0] = 0xC4;
   bytebuffer[1] = EE_Startadresse & 0x00FF;
   bytebuffer[2] = (EE_Startadresse & 0xFF00)>>8;

   NSScanner* theScanner;
   unsigned	  value;
   NSString*  tempHexString=[NSString stringWithFormat:@"%02X",(uint8_t)data];
   theScanner = [NSScanner scannerWithString:tempHexString];
   
   if ([theScanner scanHexInt:&value])
   {
      bytebuffer[3] = (char)value;
      //fprintf(stderr,"%d\t%d\n",tempWert, (char)value);
   }
   else
   {
      NSRunAlertPanel (@"Invalid data format", @"Please only use hex values between 00 and FF.", @"OK", nil, nil);
      //free (sendbuffer);
      return;
   }
   bytebuffer[3] = EE_Data;
   fprintf(stderr,"bytebuffer ready: \t");
   for (int pos = 0;pos < EE_PARTBREITE;pos++)
   {
      fprintf(stderr,"\t%02X",bytebuffer[pos]);
   }
   fprintf(stderr,"\n");
  
   int senderfolg= rawhid_send(0, bytebuffer, 64, 50);
   
   NSLog(@"reportWrite_1_Byte erfolg: %d",senderfolg);
   if ([AdresseIncrement state])
   {
      [EE_StartadresseFeld setIntValue:EE_Startadresse+1];
   }
   
 //  [EE_DataFeld setIntValue:EE_Data+1];
   free(bytebuffer);
}


- (IBAction)reportWrite_1_Line:(id)sender;
{
   NSLog(@"reportWrite_1_Line");
   usbtask = EEPROM_AUSGABE_TASK;
   
   // ******************************************************************************************
   // Daten berechnen
   // ******************************************************************************************

   ExpoDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   int DIV = 32;
   
   for (int stufe=0;stufe<4;stufe++)
   {
      
      NSArray* dataArray = [Math expoArrayMitStufe:stufe];
      [ExpoDatenArray addObject:dataArray];
      
	}
   
   for (int stufe=0;stufe<4;stufe++)
   {
      //fprintf(stderr,"%d",stufe);
      int wert=0;
      checksumme=0;
      for (int pos=0;pos<VEKTORSIZE;pos++)
      {
         if (pos%DIV == 0)
         {
            wert=0;
            uint8 lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]intValue];
            uint8 hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]intValue];
            wert = hi;
            wert <<= 8;
            wert += lo;
            
            checksumme += wert;
            //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
            fprintf(stderr,"\t%d",wert);
            //fprintf(stderr,"\t%d\t%d",lo,hi);
         }
      }
      

      wert=0;
      uint8 lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]lastObject]intValue];
      uint8 hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]lastObject]intValue];
      wert = hi;
      wert <<= 8;
      wert += lo;
      //         fprintf(stderr,"\t%d",wert);
      //fprintf(stderr,"\t%d\t%d | ",lo,hi);
      fprintf(stderr,"\n");
      fprintf(stderr,"checksumme: \t%d\n",checksumme);
      [ChecksummenArray addObject:[NSNumber numberWithInt:checksumme]];
      
   }
   NSLog(@"ChecksummenArray count: %d : %@",[ChecksummenArray count],[ChecksummenArray description]);
      
   // ******************************************************************************************
   // Erster Abschnitt enthält code
   // ******************************************************************************************
   Dataposition = 0;
   [USB_DatenArray removeAllObjects];
   
   // Stufe 0
   NSMutableArray* codeArray = [[NSMutableArray alloc]initWithCapacity:USB_DATENBREITE];
   [codeArray addObject:[NSString stringWithFormat:@"%d",0xC6]];
   
   
   // Startadresse aus Eingabefeld
   
   int EE_Startadresse = [EE_StartadresseFeld intValue];
   uint8 lo = EE_Startadresse & 0x00FF;
   uint8 hi = (EE_Startadresse & 0xFF00)>>8;
   
   [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%X",lo]];
   [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%X",hi]];
   
   fprintf(stderr,"Adresse: \t%d\t%d\n",lo,hi);
   
   [codeArray addObject:[NSString stringWithFormat:@"%d",lo]]; // LO von Startadresse
   [codeArray addObject:[NSString stringWithFormat:@"%d",hi]]; // HI von Startadresse
   
   int anzpages = 2*VEKTORSIZE/PAGESIZE/DIV;
   anzpages = 1;
   NSLog(@"reportWrite_1_Line anz Datapages: %d",anzpages);
   [codeArray addObject:[NSString stringWithFormat:@"%d",anzpages]]; // Anzahl Pages mit Daten
  
   [EE_StartadresseFeld setIntValue:EE_Startadresse+1];
   // Abschnitt mit Code laden
   
   [USB_DatenArray addObject:codeArray];
   
   // ******************************************************************************************
   // Zweiter Abschnitt enthält Data
   // ******************************************************************************************
   
   for (int stufe=0;stufe<1;stufe++)
   {
      checksumme =0;
      NSMutableArray* tempArray = [[NSMutableArray alloc]initWithCapacity:0];
      //[tempArray addObject:[NSString stringWithFormat:@"%d",lo]]; // LO von Startadresse
      
      int index=0;
      int zaehler=0;
      // Daten lo, hi hintereinander einsetzen
      for (int pos=0;pos < VEKTORSIZE-2;pos++)
      {
         if (pos%DIV == 0)
         {
            [tempArray addObject:[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]];
            //[tempArray addObject:[NSString stringWithFormat:@"%d",[[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]intValue]]];
            zaehler++;
            [tempArray addObject:[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]];

            //[tempArray addObject:[NSString stringWithFormat:@"%d",[[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]intValue]]];
            zaehler++;
            
            int wert=0;
            uint8 lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]intValue];
            uint8 hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]intValue];
            wert = hi;
            wert <<= 8;
            wert += lo;
            
            checksumme += wert;

            

            
            
            //NSLog(@"pos: %d zaehler: %d",pos,zaehler);
            //if ((pos%PAGESIZE) == PAGESIZE-1) // letztes Element geladen
            if ((zaehler) == VEKTORSIZE/DIV) // letztes Element geladen
            {
               //NSLog(@"reportWriteEEPROM Abschnitt %d zaehler: %d anzahl: %ul Data: \n%@",index, zaehler, [tempArray count], tempArray );
               //NSLog(@"Abschnitt %d zaehler: %d anzahl: %lu ",index, zaehler, (unsigned long)[tempArray count] );
      
               
               // Abschnitt mit Daten laden
               index++;
               zaehler=0;
               
            }
         } // DIV
      }
      [USB_DatenArray addObject:[tempArray copy]];
      [tempArray removeAllObjects];
  fprintf(stderr,"checksumme: \t%d\n",checksumme);

   }
   //  NSLog(@"reportWrite_1_line anzahl Abschnitte: %@",[USB_DatenArray description]);
   for (int pos=0;pos<VEKTORSIZE;pos++)
   {
      if (pos%DIV == 0)
      {
         int wert=0;
         uint8 lo = [[[[ExpoDatenArray objectAtIndex:1]objectAtIndex:0]objectAtIndex:pos]intValue];
         uint8 hi = [[[[ExpoDatenArray objectAtIndex:1]objectAtIndex:1]objectAtIndex:pos]intValue];
         wert = hi;
         wert <<= 8;
         wert += lo;
         
         //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
         //fprintf(stderr,"\t%d",wert);
         fprintf(stderr,"\t%d\t%d",lo,hi);
      }
   }
   fprintf(stderr,"\n");
   
   NSLog(@"reportWrite_1_line ");
   
   for (int index=0;index<[USB_DatenArray count];index++)
   {
      NSArray* tempZeilenArray = [USB_DatenArray objectAtIndex:index];
      
      for (int k=0;k< [tempZeilenArray count];k++)
      {
         fprintf(stderr,"\t%d",[[tempZeilenArray  objectAtIndex:k]intValue]);
      }
      fprintf(stderr,"\n");
      for (int k=0;k< [tempZeilenArray count];k++)
      {
         fprintf(stderr,"\t%02X",[[tempZeilenArray  objectAtIndex:k]intValue]);
      }
      fprintf(stderr,"\n");
      /*
       int wert=0;
       uint8 lo = [[[[ExpoDatenArray objectAtIndex:1]objectAtIndex:0]objectAtIndex:pos]intValue];
       uint8 hi = [[[[ExpoDatenArray objectAtIndex:1]objectAtIndex:1]objectAtIndex:pos]intValue];
       wert = hi;
       wert <<= 8;
       wert += lo;
       
       //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
       //fprintf(stderr,"\t%d",wert);
       fprintf(stderr,"\t%d\t%d",lo,hi);
       */
      
   }
   
   
   fprintf(stderr,"\n");
   
   // ******************************************************************************************
   // Ende zweiter Abschnitt
   // ******************************************************************************************
   
   
   
   [self USB_Aktion:NULL];
   
}



- (IBAction)reportWriteEEPROM:(id)sender
{
   NSLog(@"\n***");
   NSLog(@"reportWriteEEPROM");
   usbtask = EEPROM_WRITE_TASK;
   //Daten berechnen
   ExpoDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   
   
   for (int stufe=0;stufe<4;stufe++)
   {
      
      NSArray* dataArray = [Math expoArrayMitStufe:stufe];
      [ExpoDatenArray addObject:dataArray];
       
	}
   
   
   
   

   for (int stufe=0;stufe<4;stufe++)
   {
      //fprintf(stderr,"%d",stufe);
      int wert=0;
      for (int pos=0;pos<VEKTORSIZE;pos++)
      {
         {
            wert=0;
         uint8 lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]intValue];
         uint8 hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]intValue];
         wert = hi;
         wert <<= 8;
         wert += lo;
            
         //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
//         fprintf(stderr,"\t%d",wert);
         //fprintf(stderr,"\t%d\t%d | ",lo,hi);
         }
      }
       wert=0;
         uint8 lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]lastObject]intValue];
         uint8 hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]lastObject]intValue];
         wert = hi;
         wert <<= 8;
         wert += lo;
//         fprintf(stderr,"\t%d",wert);
         //fprintf(stderr,"\t%d\t%d | ",lo,hi);
      //fprintf(stderr,"\n");
      
   }
   
   
   //NSMutableArray* neuerDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   

   Dataposition = 0;
   [USB_DatenArray removeAllObjects];
   // Erster Abschnitt enthält code
   
   // Stufe 0
   NSMutableArray* codeArray = [[NSMutableArray alloc]initWithCapacity:USB_DATENBREITE];
   [codeArray addObject:[NSString stringWithFormat:@"%d",0xC0]];
   
   
   [codeArray addObject:[NSString stringWithFormat:@"%d",0x00]]; // LO von Startadresse
   [codeArray addObject:[NSString stringWithFormat:@"%d",0x00]]; // HI von Startadresse
   int anzpages = 2*VEKTORSIZE/PAGESIZE;
   NSLog(@"reportWriteEEPROM anz Datapages: %d",anzpages);
   [codeArray addObject:[NSString stringWithFormat:@"%d",anzpages]]; // Anzahl Pages mit Daten
   
   [USB_DatenArray addObject:codeArray];
   
   for (int stufe=0;stufe<1;stufe++)
   {
      NSMutableArray* tempArrayLO = [[NSMutableArray alloc]initWithCapacity:0];
      NSMutableArray* tempArrayHI = [[NSMutableArray alloc]initWithCapacity:0];
      NSMutableArray* tempArray = [[NSMutableArray alloc]initWithCapacity:0];
      int index=0;
      int zaehler=0;
      // Daten lo, hi hintereinander einsetzen
      for (int pos=0;pos < VEKTORSIZE;pos++)
      {
         
        // [tempArrayLO addObject:[NSString stringWithFormat:@"%d",[[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]intValue]]];
        // [tempArrayHI addObject:[NSString stringWithFormat:@"%d",[[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]intValue]]];
         [tempArray addObject:[NSString stringWithFormat:@"%d",[[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]intValue]]];
         zaehler++;
         [tempArray addObject:[NSString stringWithFormat:@"%d",[[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]intValue]]];
         zaehler++;
         //NSLog(@"pos: %d zaehler: %d",pos,zaehler);
         //if ((pos%PAGESIZE) == PAGESIZE-1) // letztes Element geladen
         if ((zaehler) == PAGESIZE) // letztes Element geladen
        {
           //NSLog(@"reportWriteEEPROM Abschnitt %d zaehler: %d anzahl: %ul Data: \n%@",index, zaehler, [tempArray count], tempArray );
           //NSLog(@"Abschnitt %d zaehler: %d anzahl: %lu ",index, zaehler, (unsigned long)[tempArray count] );

           [USB_DatenArray addObject:[tempArray copy]];
           [tempArray removeAllObjects];
           index++;
           zaehler=0;
           
        }
      }
       
      //[USB_DatenArray addObject:tempArrayLO];
      //[USB_DatenArray addObject:tempArrayHI];
      
      
      
   
   }
   //NSLog(@"reportWriteEEPROM anzahl Abschnitte: %d",[USB_DatenArray count]);
   
  // NSLog(@"reportWriteEEPROM Code Abschnitt 0 : %@",[USB_DatenArray objectAtIndex:1]);
  // NSLog(@"reportWriteEEPROM Abschnitt 1 : %@",[USB_DatenArray objectAtIndex:1]);
  //  NSLog(@"reportWriteEEPROM letzter Abschnitt : %@",[USB_DatenArray lastObject]);
 //  [self write_EEPROM];
   
   [self USB_Aktion:NULL];
}

- (IBAction)reportHalt:(id)sender
{
   NSLog(@"reportHalt state: %ul",[sender state]);
   [self setHalt:[sender state]];
   return;
   /*
   if ([sender state] && (![readTimer isValid]))
   {
      NSAlert *Warnung = [[[NSAlert alloc] init] autorelease];
      [Warnung addButtonWithTitle:@"Read einschalten"];
      [Warnung addButtonWithTitle:@"Abbrechen"];
      //	[Warnung addButtonWithTitle:@""];
      //[Warnung addButtonWithTitle:@"Abbrechen"];
      [Warnung setMessageText:[NSString stringWithFormat:@"%@",@"Verbindung zum Master trennen"]];
      
      NSString* s1=@"USB Read ist nicht eingeschaltet.";
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
            [self startRead];
            //[read]
         }break;
            
         case NSAlertSecondButtonReturn: // Ignorieren
         {
            [sender setState:0];
            return;
            
         }break;
       }
      
   }


   int code = ![sender state];
   [Read_1_Byte_Taste setEnabled:[sender state]];
   [Write_1_Byte_Taste setEnabled:[sender state]];
   [Read_Part_Taste setEnabled:[sender state]];
   [Write_Part_Taste setEnabled:[sender state]];
   [Write_Stufe_Taste setEnabled:[sender state]];
   [FixSettingTaste setEnabled:[sender state]];
   [FixMixingTaste setEnabled:[sender state]];
   [ReadSettingTaste setEnabled:[sender state]];
   [MasterRefreshTaste setEnabled:[sender state]];

   
   [self sendTask:0xF6+code];
   */
}

- (void)setHalt:(int)status
{
   
   if (status && (![readTimer isValid]))
   {
      NSAlert *Warnung = [[[NSAlert alloc] init] autorelease];
      [Warnung addButtonWithTitle:@"Read einschalten"];
      [Warnung addButtonWithTitle:@"Abbrechen"];
      //	[Warnung addButtonWithTitle:@""];
      //[Warnung addButtonWithTitle:@"Abbrechen"];
      [Warnung setMessageText:[NSString stringWithFormat:@"%@",@"Verbindung zum Master trennen"]];
      
      NSString* s1=@"USB Read ist nicht eingeschaltet.";
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
            [self startRead];
            //[read]
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
            [Halt_Taste setState:0];
            return;
            
         }break;
            
            /*
             case NSAlertThirdButtonReturn: // Abbrechen
             {
             return;
             }break;
             */
      }
      
   }
   int code = !status;
   
   [Halt_Taste setState:status];
   [Read_1_Byte_Taste setEnabled:status];
   [Write_1_Byte_Taste setEnabled:status];
   [Read_Part_Taste setEnabled:status];
   [Write_Part_Taste setEnabled:status];
   [Write_Stufe_Taste setEnabled:status];
   [FixSettingTaste setEnabled:status];
   [FixMixingTaste setEnabled:status];
   [ReadSettingTaste setEnabled:status];
   [ReadSenderTaste setEnabled:status];
   [ReadFunktionTaste setEnabled:status];

   [MasterRefreshTaste setEnabled:status];
   
   
   [self sendTask:0xF6+code];

}


- (void)sendTask:(int)task
{
   NSLog(@"sendTask: task: %X",task);
   NSScanner *theScanner;
   unsigned	  value;

   char*      taskbuffer = malloc(8);
   NSString*  tempHexString=[NSString stringWithFormat:@"%x",task];
   theScanner = [NSScanner scannerWithString:tempHexString];
   if ([theScanner scanHexInt:&value])
   {
      taskbuffer[0] = (char)value;
   }
   else
   {
      NSRunAlertPanel (@"Invalid data format", @"Please only use hex values between 00 and FF.", @"OK", nil, nil);
      //free (sendbuffer);
      return;
   }
   int senderfolg= rawhid_send(0, taskbuffer, 8, 50);
   
   NSLog(@"sendTask erfolg: %d ",senderfolg);

   free(taskbuffer);
}

- (IBAction)reportFix_KanalSettings:(id)sender // 0xF4
{
   int modelindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];
  // NSLog(@"reportFix_Settings: modelindex: %d Settings: %@",modelindex,[SettingArray description]);
   
   
   uint8_t*      bytebuffer = malloc(USB_DATENBREITE);
   int Fix_Startadresse = TASK_OFFSET+ modelindex * SETTINGBREITE; //Speicherort fuer Kanal-Settings
   
   
   uint8 lo = Fix_Startadresse & 0x00FF;
   uint8 hi = (Fix_Startadresse & 0xFF00)>>8;
   bytebuffer[0] = 0xF4;
   bytebuffer[1] = Fix_Startadresse & 0x00FF;
   bytebuffer[2] = (Fix_Startadresse & 0xFF00)>>8;

   uint8_t changecode=0; // Bits fuer geaenderte Kanaele
   
   NSMutableArray * FixDatenArray = [[NSMutableArray alloc]initWithCapacity:0]; // Settings nur fuer zu aendernde Kanaele
   
   for (int kanal=0;kanal < [[ModelArray objectAtIndex:modelindex] count];kanal++)
   {
      if ([[[[ModelArray objectAtIndex:modelindex] objectAtIndex:kanal]objectForKey:@"go"]intValue])
      {
         [FixDatenArray addObject:[[ModelArray objectAtIndex:modelindex] objectAtIndex:kanal]];
         changecode |= (1<< kanal);
      }
   }
   bytebuffer[3] = changecode; // welcher kanal zu aendern
   bytebuffer[4] = modelindex; // welches modell
   
   fprintf(stderr,"\nreportFix_KanalSettings\n fixstartadresse: %d hex: %02X\tmodelindex: %d changecode: %d\n",Fix_Startadresse,Fix_Startadresse,modelindex,changecode);
/*
   for (uint8_t kanal=0;kanal < 8;kanal++)
   {
      if (changecode & (1<<kanal))
      {
        // fprintf(stderr,"+%d+\t",changecode & (1<<kanal));
         fprintf(stderr,"*%d*\t",kanal);
      }
   }// for kanal
   fprintf(stderr,"*\n");
*/   
/* 
 Aufbau:
 art = 0;      Offset: 2   EXPO_OFFSET
 expoa = 0;    Offset: 0
 expob = 2;    Offset: 4
 go = 1;
 kanal = 0;
 levela = 1;   Offset: 0   LEVEL_OFFSET
 levelb = 1;   Offset: 4
      
 nummer = 0;
 richtung = 0; Offset: 7   
 state = 1;
 
 (
 mixart = 0;      Offset: 0  // Art                  MIX_OFFSET
 mixcanals           Offset: 1 // wer mit welchem kanal
 
 )
 */
   NSLog(@"reportFix_KanalSettings Data: %@ changecode: %02X",FixDatenArray, changecode);

   int datastartbyte = 16; // Beginn  der Settings auf dem buffer
   fprintf(stderr,"kanalsettings:\n");
   for (int kanal=0;kanal < [FixDatenArray count];kanal++)
   {
      // beteiligte Kanaele
      uint8_t expowert =0;
      NSDictionary* kanalDic = [FixDatenArray objectAtIndex:kanal];
      int expoa = [[kanalDic objectForKey:@"expoa"]intValue];
      int expob = [[kanalDic objectForKey:@"expob"]intValue];
      
      fprintf(stderr,"\nkanal: %d expoa: %02X expob: %02X\n",kanal,expoa,expob);
      
      expowert |= expoa & 0x03; // expoa Bit 0,1
      fprintf(stderr,"expowert a: %02X\n",expowert);

      expowert |= ((expob & 0x03) << 4); // expob Bit 0,1
      fprintf(stderr,"expowert a|b: %02X\n",expowert);
      
      int art = [[kanalDic objectForKey:@"art"]intValue];
      fprintf(stderr,"art: %02X\n",art);
      
      expowert |= ((art & 0x03) << 2); // Bit 2,3
      fprintf(stderr,"expowert def: %02X\n",expowert);
     
      int richtung = [[kanalDic objectForKey:@"richtung"]intValue];
      fprintf(stderr,"richtung: %02X\n",richtung);

      
      expowert |= (richtung & 0x01) << 7; // Bit 7
      fprintf(stderr,"\nreportFix_KanalSettings kanal: %d expowert mit Ri: %02X\n",[[kanalDic objectForKey:@"nummer"]intValue],expowert);
      
      uint8_t levelwert =0;
      int levela = [[kanalDic objectForKey:@"levela"]intValue];
      levelwert |= (levela & 0x07) ; // Bit 0,1,2

      int levelb = [[kanalDic objectForKey:@"levelb"]intValue];
      //NSLog(@"expowertb: %d levelb: %d %d",levelwert,levelb, levelb & 0x07);
      levelwert |= (levelb & 0x07) <<4 ; // Bit 4,5,6
      
      bytebuffer[datastartbyte + 2*kanal] = expowert;
      bytebuffer[datastartbyte + 2*kanal + 1] = levelwert;
      
      fprintf(stderr,"reportFix_KanalSettings kanal: %d\t levelwert: %02X\texpowert:\t%02X\n",[[kanalDic objectForKey:@"nummer"]intValue],levelwert,expowert);

      //fprintf(stderr,"expo: \t%02X\tlevel\t%02X *\n",expowert,levelwert);
         
   } // for kanal
   
   fprintf(stderr,"\n");
   fprintf(stderr,"report FixSettings Data F4 bytebuffer ready to send: \n");
   for (int pos = 0;pos < EE_PARTBREITE;pos++)
   {
      if (pos%8 ==0)
      {
         fprintf(stderr,"\t");
      }
      if (pos%16 ==0)
      {
         fprintf(stderr,"\n");
      }
      
      fprintf(stderr,"\t%02X",bytebuffer[pos]);
   }
   fprintf(stderr,"\n");

   int senderfolg= rawhid_send(0, bytebuffer, 64, 50);
   
   free(bytebuffer);
   
   NSTimer* fixtimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
                                                     target:self
                                                   selector:@selector(FixSettingsTimeraktion:)
                                                   userInfo:NULL repeats:NO]retain];

   
   
}

- (void)FixSettingsTimeraktion:(NSTimer*)timer
{
   [self  reportRead_Settings:NULL];
   [timer release];
}


- (IBAction)reportRead_Settings:(id)sender // 0xF5
{
   [readsetting_mark setBackgroundColor:[NSColor redColor]];
   int modelindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];
   uint8_t*      bytebuffer;
   bytebuffer=malloc(USB_DATENBREITE);
   
   bytebuffer[0] = 0xF5;
   bytebuffer[1] = TASK_OFFSET & 0x00FF;
   bytebuffer[2] = (TASK_OFFSET & 0xFF00)>>8;
   bytebuffer[3] = modelindex;
   bytebuffer[4] = 1;// verbose Level
   bytebuffer[5] = 1;// verbose Expo
   bytebuffer[6] = 1;// verbose Mix
   
   int senderfolg= rawhid_send(0, bytebuffer, 64, 50);
   
   NSLog(@"reportRead_Settings erfolg: %d",senderfolg);
   free(bytebuffer);

}

- (IBAction)reportRead_SenderSettings:(id)sender // 0xFD
{
   [readsender_mark setBackgroundColor:[NSColor redColor]];
   int modelindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];
   uint8_t*      bytebuffer;
   bytebuffer=malloc(USB_DATENBREITE);
   
   bytebuffer[0] = 0xFD;
   bytebuffer[1] = TASK_OFFSET & 0x00FF;
   bytebuffer[2] = (TASK_OFFSET & 0xFF00)>>8;
   bytebuffer[3] = modelindex;
   
   int senderfolg= rawhid_send(0, bytebuffer, 64, 50);
   
   NSLog(@"reportRead_SenderSettings erfolg: %d",senderfolg);
   free(bytebuffer);
   
}

- (IBAction)reportRead_FunktionSettings:(id)sender // 0xE7
{
   [readfunktion_mark setBackgroundColor:[NSColor redColor]];
   int modelindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];
   uint8_t*      bytebuffer;
   bytebuffer=malloc(USB_DATENBREITE);
   
   bytebuffer[0] = 0xE7;
   bytebuffer[1] = TASK_OFFSET & 0x00FF;
   bytebuffer[2] = (TASK_OFFSET & 0xFF00)>>8;
   bytebuffer[3] = modelindex;
   
   int senderfolg= rawhid_send(0, bytebuffer, 64, 50);
   
   NSLog(@"reportRead_FunktionSettings modelindex: %d erfolg: %d",modelindex, senderfolg);
   free(bytebuffer);
   
}


- (IBAction)reportFix_FunktionSettings:(id)sender // 0xE6
{
   int modelindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];
   
 //  NSLog(@"\nreportFix_FunktionSettings: modelindex: %d Settings: %@",modelindex,[[FunktionArray objectAtIndex:modelindex] description]);
   
   uint8_t*      bytebuffer = malloc(USB_DATENBREITE);
   int Funktion_Startadresse = TASK_OFFSET + FUNKTION_OFFSET;
   
   NSLog(@"\nreportFix_FunktionSettings Funktion_Startadresse: %02X",Funktion_Startadresse);
   //   uint8 lo = Funktion_Startadresse & 0x00FF;
   //   uint8 hi = (Funktion_Startadresse & 0xFF00)>>8;
   bytebuffer[0] = 0xE6;
   bytebuffer[1] = Funktion_Startadresse & 0x00FF;
   bytebuffer[2] = (Funktion_Startadresse & 0xFF00)>>8;
   
   uint8_t changecode=0; // Bits fuer geaenderte Kanaele
   
//   fprintf(stderr,"\nreportFix_FunktionSettings modelindex: %d  count: %d\n",modelindex,(int)[[FunktionArray objectAtIndex:modelindex] count]);
   
   NSMutableArray * FunktionDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   
   for (int funktionindex=0;funktionindex < [[FunktionArray objectAtIndex:modelindex] count];funktionindex++)
   {
      if ([[[[FunktionArray objectAtIndex:modelindex] objectAtIndex:funktionindex]objectForKey:@"go"]intValue]) // Zeile soll revidiert werden
      {
         [FunktionDatenArray addObject:[[FunktionArray objectAtIndex:modelindex] objectAtIndex:funktionindex]];
         
         changecode |= (1<< funktionindex);
      }
   }
   bytebuffer[3] = changecode;
   bytebuffer[4] = modelindex; // welches modell
   
   fprintf(stderr,"\nreportFix_FunktionSettings modelindex: %d changecode: %d\n",modelindex,changecode);
   
   for (uint8_t kanal=0;kanal < 8;kanal++)
   {
      if (changecode & (1<<kanal))
      {
         // fprintf(stderr,"+%d+\t",changecode & (1<<kanal));
         fprintf(stderr,"*%d*\t",kanal);
      }
   }// for kanal
   fprintf(stderr,"\n");
   
   /*
    Datenaufbau default_funktionarray in RC_LCD:
    // index: Kanal
    // bit 0-2: Funktion Seite, Hoehe ... (Text aus FunktionTable)
    // @"Seite",@"Hoehe",@"Quer",@"Motor",@"Quer L",@"Quer R",@"Lande",@"Aux"
    
    // bit 4-6: Steuerdevice L_H, L_V .. (Text aus DeviceTable)
    // @"L_H",@"L_V",@"R_H",@"R_V",@"S_L",@"S_R",@"Sch",@"-"
    
    0x00,
    0x11,
    0x22,
    0x33,
    0x44,
    0x55,
    0x66,
    0x77
    
    mixart = 0;      Offset: 0  // Art                  FUNKTION_OFFSET
    mixcanals           Offset: 1 // wer mit welchem kanal
    
    FUNKTION_OFFSET 0x60
    
    NSMutableDictionary* mixingdic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithInt:settingindex],@"mixnummer",
    [NSNumber numberWithInt:0],@"mixart",
    [NSNumber numberWithInt:0xFF],@"canala",
    [NSNumber numberWithInt:0xFF],@"canalb",
    [NSString stringWithFormat:@"Mix %d",0],@"mixing",
    nil]retain];
    
    
    */
   
   NSLog(@"reportFix_FunktionSettings Data: %@ changecode: %d",FunktionDatenArray, changecode);
   
   int datastartbyte = 16; // Beginn  der Settings auf dem buffer
   fprintf(stderr,"FunktionSettings:\n");
   
   for (int fkt=0;fkt < [FunktionDatenArray count];fkt++)
   {
      // beteiligte Kanaele
      uint8_t funktionwert =0;
      NSDictionary* funktionDic = [FunktionDatenArray objectAtIndex:fkt];
      int funktionnummer = [[funktionDic objectForKey:@"funktionnummer"]intValue];
      int devicenummer = [[funktionDic objectForKey:@"devicenummer"]intValue];
      {
         funktionwert |= funktionnummer & 0x07; // Bit 0-2
         funktionwert |= (devicenummer & 0x07) << 4; // Bit 4-5
      }
      
      fprintf(stderr,"funktionnummer:\t%02X\t devicenummer:\t%02X\t funktionwert:\t%02X  \t %d\n",funktionnummer,devicenummer,funktionwert,funktionwert);
      
      
      bytebuffer[datastartbyte + fkt] = funktionwert;
      
      fprintf(stderr,"funktionwert:\t%02X\n",funktionwert);
      
   } // for fkt
   
   fprintf(stderr,"\nreportFix_FunktionSettings bytebuffer ready: \n");
   for (int pos = 0;pos < EE_PARTBREITE;pos++)
   {
      if (pos%8 ==0)
      {
         fprintf(stderr,"\t");
      }
      if (pos%16 ==0)
      {
         fprintf(stderr,"\n");
      }
      
      fprintf(stderr,"\t%02X",bytebuffer[pos]);
   }
   fprintf(stderr,"\n");
   fprintf(stderr,"\n");
   if (usbstatus)
   {
      int senderfolg= rawhid_send(0, bytebuffer, 64, 50);
   }
   free(bytebuffer);
   
  // [self reportRead_Settings:NULL];

}


- (IBAction)reportFix_MixingSettings:(id)sender // 0xFA
{
   int modelindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];
   
   NSLog(@"\nreportFix_MixingSettings: modelindex: %d Settings: %@",modelindex,[[MixingArray objectAtIndex:modelindex] description]);
   
   uint8_t*      bytebuffer = malloc(USB_DATENBREITE);
   int Mix_Startadresse = TASK_OFFSET + MIX_OFFSET;
   uint8 lo = Mix_Startadresse & 0x00FF;
   uint8 hi = (Mix_Startadresse & 0xFF00)>>8;
   bytebuffer[0] = 0xFA;
   bytebuffer[1] = Mix_Startadresse & 0x00FF;
   bytebuffer[2] = (Mix_Startadresse & 0xFF00)>>8;
   
   uint8_t changecode=0; // Bits fuer geaenderte Kanaele
   
   fprintf(stderr,"\nreportFix_MixingSettings modelindex: %d  count: %d\n",modelindex,(int)[[MixingArray objectAtIndex:modelindex] count]);
   
   NSMutableArray * MixingDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   
   for (int mixing=0;mixing < [[MixingArray objectAtIndex:modelindex] count];mixing++)
   {
      if ([[[[MixingArray objectAtIndex:modelindex] objectAtIndex:mixing]objectForKey:@"go"]intValue])
      {
         [MixingDatenArray addObject:[[MixingArray objectAtIndex:modelindex] objectAtIndex:mixing]];
         changecode |= (1<< mixing);
      }
   }
   bytebuffer[3] = changecode;
   bytebuffer[4] = modelindex; // welches modell
   
   fprintf(stderr,"\nMix modelindex: %d changecode: %d\n",modelindex,changecode);
   
   for (uint8_t kanal=0;kanal < 8;kanal++)
   {
      if (changecode & (1<<kanal))
      {
         // fprintf(stderr,"+%d+\t",changecode & (1<<kanal));
         fprintf(stderr,"*%d*\t",kanal);
      }
   }// for kanal
   fprintf(stderr,"\n");
   
   /*
    mixart = 0;      Offset: 0  // Art                  MIX_OFFSET
    mixcanals           Offset: 1 // wer mit welchem kanal
    
    MIX_OFFSET 0x40
    
    NSMutableDictionary* mixingdic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithInt:settingindex],@"mixnummer",
    [NSNumber numberWithInt:0],@"mixart",
    [NSNumber numberWithInt:0xFF],@"canala",
    [NSNumber numberWithInt:0xFF],@"canalb",
    [NSString stringWithFormat:@"Mix %d",0],@"mixing",
    nil]retain];
    
    
    */
   
   NSLog(@"reportFix_MixingSettings Data: %@ changecode: %d",MixingDatenArray, changecode);
   
   int datastartbyte = 16; // Beginn  der Settings auf dem buffer
   fprintf(stderr,"MixingSettings:\n");
   
   for (int mixing=0;mixing < [MixingDatenArray count];mixing++)
   {
      // beteiligte Kanaele
      uint8_t mixwert =0;
      NSDictionary* mixDic = [MixingDatenArray objectAtIndex:mixing];
      int mixa = [[mixDic objectForKey:@"canala"]intValue];
      int mixb = [[mixDic objectForKey:@"canalb"]intValue];
      if ((mixa >= 8) || (mixb >= 8))
      {
         mixwert = 0x88;
      }
      else
      {
         mixwert |= mixa & 0x07; // Bit 0-2
         mixwert |= (mixb & 0x07) << 4; // Bit 4-5
      }
      // mixwert = 0x88;
      fprintf(stderr,"mixa:\t%02X\tmixb:\t%02X\tmixwert:\t%02X *\t %d\n",mixa,mixb,mixwert,mixwert);
      
      // Mix-Art: V-Mix, Butterfly usw
      uint8_t artwert =0;
      int art = [[mixDic objectForKey:@"mixart"]intValue];
      artwert |= (art & 0x03); // Bit 0-2
      
      bytebuffer[datastartbyte + 2*mixing] = mixwert;
      bytebuffer[datastartbyte + 2*mixing + 1] = artwert;
      
      fprintf(stderr,"mixwert:\t%02X\tartwert:\t%02X *\n",mixwert,artwert);
      
   } // for mixing
   
   fprintf(stderr,"\nreportFix_MixingSettings bytebuffer ready: \n");
   for (int pos = 0;pos < EE_PARTBREITE;pos++)
   {
      if (pos%8 ==0)
      {
         fprintf(stderr,"\t");
      }
      if (pos%16 ==0)
      {
         fprintf(stderr,"\n");
      }
      
      fprintf(stderr,"\t%02X",bytebuffer[pos]);
   }
   fprintf(stderr,"\n");
   
   int senderfolg= rawhid_send(0, bytebuffer, 64, 50);
   
   free(bytebuffer);
   
   [self reportRead_Settings:NULL];
}



- (IBAction)reportRefresh_Master:(id)sender
{
   NSLog(@"reportRefresh_Master");
   [refreshmaster_mark setBackgroundColor:[NSColor redColor]];
   int modelindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];

   uint8_t*      bytebuffer = malloc(USB_DATENBREITE);
   
   bytebuffer[0] = 0xFC;
   bytebuffer[4] = modelindex; // welches modell
   int senderfolg= rawhid_send(0, bytebuffer, 64, 50);

   free(bytebuffer);
}


- (void)loadExpoDatenArray
{
   // ******************************************************************************************
   // Daten berechnen
   // ******************************************************************************************
   
      int DIV = 32;
   
   for (int stufe=0;stufe<4;stufe++)
   {
      
      NSArray* dataArray = [Math expoArrayMitStufe:stufe];
      [ExpoDatenArray addObject:dataArray];
      
	}
   
   for (int stufe=0;stufe<4;stufe++)
   {
      //fprintf(stderr,"%d",stufe);
      int wert=0;
      checksumme=0;
      for (int pos=0;pos<VEKTORSIZE;pos++)
      {
         if (pos%DIV == 0)
         {
            wert=0;
            uint8 lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:pos]intValue];
            uint8 hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:pos]intValue];
            wert = hi;
            wert <<= 8;
            wert += lo;
            
            checksumme += wert;
            //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
            //      fprintf(stderr,"\t%d",wert);
            //fprintf(stderr,"\t%d\t%d",lo,hi);
         }
      }
      
      wert=0;
      uint8 lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]lastObject]intValue];
      uint8 hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]lastObject]intValue];
      wert = hi;
      wert <<= 8;
      wert += lo;
      //         fprintf(stderr,"\t%d",wert);
      //fprintf(stderr,"\t%d\t%d | ",lo,hi);
      //  fprintf(stderr,"\n");
      //  fprintf(stderr,"checksumme: \t%d\n",checksumme);
      
      
      
   }

}

- (IBAction)reportRead_Part:(id)sender
{
   //     EEDatenArray enthaelt anzstufen Arrays mit 2* Vektorsize Werten (lo, hi hintereinander) fuer die Stufe

  // [EE_taskmark setBackgroundColor:[NSColor redColor]];
  // [EE_taskmark setStringValue:@" "];
   uint8 lo=0;
   uint8 hi=0;
   int EE_Startadresse=0;
   // Startadresse aus Eingabefeld
   
   NSLog(@"LO: %@ HI: %@",[EE_StartadresseFeldHexLO stringValue],[EE_StartadresseFeldHexHI stringValue]);
   if ([[EE_StartadresseFeldHexLO stringValue]length]) // Eingabe da
   {
      NSScanner* theScanner;
      unsigned	  value;
      
      NSString* loString = [EE_StartadresseFeldHexLO stringValue];
      theScanner = [NSScanner scannerWithString:loString];
      
      if ([theScanner scanHexInt:&value])
      {
         lo = value;
         
      }
      NSLog(@"LO: string: %@ loString value: %d",loString, value);
      NSString* hiString = [EE_StartadresseFeldHexHI stringValue];
      theScanner = [NSScanner scannerWithString:hiString];
      
      if ([theScanner scanHexInt:&value])
      {
         hi = value;
         
      }
      
   }
   else
   {
      EE_Startadresse = [EE_StartadresseFeld intValue];
      lo = EE_Startadresse & 0x00FF;
      hi = (EE_Startadresse & 0xFF00)>>8;
   }
   
   [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%X",lo]];
   [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%X",hi]];
   
   fprintf(stderr,"Adresse: lo:\t%d\thi: \t%d\n",lo,hi);
   uint8_t*      sendbuffer =malloc(USB_DATENBREITE);

   sendbuffer[0] = 0xDA;
   sendbuffer[1] = lo;
   sendbuffer[2] = (hi & 0xFF00)>>8;
   //fprintf(stderr,"\n");
   
   //fprintf(stderr,"send3: %d send4: %d\n",sendbuffer[1],sendbuffer[2]);
   //fprintf(stderr,"send3: %02X send4: %02X\n",sendbuffer[1],sendbuffer[2]);
   
   
   
   int senderfolg= rawhid_send(0, sendbuffer, 64, 50);
   
   NSLog(@"read_part erfolg: %d",senderfolg);
   [EE_StartadresseFeld setIntValue: EE_Startadresse + EE_PARTBREITE];
   
   free(sendbuffer);

   
}

- (IBAction)reportWrite_Part:(id)sender
{
   usbtask = EEPROM_WRITE_TASK;
   [EE_taskmark setBackgroundColor:[NSColor redColor]];
   [EE_taskmark setStringValue:@" "];
   eepromwritestatus |= (1<<EEPROM_WRITE_BUSY_BIT );
   eepromwritestatus &= ~(1<<EEPROM_WRITE_OK_BIT );

   
   // ******************************************************************************************
   // Daten berechnen in awake
   // ******************************************************************************************

   // *******************************************************************************************************************
   //     EEDatenArray enthaelt anzstufen Arrays mit 2* Vektorsize Werten (lo, hi hintereinander) fuer die Stufe
   // *******************************************************************************************************************
   
   Dataposition = 0;
   [USB_DatenArray removeAllObjects];
   
   // Stufe 0
   uint8 lo=0;
   uint8 hi=0;
   int EE_Startadresse=0;
   // Startadresse aus Eingabefeld
   
   NSLog(@"LO: %@ HI: %@",[EE_StartadresseFeldHexLO stringValue],[EE_StartadresseFeldHexHI stringValue]);
   if ([[EE_StartadresseFeldHexLO stringValue]length]) // Eingabe da
   {
      NSScanner* theScanner;
      unsigned	  value;

      NSString* loString = [EE_StartadresseFeldHexLO stringValue];
      theScanner = [NSScanner scannerWithString:loString];
      
      if ([theScanner scanHexInt:&value])
      {
         lo = value;
         
      }
      //NSLog(@"LO: string: %@ loString value: %d",loString, value);
      NSString* hiString = [EE_StartadresseFeldHexHI stringValue];
      theScanner = [NSScanner scannerWithString:hiString];
      
      if ([theScanner scanHexInt:&value])
      {
         hi = value;
         
      }

   }
   else
   {
      EE_Startadresse = [EE_StartadresseFeld intValue];
      lo = EE_Startadresse & 0x00FF;
      hi = (EE_Startadresse & 0xFF00)>>8;
   }
   
   [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%X",lo]];
   [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%X",hi]];
   
   int stufe = [StufeFeld intValue];
   fprintf(stderr,"Stufe: \t%d\t Adresse lo: \t%d\thi: \t%d\n",stufe, lo,hi);
   
 
   [self send_EEPROMPartMitStufe:stufe anAdresse:(lo & 0x00FF) | (hi & 0xFF00)>>8];

   [EE_StartadresseFeld setIntValue: EE_Startadresse + EE_PARTBREITE];
}

- (IBAction)reportWrite_Stufe:(id)sender
{
   //     EEDatenArray enthaelt anzstufen Arrays mit 2* Vektorsize Werten (lo, hi hintereinander) fuer die Stufe
   
   NSAlert *Warnung = [[[NSAlert alloc] init] autorelease];
   [Warnung addButtonWithTitle:@"Write Data"];
   [Warnung addButtonWithTitle:@"Cancel"];
   //	[Warnung addButtonWithTitle:@""];
   //[Warnung addButtonWithTitle:@"Abbrechen"];
   [Warnung setMessageText:[NSString stringWithFormat:@"%@",NSLocalizedString(@"Really overwrite the data in this region?",@"Die Daten für diese Stufe wirklich neu schreiben?")]];
   
   NSString* s1=NSLocalizedString(@"???\0","@Alle vorhandenen Daten werden ueberschrieben.");
   NSString* s2=@"";
   NSString* InformationString=[NSString stringWithFormat:@"%@\n%@",s1,s2];
   [Warnung setInformativeText:InformationString];
   [Warnung setAlertStyle:NSWarningAlertStyle];
   
   int antwort=[Warnung runModal];
   
   // return;
    NSLog(@"antwort: %d",antwort);
   switch (antwort)
   {
      case NSAlertFirstButtonReturn: // 1000, Taste ganz rechts
      {
         // go further
      }break;
         
      case NSAlertSecondButtonReturn: // 1001 Ignorieren
      {
         //go back
         return;
      }break;
         
      case NSAlertThirdButtonReturn: // Abbrechen
      {
         return;
      }break;
   }

   int stufe = [StufeFeld intValue];
   NSLog(@"reportWrite_Stufe stufe: %d",stufe);
   [Write_Stufe_Taste setEnabled:NO];
   [PartnummerFeld setIntValue:0];
   int startadresse = 0;
   
   NSLog(@"reportWrite_Stufe stufe: %d startadresse: %02X %d",stufe,startadresse,startadresse);
   
   [self send_EEPROMPartMitStufe:stufe anAdresse:startadresse];
   
   NSLog(@"reportWrite_Stufe timer start");
   
   NSMutableDictionary* timerDic =[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:startadresse],@"startadresse",[NSNumber numberWithInt:0],@"part", [NSNumber numberWithInt:stufe],@"stufe", nil];
   
   
   EE_WriteTimer = [[NSTimer scheduledTimerWithTimeInterval:0.6
                                                 target:self
                                               selector:@selector(write_EE_Part_Timerfunktion:)
                                               userInfo:timerDic repeats:YES]retain];


}

-(void)write_EE_Part_Timerfunktion:(NSTimer*)timer
{
   //     EEDatenArray enthaelt anzstufen Arrays mit 2* Vektorsize Werten (lo, hi hintereinander) fuer die Stufe

   if (eepromwritestatus & (1<<EEPROM_WRITE_BUSY_BIT)) // write noch im Gang
   {
      NSLog(@"write_EE_Part_Timerfunktion busy");

      return;
   }
    int part = -1;
   int startadresse = -1;
   int stufe = -1;
   if ([[[timer userInfo]objectForKey:@"part"]intValue] < (2*VEKTORSIZE)/EE_PARTBREITE -1)
   //if ([[[timer userInfo]objectForKey:@"part"]intValue] < 16)
   {
      part = [[[timer userInfo]objectForKey:@"part"]intValue]+1;
      [PartnummerFeld setIntValue:part];
      startadresse = [[[timer userInfo]objectForKey:@"startadresse"]intValue]+EE_PARTBREITE;
      stufe = [[[timer userInfo]objectForKey:@"stufe"]intValue];

      NSLog(@"write_EE_Part_Timerfunktion stufe: %d part: %d startadresse: %d | %02X",stufe,part,startadresse,startadresse);
      
      [self send_EEPROMPartMitStufe:stufe anAdresse:startadresse];
      
      
      [[timer userInfo]setObject:[NSNumber numberWithInt:part] forKey:@"part"];
      [[timer userInfo]setObject:[NSNumber numberWithInt:startadresse] forKey:@"startadresse"];
   }
   else{
      NSLog(@"write_EE_Part_Timerfunktion end");
      
      [timer invalidate];
      [timer release];
      [Write_Stufe_Taste setEnabled:YES];
   }

}

- (void)send_EEPROMPartMitStufe:(int)stufe anAdresse:(int)startadresse
{
   NSLog(@"send_EEPROMPartMitStufe %d anAdresse: %d\n", stufe, startadresse);

   //EEPROMposition++;
   char*      sendbufferLO = malloc(PAGESIZE);
   char*      sendbufferHI = malloc(PAGESIZE);
   uint8_t*    partbuffer = malloc(EE_PARTBREITE);
   
   uint8_t*      sendbuffer;
   sendbuffer=malloc(USB_DATENBREITE);
   NSScanner* theScanner;
   unsigned	  value;
   
   [EE_taskmark setBackgroundColor:[NSColor redColor]];
   [EE_taskmark setStringValue:@" "];
   eepromwritestatus |= (1<<EEPROM_WRITE_BUSY_BIT );
   eepromwritestatus &= ~(1<<EEPROM_WRITE_OK_BIT );
   
   uint16_t stufestartadresse = stufe * 2*VEKTORSIZE;

   [EE_StartadresseFeld setIntValue: stufestartadresse +startadresse];
   
   int eepromchecksumme=0;
   int bytechecksumme=0;
   {
     // int startposition = EEPROMpage * PAGESIZE;
      for (int pos = 0;pos < EE_PARTBREITE;pos++)
      {
         uint8 data= [[[EEDatenArray objectAtIndex: stufe ]objectAtIndex:pos + startadresse]intValue];
         sendbufferHI[pos] = data;
         partbuffer[pos] = data;
         bytechecksumme +=data;
      }
      //fprintf(stderr,"\n\n*************\n");

      //fprintf(stderr,"send_EEPROMPartAnAdresse %d eepromchecksumme: %d bytechecksumme1: %d\n", startadresse, eepromchecksumme,bytechecksumme);
      bytechecksumme=0;
      for (int pos = 0;pos < EE_PARTBREITE;pos++)
      {
         //int wert = partbuffer[pos+1];
         //wert <<= 8;
         //wert += partbuffer[pos];
         //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
       //  fprintf(stderr,"%x\t",partbuffer[pos]);
         bytechecksumme+= partbuffer[pos];
      }
      //fprintf(stderr,"\n*************\n");
      //fprintf(stderr,"send_EEPROMPartAnAdresse %d eepromchecksumme: %d bytechecksumme2: %d\n", startadresse, eepromchecksumme,bytechecksumme);
 
   }
  
   free (sendbufferLO);
   free (sendbufferHI);
   
      for (int i=0;i<EE_PARTBREITE;i++)
   {
          NSString*  tempHexString=[NSString stringWithFormat:@"%02X",(uint8_t)partbuffer[i]];
         //NSLog(@"i: %d tempWert: %d tempWert hex: %02X tempHexString: %@",i,partbuffer[i],partbuffer[i],tempHexString);
         theScanner = [NSScanner scannerWithString:tempHexString];
         
         if ([theScanner scanHexInt:&value])
         {
            sendbuffer[EE_PARTBREITE+i] = (char)value;
            //fprintf(stderr,"%d\t%d\n",tempWert, (char)value);
         }
         else
         {
            NSRunAlertPanel (@"Invalid data format", @"Please only use hex values between 00 and FF.", @"OK", nil, nil);
            //free (sendbuffer);
            return;
         }
      //sendbuffer[i]=(char)[[tempUSB_DatenArray objectAtIndex:i]UTF8String];
   }
   sendbuffer[0] = 0xCA;
   sendbuffer[1] = (stufestartadresse + startadresse) & 0x00FF;
   sendbuffer[2] = ((stufestartadresse + startadresse) & 0xFF00)>>8;
   
   
 //  fprintf(stderr,"send_EEPROMPART sendbuffer\n");
   
   
   eepromchecksumme=0;
   for (int k=EE_PARTBREITE;k<USB_DATENBREITE;k+=2) // 32 16Bit-Werte
   {
      int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
      
//      fprintf(stderr,"%d\t",wert);
      eepromchecksumme+= wert;
      bytechecksumme+= (uint8)sendbuffer[k];
      bytechecksumme+= (uint8)sendbuffer[k+1];
   }

//fprintf(stderr,"\neepromchecksumme : %d bytechecksumme3: %d\n",eepromchecksumme,bytechecksumme);
   sendbuffer[3] = bytechecksumme & 0x00FF;
   sendbuffer[4] = (bytechecksumme & 0xFF00)>>8;
   fprintf(stderr,"send_EEPROMPART sendbuffer\n");
   fprintf(stderr,"startadresse lo: %02X\t hi: %02X\tstufestartadresse: %04X\t %d \tposition: %d\n",(uint8)sendbuffer[1],(uint8)sendbuffer[2],stufestartadresse,stufestartadresse,stufestartadresse + startadresse );

   for (int k=0;k<USB_DATENBREITE;k++) // 32 16Bit-Werte
   {
      if (k==EE_PARTBREITE)
      {
         fprintf(stderr,"\n");
      }
      else if (k && k%(EE_PARTBREITE/2)==0)
      {
         fprintf(stderr,"\t");
      }
      fprintf(stderr,"%02X\t",(uint8)sendbuffer[k]);
      
      //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
      //fprintf(stderr,"%d\t",wert);
   }// for i
   
   fprintf(stderr,"\n");
   
 //  fprintf(stderr,"send3: %d send4: %d\n",sendbuffer[3],sendbuffer[4]);
 //  fprintf(stderr,"send3: %02X send4: %02X\n",sendbuffer[3],sendbuffer[4]);
   
   int senderfolg= rawhid_send(0, sendbuffer, 64, 50);
   
//   NSLog(@"send_EEPROMPART erfolg: %d Dataposition: %d",senderfolg,Dataposition);

   free (partbuffer);
   free(sendbuffer);
}


- (void)write_EEPROM
{
//   NSLog(@"write_EEPROM");
	//NSLog(@"write_EEPROM USB_DatenArray anz: %d\n USB_DatenArray: %@",[USB_DatenArray count],[USB_DatenArray description]);
   
   if (Dataposition < [USB_DatenArray count])
	{
      
 		
      char*      sendbuffer;
      sendbuffer=malloc(USB_DATENBREITE);
      //
      int i;
      
      NSMutableArray* tempUSB_DatenArray=(NSMutableArray*)[USB_DatenArray objectAtIndex:Dataposition];
      
      NSScanner *theScanner;
      unsigned	  value;
      NSLog(@"write_EEPROM Dataposition: %d tempUSB_DatenArray count: %d",Dataposition,(int)[tempUSB_DatenArray count]);
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
      
      //NSLog(@"code: %d",sendbuffer[16]);
      
      
      fprintf(stderr,"write_EEPROM sendbuffer\n");
      for (i=0;i<8;i++ )
      {
         fprintf(stderr,"%X\t",sendbuffer[i] & 0xFF);
         
      }
      fprintf(stderr,"\n");
      
      
      int senderfolg= rawhid_send(0, sendbuffer, USB_DATENBREITE, 50);
      
      NSLog(@"write_EEPROM erfolg: %d Dataposition: %d",senderfolg,Dataposition);
      
      //dauer4 = [dateA timeIntervalSinceNow]*1000;
      //         int senderfolg= rawhid_send(0, newsendbuffer, 32, 50);
      
      //NSLog(@"write_EEPROM senderfolg: %X",senderfolg);
      //NSLog(@"write_EEPROM  Dataposition: %d ",Dataposition);
      
      
      
      
      Dataposition++;
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
	//NSLog(@"writeAbschnitt USB_DatenArray anz: %d\n USB_DatenArray: %@",[USB_DatenArray count],[USB_DatenArray description]);
   //NSLog(@"writeAbschnitt USB_DatenArray anz: %d",[USB_DatenArray count]);
   NSLog(@"writeAbschnitt Dataposition start: %d",Dataposition);
   
   if (Dataposition < [USB_DatenArray count])
	{
      char*      sendbuffer;
      sendbuffer=malloc(USB_DATENBREITE);
      //
      int i;
      
      // Daten an Pos Datenposition laden
      
      NSMutableArray* tempUSB_DatenArray=(NSMutableArray*)[USB_DatenArray objectAtIndex:Dataposition];
      
      NSScanner *theScanner;
      unsigned	  value;
      NSLog(@"writeCNCAbschnitt tempUSB_DatenArray count: %d",[tempUSB_DatenArray count]);
      NSLog(@"loop start");
      for (i=0;i<USB_DATENBREITE;i++)
      {
         if (i<[tempUSB_DatenArray count])
         {
         int tempWert=[[tempUSB_DatenArray objectAtIndex:i]intValue];
         //sendbuffer[i] = (uint8_t)tempWert;
         fprintf(stderr,"%d\t",tempWert);
         NSString*  tempHexString=[NSString stringWithFormat:@"%0x",tempWert];
         //NSLog(@"i: %d tempWert: %d tempWert hex: %02X tempHexString: %@",i,tempWert,tempWert,tempHexString);
         theScanner = [NSScanner scannerWithString:tempHexString];
         
         if ([theScanner scanHexInt:&value])
         {
            sendbuffer[i] = (char)value;
             //fprintf(stderr,"%d\t%d\n",tempWert, (char)value);
         }
         else
         {
            NSRunAlertPanel (@"Invalid data format", @"Please only use hex values between 00 and FF.", @"OK", nil, nil);
            //free (sendbuffer);
            return;
         }
         }
         else
         {
            sendbuffer[i] = 0x00;
         }
         //sendbuffer[i]=(char)[[tempUSB_DatenArray objectAtIndex:i]UTF8String];
      }
      fprintf(stderr,"\n");
      
      //NSLog(@"code: %d",sendbuffer[16]);
      
      /*
      if (Dataposition ==0)
      {
         fprintf(stderr,"write_Abschnitt sendbuffer position 0\n");
         for (int i=0;i<8;i++)
         {
            fprintf(stderr,"%X\t",(uint8)sendbuffer[i]);
         }
         fprintf(stderr,"\n");
      }
      
      else
       
      {
       
       fprintf(stderr,"\nwrite_Abschnitt Dataposition: %d sendbuffer\n",Dataposition);
         if (Dataposition<8)
         {
         for (int k=0;k<16;k+=2) // 32 16Bit-Werte
         {
            fprintf(stderr,"%X\t%X\t",(uint8)sendbuffer[k],(uint8)sendbuffer[k+1]);
            int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
            fprintf(stderr,"%d\t",wert);
         }
         }// for i
      }
      */
      fprintf(stderr,"write_Abschnitt Dataposition: %d sendbuffer\n",Dataposition);
      if (Dataposition<4)
      {
         for (int k=0;k<32;k++) // 32 16Bit-Werte
         {
            fprintf(stderr,"%02X\t",(uint8)sendbuffer[k]);
            //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
            //fprintf(stderr,"%d\t",wert);
         }
      }// for i

      fprintf(stderr,"\n");
       
      
      int senderfolg= rawhid_send(0, sendbuffer, 64, 50);
      
      NSLog(@"write_Abschnitt erfolg: %d Dataposition: %d",senderfolg,Dataposition);
      
      //dauer4 = [dateA timeIntervalSinceNow]*1000;
      //         int senderfolg= rawhid_send(0, newsendbuffer, 32, 50);
      
      //NSLog(@"writeCNCAbschnitt senderfolg: %X",senderfolg);
      //NSLog(@"write_Abschnitt  Dataposition: %d ",Dataposition);
      
      Dataposition++;
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
	char        buffer[64]={};
	int	 		result = 0;
	NSData*		dataRead;
	int         reportSize=64;
   
   if (Dataposition < [USB_DatenArray count])
   {
      //     [self stop_Timer];
      //     return;
   }
	//NSLog(@"read_USB A");
   
   result = rawhid_recv(0, buffer, 64, 50);
   
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
      if (result)
      {
         //fprintf(stderr,"USB Eingang:\t"); // Potentiometerstellungen
         for (int i=0;i<8;i++)
         {
 //           UInt8 wertL = (UInt8)buffer[2*i];
 //           UInt8 wertH = ((UInt8)buffer[2*i+1]);
 //           int wert = wertL | (wertH<<8);
            //int wert = wertL + (wertH );
            //  fprintf(stderr,"%d\t%d\t%d\t",wertL,wertH,(wert));
           // fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
           // fprintf(stderr," | ");
         }
         //fprintf(stderr,"\n");

         
      }
     // NSLog(@"result: %d dataRead: %@",result,[dataRead description]);
      [self setLastValueRead:dataRead];
      if (!((buffer[0] & 0xF0)   || (buffer[0] ==0)))
      {
         NSLog(@"usbtask: %d buffer0: %02X",usbtask,buffer[0]& 0xFF);
      }
      /*
      if (buffer[0] & 0xF0)  
      {
         for (int k=60;k<64;k++) // 32 16Bit-Werte
         {
            
            if (k==48)
            {
               fprintf(stderr,"\n\n");
               
            }
            
            fprintf(stderr,"%02X\t",(uint8)buffer[k]);
            //fprintf(stderr,"%02X\t%02X\t",(uint8)buffer[k],(uint8)buffer[k+1]);
            //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
            //fprintf(stderr,"%d\t",wert);
         }
         
         
         fprintf(stderr,"\n");
      }
       */
     
      
//      NSLog(@"code raw result: %d dataRead: %X",result,(UInt8)buffer[0] );
      // start
      
      // end

      
      //  ---------------------------------------
      switch (usbtask)
      {
         //NSLog(@"result: %d dataRead: %@",result,[dataRead description]);
            
         //case EEPROM_WRITE_TASK:
         //case EEPROM_READ_TASK:
         //case EEPROM_AUSGABE_TASK:
         default:
         {
            UInt8 code = (UInt8)buffer[0];
            //NSLog(@"code raw result: %d dataRead: %X",result,code );
            if (code)
            {
               
               
               switch (code)
               {
                     
                  case 0xB0:
                  {
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n+++ echo B0 fixadresse hex: %02X\tdez: %d\t\terr_count 0: %d\n ",startadresse,startadresse,buffer[3]);
                     fprintf(stderr,"writedatabyte: %02X\t checkbyte: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     fprintf(stderr,"\n");
                     //fprintf(stderr,"wert 1: %02X\t wert 2: %02X\t",(uint8)buffer[9],(uint8)buffer[10]);
                     fprintf(stderr,"\n");
                     fprintf(stderr,"B0 Eingang von LCD \n");

                     for (int k=0;k<USB_DATENBREITE;k++) // 32 16Bit-Werte
                     {
                        
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"*\t");
                        }
                        
                        
                        fprintf(stderr,"%02X\t",(uint8)buffer[k]);
                       
                     }
                     fprintf(stderr,"\n");
                     fprintf(stderr,"\n");

                  }break;
                     
                     
                  case 0xC1: // Write EE Abschnitt an Dataposition senden
                  {
                     //NSLog(@"********  B1 result: %d dataRead: %X testadress: %X testdata: %X indata: %X Dataposition: %d",result,code,(UInt8)buffer[2],(UInt8)buffer[3],(UInt8)buffer[4] ,Dataposition);
                     //fprintf(stderr,"echo C1:\t");
                     for (int i=0;i<16;i++)
                     {
                        //fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
                     }
                     //fprintf(stderr,"\n");
                     
                     if (Dataposition < [USB_DatenArray count])
                     {
                        fprintf(stderr,"*");
                        
                        fprintf(stderr," echo C1\n");
                        for (int k=0;k<16;k+=2) // 32 16Bit-Werte
                        {
                           fprintf(stderr,"%02X\t%02X\t",(uint8)buffer[k],(uint8)buffer[k+1]);
                           //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
                           //fprintf(stderr,"%d\t",wert);
                        }
                        
                        
                        fprintf(stderr,"\n\n");
                        
                        [self write_Abschnitt];
                     }
                     else
                     {
                        usbtask =0;
                     }
                  }break;
                     
                  case 0xC2: // letzter Abschnitt, Write EE beendet
                  {
                     
                     fprintf(stderr," C2 end\n");
                     
                     //NSLog(@"++++  B2 ");
                     //[self startRead];
                     usbtask = 0;
                     
                  }break;
                     
                  case 0xE5: // write EEPROM Byte
                  {
                     fprintf(stderr,"echo E5 write EEPROM Byte in eeprombyteschreiben. Fehler: %d\n",(uint8)buffer[3]);
                     
                     /*
                      for (int i=0;i<12;i++)
                      {
                      UInt8 wertL = (UInt8)buffer[2*i];
                      UInt8 wertH = ((UInt8)buffer[2*i+1]);
                      int wert = wertL | (wertH<<8);
                      //int wert = wertL + (wertH );
                      //  fprintf(stderr,"%d\t%d\t%d\t",wertL,wertH,(wert));
                      fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
                      //fprintf(stderr," | ");
                      }
                      fprintf(stderr,"\n");
                      */
                     // fprintf(stderr,"Fehler: %d \n",(uint8)buffer[3]);
                     if ((uint8)buffer[3] ==0)
                     {
                        [EE_taskmark setStringValue:@"OK"];
                        [EE_taskmark setBackgroundColor:[NSColor greenColor]];
                        eepromwritestatus &= ~(1<<EEPROM_WRITE_BUSY_BIT );
                        eepromwritestatus |= (1<<EEPROM_WRITE_OK_BIT );

                     }
                     int startadresse = buffer[1] | (buffer[2]>>8);
                     fprintf(stderr,"startadresse: %d\ndata: %02X\ncheck: %02X\nerr_count: %d\tw: %d\n ",startadresse,buffer[4],buffer[5],buffer[3],buffer[6]);
                     
                     for (int k=0;k<USB_DATENBREITE;k++) // 32 16Bit-Werte
                     {
                        
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"*\t");
                        }
                        
                        
                        fprintf(stderr,"%02X\t",(uint8)buffer[k]);
                        
                        //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
                        //fprintf(stderr,"%d\t",wert);
                     }
                     
                     usbtask = 0;
                  }break;
                     
                  case 0xCB: // echo CB in Ladefunktion
                  {
                     
                     fprintf(stderr,"* echo CB in Ladefunktion: Fehler: %d\n",(uint8_t)buffer[3]);
                     if ((uint8_t)buffer[3] == 0)
                     {
                        [EE_taskmark setStringValue:@"OK"];
                        [EE_taskmark setBackgroundColor:[NSColor greenColor]];
                        eepromwritestatus &= ~(1<<EEPROM_WRITE_BUSY_BIT );
                        eepromwritestatus |= (1<<EEPROM_WRITE_OK_BIT );
                     }

                     for (int k=0;k<USB_DATENBREITE;k++) //
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(uint8_t)buffer[k]);
                        //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
                        //fprintf(stderr,"%d\t",wert);
                     }
                     
                     
                     fprintf(stderr,"\n\n");
                     usbtask = 0;
                     
                  }break;
                     
                  case 0xD5: // // MARK: D5 aus eepromverbosebytelesen
                  {
                     int readadresse = (uint8_t)buffer[1] | ((uint8_t)buffer[2] <<8);
                     
                     //fprintf(stderr,"echo D5 aus eepromverbosebytelesen  adresse hex:\t %02X\t  dec:\t %d\t",readadresse,readadresse);
                     
                     //fprintf(stderr,"Byte data hex:\t %02X\t  dec:\t %d\n",buffer[3]& 0xFF,buffer[3]& 0xFF);
                     
                     // buffer1 ist data
                     
                     /*
                      for (int i=0;i<8;i++)
                      {
                      fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
                      //fprintf(stderr," | ");
                      }
                      fprintf(stderr,"\n");
                      */
                     
                     [EE_DataFeld setStringValue:[NSString stringWithFormat:@"%d",(UInt8)buffer[3]& 0xFF]];
                     [EE_datalo setIntValue:(UInt8)buffer[3]& 0x00FF];
                     
                     [EE_datalohex setStringValue:[NSString stringWithFormat:@"%02X",(UInt8)buffer[3]& 0x00FF]];
                     /*
                      NSString* binstring = [Math BinStringFromInt:((UInt8)buffer[3]& 0x00FF) ];
                      //NSLog(@"binstring: %@",binstring );
                      binstring = [[EE_databin stringValue]stringByAppendingFormat:@"%@\r",binstring];
                      
                      [EE_databin setStringValue:binstring];
                      */
                     NSString* adressestring =[NSString stringWithFormat:@"%02X",readadresse];
                     NSString* hexstring =[NSString stringWithFormat:@"%02X",(UInt8)buffer[3]& 0xFF];
                     NSString* binstring = [Math BinStringFromInt:((UInt8)buffer[3]& 0x00FF) ];
                     NSString* kanalstring = [NSString string];
                     NSString* datastring = [NSString string];
                     
                     int kanal =readadresse & 0x000F;
                     
                     int databytecode = readadresse & 0xFFF0;
                     
                     int data =(UInt8)buffer[3]&0x00FF;
                     
                     //NSLog(@"aus eepromverbosebytelesen D5 kanal: %d databytecode: %02X",kanal,databytecode);
                     /*
                      Aufbau:
                      art = 0;      Offset: 2   EXPO_OFFSET
                      expoa = 0;    Offset: 0
                      expob = 2;    Offset: 4
                      go = 1;
                      kanal = 0;
                      levela = 1;   Offset: 0   LEVEL_OFFSET
                      levelb = 1;   Offset: 4
                      
                      nummer = 0;
                      richtung = 0; Offset: 7
                      state = 1;
                      
                      (
                      mixart = 0;      Offset: 0  // Art                  MIX_OFFSET
                      mixcanals        Offset: 1 // wer mit welchem kanal
                      
                      )
                      */
                     
                     switch (databytecode)
                     {
                        case 0x2020: //level
                        {
                           if (kanal==0)
                           {
                              kanalstring = [NSString stringWithFormat:@"Lev\tkan\t%d",kanal];
                           }
                           else
                           {
                              kanalstring = [NSString stringWithFormat:@"\tkan\t%d",kanal];
                              
                           }
                           
                           int levela = data&0x0F;
                           int levelb = (data&0xF0)>>4;
                           
                           datastring = [NSString stringWithFormat:@"\tla: %d\tlb: %d",levela,levelb];
                           
                        }break;
                        case 0x2030: //expo
                        {
                           /*
                            expoa:     Bit 0,1
                            art:       Bit 2,3
                            expob:     Bit 4,5
                            Richtung:  Bit 7
                            
                            */
                           if (kanal==0)
                           {
                              kanalstring = [NSString stringWithFormat:@"Exp\tkanal\t%d",kanal];
                           }
                           else
                           {
                              kanalstring = [NSString stringWithFormat:@"\tkanal\t%d",kanal];
                           }
                           int dir=0;
                           if (data & 0x80)
                           {
                              dir = 1;
                           }
                           
                           int expoa= data&0x03;
                           int expob= (data&0x30)>>4;
                           
                           int art= (data&0x0C)>>2;
                           
                           //NSLog(@"kanal: %d data: %02X expoa: %02X expob: %02X",kanal,data,expoa,expob);
                           datastring = [NSString stringWithFormat:@"\tea: %d\teb: %d\tart: %d\tdir: %d",expoa,expob,art,dir];
                           
                        }break;
                           
                        case 0x2040: //mix
                        {
                           //mixwert |= mixa & 0x07; // Bit 0-2
                           //mixwert |= (mixb & 0x07) << 4; // Bit 4-5
                           
                           if (kanal==0)
                           {
                              kanalstring = [NSString stringWithFormat:@"Mix\t"];
                           }
                           else
                           {
                              kanalstring = [NSString stringWithFormat:@"\t"];
                           }
                           
                           
                           
                           if (kanal % 2) // ungerade, typ
                           {
                              kanalstring = [NSString stringWithFormat:@"%@\t",kanalstring];
                              int mixtyp = (data & 0x03);
                              datastring = [NSString stringWithFormat:@"\ttyp\t%d",mixtyp];
                              //NSLog(@"kanal ungerade: %d data: %02X mixtyp: %02X datastring: %@",kanal,data,mixtyp,datastring);
                              
                           }
                           else // gerade, kanalnummern
                           {
                              kanalstring = [NSString stringWithFormat:@"%@Mix\t%d",kanalstring,kanal/2];
                              
                              int mixa = data & 0x0F;
                              int mixb = (data & 0xF0)>>4;
                              //int mixa = data & 0x07;
                              //int mixb = (data & 0x70)>>4;
                              
                              datastring = [NSString stringWithFormat:@"\tkan\tka: %d\tkb: %d", mixa, mixb];
                              //NSLog(@"kanal gerade: %d data: %02X mixa: %02X mixb: %02X datastring: %@",kanal,data,mixa,mixb,datastring);
                              
                           }
                           
                           
                           
                        }break;
                           
                        case 0x2060: // funktion
                        {
                           
                           if (kanal==0)
                           {
                              kanalstring = [NSString stringWithFormat:@"Fkt\t"];
                           }
                           else
                           {
                              kanalstring = [NSString stringWithFormat:@"\t"];
                           }
                           
                           kanalstring = [NSString stringWithFormat:@"%@\t%d",kanalstring,kanal];
                           int funktion = (data & 0x07);
                           int device = (data & 0x70)>>4;
                           datastring = [NSString stringWithFormat:@"\tfkt\t%d\tdev\t%d",funktion,device];
                           //NSLog(@"D5 funktion kanal : %d data: %02X funktion: %02X datastring:%@",kanal,data,funktion,datastring);
                           
                        }break;
                           
                     } // switch databytecode
                     
                     
                     // eventuell: http://www.mactech.com/articles/mactech/Vol.19/19.08/NSParagraphStyle/index.html
                     float firstColumnInch = 1.75,
                     otherColumnInch = 0.5, pntPerInch = 72.0;
                     NSMutableArray * TabArray = [NSMutableArray arrayWithCapacity:0];
                     NSTextTab *aTab;
                     
                     aTab = [[NSTextTab alloc]
                             initWithType:NSLeftTabStopType
                             location:30]; // kanal
                     [TabArray addObject:aTab];
                     
                     aTab = [[NSTextTab alloc]
                             initWithType:NSLeftTabStopType
                             location:70]; // kan nr
                     [TabArray addObject:aTab];
                     
                     aTab = [[NSTextTab alloc]
                             initWithType:NSLeftTabStopType
                             location:90];//adresse
                     [TabArray addObject:aTab];
                     
                     aTab = [[NSTextTab alloc]
                             initWithType:NSLeftTabStopType
                             location:120];//data
                     [TabArray addObject:aTab];
                     aTab = [[NSTextTab alloc]
                             initWithType:NSLeftTabStopType
                             location:160];// bin
                     [TabArray addObject:aTab];
                     
                     
                     for(int i=1;i<8;i++)
                     {
                        aTab = [[NSTextTab alloc]
                                initWithType:NSRightTabStopType
                                location:180
                                + ((float)i * 40)];
                        [TabArray addObject:aTab];
                        [aTab release]; // aTab was alloc'd and the array owns it now so release it
                     }
                     // NSLog(@"TabArray: %@",TabArray);
                     // http://stackoverflow.com/questions/5005228/how-to-have-unlimited-tab-stops-in-a-",TabArray);-with-disabled-text-wrap
                     NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
                     
                     [style setTabStops:TabArray];
                     
                     //[EE_dataview setDefaultParagraphStyle:style];
                     //[EE_dataview setTypingAttributes:[NSDictionary dictionaryWithObject:style forKey:NSParagraphStyleAttributeName]];
                     //[style release];
                     
                     //binstring =[NSString stringWithFormat:@"%@ \t%@ \t%@\t%@\t%@\n",kanalstring,adressestring,hexstring,binstring,datastring];
                     
                     // http://stackoverflow.com/questions/15172971/append-to-nstextview-and-scroll
                     // https://discussions.apple.com/thread/915981
                     
                     NSMutableAttributedString * tab =[[NSMutableAttributedString alloc] initWithString: @"\t"];
                     NSMutableAttributedString * CR =[[NSMutableAttributedString alloc] initWithString: @"\r"];
                     
                     NSMutableAttributedString* attrstring = [[NSMutableAttributedString alloc] initWithString:kanalstring];
                     
                     [attrstring addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [attrstring length])];
                     
                     [attrstring appendAttributedString: tab];
                     NSAttributedString * stringa =[[NSAttributedString alloc] initWithString: adressestring];
                     [attrstring appendAttributedString: stringa];
                     [attrstring appendAttributedString: tab];
                     NSAttributedString * stringb =[[NSAttributedString alloc] initWithString: hexstring];
                     [attrstring appendAttributedString: stringb];
                     
                     [attrstring appendAttributedString: tab];
                     NSAttributedString * stringd =[[NSAttributedString alloc] initWithString: binstring];
                     [attrstring appendAttributedString: stringd];
                     [attrstring appendAttributedString: tab];
                     NSAttributedString * stringe =[[NSAttributedString alloc] initWithString: datastring];
                     [attrstring appendAttributedString: stringe];
                     
                     [attrstring appendAttributedString: CR];
                     
                     [[EE_dataview textStorage]appendAttributedString:attrstring];
                     
                     [EE_dataview scrollRangeToVisible:NSMakeRange([[EE_dataview string] length],0)];
                     
                     usbtask = 0;
                  }break;
                     
                     

                     
                  case 0xD7: // // MARK: D7 read Settings
                  {
                     int readadresse = (uint8_t)buffer[1] | ((uint8_t)buffer[2] <<8);
                     
                     fprintf(stderr,"echo D7 aus bytelesen2 read Settings Byte adresse hex:\t %02X\t  dec:\t %d\t",readadresse,readadresse);
                     
                     fprintf(stderr,"Byte data hex:\t %02X\t  dec:\t %d\n",buffer[3]& 0xFF,buffer[3]& 0xFF);

                     // buffer1 ist data
                     
                     /*
                     for (int i=0;i<8;i++)
                     {
                        fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     */
                     
                      NSString* adressestring =[NSString stringWithFormat:@"%02X",readadresse];
                     NSString* hexstring =[NSString stringWithFormat:@"%02X",(UInt8)buffer[3]& 0xFF];
                     NSString* binstring = [Math BinStringFromInt:((UInt8)buffer[3]& 0x00FF) ];
                     NSString* kanalstring = [NSString string];
                     NSString* datastring = [NSString string];
                     int kanal =readadresse & 0x000F;
                     int databytecode = readadresse & 0xFFF0;
                     int data =(UInt8)buffer[3]&0x00FF;
                     //NSLog(@"kanal: %d databytecode: %02X",databytecode,kanal);
                     /*
                      Aufbau:
                      art = 0;      Offset: 2   EXPO_OFFSET
                      expoa = 0;    Offset: 0
                      expob = 2;    Offset: 4
                      go = 1;
                      kanal = 0;
                      levela = 1;   Offset: 0   LEVEL_OFFSET
                      levelb = 1;   Offset: 4
                      
                      nummer = 0;
                      richtung = 0; Offset: 7   
                      state = 1;
                      
                      (
                      mixart = 0;      Offset: 0  // Art                  MIX_OFFSET
                      mixcanals        Offset: 1 // wer mit welchem kanal
                      
                      )
                      */

                     switch (databytecode)
                     {
                        case 0x2020: //level
                        {
                           if (kanal==0)
                           {
                              kanalstring = [NSString stringWithFormat:@"Lev\tkan\t%d",kanal];
                           }
                           else
                           {
                              kanalstring = [NSString stringWithFormat:@"\tkan\t%d",kanal];

                           }
                           
                           int levela = data&0x0F;
                           int levelb = (data&0xF0)>>4;
                           
                        datastring = [NSString stringWithFormat:@"\tla: %d\tlb: %d",levela,levelb];
                        
                        }break;
                           
                        case 0x2030: //expo
                        {
                           /*
                            expoa:     Bit 0,1
                            art:       Bit 2,3
                            expob:     Bit 4,5
                            Richtung:  Bit 7
                            
                            */
                           if (kanal==0)
                           {
                              kanalstring = [NSString stringWithFormat:@"Exp\tkanal\t%d",kanal];
                           }
                           else
                           {
                              kanalstring = [NSString stringWithFormat:@"\tkanal\t%d",kanal];
                           }
                           int dir=0;
                           if (data & 0x80)
                           {
                              dir = 1;
                           }
                           
                           int expoa= data&0x03;
                           int expob= (data&0x30)>>4;
                           
                           int art= (data&0x0C)>>2;
                           
                           NSLog(@"kanal: %d data: %02X expoa: %02X expob: %02X",kanal,data,expoa,expob);
                           datastring = [NSString stringWithFormat:@"\tea: %d\teb: %d\tart: %d\tdir: %d",expoa,expob,art,dir];
                        
                        }break;

                        case 0x2040: //mix
                        {
                           //mixwert |= mixa & 0x07; // Bit 0-2
                           //mixwert |= (mixb & 0x07) << 4; // Bit 4-5

                           if (kanal==0)
                           {
                              kanalstring = [NSString stringWithFormat:@"Mix\t"];
                           }
                           else
                           {
                              kanalstring = [NSString stringWithFormat:@"\t"];
                           }
                           
 
                           
                           if (kanal % 2) // ungerade, typ
                           {
                              kanalstring = [NSString stringWithFormat:@"%@\t",kanalstring];
                              int mixtyp = (data & 0x03);
                              datastring = [NSString stringWithFormat:@"\ttyp\t%d",mixtyp];
                              //NSLog(@"kanal ungerade: %d data: %02X mixtyp: %02X datastring: %@",kanal,data,mixtyp,datastring);

                           }
                           else // gerade, kanalnummern
                           {
                              kanalstring = [NSString stringWithFormat:@"%@Mix\t%d",kanalstring,kanal/2];

                              int mixa = data & 0x0F;
                              int mixb = (data & 0xF0)>>4;
                              //int mixa = data & 0x07;
                              //int mixb = (data & 0x70)>>4;
                              
                              datastring = [NSString stringWithFormat:@"\tkan\tka: %d\tkb: %d", mixa, mixb];
                              //NSLog(@"kanal gerade: %d data: %02X mixa: %02X mixb: %02X datastring: %@",kanal,data,mixa,mixb,datastring);

                           }

                           
                           
                        }break;
                           
                        case 0x60: // funktion
                        {
                           
                        }break;
                           
                     } // switch databytecode
                     
                     
                     
                     usbtask = 0;
                  }break;
                     
                     
 
                  case 0xDB: // read EEPROM Part
                  {
                     fprintf(stderr,"echo read EEPROM Part data hex: %02X  dec: %d\n",buffer[3]& 0xFF,buffer[3]& 0xFF);
                     // buffer3 ist data
                     
                     for (int k=0;k<USB_DATENBREITE;k++)
                        
                     {
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"*\t");
                        }

                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                      
                     [EE_DataFeld setStringValue:[NSString stringWithFormat:@"%d",(UInt8)buffer[3]& 0xFF]];
                     [EE_datalo setIntValue:(UInt8)buffer[3]& 0x00FF];
                     
                     [EE_datalohex setStringValue:[NSString stringWithFormat:@"%02X",(UInt8)buffer[3]& 0x00FF]];
                     
                     NSString* binstring = [Math BinStringFromInt:((UInt8)buffer[3]& 0x00FF) ];
                     NSLog(@"binstring: %@",binstring );
                     
                     usbtask = 0;
                  }break;

                     // Ausgabe_TASK
                  case 0xC7: // EEPROM_AUSGABE
                  {
                     /*
                      fprintf(stderr,"echo C7 EEPROM_AUSGABE: ");
                      for (int i=0;i<8;i++)
                      {
                      fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
                      //fprintf(stderr," | ");
                      }
                      fprintf(stderr,"\n");
                      */
                     // von Write Page
                     if (Dataposition < [USB_DatenArray count])
                     {
                        buffer[63] = '\0';
                        NSMutableData *data=[[NSMutableData alloc] init];
                        [data appendBytes:buffer length:64];
                        
                        //NSString* Ausgabestring = [NSString stringWithUTF8String:buffer];
                        // NSLog(@"Ausgabestring: %@",Ausgabestring);
                        //[USB_DataFeld setStringValue:Ausgabestring];
                        fprintf(stderr,"*");
                        
                        fprintf(stderr," echo C7: ");
                        for (int k=0;k<16;k++) // 32 16Bit-Werte
                        {
                           
                           fprintf(stderr,"%02X\t",(uint8)buffer[k]);
                           //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
                           //fprintf(stderr,"%d\t",wert);
                        }
                        
                        
                        fprintf(stderr,"\n\n");
                        
                        [self write_Abschnitt];
                        
                     }
                     else
                     {
                        usbtask =0;
                     }
                     
                     //
                     
                     [EE_DataFeld setStringValue:@"Ausgabe"];
                  }break;
                 
                     // default
                  case 0xA3:
                  {
                     fprintf(stderr,"echo A3: ");
                     for (int i=0;i<8;i++)
                     {
                        fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     
                  }break;
                     
                  case 0xC5: // write EEPROM Byte
                  {
                     fprintf(stderr,"\necho C5 default write EEPROM Byte \n");
                     
                     /*
                      for (int i=0;i<12;i++)
                      {
                      UInt8 wertL = (UInt8)buffer[2*i];
                      UInt8 wertH = ((UInt8)buffer[2*i+1]);
                      int wert = wertL | (wertH<<8);
                      //int wert = wertL + (wertH );
                      //  fprintf(stderr,"%d\t%d\t%d\t",wertL,wertH,(wert));
                      fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
                      //fprintf(stderr," | ");
                      }
                      fprintf(stderr,"\n");
                      */
                     for (int k=0;k<USB_DATENBREITE;k++) // 32 16Bit-Werte
                     {
                        
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        
                        fprintf(stderr,"%02X\t",(uint8)buffer[k]);
                        
                        //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
                        //fprintf(stderr,"%d\t",wert);
                     }
                     fprintf(stderr,"\n");
                     usbtask = 0;
                  }break;
                     
                     // MARK: E6 Fix Funktionen
                  case 0xE6:
                  {
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n+++ echo E6 fixadresse hex: %02X\tdez: %d\t\terr_count 0: %d\terr_count 1: %d\n ",startadresse,startadresse,buffer[3],buffer[8]);
                     fprintf(stderr,"changecode: %02X\t modelindex: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     fprintf(stderr,"\n");
                     fprintf(stderr,"wert 1: %02X\t wert 2: %02X\t",(uint8)buffer[15],(uint8)buffer[16]);
                     fprintf(stderr,"\n");
                     fprintf(stderr,"F4 Eingang von LCD \n");
                     for (int k=0;k<USB_DATENBREITE;k++)
                     {
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     fprintf(stderr,"\n");

                  }
                     
                     
                     // MARK: E7 Read Funktionen
                  case 0xE7: // echo Read Funktionen
                  {
                     /*
                      */
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n*** echo E7 Funktionen lesen readadresse hex: %02X\t dez: %d\tmodelindex: %d\n ",startadresse,startadresse,(uint8)buffer[5]);
                     
                     for (int k=0;k<USB_DATENBREITE;k++)
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"***\n");
                     
                     
                     //fprintf(stderr,"byte: %02X\t checkbyte: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     // fprintf(stderr,"\n");
                     
                     
                     
                     // Funktion
                     /*
                      NSMutableDictionary* funktiondic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:devicenummer],@"devicenummer",
                      [default_DeviceArray objectAtIndex:funktionindex],@"device",
                      [NSNumber numberWithInt:funktionnummer],@"funktionnummer",
                      
                      [default_FunktionArray objectAtIndex:funktionindex],@"funktion",
                      
                      [NSNumber numberWithInt:((funktionnummer & 0xFF) | ((devicenummer & 0xFF)<<4))],@"device_funktion",

                      */
                     int modelindex = buffer[5];

                      int readposition =0; // position im Buffer
                      
                      //NSLog(@"read_USB E7 FunktionArray[0] vor: %@",[FunktionArray objectAtIndex:0]);
                      
                      NSMutableArray* memFunktionArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
                      
                      for (int k=0;k<8;k++)
                      {
                         NSMutableDictionary* funktionDic = [[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
                         [funktionDic setObject:[NSNumber numberWithInt:modelindex]
                                         forKey:@"modelnummer"];
                         [funktionDic setObject:[NSString stringWithFormat:@"M %d",modelindex] forKey:@"model"];
                         [funktionDic setObject:[NSNumber numberWithInt:0] forKey:@"go"];
                         [funktionDic setObject:[NSNumber numberWithInt:0] forKey:@"state"];
                         [funktionDic setObject:[NSNumber numberWithInt:k] forKey:@"nummer"];
                         
                         int funktionbyte = buffer[0x20 + k]&0xFF; // ab 32
                         
                         // index ist Kanal
                         // !! Funktion ist bit 0-2 , Steuerdevice ist bit 4-6!!
                         int funktionindex = funktionbyte & 0x07;
                         
                         [funktionDic setObject:[NSNumber numberWithInt:(funktionbyte & 0x07)] forKey:@"funktionnummer"]; // bit 0-2
                         // NSLog(@"count: %d*",[default_FunktionArray count]);
                         //NSLog(@"read_USB E7 default_FunktionArray: %@",[default_FunktionArray description]);
                         
                         [funktionDic setObject:[default_FunktionArray objectAtIndex:funktionindex] forKey:@"funktion"];
                         
                         int deviceindex = (funktionbyte & 0x70)>>4;
                         
                         [funktionDic setObject:[NSNumber numberWithInt:(funktionbyte & 0x70)>>4] forKey:@"devicenummer"]; // bit 4-6
                         [funktionDic setObject:[default_DeviceArray objectAtIndex:deviceindex] forKey:@"device"];
                         
                         //NSLog(@"read_USB E7 k: %d funktionbyte: %02X funktionDic: %@",k,funktionbyte, funktionDic);
                         
                         [memFunktionArray addObject:funktionDic];
                         
                      } // for k
                     
                     //NSLog(@"read_USB E7 FunktionArray vor: %@",[FunktionArray objectAtIndex:0]);
                     
                     [FunktionArray replaceObjectAtIndex:modelindex withObject:memFunktionArray];
                                          [memFunktionArray release];
                     //NSLog(@"read_USB E7 FunktionArray nach: %@",[FunktionArray objectAtIndex:0]);

                     [FunktionTable reloadData];
                     
                     
                     
                     
                     
                     
                     // Ausgabe
                     fprintf(stderr,"\n");

                       fprintf(stderr,"E7 Funktion:\n");
                      int offset = 0x20;
                     //for (int k=offset;k<(offset+8);k++)
                      for (int k=0;k<8;k++)
                      {
                         fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                      }
                      fprintf(stderr,"\n");
                     
                     
                     
                     
                     fprintf(stderr,"\nE7 Ausgabe von 32 an");
                     for (int k=32;k<USB_DATENBREITE;k++)
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     fprintf(stderr,"\n");
                     
                     // Master refresh
                     [readfunktion_mark setBackgroundColor:[NSColor greenColor]];
                     
                   //  [self reportRefresh_Master:NULL];
                     
                  }break;
   
                     
                     
                     
                  case 0xEC:
                  {
                     
                     fprintf(stderr,"* echo EC nach laden: \n");
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"startadresse: %02d\nerr_count: %d\n ",startadresse,buffer[3]);

                     for (int k=0;k<USB_DATENBREITE;k++) // 32 16Bit-Werte
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        fprintf(stderr,"%02X\t",(uint8)buffer[k]);
                        
                        //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
                        //fprintf(stderr,"%d\t",wert);
                     }
                     
                     
                     fprintf(stderr,"\n\n");
                     usbtask = 0;
                     
                  }break;
                     
                     
                  case 0xF0:// MARK: F0 Daten von Master
                  {
                     int adc0L = (UInt8)buffer[0x3E];// LO
                     int adc0H = (UInt8)buffer[0x3F];// HI
                     int adc0 = adc0L | (adc0H<<8);
                     
                     //NSLog(@"adc0L: %d adc0H: %d adc0: %d",adc0L,adc0H,adc0);
                     if (adc0L)
                     {
                        [ADC_DataFeld setIntValue:adc0];
                        [ADC_Level setIntValue:adc0];
                     }
                     if (buffer[0x3B])
                     {
                        NSLog(@"task_out: %d ",(UInt8)buffer[0x3B]);
                     }
                     
                     int pot0L = (UInt8)buffer[1];
                     int pot0H = (UInt8)buffer[2];
                     
                     int pot0 = pot0L | (pot0H<<8);
                     
                     if (pot0L)
                     {
                        //NSLog(@"pot0L: %d pot0H: %d\n",pot0L,pot0H);
                        //fprintf(stderr,"\t%d\t%d\t%d\n",pot0L,pot0H,pot0);
                        [Pot0_Level setIntValue:pot0];
                        [Pot0_Slider setIntValue:pot0];
                        
                        [Pot0_DataFeld setIntValue:pot0];
                        //[Vertikalbalken setLevel:pot0/4096.0*255];
                        [Pot0_SliderInt setIntValue:pot0];
                        
                        [Vertikalbalken setLevel:(pot0-1000)/1000.0*255];
                        
                     }
                     
                     int pot1L = (UInt8)buffer[3];
                     int pot1H = (UInt8)buffer[4];
                     int pot1 = pot1L | (pot1H<<8);
                     if (pot1L)
                     {
                        [Pot1_Level setIntValue:pot1];
                        [Pot1_Slider setIntValue:pot1];
                        [Pot1_DataFeld setIntValue:pot1];
                        [Pot1_SliderInt setIntValue:pot1];
                        
                     }
                     if (pot0L && pot1L)
                     {
                        //fprintf(stderr,"\t%d\t%d\n",pot0,pot1);
                     }
                     
                     //for (int k=0;k<5;k++)
                     {
                        //NSLog(@"dataL: %d dataH: %d dataL: %d dataH: %d",(UInt8)buffer[20],(UInt8)buffer[21],(UInt8)buffer[18],(UInt8)buffer[19]);
                     }
                     int potxL = (UInt8)buffer[20];
                     int potxH = (UInt8)buffer[21];
                     
                     int potx = potxL | (potxH<<8);
                     [PPMFeldA setIntValue:potx];
                     
                     int potyL = (UInt8)buffer[18];
                     int potyH = (UInt8)buffer[19];
                     
                     int poty = potyL | (potyH<<8);
                     [PPMFeldB setIntValue:poty];
                     //NSLog(@"testdata");
                     
                     // Daten ausgeben
                     //for (int k=0;k<8;k++)
                     {
                       // fprintf(stderr,"%02X\t",(UInt8)buffer[EE_PARTBREITE+k]);
                     }
                     //fprintf(stderr,"\n");
                     //NSLog(@"testdata data0: %02X data1: %02X data2: %02X data3: %02X",(UInt8)buffer[EE_PARTBREITE],(UInt8)buffer[EE_PARTBREITE+1],(UInt8)buffer[EE_PARTBREITE+2],(UInt8)buffer[EE_PARTBREITE+3]);
                     /*
                     
                     int ppmalo =  (UInt8)buffer[24]; //byte 16
                     int ppmahi =  (UInt8)buffer[25]; //byte 17
                     int ppma = ppmalo | (ppmahi << 8);
                     //fprintf(stderr,"ppma \t%d\t%d\t%d\t",ppmalo,ppmahi,ppma);
                     [PPMFeldA setIntValue:ppma];
                     
 
                     int ppmblo =  (UInt8)buffer[26]; //byte 18
                     int ppmbhi =  (UInt8)buffer[27]; //byte 19
                     int ppmb = ppmblo | (ppmbhi << 8);
                     //fprintf(stderr,"ppmb \t%d\t%d\t%d\n",ppmblo,ppmbhi,ppmb);
                     [PPMFeldB setIntValue:ppmb];
                    // fprintf(stderr,"%d\t%d\n",ppma,ppmb);
                     
                     int canalwerta = (UInt8)buffer[28]|((UInt8)buffer[29]<<8);
                     int canalwertb = (UInt8)buffer[30]|((UInt8)buffer[31]<<8);
                     
                    // [Pot0_SliderInt setIntValue:ppma];
                    // [Pot1_SliderInt setIntValue:ppmb];
                     
                     //fprintf(stderr,"canalwerta:\t%d\tcanalwertb:\t%d\n",canalwerta,canalwertb);
                     */
                     /*
                     fprintf(stderr,"Eingang von LCD\n");
                     for (int k=0;k<USB_DATENBREITE/2;k++)
                        
                     {
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
*/
                  }break;
                     
                  // MARK: Fix Sendersettings
                  case 0xF2:
                  {
                     /*
                      bytebuffer[3] = changecode; // welcher kanal zu aendern
                      bytebuffer[4] = modelindex; // welches modell
                      */
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n+++ echo F2 fixadresse hex: %02X\tdez: %d\t\terr_count 0: %d\terr_count 1: %d\n ",startadresse,startadresse,buffer[3],buffer[8]);
                     fprintf(stderr,"changecode: %02X\t modelindex: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     fprintf(stderr,"\n");
                     //fprintf(stderr,"F2 funktion: %02X\t device: %02X\t",(uint8)buffer[15],(uint8)buffer[16]);
                     fprintf(stderr,"\n");
                     fprintf(stderr,"F2 Eingang von LCD \n");

                     
                  }break; // Fix Sendersettings
                     
                     
                 // MARK: F4 Fix Settings
                  case 0xF4: // echo Fix Settings
                  {
                     /*
                      bytebuffer[3] = changecode; // welcher kanal zu aendern
                      bytebuffer[4] = modelindex; // welches modell
                      */
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n+++ echo F4 fixadresse hex: %02X\tdez: %d\t\terr_count 0: %d\terr_count 1: %d\n ",startadresse,startadresse,buffer[3],buffer[8]);
                     fprintf(stderr,"changecode: %02X\t modelindex: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     fprintf(stderr,"\n");
                     fprintf(stderr,"levelwert: %02X\t expowert: %02X\t",(uint8)buffer[15],(uint8)buffer[16]);
                     fprintf(stderr,"\n");
                     fprintf(stderr,"F4 Eingang von LCD \n");
                     for (int k=0;k<USB_DATENBREITE;k++)
                     {
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }

                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");

                  }break;
                     
                  // MARK: F5 Read Settings
                  case 0xF5: // echo Read Settings
                  {
                     /*
                      */
                     
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n*** echo F5 Setting lesen readadresse hex: %02X\t dez: %d\tmodelindex: %d\n ",startadresse,startadresse,buffer[3]);
                     
                     for (int k=0;k<USB_DATENBREITE;k++)
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"\n***\n");
                     
                     
                     //fprintf(stderr,"byte: %02X\t checkbyte: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     // fprintf(stderr,"\n");
                     
                     NSMutableArray* memSettingArray = [[[NSMutableArray alloc]initWithCapacity:0]autorelease];
                     int modelindex = buffer[3];
                     for (int k=0;k<8;k++)
                     {
                        NSMutableDictionary* kanalDic = [[NSMutableDictionary alloc]initWithCapacity:0];
                        [kanalDic setObject:[NSNumber numberWithInt:modelindex] forKey:@"modelnummer"];
                        [kanalDic setObject:[NSString stringWithFormat:@"M %d",modelindex] forKey:@"model"];
                        [kanalDic setObject:[NSNumber numberWithInt:0] forKey:@"go"];
                        [kanalDic setObject:[NSNumber numberWithInt:0] forKey:@"state"];
                        [kanalDic setObject:[NSNumber numberWithInt:k] forKey:@"nummer"];
                        
                        // Level
                        int levelbyte = buffer[0x20 + k]; // EE_PARTBREITE in RC_LCD, 0x20
                        [kanalDic setObject:[NSNumber numberWithInt:(levelbyte & 0x07)] forKey:@"levela"]; // bit 0-2
                        [kanalDic setObject:[NSNumber numberWithInt:(levelbyte & 0x70)>>4] forKey:@"levelb"]; // bit 4-6
                        
                        // Expo
                        int expobyte = buffer[0x28 + k];
                        [kanalDic setObject:[NSNumber numberWithInt:(expobyte & 0x03)] forKey:@"expoa"];
                        [kanalDic setObject:[NSNumber numberWithInt:(expobyte & 0x30)>>4] forKey:@"expob"];
                        
                        // Art
                        [kanalDic setObject:[NSNumber numberWithInt:(expobyte & 0x0C)>>2] forKey:@"art"];
                        
                        // Richtung
                        [kanalDic setObject:[NSNumber numberWithInt:(expobyte & 0x80)>>7] forKey:@"richtung"];
                        
                        
                        
                        [memSettingArray addObject:kanalDic];
                     }
                     //NSLog(@"memSettingArray 0: %@",[memSettingArray objectAtIndex:0]);
                     //NSLog(@"memSettingArray 1: %@",[memSettingArray objectAtIndex:1]);
                     //NSLog(@"memSettingArray 2: %@",[memSettingArray objectAtIndex:2]);
                     //NSLog(@"memSettingArray 3: %@",[memSettingArray objectAtIndex:3]);
                     
                     [ModelArray replaceObjectAtIndex:modelindex withObject:memSettingArray];
                     //[memSettingArray release];
                     [KanalTable reloadData];
                     
                     //140105 Auskommentiert, verursachte Crash beim FixSettings. Warum hier aufgerufen???
                     int readposition =0; // position im Buffer
                     
                     //NSLog(@"read_USB MixingArray vor: %@",[MixingArray objectAtIndex:0]);
                     
                     NSMutableArray* memMixingArray = [[[NSMutableArray alloc]initWithCapacity:0]autorelease];
                     for (int k=0;k<4;k++)
                     {
                        
                        NSMutableDictionary* mixDic = [[NSMutableDictionary alloc]initWithCapacity:0];
                        [mixDic setObject:[NSNumber numberWithInt:modelindex] forKey:@"modelnummer"];
                        [mixDic setObject:[NSString stringWithFormat:@"M %d",modelindex] forKey:@"model"];
                        [mixDic setObject:[NSNumber numberWithInt:0] forKey:@"go"];
                        [mixDic setObject:[NSNumber numberWithInt:0] forKey:@"state"];
                        [mixDic setObject:[NSNumber numberWithInt:k] forKey:@"mixnummer"];
                        
                        // Kanal
                        int canalbyte = buffer[0x30 + readposition]; // EE_PARTBREITE +8, 0x
                        //canalbyte = 0x88;
                        int canala = canalbyte & 0x0F;
                        int canalb = (canalbyte & 0xF0)>>4;
                       // fprintf(stderr,"mixDic k: %d readposition: %d canalbyte: %02X canala: %d canalb: %d\n",k,readposition,canalbyte&0xFF,canala,canalb);
                        [mixDic setObject:[NSNumber numberWithInt:canala] forKey:@"canala"];
                        [mixDic setObject:[NSNumber numberWithInt:canalb] forKey:@"canalb"];
                        readposition++;
                        
                        // Art
                        int artbyte = buffer[0x30 + readposition];
                        int mixart = (artbyte & 0x07);
                        [mixDic setObject:[NSNumber numberWithInt:mixart] forKey:@"mixart"];
                        fprintf(stderr,"mixDic k: %d readposition: %d artbyte: %02X mixart: %d \n",k,readposition,artbyte,mixart);
                        
                        //NSLog(@"k: %d canalbyte: %02X",k,canalbyte);
                        //if (artbyte) // Einstellungen fuer Mixing vorhanden
                        {
                           //NSLog(@"load k: %d canalbyte: %02X",k,canalbyte);
                           [memMixingArray addObject:mixDic];
                        }
                        readposition++;
                     } // for k
                     //NSLog(@"memMixingArray: %@",memMixingArray );
                     
                     
                     
                     //NSLog(@"replace modelindex: %d ",modelindex);
                     //NSLog(@"MixingArray vor replace: %@",MixingArray );
                     [MixingArray replaceObjectAtIndex:modelindex withObject:memMixingArray];
                     //NSLog(@"MixingArray nach: %@",[MixingArray objectAtIndex:0]);
                     //[memMixingArray release];
                     [MixingTable reloadData];
                     
                     
                     
                     
                     
                     
                     // Ausgabe
                     fprintf(stderr,"\n");
                     fprintf(stderr,"Level:\n");
                     int offset = 0x20;
                     for (int k=offset;k<(offset+8);k++)
                     {
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"\n");
                     fprintf(stderr,"Expo:\n");
                     offset = 0x28; // 40
                     for (int k=offset;k<(offset+8);k++)
                     {
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"\n");
                     
                     fprintf(stderr,"Mix:\n");
                     offset = 0x30; // 48
                     for (int k=offset;k<(offset+8);k++)
                     {
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"\n");
                     
                     /*
                     fprintf(stderr,"Funktion:\n");
                     offset = 0x38;
                     for (int k=offset;k<(offset+8);k++)
                     {
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"\n");
                     */
                   
                     
                     
                     fprintf(stderr,"\nF5 Ausgabe von 32 an");
                     for (int k=32;k<USB_DATENBREITE;k++)
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     
                     // Master refresh
                     [readsetting_mark setBackgroundColor:[NSColor greenColor]];
                     [self reportRefresh_Master:NULL];
                     
                  }break;
                  
                  case 0xF6: // echo Fix Mixing Byteschreiben
                  {
                     /*
                      sendbuffer[1] = writeadresse & 0xFF;
                      sendbuffer[2] = (writeadresse & 0xFF00)>>8;
                      sendbuffer[3] = byte_errcount;
                      sendbuffer[4] = eeprom_writedatabyte;
                      sendbuffer[5] = checkbyte;
                      sendbuffer[6] = w;
                      sendbuffer[7] = 0x00;
                      sendbuffer[8] = 0xF9;
                      sendbuffer[9] = 0xFA;
                      */
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n*** echo F6 Mixing byteschreiben writeadresse: %02X\terr_count: %d\n ",startadresse,buffer[3]);
                     fprintf(stderr,"eeprom_writedatabyte: %02X\t checkbyte: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     fprintf(stderr,"\n");
                     for (int k=0;k<USB_DATENBREITE;k++)
                        
                     {
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     
                  }break;

                  case 0xFA: // echo Fix Mixing main
                  {
                     /*
                      sendbuffer[1] = writeadresse & 0xFF;
                      sendbuffer[2] = (writeadresse & 0xFF00)>>8;
                      sendbuffer[3] = byte_errcount;
                      sendbuffer[4] = eeprom_writedatabyte;
                      sendbuffer[5] = checkbyte;
                      sendbuffer[6] = w;
                      sendbuffer[7] = 0x00;
                      sendbuffer[8] = 0xF9;
                      sendbuffer[9] = 0xFA;
                      */
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n*** echo FA Mixing main writeadresse hex: %02X\tint: %d\terr_count: %d\n ",startadresse,startadresse,buffer[3]);
                     //fprintf(stderr,"eeprom_writedatabyte: %02X\t checkbyte: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     //fprintf(stderr,"\n");
                     for (int k=0;k<USB_DATENBREITE;k++)
                        
                     {
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"*\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     
                  }break;
                   
                  // MARK: FB Fix Mixings   
                  case 0xFB: // echo Fix Mixing Byteschreiben
                  {
                     /*
                      sendbuffer[1] = writeadresse & 0xFF;
                      sendbuffer[2] = (writeadresse & 0xFF00)>>8;
                      sendbuffer[3] = byte_errcount;
                      sendbuffer[4] = eeprom_writedatabyte;
                      sendbuffer[5] = checkbyte;
                      sendbuffer[6] = w;
                      sendbuffer[7] = 0x00;
                      sendbuffer[8] = 0xF9;
                      sendbuffer[9] = 0xFA;
                      */
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n*** echo FB Mixing byteschreiben writeadresse hex: %02X\tint: %d\terr_count: %d databyte: %02X\n ",startadresse,startadresse,buffer[3],(uint8_t)buffer[4]);
                     fprintf(stderr,"changecode: %02X\n",(uint8_t)buffer[4]);
                     //fprintf(stderr,"eeprom_writedatabyte: %02X\t checkbyte: %02X\t",(uint8)buffer[4],(uint8)buffer[5]);
                     //fprintf(stderr,"\n");
                     for (int k=0;k<USB_DATENBREITE;k++)
                        
                     {
                        
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     
                  }break;
                     
                  case 0xFC: // echo Refresh
                  {
                     fprintf(stderr,"\n*** echo FC Refresh\n ");
                     [refreshmaster_mark setBackgroundColor:[NSColor greenColor]];
                     NSBeep();
                  }break;
                     
                     
                     // MARK: FD Read SenderSettings
                  case 0xFD: // echo Read SenderSettings
                  {
                     /*
                      */
                     [readsender_mark setBackgroundColor:[NSColor greenColor]];
                     int modelindex = buffer[3];
                     int startadresse = (uint8)buffer[1] | ((uint8)buffer[2]<<8);
                     fprintf(stderr,"\n*** echo FD SenderSetting lesen readadresse hex: %02X\t dez: %d\tmodelindex: %d\n ",startadresse,startadresse,buffer[3]);
                     
                     int kanal =startadresse & 0x000F;
                     int databytecode = startadresse & 0xFFF0;
                     int data =(UInt8)buffer[3]&0x00FF;
                     NSLog(@"kanal: %d databytecode: %02X",databytecode,kanal);

                     
                     
                     for (int k=0;k<USB_DATENBREITE;k++)
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"***\n");
                     
                     //NSLog(@"read_USB E7 FunktionArray[0] vor: %@",[FunktionArray objectAtIndex:0]);
                     
                     NSMutableArray* memFunktionArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
                     
                     for (int k=0;k<8;k++)
                     {
                        NSMutableDictionary* funktionDic = [[[NSMutableDictionary alloc]initWithCapacity:0]autorelease];
                        [funktionDic setObject:[NSNumber numberWithInt:modelindex]
                                        forKey:@"modelnummer"];
                        [funktionDic setObject:[NSString stringWithFormat:@"M %d",modelindex] forKey:@"model"];
                        [funktionDic setObject:[NSNumber numberWithInt:0] forKey:@"go"];
                        [funktionDic setObject:[NSNumber numberWithInt:0] forKey:@"state"];
                        [funktionDic setObject:[NSNumber numberWithInt:k] forKey:@"nummer"];
                        
                        int funktionbyte = buffer[0x20 + k]&0xFF; // ab 32
                        
                        // index ist Kanal
                        // !! Funktion ist bit 0-2 , Steuerdevice ist bit 4-6!!
                        int funktionindex = funktionbyte & 0x07;
                        
                        [funktionDic setObject:[NSNumber numberWithInt:(funktionbyte & 0x07)] forKey:@"funktionnummer"]; // bit 0-2
                        // NSLog(@"count: %d*",[default_FunktionArray count]);
                        //NSLog(@"read_USB E7 default_FunktionArray: %@",[default_FunktionArray description]);
                        
                        [funktionDic setObject:[default_FunktionArray objectAtIndex:funktionindex] forKey:@"funktion"];
                        
                        int deviceindex = (funktionbyte & 0x70)>>4;
                        
                        [funktionDic setObject:[NSNumber numberWithInt:(funktionbyte & 0x70)>>4] forKey:@"devicenummer"]; // bit 4-6
                        [funktionDic setObject:[default_DeviceArray objectAtIndex:deviceindex] forKey:@"device"];
                        
                        //NSLog(@"read_USB E7 k: %d funktionbyte: %02X funktionDic: %@",k,funktionbyte, funktionDic);
                        
                        [memFunktionArray addObject:funktionDic];
                        
                     } // for k
                     
                     //NSLog(@"read_USB E7 FunktionArray vor: %@",[FunktionArray objectAtIndex:0]);
                     
                     [FunktionArray replaceObjectAtIndex:modelindex withObject:memFunktionArray];
                     [memFunktionArray release];
                     
                     //NSLog(@"read_USB E7 FunktionArray nach: %@",[FunktionArray objectAtIndex:0]);
                     
                     [FunktionTable reloadData];
                     
                     
                     
                     
                     
                     
                     
                     // Ausgabe
                     fprintf(stderr,"\n");
                     fprintf(stderr,"FD Funktion:\n");
                     int offset = 0x20;
                     for (int k=offset;k<(offset+8);k++)
                     {
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"\n");
                     fprintf(stderr,"Device:\n");
                     offset = 0x28;
                     for (int k=offset;k<(offset+8);k++)
                     {
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"\n");
                     fprintf(stderr,"Ausgang:\n");
                     offset = 0x30;
                     for (int k=offset;k<(offset+8);k++)
                     {
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                     }
                     fprintf(stderr,"\n");
                     
                     fprintf(stderr,"\nFD Ausgabe von 32 an");
                     for (int k=32;k<USB_DATENBREITE;k++)
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"\n");
                        }
                        
                        else if (k && k%(EE_PARTBREITE/4)==0)
                        {
                           fprintf(stderr,"\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(buffer[k]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     
                     

                     [FunktionTable reloadData];
                  }break;

               }// switch code
               
               
               
            } // if code EEPROM_WRITE_TASK
            
         }break;
             
      
      } // switch usbtask
      
      
     
      anzDaten++;
      
   } // neue Daten
}

/*******************************************************************/
// CNC
/*******************************************************************/
- (void)USB_Aktion:(NSNotification*)note
{
   NSLog(@"USB_Aktion");
   //NSLog(@"USB_Aktion usbstatus: %d usb_present: %d",usbstatus,usb_present());
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
   
   
// Start neue Daten
      Dataposition=0;
      
      if ([USB_DatenArray count])
      {
         if (sizeof(newsendbuffer))
         {
            free(newsendbuffer);
         }
         newsendbuffer=malloc(64);
         
         NSMutableArray* tempUSB_DatenArray=(NSMutableArray*)[USB_DatenArray objectAtIndex:Dataposition];
         //[tempUSB_DatenArray addObject:[NSNumber numberWithInt:[AVR pwm]]];
         NSScanner *theScanner;
         unsigned	  value;
         //NSLog(@"USB_Aktion tempUSB_DatenArray count: %d",[tempUSB_DatenArray count]);
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
         //NSLog(@"USB_Aktion Kontrolle Abschnitt 0 vor writeAbschnitt. Dataposition: %d",Dataposition);
         for (i=0;i<[tempUSB_DatenArray count];i++)
         {
            fprintf(stderr,"\t%02X",[[tempUSB_DatenArray objectAtIndex:i]intValue] & 0xFF);
         }
         fprintf(stderr,"\n");
         //Dataposition++;
         [self write_Abschnitt];
         
      } // if count
      
      //NSLog(@"USB_Aktion Start Timer");
   
      // home ist 1 wenn homebutton gedrückt ist
      NSMutableDictionary* timerDic =[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"home", nil];
      
      
      if (readTimer)
      {
         if ([readTimer isValid])
         {
            //NSLog(@"USB_Aktion laufender timer inval");
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

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
   [KanalTable setDataSource:self];
}

// MARK: awake

/*" Invoked when the nib file including the window has been loaded. "*/
- (void) awakeFromNib
{
   // Experimente
   int offset=3;
   uint16_t tmp1 = (0x76);//<<8;         // 8 bit nach oben zum voraus: Platz schaffen
   uint16_t tmp2 =tmp1<<(8-offset);          // offset
   uint8_t tmp3 = (tmp2&0xFF00)>>8; // obere 8 bit, 8 bit nach unten, ergibt lo
   uint8_t tmp4 = (tmp2&0x00FF)>>4; // obere 8 bit, 4 bit nach unten, ergibt hi
   
   
   fprintf(stderr,"tmp1 A: %02X\n",tmp1);
   //tmp1 += 0x10;
   //fprintf(stderr,"tmp1 B: %02X\n",tmp1);
   //tmp1 += 0x10;
   //fprintf(stderr,"tmp1 C: %02X\n",tmp1);
   //tmp1 &= ~0x30;
   //fprintf(stderr,"tmp1 D: %02X\n",tmp1 );

   
   uint8_t ri = (tmp1 & 0x70);
  uint8_t ra = tmp1 & 0x07;
   
   fprintf(stderr,"ri 1: %02X\n",ri);
   ri -= 0x20;
   fprintf(stderr,"ri 2: %02X\n",ri);
   ri=0;
   //tmp1 |= 0x0F;
   //fprintf(stderr,"tmp1 B: %02X\n",tmp1);

   //tmp1 = tmp1|ri;
   //fprintf(stderr,"tmp1 C: %02X\n",tmp1);
   
  // tmp1 = (ri)|ra;
   tmp1 = ri | (tmp1&0x0F);
   fprintf(stderr,"tmp1 D: %02X\n",tmp1);
   
   ri >>= 7;
   fprintf(stderr,"%d\n",ri);
   
   int16_t rii = 247;
   fprintf(stderr,"rii: %d\n",rii);
   rii *= (-1);
   fprintf(stderr,"rii: %d\n",rii);
   
   
  // fprintf(stderr,"%02X\t%02X\t%02X\t%02X\n",tmp1,tmp2,tmp3,tmp4);

   int aaa = 0x8000;
   fprintf(stderr, "aaa: %02X\n",aaa);
   int bbb = (aaa & 0xF000);
   fprintf(stderr, "bbb: %02X\n",bbb);
   bbb>>=8;
   fprintf(stderr, "bbb: %02X\n",bbb);
   bbb >>=4;
   fprintf(stderr, "bbb: %02X\n",bbb);
   
   
   uint8_t a=0;
   mausistdown=0;
   anzrepeat=0;
   int listcount=0;
   struct Abschnitt *first;
   // LinkedList
   first=NULL;
   
 //
   int mixcanal = 0x00;
   
   if (mixcanal ^ 0x88) // 88 bedeutet OFF
   {
      NSLog(@"mixcanal ist ok: %02X ",mixcanal);
   }
   else
   {
      NSLog(@"mixcanal ist OFF: %02X ",mixcanal);
   }

	
	uint8_t zahl=244;
	char string[3];
	uint8_t l,h;                             // schleifenzähler
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
   
   fprintf(stderr,"LCD\n");
   
   ModelArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
   
   [KanalTable setDelegate:self];
   
   
   for (int model=0;model<3;model++)
   {
      SettingArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
      for (int kanal=0;kanal<8;kanal++)
      {
         NSMutableDictionary* kanaldic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInt:kanal],@"nummer", // 3 bit
                                           [NSNumber numberWithInt:0],@"art",        // 2 bit
                                           [NSNumber numberWithInt:0],@"richtung",   // 1 bit
                                           [NSNumber numberWithInt:0],@"levela",    // 3 bit
                                           [NSNumber numberWithInt:0],@"levelb",    // 3 bit
                                           [NSNumber numberWithInt:0],@"expoa",     // 3 bit
                                           [NSNumber numberWithInt:0],@"expob",     // 3 bit
                                           [NSNumber numberWithInt:0],@"mix",
                                           [NSNumber numberWithInt:kanal],@"mixkanal", // 3 bit
                                           [NSNumber numberWithInt:0],@"go",
                                           [NSNumber numberWithInt:0],@"state",
                                           [NSNumber numberWithInt:model],@"modelnummer", // 3 bit
                                           [NSString stringWithFormat:@"M %d",model],@"model",
                                           nil]retain]; // 27 bit
         [SettingArray addObject:kanaldic];
         [kanaldic release];
      }
      [ModelArray addObject:SettingArray];
      [SettingArray release];
      [KanalTable reloadData];
      
      MixingArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
      [MixingTable setDelegate:self];
      [MixingTable setDataSource:self];
      
      NSMutableArray* MixingSettingArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
      for (int settingindex=0;settingindex<4;settingindex++)
      {
         NSMutableDictionary* mixingdic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:settingindex],@"mixnummer",
                                            [NSNumber numberWithInt:0x00],@"mixart",
                                            [NSNumber numberWithInt:0x08],@"canala",
                                            [NSNumber numberWithInt:0x08],@"canalb",
                                            [NSString stringWithFormat:@"Mix %d",0],@"mixing",
                                            nil]retain];
         [MixingSettingArray addObject:mixingdic];
         [mixingdic release];
      }
      [[MixingSettingArray objectAtIndex:0]setObject:[NSNumber numberWithInt:0x01] forKey:@"mixart"];
      [[MixingSettingArray objectAtIndex:1]setObject:[NSNumber numberWithInt:0x02] forKey:@"mixart"];
      [MixingArray addObject:MixingSettingArray];
      [MixingSettingArray release];
      [MixingTable reloadData];
      /*
       // Dispatch
       DispatchArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
       [DispatchTable setDelegate:self];
       [DispatchTable setDataSource:self];
       
       NSMutableArray* DispatchSettingArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
       for (int dispatchindex=0;dispatchindex<8;dispatchindex++)
       {
       int canal = dispatchindex;
       int device = dispatchindex;
       NSMutableDictionary* dispatchdic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
       [NSNumber numberWithInt:canal],@"canal",
       [NSNumber numberWithInt:device],@"device",
       [NSNumber numberWithInt:(canal | (device<<4))],@"dispatchcanal",
       [NSString stringWithFormat:@"Dispatch %d",0],@"dispatch",
       nil]retain];
       [DispatchSettingArray addObject:dispatchdic];
       [dispatchdic release];
       }
       NSLog(@"DispatchSettingArray : %@",[DispatchSettingArray  description]);
       [DispatchArray addObject:DispatchSettingArray];
       [DispatchSettingArray release];
       [DispatchTable reloadData];
       // end Dispatch
       */
      // Funktion tag 700
      /*
       const char funktion0[] PROGMEM = "Seite \0";
       const char funktion1[] PROGMEM = "Hoehe \0";
       const char funktion2[] PROGMEM = "Quer   \0";
       const char funktion3[] PROGMEM = "Motor \0";
       const char funktion4[] PROGMEM = "Quer L\0";
       const char funktion5[] PROGMEM = "Quer R\0";
       const char funktion6[] PROGMEM = "Lande \0";
       const char funktion7[] PROGMEM = "Aux    \0";
       */
      
      //Device
      default_DeviceArray = [NSArray arrayWithObjects:@"L_H",@"L_V",@"R_H",@"R_V",@"S_L",@"S_R",@"Sch",@"-", nil];
      [default_DeviceArray retain];
      // Funktion
      default_FunktionArray = [NSArray arrayWithObjects:@"Seite",@"Hoehe",@"Quer",@"Motor",@"Quer L",@"Quer R",@"Lande",@"Aux", nil];
      [default_FunktionArray retain];
      //NSLog(@"awake default_FunktionArray: %@",default_FunktionArray);
      
      
      FunktionArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
      [FunktionTable setDelegate:self];
      [FunktionTable setDataSource:self];
      
      // Settings pro model
      NSMutableArray* FunktionSettingArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
      for (int funktionindex=0;funktionindex<8;funktionindex++)
      {
         int canal = funktionindex;
         int devicenummer = funktionindex;
         int funktionnummer = 7-funktionindex;
         
         NSMutableDictionary* funktiondic = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:funktionindex],@"nummer",
                                              [NSNumber numberWithInt:devicenummer],@"devicenummer",
                                              [default_DeviceArray objectAtIndex:funktionindex],@"device",
                                              [NSNumber numberWithInt:funktionnummer],@"funktionnummer",
                                              
                                              [default_FunktionArray objectAtIndex:funktionindex],@"funktion",
                                              
                                              [NSNumber numberWithInt:((funktionnummer & 0xFF) | ((devicenummer & 0xFF)<<4))],@"device_funktion",
                                              
                                              nil]retain];
         [FunktionSettingArray addObject:funktiondic];
         [funktiondic release];
      }
      //NSLog(@"FunktionSettingArray : %@",[FunktionSettingArray  description]);
      [FunktionArray addObject:FunktionSettingArray];
      [FunktionSettingArray release];
      [FunktionTable reloadData];
      // end Funktion
      
      
   }
   
  // NSLog(@"ModelArray 0 count: %d data: %@ ",(int)[[ModelArray objectAtIndex:0] count],[ModelArray objectAtIndex:0]);
   
   [SettingTab selectTabViewItemAtIndex:0];
    [[[[SettingTab selectedTabViewItem] view]viewWithTag:100]setStringValue: @"M 0"];

   
   //NSLog(@"SettingArray : %@",[SettingArray  description]);
   eepromwritestatus=0; // enthalt Bits fuer den Write-Status
   
   EEPROMposition = 0;
   
   //int aa=(15625& 0x00FF)>>8;
   //int bb = 15625& 0x00FF;
   //NSLog(@"aa: %d bb: %d",aa,bb);
	
   Math = [[rMath alloc]init];
   ChecksummenArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
   checksumme=0;
   ExpoDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   
   [self loadExpoDatenArray];
   int anzstufen=4;
   
   
   /*
    EEDatenArray enthaelt anzstufen Arrays mit 2* Vektorsize Werten (lo, hi hintereinander) fuer die Stufe
    */
   
   EEDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   
   
   for (int stufe=0;stufe<anzstufen;stufe++)
   {
      NSArray* neuerDatenArray = [Math expoDatenArrayMitStufe:stufe];
      
      //fprintf(stderr,"stufe: %d\n",stufe);
      int wert=0;
      
      for (int pos=0;pos<2*VEKTORSIZE-1;pos++)
      {
         if (pos%32==0)
         {
//            fprintf(stderr,"\n");
         }

         if (pos%2 == 0)
         {
            wert=0;
            uint8 lo = [[neuerDatenArray objectAtIndex:pos]intValue];
            uint8 hi = [[neuerDatenArray objectAtIndex:pos+1]intValue];
            wert = hi;
            wert <<= 8;
            wert += lo;
            
            
            //fprintf(stderr,"\t%d \t%d\t%d\t* \tw:\t %d *\t\n",pos/2,lo,hi,wert);
            //fprintf(stderr,"%d\t%d\n",pos/2,wert);
//            fprintf(stderr,"\t%d\t%d",lo,hi);
         }
      }
//      fprintf(stderr,"\n\n");
      [EEDatenArray addObject:neuerDatenArray];
      //NSLog(@"awake end default_FunktionArray: %@",default_FunktionArray);
   }
   
   
   
   // Werte ausgeben
   
   for (int stufe=0;stufe<anzstufen;stufe++)
   {
      NSArray* neuerDatenArray = [Math expoDatenArrayMitStufe:stufe];
      
      //fprintf(stderr,"stufe: %d\n",stufe);
      int wert=0;
      
      for (int pos=0;pos<2*VEKTORSIZE-1;pos+=2)
      {
         //       if (pos%32==0)
         {
            //          fprintf(stderr,"\n");
         }
         
         if (pos%2 == 0)
         {
            wert=0;
            uint8 lo = [[neuerDatenArray objectAtIndex:pos]intValue];
            uint8 hi = [[neuerDatenArray objectAtIndex:pos+1]intValue];
            wert = hi;
            wert <<= 8;
            wert += lo;
            //      fprintf(stderr,"\t%d",wert);
         }
      }
 //     fprintf(stderr,"\n\n");
   }
   
   DiagrammExpoDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   {
     
      int wert=0;
      for (int pos=0;pos<2*VEKTORSIZE-1;pos++)
      //for (int pos=0;pos<100-1;pos++)
      {
         if (pos%2 == 0)
         {
  //          if ((pos%16==0) || (pos == 2*VEKTORSIZE-2))
            {
 //              fprintf(stderr,"%d\t",pos/2);
               NSMutableArray* tempDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
               [tempDatenArray addObject:[NSNumber numberWithFloat:(float)pos]];
               for (int stufe=0;stufe<anzstufen;stufe++)
               {
                  wert=0;
                  uint8 lo = [[[EEDatenArray objectAtIndex:stufe] objectAtIndex:pos]intValue];
                  uint8 hi = [[[EEDatenArray objectAtIndex:stufe] objectAtIndex:pos+1]intValue];
                  wert = hi;
                  wert <<= 8;
                  wert += lo;
                  [tempDatenArray addObject:[NSNumber numberWithFloat:(float)wert-STARTWERT]];
                  
                  //[DiagrammExpoDatenArray addObject:[NSNumber numberWithFloat:(float)wert]];
                  
                  //fprintf(stderr,"\t%d \t%d\t%d\t* \tw:\t %d *\t\n",pos/2,lo,hi,wert);
                 
  //                fprintf(stderr,"%d\t",wert);
                  
                  //fprintf(stderr,"\t%d\t%d | ",lo,hi);

               }
               [DiagrammExpoDatenArray addObject:tempDatenArray];
              
               {
  //             fprintf(stderr,"\n");
               }
            }
         
         }
      }
   }
   
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
      [Warnung setMessageText:[NSString stringWithFormat:@"%@",@"RC-Programm starten"]];
      
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
            //return;
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
   
   if (usbstatus)
   {
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
   
   } //   if usbstatus
   //
   NSRect Balkenrect = [Vertikalbalken frame];
   //[Vertikalbalken initWithFrame:Balkenrect];
   //[Vertikalbalken setLevel:177];
   [Vertikalbalken setNeedsDisplay:YES];
   
   NSRect DataFeld = [DatadiagrammFeld frame];
   DataFeld.origin.x += 0.1;
   Datadiagramm = [[rDataDiagramm alloc]initWithFrame:DataFeld];
  // [[[self window]contentView]addSubview:Datadiagramm];
   
   [[[SettingTab tabViewItemAtIndex:1]view ]addSubview:Datadiagramm];
   
    
   NSRect OrdinatenFeld=[Datadiagramm frame];
	OrdinatenFeld.size.width=30;
	
	OrdinatenFeld.origin.x-=35;
   DataOrdinate =[[rOrdinate alloc]initWithFrame:OrdinatenFeld];
   //[[[self window]contentView]addSubview:DataOrdinate];
   
    [[[SettingTab tabViewItemAtIndex:1]view ]addSubview:DataOrdinate];
   
   [Datadiagramm setOrdinate:DataOrdinate];
   [Datadiagramm setGrundlinienOffset:5.0];
   
   
   int maxY = ENDWERT+1000;
   int maxX = 2048+100;
   
   
   
   
   float faktorX = DataFeld.size.width/maxX;
   float faktorY = DataFeld.size.height/maxY;
   //NSLog(@"faktorX: %2.4f faktorY: %2.4f",faktorX,faktorY);
 
   NSDictionary* VorgabenDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:faktorX],@"faktorx",[NSNumber numberWithFloat:faktorY],@"faktory", [NSNumber numberWithFloat:faktorX],@"faktorx",nil];
  
   [Datadiagramm setVorgaben:VorgabenDic];
   NSArray* KanalArray = [NSArray arrayWithObjects:@"1",@"1",@"1",@"1",@"0",@"0",@"0",@"0",nil];
   for (int index=0;index < [DiagrammExpoDatenArray count]-1;index++)
   {
      [Datadiagramm setWerteArray:[DiagrammExpoDatenArray objectAtIndex:index ] mitKanalArray:KanalArray mitVorgabenDic:VorgabenDic];
   }
   [Datadiagramm setNeedsDisplay:YES];
  // [DataOrdinate setGrundlinienOffset:5.0];
   //[DataOrdinate setMaxOrdinate:10];
   NSPoint DiagrammEcke=[Datadiagramm frame].origin;
	
	DiagrammEcke.x+=2;
//	[Datadiagramm setFrameOrigin:DiagrammEcke];
   [Datadiagramm setNeedsDisplay:YES];

   ChecksummenArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
   checksumme=0;

//   [self startRead];
   NSTextContainer *  container = [EE_dataview textContainer];
   [container setWidthTracksTextView: NO];
   NSSize    size = [container containerSize];
   size.width = 2000;
   [container setContainerSize: size];
   if (usbstatus)
   {
      
   NSTimer* startTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
                                                 target:self
                                               selector:@selector(startReadAktion:)
                                               userInfo:NULL repeats:NO]retain];

   }
}


- (void)startReadAktion:(NSTimer*)timer
{
   [timer invalidate];
    [timer release];
   NSLog(@"startReadAktion");
   [self startRead];
   NSTimer* haltTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(Read_SettingsAktion:)
                                                         userInfo:NULL repeats:NO]retain];

   [self setHalt:YES];
//   [self reportRead_Settings:NULL];
}

- (void)Read_SettingsAktion:(NSTimer*)timer
{
   [timer invalidate];
   [timer release];
   NSLog(@"Read_SettingsAktion");
   [self reportRead_Settings:NULL];
   
   
   NSTimer* startTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0
                                                          target:self
                                                        selector:@selector(Read_Sender_Aktion:)
                                                        userInfo:NULL repeats:NO]retain];

   
   // refresh in F5 veranlasst EVENTUELL IN READ_SENDER_AKTION aktivieren !!
   /*
   NSTimer* haltTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0
                                                          target:self
                                                        selector:@selector(Refresh_MasterAktion:)
                                                        userInfo:NULL repeats:NO]retain];
*/
   
   
}


- (void)Read_Sender_Aktion:(NSTimer*)timer
{
   [timer invalidate];
   [timer release];
   NSLog(@"startSendersettingReadAktion");
   //[self reportRead_FunktionSettings:NULL];
   
   [self reportRead_SenderSettings:NULL];
   
   
   // refresh in F5 veranlasst
   /*
    NSTimer* haltTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0
    target:self
    selector:@selector(Refresh_MasterAktion:)
    userInfo:NULL repeats:NO]retain];
    */
   
   
}






- (void)Refresh_MasterAktion:(NSTimer*)timer
{
   [timer invalidate];
   [timer release];
   NSLog(@"Refresh_MasterAktion");
   [self reportRefresh_Master:NULL];
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


#pragma mark Defs

- (IBAction)reportDefinitionen:(id)sender
{
   if (!Definitionen)
   {
      Definitionen = [[rDefinitionen alloc]initWithWindowNibName:@"Definitionen"];
   }
   [Definitionen showWindow:self];
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
   if ([Halt_Taste state])
   {
      NSBeep();
      [Halt_Taste performClick:NULL ];
      return NO;
   }

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
   if ([Halt_Taste state])
   {
      NSBeep();
      [Halt_Taste performClick:NULL ];
      return NO;
   }
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
   if ([Halt_Taste state])
   {
      NSBeep();
      [Halt_Taste performClick:NULL ];
      return NO;
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
   
   if ([Halt_Taste state])
   {
      NSBeep();
      [Halt_Taste performClick:NULL ];
      return NO;
   }
	
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

// MARK: TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
   
   //int tabindex = [aTableView tag]%100;
   int tabindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];

   switch([aTableView tag]/100 )
   {
      case 4:
      {
         //NSLog(@"ModelArray count: %d",[ModelArray count]);
         return [[ModelArray objectAtIndex:tabindex] count];
      }break;
      case 5:
      {
         //NSLog(@"MixingArray count: %d",[MixingArray count]);
         return [[MixingArray objectAtIndex:tabindex] count];
      }break;
      case 6:
      {
         return [[DispatchArray objectAtIndex:tabindex] count];
      }break;

      case 7:
      {
         NSLog(@"FunktionArray count: %d",[FunktionArray count]);
         return [[FunktionArray objectAtIndex:tabindex] count];
      }break;

      case 8:
      {
         return [[AusgangArray objectAtIndex:tabindex] count];
      }break;

   }
   return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   //int tabindex = [aTableView tag]%100;
   
   int tabindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];
   //NSLog(@"objectValueForTableColumn rowIndex: %d tabindex: %d",rowIndex, tabindex);
   switch((int)[aTableView tag]/100 )
   {
      case 4:
      {
        // if (tabindex < [ModelArray count])
         {
            return [[[ModelArray objectAtIndex:tabindex] objectAtIndex:rowIndex]objectForKey:[aTableColumn identifier]];
         }
      }break;
      case 5:
      {
        // NSLog(@"objectValueForTableColumn rowIndex: %d tabindex: %d",rowIndex, tabindex);
         //if (tabindex < [MixingArray count])
         {
            
            return [[[MixingArray objectAtIndex:tabindex] objectAtIndex:rowIndex]objectForKey:[aTableColumn identifier]];
         }
      }break;

      case 6:
      {
         //NSLog(@"objectValueForTableColumn rowIndex: %d tabindex: %d",rowIndex, tabindex);
         //if (tabindex < [DispatchArray count])
         {
            
            return [[[DispatchArray objectAtIndex:tabindex] objectAtIndex:rowIndex]objectForKey:[aTableColumn identifier]];
         }
      }break;

      case 7:
      {
         //NSLog(@"objectValueForTableColumn rowIndex: %d tabindex: %d",rowIndex, tabindex);
         //if (tabindex < [FunktionArray count])
         {
            
            return [[[FunktionArray objectAtIndex:tabindex] objectAtIndex:rowIndex]objectForKey:[aTableColumn identifier]];
         }
      }break;
         
      case 8:
      {
         //NSLog(@"objectValueForTableColumn rowIndex: %d tabindex: %d",rowIndex, tabindex);
         if (tabindex < [AusgangArray count])
         {
            
            return [[[AusgangArray objectAtIndex:tabindex] objectAtIndex:rowIndex]objectForKey:[aTableColumn identifier]];
         }
      }break;
         
   }
   
   return NULL;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
   //int tabindex = [aTableView tag]%100;
   int tabindex = [SettingTab indexOfTabViewItem:[SettingTab selectedTabViewItem]];
   NSString* ident = [aTableColumn identifier];
  // if (tabindex < [ModelArray count])
	{
      switch((int)[aTableView tag]/100 )
      {
         case 4:
         {
            //NSLog(@"ident: %@ einDic: %@",ident,[einDic description]);
            
            if ([ident isEqual: @"go"])
            {
               //if ([aTableView selectedRow] == rowIndex)
               {
                  //NSLog(@"go: rowIndex: %lu data: %d",(long)rowIndex,[[SettingArray objectAtIndex:rowIndex]intValue]);
                  [[[ModelArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:@"state"];
                  
               }
            }
            
            {
               [[[ModelArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:ident];
            }
            //NSLog(@"go: rowIndex: %lu data: %@",(long)rowIndex,[[SettingArray objectAtIndex:rowIndex]description]);
            //NSLog(@"SettingArray: %@",[[ModelArray objectAtIndex:tabindex] description]);
            // NSArray* keyArray = [einDic allKeys];
            
            //[einDic setObject:anObject forKey:[aTableColumn identifier]];
         }break;
            
         case 5:
         {
            //NSLog(@"ident: %@ ",ident);
            
            if ([ident isEqual: @"go"])
            {
               //if ([aTableView selectedRow] == rowIndex)
               {
                  //NSLog(@"go: rowIndex: %lu data: %d",(long)rowIndex,[[SettingArray objectAtIndex:rowIndex]intValue]);
                  [[[MixingArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:@"state"];
                  
               }
            }
            
            {
               [[[MixingArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:ident];
            }
            if ([ident isEqualToString:@"mixart"])
            {
               NSLog(@"go: rowIndex: %lu data: %@",(long)rowIndex,[[[MixingArray objectAtIndex:tabindex] objectAtIndex:rowIndex]description]);
            }
               
            //
            //NSLog(@"SettingArray: %@",[SettingArray description]);
            // NSArray* keyArray = [einDic allKeys];
            
            //[einDic setObject:anObject forKey:[aTableColumn identifier]];
         }break;

         case 6: // Dispatch
         {
            //NSLog(@"ident: %@ ",ident);
            
            if ([ident isEqual: @"go"])
            {
               //if ([aTableView selectedRow] == rowIndex)
               {
                  //NSLog(@"go: rowIndex: %lu data: %d",(long)rowIndex,[[SettingArray objectAtIndex:rowIndex]intValue]);
                  [[[DispatchArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:@"state"];
                  
               }
            }
            
            {
               [[[DispatchArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:ident];
            }
            if ([ident isEqualToString:@"mixart"])
            {
               NSLog(@"go: rowIndex: %lu data: %@",(long)rowIndex,[[[DispatchArray objectAtIndex:tabindex] objectAtIndex:rowIndex]description]);
            }
            
            //
            //NSLog(@"DispatchArray: %@",[DispatchArray description]);
            // NSArray* keyArray = [einDic allKeys];
            
            //[einDic setObject:anObject forKey:[aTableColumn identifier]];
         }break;

         case 7: // Funktion
         {
            //NSLog(@"ident: %@ ",ident);
            
            if ([ident isEqual: @"go"])
            {
               //if ([aTableView selectedRow] == rowIndex)
               {
                  //NSLog(@"go: rowIndex: %lu data: %d",(long)rowIndex,[[SettingArray objectAtIndex:rowIndex]intValue]);
                  [[[FunktionArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:@"state"];
                  
               }
            }
            
            /*
             if ([ident isEqualToString:@"device"])
            {
              // NSLog(@"go: rowIndex: %lu data: %@",(long)rowIndex,[[[FunktionArray objectAtIndex:tabindex] objectAtIndex:rowIndex]description]);
               int tempdevicenummer =[[[[FunktionArray objectAtIndex:tabindex] objectAtIndex:rowIndex]objectForKey:@"devicenummer"]intValue];
               [default_DeviceArray objectAtIndex:tempdevicenummer];
           // [[[FunktionArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:[default_DeviceArray objectAtIndex:tempdevicenummer] forKey:@"device"];
            
            
            }
             */
            
            {
               [[[FunktionArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:ident];
            }

            //
            //NSLog(@"DispatchArray: %@",[DispatchArray description]);
            // NSArray* keyArray = [einDic allKeys];
            
            //[einDic setObject:anObject forKey:[aTableColumn identifier]];
         
         
         }break;
            
         case 8: // Ausgang
         {
            //NSLog(@"ident: %@ ",ident);
            
            if ([ident isEqual: @"go"])
            {
               //if ([aTableView selectedRow] == rowIndex)
               {
                  //NSLog(@"go: rowIndex: %lu data: %d",(long)rowIndex,[[SettingArray objectAtIndex:rowIndex]intValue]);
                  [[[AusgangArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:@"state"];
                  
               }
            }
            
            {
               [[[AusgangArray objectAtIndex:tabindex] objectAtIndex:rowIndex] setObject:anObject forKey:ident];
            }
            if ([ident isEqualToString:@"mixart"])
            {
               NSLog(@"go: rowIndex: %lu data: %@",(long)rowIndex,[[[AusgangArray objectAtIndex:tabindex] objectAtIndex:rowIndex]description]);
            }
            
            //
            //NSLog(@"AusgangArray: %@",[AusgangArray description]);
            // NSArray* keyArray = [einDic allKeys];
            
            //[einDic setObject:anObject forKey:[aTableColumn identifier]];
         }break;
            

            
      } // switch
	}
   [aTableView reloadData];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   // aCell als id: aCell laesst setBackgroungColor nicht zu
 //  if ([[aTableColumn identifier] isEqual: @"nummer"])
   {
      if (rowIndex %2==1)
      {
         //NSLog(@"rowIndex: %d",(int)rowIndex);
         [aCell setBackgroundColor:[NSColor greenColor]];
      }
      else
      {
         [aCell setBackgroundColor:[NSColor whiteColor]];
      }
   }
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem*)aTabViewItem
{
   //NSLog(@"didSelectTabViewItem index: %d",(int)[aTabView indexOfTabViewItem:aTabViewItem]);
   
   int index = [aTabView indexOfTabViewItem:aTabViewItem];
   //NSLog(@"subviews: %@",[[[aTabViewItem view]subviews]description]);
   //NSLog(@"subviews tag: %d",[[[[aTabViewItem view]subviews]lastObject ]tag]);

   if (index <[ModelArray count])
   {
      //[ModelFeld setStringValue:[[[ModelArray objectAtIndex:index]objectAtIndex:0]objectForKey:@"model"]];
      [[[aTabViewItem view]viewWithTag:100+index] setStringValue:[[[ModelArray objectAtIndex:index]objectAtIndex:0]objectForKey:@"model"]];
      
   }
   else
   {
      
      [[[aTabViewItem view]viewWithTag:100+index] setStringValue:@"-"];
   }
}




@end
