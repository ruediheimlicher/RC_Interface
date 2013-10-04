#import "rMath.h"




@implementation rMath

- (id) init
{
   if (self = [ super init])
       {
          return self;
       }
   return NULL;
}

- (NSArray*)expoArrayMitStufe:(int)stufe
{
   NSMutableArray* arrayLO = [[NSMutableArray alloc]initWithCapacity:0];
   NSMutableArray* arrayHI = [[NSMutableArray alloc]initWithCapacity:0];
   
   float exparr[ENDWERT-STARTWERT];
    float wertarray[ENDWERT-STARTWERT];
   int intwertarray[ENDWERT-STARTWERT];

   float maxwert = 0;
   for (int i=0;i<VEKTORSIZE;i++)
   {
      if (stufe)
      {
         float delta = stufe *1.0/4;
      float position = STARTWERT + i*SCHRITTWEITE;
      float exponent = delta*position/1000;
      float wert = exp(exponent);
      //float maxwert = wert;
      exparr[i]= wert;
      }
      else
      {
         exparr[i] = STARTWERT + (ENDWERT - STARTWERT)/VEKTORSIZE*i;
      }
     // fprintf(stderr,"%2.0f\t%2.8f\t%2.2f\n",position,exponent,wert);
     // float wert1 = pow(2.0,(stufe+0.2)*position/1000 );
      //float wert2 = pow(2.0,(stufe+0.4)*position/1000 );
      
      //fprintf(stderr,"%2.0f\t%2.2f\t%2.2f\t%2.2f\n",position,wert,wert1,wert2);
   }
   
   for (int i=0;i<VEKTORSIZE;i++)
   {
      //float wert = (exparr[i]-exparr[0])*1000 + STARTWERT;
      wertarray[i]=(exparr[i]-exparr[0])*1000 + STARTWERT;
      //fprintf(stderr,"%2d\t%2.2f\n",i,wert);
   }

   maxwert=wertarray[VEKTORSIZE-1];
   //fprintf(stderr,"maxwert: %2.2f\n",maxwert);
   for (int i=0;i<VEKTORSIZE;i++)
   {
      float wert = STARTWERT + (wertarray[i]-STARTWERT)/(maxwert - STARTWERT) * (ENDWERT - STARTWERT) ;
     intwertarray[i]= round(wert);
      int intwert = round(wert);
     // if (i<8)
      {
       //  fprintf(stderr,"%2d\t%2.2f\n",i,wert);
      }
      
      [arrayLO addObject:[NSNumber numberWithInt:(intwert & 0xFF)]];
      [arrayHI addObject:[NSNumber numberWithInt:(intwert >>8)]];
  
   }

   
   return [NSArray arrayWithObjects:arrayLO,arrayHI, nil];
}


@end
