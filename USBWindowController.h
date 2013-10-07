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

#import "rMath.h"

#import "hid.h"

#include <IOKit/hid/IOHIDDevicePlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#define maxLength 32

#define USBATTACHED           5
#define USBREMOVED            6


#define PAGESIZE              64

#define EE_PAGESIZE           64


#define EEPROM_WRITE_TASK     1
#define EEPROM_READ_TASK     2




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

@interface USBWindowController : NSWindowController <NSApplicationDelegate>
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
   
   IBOutlet    NSLevelIndicator*			ADC_Level;
   
   IBOutlet    NSLevelIndicator*			Pot0_Level;
   IBOutlet    NSSlider*            Pot0_Slider;
   IBOutlet    NSTextField*			Pot0_DataFeld;
   
   IBOutlet    NSLevelIndicator*			Pot1_Level;
   IBOutlet    NSSlider*            Pot1_Slider;
   IBOutlet    NSTextField*			Pot1_DataFeld;

   
   
    NSData*								lastValueRead; /*" The last value read"*/
    NSData*								lastDataRead; /*" The last value read"*/
	 
	rMath*                           Math;
    	

//	rADWandler*			ADWandler;
	NSMutableArray*	EinkanalDaten;
	NSDate*				DatenleseZeit;
	
   IBOutlet id			FileMenu;
	//rAVR*					AVR;
	IBOutlet id			ProfilMenu;
	
	// SPI
	int					Teiler;
	
	// TWI
	IBOutlet    id      InitI2CTaste;
	
	
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
  
   int               usbstatus; // was tun
   int               usbtask; // welche Task ist aktuell
   
   // RC
   
   NSMutableArray*   ExpoDatenArray;     // Daten fuer EEPROM mit exponentialkurven
	NSMutableArray*	USB_EEPROMArray;
	int					EEPROMposition;
   
   int lastdata0;
   int lastdata1;

   
   IBOutlet rVertikalanzeige* Vertikalbalken;
   
   IBOutlet id       Taskwahl;
   IBOutlet id       EE_StartadresseFeld;
   IBOutlet id       EE_startadresselo;
   IBOutlet id       EE_startadressehi;
   IBOutlet id       EE_DataFeld;
   IBOutlet id       EE_datalo;
   IBOutlet id       EE_datahi;
   IBOutlet id       EE_datalohex;
   IBOutlet id       EE_datahihex;

}




- (IBAction)showADWandler:(id)sender;
- (void)readPList;
- (IBAction)terminate:(id)sender;
- (void) setLastValueRead:(NSData*) inData;
- (int)USBOpen;


- (IBAction)reportReadUSB:(id)sender;
- (IBAction)reportWriteUSB:(id)sender;

- (IBAction)reportWriteEEPROM:(id)sender;
- (IBAction)reportWrite_1_EEPROM:(id)sender;
- (IBAction)reportRead_1_EEPROM:(id)sender;
- (IBAction)reportHalt:(id)sender;

- (void)sendTask:(int)status;

- (void)USB_Aktion:(NSNotification*)note;
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