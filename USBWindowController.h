/* USBWindowController */

#import <Cocoa/Cocoa.h>

#include <stdio.h>
#include <stdlib.h>

//#import "rHexEingabe.h"
//#import "rADWandler.h"
//#import "rAVR.h"
//#import "rDump_DS.h"
//#import "rUtils.h"

#import "rVertikalanzeige.h"
#import "rDataDiagramm.h"
#import "rOrdinate.h"
#import "rDiagrammGitterlinien.h"

#import "rDefinitionen.h"

#import "rMath.h"

#import "hid.h"

#include <IOKit/hid/IOHIDDevicePlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#define maxLength 32

#define USBATTACHED           5
#define USBREMOVED            6


#define PAGESIZE              32

#define USB_DATENBREITE           64

#define EE_PARTBREITE           32


#define EEPROM_WRITE_TASK     1
#define EEPROM_READ_TASK     2
#define EEPROM_AUSGABE_TASK   5


#define EEPROM_WRITE_BUSY_BIT 0
#define EEPROM_WRITE_OK_BIT   1

#define TASK_OFFSET           0x2000 // Ort fuer Einstellungen


#define SETTINGBREITE         0x100; // 256 byte Breite des Settingblocks fuer ein model

#define MITTE_OFFSET          0x10 // 16, 16 byte (2 pro kanal)

#define  LEVEL_OFFSET         0x20 // 32, 8 byte
#define  EXPO_OFFSET          0x30 // 48, 8 byte


#define MIX_OFFSET            0x40 // 64, 8 byte (2 pro mixing)

#define FUNKTION_OFFSET    0x60 // 96
#define DEVICE_OFFSET      0x70 // 122
#define AUSGANG_OFFSET     0x80 // 128


#define MITTE_TASK            0x01 // Mitte lesen
#define KANAL_TASK            0x02 // Level und Expo lesen
#define MIX_TASK              0x03 // Mix lesen


 struct Abschnitt
 {
    uint8_t *data;//[maxLength];
    uint8_t num;
    uint8_t lage;
    
    struct Abschnitt * next;
    struct Abschnitt * prev;
 };
 
//#define NSLog(...) 0


// int rawhid_open(int max, int vid, int pid, int usage_page, int usage)
// extern int rawhid_recv( );

@interface USBWindowController : NSWindowController <NSApplicationDelegate, NSTableViewDataSource,NSTableViewDelegate, NSTabViewDelegate, NSComboBoxDataSource,NSComboBoxDelegate>
{
    BOOL									isReading;
	BOOL									isTracking;
    NSTimer*							readTimer;
    NSTimer*							trackTimer;

    BOOL                         ignoreDuplicates;
    int									anzDaten;
    NSMutableArray*					logEntries;
    NSMutableArray*					dumpTabelle;
    IBOutlet	NSTableView*		dumpTable;
	int									dumpCounter;
	//rDump_DS*							Dump_DS;
    IBOutlet	NSTableView*		logTable;
    IBOutlet	NSWindow*			window;
    IBOutlet	NSPopUpButton*		macroPopup;
    IBOutlet    NSButton*			readButton;
   
   
    
	 IBOutlet    NSPopUpButton*       AdressPop;
   
   
   IBOutlet    NSButton*            readUSB;
   IBOutlet    NSTextField*			USB_DataFeld;
   IBOutlet    NSTextField*			rundeFeld;
   
   IBOutlet    NSTextField*			ADC_DataFeld;
   
   IBOutlet    NSLevelIndicator*		ADC_Level;
   
   IBOutlet    NSLevelIndicator*		Pot0_Level;
   IBOutlet    NSSlider*            Pot0_Slider;
   IBOutlet    NSTextField*			Pot0_DataFeld;
   
   IBOutlet    NSLevelIndicator*		Pot1_Level;
   IBOutlet    NSSlider*            Pot1_Slider;
   IBOutlet    NSTextField*			Pot1_DataFeld;

   IBOutlet    NSSlider*            Pot0_SliderInt;
   IBOutlet    NSSlider*            Pot1_SliderInt;

   
   
    NSData*                         lastValueRead; /*" The last value read"*/
    NSData*                         lastDataRead; /*" The last value read"*/
	 
	rMath*                           Math;
    	

//	rADWandler*			ADWandler;
	NSMutableArray*	EinkanalDaten;
	NSDate*				DatenleseZeit;
	
   IBOutlet id			FileMenu;
	//rAVR*					AVR;
	IBOutlet id			ProfilMenu;
	
	// SPI
	int					Teiler;
	
   IBOutlet id       Halt_Taste;

   IBOutlet id       Write_1_Byte_Taste;
   IBOutlet id       Read_1_Byte_Taste;
   IBOutlet id       Write_Part_Taste;
   IBOutlet id       Read_Part_Taste;
   
   IBOutlet id       Write_Stufe_Taste;
   IBOutlet id       StufeFeld;
   IBOutlet id       PartnummerFeld;
   
    IBOutlet id       PPMFeldA;
    IBOutlet id       PPMFeldB;
   
   NSTimer* EE_WriteTimer;
	
	// CNC
	NSMutableArray*	USB_DatenArray;
	int					Dataposition;
	
	int					schliessencounter;
	int					haltFlag;
   int               mausistdown;
   int               anzrepeat;
   int               pfeilaktion;
   int               HALTStatus;
    int              USBStatus;
   int               pwm;
   int               halt;
   NSMutableIndexSet* HomeAnschlagSet;
   char*             newsendbuffer;
   
   int               eepromwritestatus; // was tun
  
   int               usbstatus; // was tun
   int               usbtask; // welche Task ist aktuell
    
   // RC
   
