/* rMath */

#import <Cocoa/Cocoa.h>

#define VEKTORSIZE 0x400  // Anzahl Werte: 1024
#define STARTWERT   0x2000  // Startwert: 2048
#define ENDWERT     0x4000 // Endwert: 4096
#define SCHRITTWEITE 0x20
#define DELTA  1.0/32 // Auffächerung. je kleiner desto enger

#define FAKTOR 0x400

@interface rMath : NSObject
{
   
}

/*
Array mit DataArrays von je 2 Vektoren von 32 byte laenge mit 16-bit-Wert
*/
- (NSArray*)expoArrayMitStufe:(int) stufe;
- (NSArray*)expoDatenArrayMitStufe:(int)stufe;


@end
