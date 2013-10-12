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
   NSLog(@"startRead");
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
   
   readTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(read_USB:)
                                               userInfo:timerDic repeats:YES]retain];

}


- (IBAction)reportWriteTask:(id)sender;
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

   // C4
   NSLog(@"\n***");
   NSLog(@"reportWrite_1_Byte");
   usbtask = EEPROM_WRITE_TASK;
   
   
    int EE_Startadresse = [EE_StartadresseFeld intValue];
   uint8 lo = EE_Startadresse & 0x00FF;
   uint8 hi = (EE_Startadresse & 0xFF00)>>8;
   
   uint8 data= [[[[ExpoDatenArray objectAtIndex:1]objectAtIndex:(EE_Startadresse % 2)]objectAtIndex:EE_Startadresse]intValue];

   //data = 0x14;
    
   [EE_DataFeld setIntValue: data];
   
    fprintf(stderr,"\n");
   fprintf(stderr,"data:\t%d\n",data);
 
   [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%X",lo]];
   [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%X",hi]];
   
   int EE_Data = [EE_DataFeld intValue];
   
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
   
   for (int pos = 0;pos < EE_PARTBREITE;pos++)
   {
      fprintf(stderr,"%x\t",bytebuffer[pos]);
   }
   fprintf(stderr,"\n");

   int senderfolg= rawhid_send(0, bytebuffer, 64, 50);
   
   NSLog(@"reportWrite_1_Byte erfolg: %d",senderfolg);
   [EE_StartadresseFeld setIntValue:EE_Startadresse+1];
   
   free(bytebuffer);
}


- (IBAction)reportRead_1_Byte_Increment:(id)sender
{
   // D4
   //NSLog(@"\n***");
   NSLog(@"reportRead_1_Byte");
   Dataposition = 0;
   usbtask = EEPROM_READ_TASK;
   [USB_DatenArray removeAllObjects];
   // Request einrichten
   NSMutableArray* codeArray = [[NSMutableArray alloc]initWithCapacity:USB_DATENBREITE];
   [codeArray addObject:[NSString stringWithFormat:@"%d",0xD6]];
   int EE_Startadresse = [EE_StartadresseFeld intValue];
   uint8 lo = EE_Startadresse & 0x00FF;
   uint8 hi = (EE_Startadresse & 0xFF00)>>8;
   
   [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%X",lo]];
   [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%X",hi]];
   
   
   fprintf(stderr,"Adresse: \t%d\t%d\n",lo,hi);
   
   
   
   [codeArray addObject:[NSString stringWithFormat:@"%d",lo]]; // LO von Startadresse
   [codeArray addObject:[NSString stringWithFormat:@"%d",hi]]; // HI von Startadresse
   
   int EE_Data = [EE_DataFeld intValue];
   
   NSLog(@"reportWrite_1_EEPROM Data: %X",EE_Data);
   lo = EE_Data & 0x00FF;
   
   hi = (EE_Data & 0xFF00)>>8;
   
   [EE_datahi setStringValue:[NSString stringWithFormat:@"%X",hi]];
   [EE_datalo setStringValue:[NSString stringWithFormat:@"%X",lo]];
   
   
   fprintf(stderr,"Data: \t%d\t%d\n",lo,hi);
   
   [codeArray addObject:[NSString stringWithFormat:@"%d",lo]]; // LO von Data
   [codeArray addObject:[NSString stringWithFormat:@"%d",hi]]; // HI von Data
   
   [USB_DatenArray addObject:codeArray];
   [self write_EEPROM];
   [self USB_Aktion:NULL]; // Antwort lesen
   
   EE_Startadresse++;
   [EE_StartadresseFeld setIntValue:EE_Startadresse];
   lo = EE_Startadresse & 0x00FF;
   hi = (EE_Startadresse & 0xFF00)>>8;
   
   [EE_startadresselo setStringValue:[NSString stringWithFormat:@"%02X",lo]];
   [EE_startadressehi setStringValue:[NSString stringWithFormat:@"%02X",hi]];
   
   
   //[self USB_Aktion:NULL]; // Antwort lesen
   
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
   NSLog(@"reportHalt state: %",[sender state]);

   int code = ![sender state];
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

- (IBAction)reportReadRead_Part:(id)sender
{
   [EE_taskmark setBackgroundColor:[NSColor redColor]];
   [EE_taskmark setStringValue:@" "];

   
}

- (IBAction)reportWrite_Part:(id)sender
{
   usbtask = EEPROM_WRITE_TASK;
   [EE_taskmark setBackgroundColor:[NSColor redColor]];
   [EE_taskmark setStringValue:@" "];
   
   
   // ******************************************************************************************
   // Daten berechnen in awake
   // ******************************************************************************************

   // ******************************************************************************************
   // Erster Abschnitt enthält code
   // ******************************************************************************************
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
   
   fprintf(stderr,"Adresse: \t%d\t%d\n",lo,hi);
   
 
   [self send_EEPROMPartMitStufe:3 anAdresse:(lo & 0x00FF) | (hi & 0xFF00)>>8];

}

- (void)send_EEPROMPartMitStufe:(int)stufe anAdresse:(int)startadresse
{
   
   //EEPROMposition++;
   char*      sendbufferLO = malloc(PAGESIZE);
   char*      sendbufferHI = malloc(PAGESIZE);
   uint8_t*    partbuffer = malloc(EE_PARTBREITE);
   
   uint8_t*      sendbuffer;
   sendbuffer=malloc(USB_DATENBREITE);
   NSScanner* theScanner;
   unsigned	  value;
   
   int eepromchecksumme=0;
   int bytechecksumme=0;
   {
     // int startposition = EEPROMpage * PAGESIZE;
      for (int pos = 0;pos < EE_PARTBREITE;pos++)
      {
         
         if (pos % 2) // ungerade, wert fuer lo
         {
            //Wert an Stelle (pos + startposition) in ExpoDatenArray
            int lo = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:1]objectAtIndex:(pos + startadresse)]intValue];
            sendbufferLO[pos] = lo;
            partbuffer[pos] = lo;
            bytechecksumme += lo;
            
         }
         else
         {
            int hi = [[[[ExpoDatenArray objectAtIndex:stufe]objectAtIndex:0]objectAtIndex:(pos + startadresse)]intValue];
            sendbufferHI[pos] = hi;
            partbuffer[pos] = hi;
            bytechecksumme +=hi;
         }
         
         
      }
      fprintf(stderr,"\n");

      fprintf(stderr,"send_EEPROMPartAnAdresse %d eepromchecksumme: %d bytechecksumme1: %d\n", startadresse, eepromchecksumme,bytechecksumme);
      bytechecksumme=0;
      for (int pos = 0;pos < EE_PARTBREITE;pos++)
      {
         //int wert = partbuffer[pos+1];
         //wert <<= 8;
         //wert += partbuffer[pos];
         //fprintf(stderr,"| \t%2d\t%d\t* \tw: %d *\t\n",lo,hi,wert);
         fprintf(stderr,"%x\t",partbuffer[pos]);
         bytechecksumme+= partbuffer[pos];
      }
      fprintf(stderr,"\n");
      fprintf(stderr,"send_EEPROMPartAnAdresse %d eepromchecksumme: %d bytechecksumme2: %d\n", startadresse, eepromchecksumme,bytechecksumme);
 
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
   sendbuffer[1] = startadresse & 0x00FF;
   sendbuffer[2] = (startadresse & 0xFF00)>>8;
   
   
   fprintf(stderr,"send_EEPROMPART sendbuffer\n");
   
   
   eepromchecksumme=0;
   for (int k=EE_PARTBREITE;k<USB_DATENBREITE;k+=2) // 32 16Bit-Werte
   {
      int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
      
      fprintf(stderr,"%d\t",wert);
      eepromchecksumme+= wert;
      bytechecksumme+= (uint8)sendbuffer[k];
      bytechecksumme+= (uint8)sendbuffer[k+1];
   }

fprintf(stderr,"\neepromchecksumme : %d bytechecksumme3: %d\n",eepromchecksumme,bytechecksumme);
   sendbuffer[3] = bytechecksumme & 0x00FF;
   sendbuffer[4] = (bytechecksumme & 0xFF00)>>8;
   for (int k=0;k<USB_DATENBREITE;k++) // 32 16Bit-Werte
   {
      if (k==EE_PARTBREITE)
      {
         fprintf(stderr,"\n");
      }
      else if (k && k%(EE_PARTBREITE/2)==0)
      {
         fprintf(stderr,"|\t");
      }
      fprintf(stderr,"%02X\t",(uint8)sendbuffer[k]);
      
      //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
      //fprintf(stderr,"%d\t",wert);
   }// for i
   
   fprintf(stderr,"\n");
   
   fprintf(stderr,"send3: %d send4: %d\n",sendbuffer[3],sendbuffer[4]);
   fprintf(stderr,"send3: %02X send4: %02X\n",sendbuffer[3],sendbuffer[4]);

  
   
   int senderfolg= rawhid_send(0, sendbuffer, 64, 50);
   
   NSLog(@"send_EEPROMPART erfolg: %d Dataposition: %d",senderfolg,Dataposition);

 free (partbuffer);
   free(sendbuffer);
}


- (void)write_EEPROM
{
   NSLog(@"write_EEPROM");
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
//      NSLog(@"code raw result: %d dataRead: %X",result,(UInt8)buffer[0] );
      // start
      
      // end

      
      //  ---------------------------------------
      switch (usbtask)
      {
         //NSLog(@"result: %d dataRead: %@",result,[dataRead description]);
            
         case EEPROM_WRITE_TASK:
         case EEPROM_READ_TASK:
         case EEPROM_AUSGABE_TASK:
         default:
         {
            UInt8 code = (UInt8)buffer[0];
            //NSLog(@"code raw result: %d dataRead: %X",result,code );
            if (code)
            {
               
               
               switch (code)
               {
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
                        
                     }
                     
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
                     
                  case 0xCB:
                  {
                     
                     fprintf(stderr,"* echo CB in Ladefunktion: Fehler: %d\n",(uint8_t)buffer[3]);
                     [EE_taskmark setStringValue:@"OK"];
                     [EE_taskmark setBackgroundColor:[NSColor greenColor]];
                     for (int k=0;k<USB_DATENBREITE;k++) //
                     {
                        if (k==EE_PARTBREITE)
                        {
                           fprintf(stderr,"\n");
                        }
                        else if (k && k%(EE_PARTBREITE/2)==0)
                        {
                           fprintf(stderr,"*\t");
                        }
                        
                        fprintf(stderr,"%02X\t",(uint8_t)buffer[k]);
                        //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
                        //fprintf(stderr,"%d\t",wert);
                     }
                     
                     
                     fprintf(stderr,"\n\n");
                     usbtask = 0;
                     
                  }break;
                     
                     
                  case 0xD5: // read EEPROM Byte
                  {
                     fprintf(stderr,"echo read EEPROM Byte data hex: %02X  dec: %d\n",buffer[3]& 0xFF,buffer[3]& 0xFF);
                     // buffer1 ist data
                     
                     for (int i=0;i<8;i++)
                     {
                        fprintf(stderr,"%X\t",(buffer[i]& 0xFF));
                        //fprintf(stderr," | ");
                     }
                     fprintf(stderr,"\n");
                     
                     
                     [EE_DataFeld setStringValue:[NSString stringWithFormat:@"%d",(UInt8)buffer[3]& 0xFF]];
                     [EE_datalo setIntValue:(UInt8)buffer[3]& 0x00FF];
                     
                     [EE_datalohex setStringValue:[NSString stringWithFormat:@"%02X",(UInt8)buffer[3]& 0x00FF]];
                     
                     
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
                           fprintf(stderr,"*\t");
                        }
                        
                        
                        fprintf(stderr,"%02X\t",(uint8)buffer[k]);
                        
                        //int wert = (uint8)sendbuffer[k] | ((uint8)sendbuffer[k+1]<<8);
                        //fprintf(stderr,"%d\t",wert);
                     }
                     fprintf(stderr,"\n");
                     usbtask = 0;
                  }break;
                     
                     
                     
                  case 0xEC:
                  {
                     
                     fprintf(stderr,"* echo default EC nach laden: \n");
                     
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
                     
                     
                     fprintf(stderr,"\n\n");
                     usbtask = 0;
                     
                  }break;
                     
                     
                  case 0xF0:
                  {
                     int adc0L = (UInt8)buffer[18];// LO
                     int adc0H = (UInt8)buffer[19];// HI
                     int adc0 = adc0L | (adc0H<<8);
                     
                     //NSLog(@"adc0L: %d adc0H: %d adc0: %d",adc0L,adc0H,adc0);
                     if (adc0L)
                     {
                        [ADC_DataFeld setIntValue:adc0];
                        [ADC_Level setIntValue:adc0];
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
                     }
                     if (pot0L && pot1L)
                     {
                        //fprintf(stderr,"\t%d\t%d\n",pot0,pot1);
                     }
                     
                  }break;
                     
                     // end default
                     
               }// switch code
               
               
               
            } // if code EEPROM_WRITE_TASK
            
         }break;
   // ---------------------------------------------------- case TASKS Sammlung
/*
          default:
         {
            UInt8 code = (UInt8)buffer[0];
            switch (code)
           {

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
                 fprintf(stderr,"\n");
                 usbtask = 0;
              }break;

                 

              case 0xEC:
              {
                 
                 fprintf(stderr,"* echo default EC nach laden: \n");
                 
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
                 
                 
                 fprintf(stderr,"\n\n");
                 usbtask = 0;
                 
              }break;

              
              case 0xF0:
              {
                 int adc0L = (UInt8)buffer[18];// LO
                 int adc0H = (UInt8)buffer[19];// HI
                 int adc0 = adc0L | (adc0H<<8);
                 
                 //NSLog(@"adc0L: %d adc0H: %d adc0: %d",adc0L,adc0H,adc0);
                 if (adc0L)
                 {
                    [ADC_DataFeld setIntValue:adc0];
                    [ADC_Level setIntValue:adc0];
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
                 }
                 if (pot0L && pot1L)
                 {
                    //fprintf(stderr,"\t%d\t%d\n",pot0,pot1);
                 }

              }break;
                 
 
            } // switch code
            
  
         } // case default
   */         
            
      
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
   
   EEPROMposition = 0;
   
   //int aa=(15625& 0x00FF)>>8;
   //int bb = 15625& 0x00FF;
   //NSLog(@"aa: %d bb: %d",aa,bb);
	
   Math = [[rMath alloc]init];
   ChecksummenArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
   checksumme=0;
   ExpoDatenArray = [[NSMutableArray alloc]initWithCapacity:0];
   
   [self loadExpoDatenArray];
                     
   
   /*
    Daten fuer EXPO-Verlauf berechnen
    expoArrayMitStufe ergibt 2 Array mit lo, hi von uint8 zu den Werten von Stufe
    Uebertragen in EEPROM:
      
    
    */
   /*
   
   
   
   for (int stufe=0;stufe<4;stufe++)
   {
      
      NSArray* dataArray = [Math expoArrayMitStufe:stufe];
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
   */
   //[self send_EEPROMpage:0];
   
   
   
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
   
   ChecksummenArray = [[[NSMutableArray alloc]initWithCapacity:0]retain];
   checksumme=0;

   [self startRead];
   
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

@end