   NSMutableArray*   ExpoDatenArray;     // Daten fuer EEPROM mit exponentialkurven, Werte in zwei Arrays lo, hi
   
   NSMutableArray* DiagrammExpoDatenArray; // Daten fuer EEPROM nach stufe
   
   NSMutableArray* EEDatenArray;// Daten fuer EEPROM mit exponentialkurven linear
   
	NSMutableArray*	USB_EEPROMArray;
	int					EEPROMposition;
   
   int lastdata0;
   int lastdata1;
   
   int checksumme;
   NSMutableArray*	ChecksummenArray;

   
   IBOutlet rVertikalanzeige* Vertikalbalken;
   
   IBOutlet id       Taskwahl;
   IBOutlet id       EE_StartadresseFeld;
   IBOutlet id       EE_StartadresseFeldHexLO;
   IBOutlet id       EE_StartadresseFeldHexHI;
   IBOutlet id       EE_startadresselo;
   IBOutlet id       EE_startadressehi;
   IBOutlet id       EE_DataFeld;
   IBOutlet id       EE_datalo;
   IBOutlet id       EE_datahi;
   IBOutlet id       EE_datalohex;
   IBOutlet id       EE_datahihex;
   IBOutlet id       EE_databin;
   IBOutlet id      EE_dataview;
   IBOutlet id      PPM_testdatafeld;
   
   IBOutlet id      readsetting_mark;
   IBOutlet id      readsender_mark;
   IBOutlet id      readfunktion_mark;
   IBOutlet id      refreshmaster_mark;

   
   IBOutlet id       AdresseIncrement;
   
   IBOutlet id                EE_taskmark;
   
   IBOutlet id                DatadiagrammFeld;
   
   IBOutlet rDataDiagramm*    Datadiagramm;
   rOrdinate*                 DataOrdinate;
   rDiagrammGitterlinien*     Gitterlinien;

   /*
    // Funktion
    
    const char funktion0[] PROGMEM = "Seite \0";
    const char funktion1[] PROGMEM = "Hoehe \0";
    const char funktion2[] PROGMEM = "Quer   \0";
    const char funktion3[] PROGMEM = "Motor \0";
    const char funktion4[] PROGMEM = "Quer L\0";
    const char funktion5[] PROGMEM = "Quer R\0";
    const char funktion6[] PROGMEM = "Lande \0";
    const char funktion7[] PROGMEM = "Aux    \0";

    */
   
   NSArray*   default_FunktionArray;//
   NSArray*   default_DeviceArray;//
   NSArray*   default_AusgangArray;//
   
   
   
   // Einstellungen
   NSMutableArray*   ModelArray;//
   NSMutableArray*   SettingArray;//
   IBOutlet id      SettingTab;
   IBOutlet id      KanalTable;
   IBOutlet id      ExpoTabel;
   IBOutlet id      FixSettingTaste;
   IBOutlet id      FixMixingTaste;
   IBOutlet id      FixFunktionTaste;

   IBOutlet id      ReadSettingTaste;
   IBOutlet id      ReadSenderTaste;
   IBOutlet id      ReadFunktionTaste;
   
   IBOutlet id      ModelFeld;
   IBOutlet id      SetFeld;
   
   IBOutlet id      MasterRefreshTaste;

   
   NSMutableArray*   MixingArray;//
   IBOutlet id      MixingTab;
   IBOutlet id      MixingTable;

   NSMutableArray*   DispatchArray;//
   IBOutlet id      DispatchTab;
   IBOutlet id      DispatchTable;

   NSMutableArray*   FunktionArray;//
   IBOutlet id      FunktionTab;
   IBOutlet id      FunktionTable;
   
   NSMutableArray*   AusgangArray;//
   IBOutlet id      AusgangTab;
   IBOutlet id      AusgangTable;
   
   
   rDefinitionen* Definitionen;
   
   
  
}




- (IBAction)showADWandler:(id)sender;
- (void)readPList;
- (IBAction)terminate:(id)sender;
- (void) setLastValueRead:(NSData*) inData;
- (int)USBOpen;


- (IBAction)reportReadUSB:(id)sender;
- (IBAction)reportWriteUSB:(id)sender;
- (void)loadExpoDatenArray;
- (IBAction)reportWriteEEPROM:(id)sender;

- (IBAction)reportWrite_1_Byte:(id)sender;

- (IBAction)reportWrite_1_Line:(id)sender;
- (IBAction)reportWrite_Part:(id)sender;
- (IBAction)reportWrite_Stufe:(id)sender;

- (IBAction)reportRead_1_Byte:(id)sender;
- (IBAction)reportRead_Part:(id)sender;

- (IBAction)reportFix_KanalSettings:(id)sender;

- (IBAction)reportRefresh_Master:(id)sender;
- (void)setHalt:(int)status;
- (IBAction)reportHalt:(id)sender;

- (void)sendTask:(int)status;

- (void)USB_Aktion:(NSNotification*)note;

- (void)send_EEPROMPartMitStufe:(int)stufe anAdresse:(int)startadresse;










- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex;


@end


@interface USBWindowController(rADWandlerController)
//- (id)initWithFrame:(NSRect)frame;
- (IBAction)showADWandler:(id)sender;
- (IBAction)saveMehrkanalDaten:(id)sender;
@end



#pragma mark AVRController
@interface USBWindowController(rAVRController)
- (IBAction)showAVR:(id)sender;
- (IBAction)openProfil:(id)sender;
//- (int)USBOpen;
- (void)writeCNCAbschnitt;
- (void)Reset;
- (void)StartTWI;
- (void)initList;
- (void)StepperstromEinschalten:(int)ein;
//- (IBAction)print:(id)sender;
@end