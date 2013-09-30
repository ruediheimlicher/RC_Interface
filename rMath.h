/* rMath */

#import <Cocoa/Cocoa.h>

#define VEKTORSIZE 0x10
#define STARTWERT   0x800
#define ENDWERT     0x1000
#define SCHRITTWEITE 0x40

@interface rMath : NSObject
{
   
}

/*
Array mit DataArrays von je 2 Vektoren von 32 byte laenge mit 16-bit-Wert
*/
- (NSArray*)expoArrayMitStufe:(int) stufe;


@end
