/* rMath */

#import <Cocoa/Cocoa.h>

#define VEKTORSIZE 0x200
#define STARTWERT   0x400
#define ENDWERT     0x800
#define SCHRITTWEITE 0x20

@interface rMath : NSObject
{
   
}

/*
Array mit DataArrays von je 2 Vektoren von 32 byte laenge mit 16-bit-Wert
*/
- (NSArray*)expoArrayMitStufe:(int) stufe;


@end
