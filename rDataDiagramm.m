#import "rDataDiagramm.h"

/*
 
Funktion zur Umwandlung einer vorzeichenbehafteten 32 Bit Zahl in einen String
 
*/
 
void r_itoa(int32_t zahl, char* string) 
{
  uint8_t i;
 
  string[11]='\0';                  // String Terminator
  if( zahl < 0 ) {                  // ist die Zahl negativ?
    string[0] = '-';              
    zahl = -zahl;
  }
  else string[0] = ' ';             // Zahl ist positiv
 
  for(i=10; i>=1; i--) {
    string[i]=(zahl % 10) +'0';     // Modulo rechnen, dann den ASCII-Code von '0' addieren
    zahl /= 10;
  }
}

@implementation rDataDiagramm
- (void) logRect:(NSRect)r
{
	NSLog(@"logRect: origin.x %2.2f origin.y %2.2f size.heigt %2.2f size.width %2.2f",r.origin.x, r.origin.y, r.size.height, r.size.width);
}


- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) 
	{
		// Add initialization code here
		NSRect Diagrammfeld=frameRect;
		//		Diagrammfeld.size.width+=400;
		[self setFrame:Diagrammfeld];
		
		OffsetY=0.0;
      FaktorX=1.0;
      FaktorY=1.0;
		StartwertX=1.0;
      GrundlinienOffset=5;
      OrdinatenOffset = 2;
      Darstellungsoption=0; // keine Datenbeschriftung, in drawRect abgefragt
      DiagrammEcke=NSMakePoint(OrdinatenOffset,GrundlinienOffset);
      
      MaxOrdinate=[self frame].size.height-15;
      MaxAbszisse=[self frame].size.width-15;
		FaktorY=(frameRect.size.height-15.0)/255.0; // Reduktion auf Feldhoehe
		//NSLog(@"DataDiagramm Diagrammfeldhoehe: %2.2f Faktor: %2.2f",(frameRect.size.height-15),FaktorY);
      
      
      Graph=[NSBezierPath bezierPath];
		[Graph retain];
		[Graph moveToPoint:DiagrammEcke];
		lastPunkt=DiagrammEcke;
		GraphFarbe=[NSColor blueColor];

      GraphArray=[[[NSMutableArray alloc]initWithCapacity:0]autorelease];
		[GraphArray retain];
		GraphFarbeArray=[[[NSMutableArray alloc]initWithCapacity:0]autorelease];
		[GraphFarbeArray retain];
		GraphKanalArray=[[[NSMutableArray alloc]initWithCapacity:0]autorelease];
		[GraphKanalArray retain];
		GraphKanalOptionenArray=[[[NSMutableArray alloc]initWithCapacity:0]autorelease];
		[GraphKanalOptionenArray retain];
	
		DatenArray=[[[NSMutableArray alloc]initWithCapacity:0]autorelease];
		[DatenArray retain];
		
		// Feld fuer die Wertangabe am Ende der Datenlinie
		DatenFeldArray=[[[NSMutableArray alloc]initWithCapacity:0]autorelease];
		[DatenFeldArray retain];
		DatenWertArray=[[[NSMutableArray alloc]initWithCapacity:0]autorelease];
		[DatenWertArray retain];
		
		// Bezeichnung der Daten des Kanals
		DatenTitelArray=[[[NSMutableArray alloc]initWithCapacity:0]autorelease];
		[DatenTitelArray retain];
		int i;
		
		
		for (i=0;i<8;i++)
		{
			NSBezierPath* tempGraph=[NSBezierPath bezierPath];
         
			[tempGraph retain];
         [tempGraph setLineWidth:1.5];
			float varRed=sin(i+(float)i/10.0)/3.0+0.6;
			float varGreen=sin(2*i+(float)i/10.0)/3.0+0.6;
			float varBlue=sin(3*i+(float)i/10.0)/3.0+0.6;
			//NSLog(@"sinus: %2.2f",varRed);
			NSColor* tempColor=[NSColor colorWithCalibratedRed:varRed green: varGreen blue: varBlue alpha:1.0];
			//NSLog(@"Farbe Kanal: %d Color: %@",i,[tempColor description]);
			tempColor=[NSColor blackColor];
			[tempColor retain];
			[GraphFarbeArray addObject:tempColor];
			[GraphArray addObject:tempGraph];
			//[GraphKanalArray addObject:[NSMutableDictionary alloc]initWithCapacity:0]];
			[GraphKanalArray addObject:[NSNumber numberWithInt:0]];
			[DatenArray addObject:[[NSMutableArray alloc]initWithCapacity:0]];
			NSRect tempRect=NSMakeRect(0,0,25,16);
			NSTextField* tempDatenFeld=[[NSTextField alloc]initWithFrame:tempRect];
			NSFont* DatenFont=[NSFont fontWithName:@"Helvetica" size: 9];

			[tempDatenFeld setEditable:NO];
			[tempDatenFeld setSelectable:NO];
			[tempDatenFeld setStringValue:@""];
			[tempDatenFeld setFont:DatenFont];
			[tempDatenFeld setAlignment:NSLeftTextAlignment];
			[tempDatenFeld setBordered:NO];
			[tempDatenFeld setDrawsBackground:NO];
			[self addSubview:tempDatenFeld];
			[DatenFeldArray addObject:tempDatenFeld];
         
         tempRect.origin.x += 1;
 			NSTextField* tempWertFeld=[[NSTextField alloc]initWithFrame:tempRect];
         
			[tempWertFeld setEditable:NO];
			[tempWertFeld setSelectable:NO];
			[tempWertFeld setStringValue:@""];
			[tempWertFeld setFont:DatenFont];
			[tempWertFeld setAlignment:NSRightTextAlignment];
			[tempWertFeld setBordered:NO];
			[tempWertFeld setDrawsBackground:NO];
			[self addSubview:tempWertFeld];
			[DatenWertArray addObject:tempWertFeld];
        
         
         
         
         
			[DatenTitelArray addObject:@""];
			// Bezeichnungen in Subklasse aendern
		}//for i
		
		//NSLog(@"Farbe Kanal:  ColorArray: %@",[GraphFarbeArray description]);
		MinorTeileY=2;
		MajorTeileY=4;
		MaxY=2.0;
		
		MinY=-2.0;
		NullpunktY=0.0;

		MinorTeileX=2;
		MajorTeileX=4;
		MaxX=2.0;
		
		MinX=-2.0;
		NullpunktX=0.0;
		
      
      ZeitKompression=1.0;
      
 		MaxOrdinate= frameRect.size.height-20;
		
      [self setGitterLinien];
		NSNotificationCenter * nc;
		nc=[NSNotificationCenter defaultCenter];
		[nc addObserver:self
		   selector:@selector(StartAktion:)
			   name:@"data"
			 object:nil];

	}
	return self;
}

- (void)setTag:(int)derTag
{
	Tag= derTag;
}

- (void)setOrdinate:(id)dieOrdinate
{
	Ordinate=dieOrdinate;
	[Ordinate retain];
   //[self addSubview:Ordinate];
}

- (void)setGraphFarbe:(NSColor*) dieFarbe forKanal:(int) derKanal
{
	[GraphFarbeArray replaceObjectAtIndex:derKanal withObject:dieFarbe];
}

- (void)setStartZeit:(NSCalendarDate*)dasDatum
{
DatenserieStartZeit = dasDatum;
[dasDatum retain];
[DatenserieStartZeit release];

}


- (void)StartAktion:(NSNotification*)note
{
	//NSLog(@"StartAktion note: %@",[[note userInfo]description]);
	if ([[note userInfo]objectForKey:@"datenseriestartzeit"])
	{
		DatenserieStartZeit= (NSCalendarDate*)[[note userInfo]objectForKey:@"datenseriestartzeit"];
		[DatenserieStartZeit retain];
		//NSLog(@"MehrkanalDiagramm DatenserieStartZeit %@",DatenserieStartZeit);
		
	}

}

- (void)setDiagrammlageY:(float)DiagrammlageY // Lage im SuperView
{
	float x=[self frame].origin.x;
	[self setFrameOrigin:NSMakePoint(x,DiagrammlageY)];
	
}

- (void)setEinheitenDicY:(NSDictionary*)derEinheitenDic
{
	//NSLog(@"setEinheitenDicY: %@",[derEinheitenDic description]);
	if ([derEinheitenDic objectForKey:@"einheit"])
	{
		Einheit=[derEinheitenDic objectForKey:@"einheit"];
	}
   

	
	if ([derEinheitenDic objectForKey:@"majorteile"])
	{
		MajorTeileY=[[derEinheitenDic objectForKey:@"majorteile"]intValue];
	}
	if ([derEinheitenDic objectForKey:@"minorteile"])
	{
		MinorTeileY=[[derEinheitenDic objectForKey:@"minorteile"]intValue];
	}
	if ([derEinheitenDic objectForKey:@"maxy"])
	{
		MaxY=[[derEinheitenDic objectForKey:@"maxy"]floatValue];
	}
	if ([derEinheitenDic objectForKey:@"miny"])
	{
		MinY=[[derEinheitenDic objectForKey:@"miny"]floatValue];
	}
	if ([derEinheitenDic objectForKey:@"nullpunkt"])
	{
		NullpunktY=[[derEinheitenDic objectForKey:@"nullpunkt"]intValue];
		
		//NSLog(@"EinheitenDicY %d  NullpunktY: %d",[[derEinheitenDic objectForKey:@"nullpunkt"]intValue],NullpunktY);
		
	}
	
	if ([derEinheitenDic objectForKey:@"zeitkompression"])
	{
		ZeitKompression=[[derEinheitenDic objectForKey:@"zeitkompression"]floatValue];
	//	[self setZeitKompression:[[derEinheitenDic objectForKey:@"zeitkompression"]floatValue]];
	
	}
	
	//if ([[[NSApp mainWindow] contentView] viewWithTag:Tag+1]) // Ordinate
	if (Ordinate)
	{
		NSLog(@"Ordinate da");
		[Ordinate setAchsenDic:derEinheitenDic];
		//[[[[NSApp window] contentView] viewWithTag:Tag+1]setAchsenDic:derEinheitenDic];
	}
	else
	{
		//NSLog(@"Ordinate nicht da");
	}
	
	
	
	[self setNeedsDisplay:YES];
	
}

- (void)setOffsetX:(float)x  // Startwert-Offset
{
StartwertX=x;
NSLog(@"setOffsetX: %2.2f",x);
}


- (void)setOffsetY:(float)y
{


}

- (float)GrundlinienOffset // Abstand der Grundlinie vom unteren Rand
{
	return GrundlinienOffset;
}

- (void)setGrundlinienOffset:(float)offset
{
	NSLog(@"Diagramm setGrundlinienOffset: %2.2f",offset);
	GrundlinienOffset=offset;
	DiagrammEcke.y += offset;
	lastPunkt=DiagrammEcke;
   
	
   NSRect r=[self frame];
	//r.size.height+=offset;
   //r.origin.y+=offset;

   
	[self setFrame:r];
   
   [self setGitterLinien];
   
   [Ordinate setGrundlinienOffset:offset];
	[Ordinate setNeedsDisplay:YES];

}

- (void)setMaxOrdinate:(int)laenge
{

	MaxOrdinate=laenge;
	NSLog(@"***   MKDigramm setMaxOrdinate: %2.2f",MaxOrdinate);

}

- (int)MaxOrdinate
{
return MaxOrdinate;
}

- (void)setMaxEingangswert:(int)maxEingang
{
	MaxEingangsWert=maxEingang;

}


- (void)setWert:(NSPoint)derWert  forKanal:(int)derKanal
{
NSLog(@"setWert Kanal: %d  x: %2.2f y: %2.2f ",derKanal, derWert.x, derWert.y);


}

- (void)setWertMitX:(float)x mitY:(float)y forKanal:(int)derKanal
{


}

- (void)setStartWerteArray:(NSArray*)Werte
{
	NSLog(@"setStartWerteArray: %@ ",[Werte description]);
	float x=DiagrammEcke.x;
	int i;
	for (i=0;i<[Werte count];i++)
	{
		float y=[[Werte objectAtIndex:i]floatValue];
		[[GraphArray objectAtIndex:i]moveToPoint:NSMakePoint(x,y)];
		
	}
}

- (void)setWerteArray:(NSArray*)derWerteArray mitKanalArray:(NSArray*)derKanalArray
{
	int i;
	int stop=0;
   if ([[derWerteArray objectAtIndex:0]intValue]==1984)
   {
      NSLog(@"setWerteArray WerteArray: %@",[derWerteArray description]);//,[derKanalArray description]);
      stop=1;
   }
	float	maxAnzeigewert=MaxY-MinY;
	//NSLog(@"setWerteArray: FaktorY: %2.2f MaxY; %2.2F MinY: %2.2F maxAnzeigewert: %2.2F AnzeigeFaktor: %2.2F",FaktorY,MaxY,MinY,maxAnzeigewert, AnzeigeFaktor);
	//NSLog(@"setWerteArray:SortenFaktor: %2.2f",SortenFaktor);

	for (i=0;i<[derWerteArray count]-1;i++) // erster Wert ist Abszisse
	{
		if ([[derKanalArray objectAtIndex:i]intValue])
		{
			//NSLog(@"+++			Temperatur  setWerteArray: Kanal: %d	x: %2.2f",i,[[derWerteArray objectAtIndex:0]floatValue]);
			NSPoint neuerPunkt=DiagrammEcke;
			neuerPunkt.x+=[[derWerteArray objectAtIndex:0]floatValue]*ZeitKompression;	//	Zeit, x-Wert, erster Wert im Array
			float InputZahl=[[derWerteArray objectAtIndex:i+1]floatValue];	// Input vom IOW, 0-255
			
			
			float graphZahl=(InputZahl-2*MinY)*FaktorY;								// Red auf reale Diagrammhoehe
			
			float rawWert=graphZahl*FaktorY;							// Wert fuer Anzeige des ganzen Bereichs
			
			float DiagrammWert=(rawWert);
			//NSLog(@"setWerteArray: Kanal: %d InputZahl: %2.2F graphZahl: %2.2F rawWert: %2.2F DiagrammWert: %2.2F",i,InputZahl,graphZahl,rawWert,DiagrammWert);

			neuerPunkt.y += DiagrammWert;
			//neuerPunkt.y=InputZahl;
			//NSLog(@"setWerteArray: Kanal: %d MinY: %2.2F FaktorY: %2.2f",i,MinY, FaktorY);

			//NSLog(@"setWerteArray: Kanal: %d InputZahl: %2.2F FaktorY: %2.2f graphZahl: %2.2F rawWert: %2.2F DiagrammWert: %2.2F ",i,InputZahl,FaktorY, graphZahl,rawWert,DiagrammWert);

			NSString* tempWertString=[NSString stringWithFormat:@"%2.1f",InputZahl/2.0];
			//NSLog(@"neuerPunkt.y: %2.2f tempWertString: %@",neuerPunkt.y,tempWertString);

			NSArray* tempDatenArray=[NSArray arrayWithObjects:[NSNumber numberWithFloat:neuerPunkt.x],[NSNumber numberWithFloat:neuerPunkt.y],tempWertString,nil];
			NSDictionary* tempWerteDic=[NSDictionary dictionaryWithObjects:tempDatenArray forKeys:[NSArray arrayWithObjects:@"x",@"y",@"wert",nil]];
			[[DatenArray objectAtIndex:i] addObject:tempWerteDic];
			
			NSBezierPath* neuerGraph=[NSBezierPath bezierPath];
			if ([[GraphArray objectAtIndex:i]isEmpty]) // Anfang
			{
				neuerPunkt.x=DiagrammEcke.x;
				[neuerGraph moveToPoint:neuerPunkt];
				[[GraphArray objectAtIndex:i]appendBezierPath:neuerGraph];
				
			}
			else
			{
				[neuerGraph moveToPoint:[[GraphArray objectAtIndex:i]currentPoint]];//last Point			
				[neuerGraph lineToPoint:neuerPunkt];
				[[GraphArray objectAtIndex:i]appendBezierPath:neuerGraph];
			}		
		}// if Kanal
	} // for i
	[derKanalArray retain];
   if (stop)
   {
      NSLog(@"AA");
   }
	[GraphKanalArray setArray:derKanalArray];
	//[GraphKanalArray retain];
//	[self setNeedsDisplay:YES];
}

- (void)setZeitKompression:(float)dieKompression
{
	float stretch = dieKompression/ZeitKompression;
	//NSLog(@"MKDiagramm setZeitKompression ZeitKompression: %2.2f dieKompression: %2.2f stretch: %2.2f",ZeitKompression,dieKompression,stretch);
	ZeitKompression=dieKompression;
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy: stretch yBy: 1.0];
	int i=0;
	if ([GraphArray count]==0)
	return;
	for (i=0;i<8;i++)
	{
		if ([GraphArray objectAtIndex:i])// && ![[GraphArray objectAtIndex:i] isEmpty])
		{
		//NSLog(@"i: %d GraphArray objectAtIndex:i: %@",i,[[GraphArray objectAtIndex:i] description]);
			if ( ![[GraphArray objectAtIndex:i] isEmpty])
			{
			[[GraphArray objectAtIndex:i] transformUsingAffineTransform: transform];
			[[GraphArray objectAtIndex:i]stroke];
			}
		}
		
	} // for i
	/*
	NSRect tempRect=[self frame];
	tempRect.size.width = tempRect.size.width * stretch;
	[self setFrame:tempRect];
	*/
	[self setNeedsDisplay:YES];
	
}

- (void)setVorgaben:(NSDictionary*)dieVorgaben
{
   FaktorX=1.0;
	if ([dieVorgaben objectForKey:@"faktorx"])
	{
		FaktorX=[[dieVorgaben objectForKey:@"faktorx"]floatValue];
	}
	FaktorY=1.0;
	if ([dieVorgaben objectForKey:@"faktory"])
	{
		FaktorY=[[dieVorgaben objectForKey:@"faktory"]floatValue];
	}
	OffsetY=0.0;
	if ([dieVorgaben objectForKey:@"offsety"])
	{
		OffsetY=[[dieVorgaben objectForKey:@"offsety"]floatValue];
	}
   
}


- (void)setWerteArray:(NSArray*)derWerteArray mitKanalArray:(NSArray*)derKanalArray mitVorgabenDic:(NSDictionary*)dieVorgaben
{
//	NSLog(@"setWerteArray: %@ KanalArray: %@ dieVorgaben: %@",[derWerteArray description],[derKanalArray description],[dieVorgaben description] );
	int i;
	if ([dieVorgaben objectForKey:@"faktorx"])
	{
		FaktorX=[[dieVorgaben objectForKey:@"faktorx"]floatValue];
	}
	if ([dieVorgaben objectForKey:@"faktory"])
	{
		FaktorY=[[dieVorgaben objectForKey:@"faktory"]floatValue];
	}
	if ([dieVorgaben objectForKey:@"offsety"])
	{
		OffsetY=[[dieVorgaben objectForKey:@"offsety"]floatValue];
	}
	//NSLog(@"setWerteArray: faktorX: %2.2f faktorY: %2.2f ",FaktorX,FaktorY);
	for (i=0;i<[derWerteArray count]-1;i++)
	{
		//NSLog(@"setWerteArray: Kanal: %d",i);
		NSPoint neuerPunkt=DiagrammEcke;
      //NSLog(@"setWerteArray: Kanal: %d x: %2.2f y: %2.2f",i,[[derWerteArray objectAtIndex:0]floatValue],[[derWerteArray objectAtIndex:i+1]floatValue]);

		neuerPunkt.x+=[[derWerteArray objectAtIndex:0]floatValue]*FaktorX;
		neuerPunkt.y+=([[derWerteArray objectAtIndex:i+1]floatValue]*FaktorY)+OffsetY;
		//NSLog(@"setWerteArray korr: Kanal: %d x: %2.2f y: %2.2f",i,neuerPunkt.x,neuerPunkt.y);

		NSBezierPath* neuerGraph=[NSBezierPath bezierPath];
      if ([[GraphArray objectAtIndex:i]isEmpty]) // Start, noch kein vorheriger 
      {
         [neuerGraph moveToPoint:neuerPunkt];
               }
      else
      {
         [neuerGraph moveToPoint:[[GraphArray objectAtIndex:i]currentPoint]];//last Point
         [neuerGraph lineToPoint:neuerPunkt];
      }
		
		[[GraphArray objectAtIndex:i]appendBezierPath:neuerGraph];
	}
	[derKanalArray retain];
	[GraphKanalArray setArray:derKanalArray];
	//[GraphKanalArray release];
	[self setNeedsDisplay:YES];
}

- (void)clear8Kanal
{
	//NSLog(@"MehrkanalDiagramm clear8Kanal");
	[Graph moveToPoint:DiagrammEcke];
	int i;
	for (i=0;i<8;i++)
	{
	
	[[GraphArray objectAtIndex:i]removeAllPoints];
	[[GraphArray objectAtIndex:i]moveToPoint:DiagrammEcke];
	}
	
	[NetzlinienX setArray:[NSArray array]];
	[NetzlinienY setArray:[NSArray array]];
	lastPunkt=DiagrammEcke;
	[self setNeedsDisplay:YES];
}

- (void)setGitterLinien
{
   if (SenkrechteLinie)
   {
   [SenkrechteLinie removeAllPoints];
   }
   else
   {
      SenkrechteLinie=[[NSBezierPath bezierPath]retain];
   }
   
   if (WaagrechteLinie)
   {
      [WaagrechteLinie  removeAllPoints];
   }
   else
   {
      WaagrechteLinie=[[NSBezierPath bezierPath]retain];
   }
   
   


   
   //MaxAbszisse=200;
   //MaxOrdinate=200;
   NSRect DiagrammRahmen=[self frame];//NSMakeRect(NetzEcke.x,NetzEcke.y,200,100);
	//AchsenRahmen.size.height-=14.9;
   
   // Platz schaffen
	DiagrammRahmen.origin.x+=0.1;
	DiagrammRahmen.origin.y+=0.1;
   DiagrammRahmen.size.width-=0.2;
   DiagrammRahmen.size.height-=0.2;
   
   float breite=DiagrammRahmen.size.width;
   float hoehe=DiagrammRahmen.size.height;
   
   // Startpunkte fuer Gitterlinien
	NSPoint unten=DiagrammEcke;
	NSPoint oben=unten;
	
	oben.y+=DiagrammRahmen.size.height;//-10;
   
	NSPoint rechts=unten;
   rechts.x += DiagrammRahmen.size.width-1;
   
	NSPoint links=unten;
   float BereichY = (MaxY-MinY);
   float SchrittweiteY=255.0/(MajorTeileY*MinorTeileY);
	float deltaY=MaxOrdinate/255.0*SchrittweiteY;
   
   float BereichX = (MaxX-MinX);
   float SchrittweiteX=255.0/(MajorTeileX*MinorTeileX);
	float deltaX=MaxAbszisse/255.0*SchrittweiteX;
   NSPoint MarkPunktX=links;
 	NSPoint MarkPunktY=unten;
   
   
   // waagrechte Linien
   for (int i=0;i<(MajorTeileY*MinorTeileY+1);i++)
	{
		//NSLog(@"i: %d rest: %d",i,i%MajorTeile);
      //NSLog(@"i: %d links y: %2.2f rechts y: %2.2f",i,links.y,rechts.y);
		if (i%MinorTeileY)//Zwischenraum
		{
			//NSLog(@"i: %d ",i);
			//MarkPunkt.x-=breiteY;
			//[WaagrechteLinie moveToPoint:MarkPunkt];
		}
		
		else
		{
			[WaagrechteLinie moveToPoint:links];
			//	[NSBezierPath strokeRect: Zahlfeld];
			//NSLog(@"i: %d Zahl: %2.2f",i,Bereich/(MajorTeile*MinorTeile)*i-Nullpunkt);
         //			Zahl=[NSNumber numberWithFloat:Bereich/(MajorTeile*MinorTeile)*i-Nullpunkt];
         //			[[Zahl stringValue]drawInRect:Zahlfeld withAttributes:AchseTextDic];
         [WaagrechteLinie lineToPoint:rechts];
      }
		
		
		rechts.y+=deltaY;
		links.y+=deltaY;
	}

   // senkrechte Linien
   for (int i=0;i<(MajorTeileX*MinorTeileX+1);i++)
	{
		//NSLog(@"i: %d rest: %d",i,i%MajorTeile);
      
		if (i%MinorTeileX)//Zwischenraum
		{
			//NSLog(@"i: %d ",i);
			//MarkPunkt.x-=breiteY;
			//[WaagrechteLinie moveToPoint:MarkPunkt];
		}
		
		else
		{
			[SenkrechteLinie moveToPoint:unten];
			//	[NSBezierPath strokeRect: Zahlfeld];
			//NSLog(@"i: %d Zahl: %2.2f",i,Bereich/(MajorTeile*MinorTeile)*i-Nullpunkt);
         //			Zahl=[NSNumber numberWithFloat:Bereich/(MajorTeile*MinorTeile)*i-Nullpunkt];
         //			[[Zahl stringValue]drawInRect:Zahlfeld withAttributes:AchseTextDic];
		}
		[SenkrechteLinie lineToPoint:oben];
		
		unten.x+=deltaX;
		oben.x+=deltaX;
	}


}


- (void)waagrechteLinienZeichnen
{
	NSRect AchsenRahmen=[self frame];//NSMakeRect(NetzEcke.x,NetzEcke.y,200,100);
	//AchsenRahmen.size.height-=14.9;

	AchsenRahmen.origin.x+=5.1;
	AchsenRahmen.origin.y+=5.1;
   AchsenRahmen.size.width-=1;

	//NSLog(@"MK AchsenRahmen x: %f y: %f h: %f w: %f",AchsenRahmen.origin.x,AchsenRahmen.origin.y,AchsenRahmen.size.height,AchsenRahmen.size.width);
	int i;
	[[NSColor greenColor]set];
//	[NSBezierPath strokeRect:AchsenRahmen];
	
	NSPoint unten=DiagrammEcke;
	unten.x+=AchsenRahmen.size.width-1;
	NSPoint oben=unten;
	oben.x=unten.x;
	oben.y+=AchsenRahmen.size.height;//-10;
	//NSLog(@"Diagramm hight: %2.2f",AchsenRahmen.size.height);
 
	//NSBezierPath* WaagrechteLinie=[NSBezierPath bezierPath];
	[WaagrechteLinie setLineWidth:0.2];
	
	NSPoint rechts=unten;//
	NSPoint links=unten;
   
   
	//MaxOrdinate=205.0;
	
	float breite=AchsenRahmen.size.width-1;
   
	float Bereich=MaxY-MinY;
	float Schrittweite=255.0/(MajorTeileY*MinorTeileY);
	float delta=MaxOrdinate/255.0*Schrittweite;
	NSPoint MarkPunkt=links;
	//NSRect Zahlfeld=NSMakeRect(links.x-40,links.y-2,30,10);
	//NSLog(@"MaxOrdinate: %2.2f",MaxOrdinate);
	
	//NSLog(@"MKDiagramm 	MajorTeile: %d MinorTeile: %d delta: %2.2f",MajorTeileY,MinorTeileY,delta);
	
	for (i=0;i<(MajorTeileY*MinorTeileY+1);i++)
	{
		MarkPunkt.x=links.x;
		//NSLog(@"i: %d rest: %d",i,i%MajorTeile);
		if (i%MinorTeileY)//Zwischenraum
		{
			//NSLog(@"i: %d ",i);
			//MarkPunkt.x-=breiteY;
			//[WaagrechteLinie moveToPoint:MarkPunkt];
		}
		
		else
		{
			MarkPunkt.x-=breite;
			[WaagrechteLinie moveToPoint:MarkPunkt];
			//	[NSBezierPath strokeRect: Zahlfeld];
			//NSLog(@"i: %d Zahl: %2.2f",i,Bereich/(MajorTeile*MinorTeile)*i-Nullpunkt);
//			Zahl=[NSNumber numberWithFloat:Bereich/(MajorTeile*MinorTeile)*i-Nullpunkt];
//			[[Zahl stringValue]drawInRect:Zahlfeld withAttributes:AchseTextDic];
		}
		[WaagrechteLinie lineToPoint:rechts];
		[WaagrechteLinie stroke];
		rechts.y+=delta;
	}
	[[NSColor blackColor]set];
	//[NSBezierPath strokeRect:AchsenRahmen];
	//[NSBezierPath strokeRect:[self frame]];

}

- (void)drawRect:(NSRect)rect
{
   [[NSColor blueColor]set];
	[NSBezierPath strokeRect:[self bounds]];

	//NSLog(@"MKDiagramm drawRect");
	NSRect NetzBoxRahmen=[self bounds];//NSMakeRect(NetzEcke.x,NetzEcke.y,200,100);
	NetzBoxRahmen.size.height-=10;
	NetzBoxRahmen.size.width-=1;
	//NetzBoxRahmen.origin.x+=0.2;
	//NSLog(@"NetzBoxRahmen x: %f y: %f h: %f w: %f",NetzBoxRahmen.origin.x,NetzBoxRahmen.origin.y,NetzBoxRahmen.size.height,NetzBoxRahmen.size.width);
	
	[[NSColor greenColor]set];
	[NSBezierPath strokeRect:NetzBoxRahmen];
	[SenkrechteLinie stroke];
   [WaagrechteLinie stroke];
   
//	NSBezierPath* SenkrechteLinie=[NSBezierPath bezierPath];
	int i;
	NSPoint untenV=DiagrammEcke;
	NSPoint obenV=untenV;
	NSPoint links=untenV;
	obenV.x=untenV.x;
	obenV.y+=NetzBoxRahmen.size.height;
	NSPoint mitteH=DiagrammEcke;
	mitteH.y+=(NetzBoxRahmen.size.height)/256*NullpunktY;
		int k;
	NSPoint untenH=DiagrammEcke;
	NSPoint rechtsH=untenH;
	NSPoint linksH=untenH;
	rechtsH.x=untenH.x;
	rechtsH.x+=NetzBoxRahmen.size.width-5;
	 
	
	
	
	NSBezierPath* WaagrechteMittelLinie=[NSBezierPath bezierPath];
	
	NSPoint mitterechtsH=mitteH;
	mitterechtsH.y=mitteH.y;
	mitterechtsH.x+=NetzBoxRahmen.size.width-5;
	
	[WaagrechteMittelLinie moveToPoint:mitteH];
	[WaagrechteMittelLinie lineToPoint:mitterechtsH];

	
   //	[WaagrechteMittelLinie stroke];
	
   
   for (i=0;i<8;i++)
	{
		//NSLog(@"drawRect Farbe Kanal: %d Color: %@",i,[[GraphFarbeArray objectAtIndex:i] description]);
		if ([[GraphKanalArray objectAtIndex:i]intValue])
		{
			[(NSColor*)[GraphFarbeArray objectAtIndex:i]set];
         //[[GraphArray objectAtIndex:i]setLineWidth:4.5];
			[[GraphArray objectAtIndex:i]stroke];
         
         if (Darstellungsoption)
         {
			NSPoint cP=[[GraphArray objectAtIndex:i]currentPoint];
			//cP.x+=2;
			cP.y-=12;
			[[DatenFeldArray objectAtIndex:i]setFrameOrigin:cP];
			//NSLog(@"drawRect: %@",[[DatenArray objectAtIndex:i]description]);
			
         cP.x += 20;
 			[[DatenWertArray objectAtIndex:i]setFrameOrigin:cP];
       
         // in SolarDiagramm und SolarStatistikDiagramm verwendet
         [[DatenFeldArray objectAtIndex:i]setStringValue:[NSString stringWithFormat:@"%@:",[DatenTitelArray objectAtIndex:i]]];
         [[DatenWertArray objectAtIndex:i]setStringValue:[NSString stringWithFormat:@"%@",[[[DatenArray objectAtIndex:i]lastObject]objectForKey:@"wert"]]];
         
         
			//NSString* AnzeigeString=[NSString stringWithFormat:@"%@: %@",[DatenTitelArray objectAtIndex:i],[[[DatenArray objectAtIndex:i]lastObject]objectForKey:@"wert"]];
			//[[DatenFeldArray objectAtIndex:i]setStringValue:AnzeigeString];
			//		[[DatenFeldArray objectAtIndex:i]setStringValue:[[[DatenArray objectAtIndex:i]lastObject]objectForKey:@"wert"]];
         }
		}
	}
	
	
	
}


- (void)clean
{

if (GraphArray &&[GraphArray count])
{
[GraphArray removeAllObjects];
}

if (GraphFarbeArray && [GraphFarbeArray count])
{
[GraphFarbeArray removeAllObjects];
}


if (GraphKanalArray &&[GraphKanalArray count])
{
[GraphKanalArray removeAllObjects];
}

if (DatenArray &&[DatenArray count])
{
	[DatenArray removeAllObjects];
}

int i=0;
for (i=0;i<8;i++)
{

	NSBezierPath* tempGraph=[NSBezierPath bezierPath];
	[tempGraph retain];
	float varRed=sin(i+(float)i/10.0)/3.0+0.6;
	float varGreen=sin(2*i+(float)i/10.0)/3.0+0.6;
	float varBlue=sin(3*i+(float)i/10.0)/3.0+0.6;
	//NSLog(@"sinus: %2.2f",varRed);
	NSColor* tempColor=[NSColor colorWithCalibratedRed:varRed green: varGreen blue: varBlue alpha:1.0];
	//NSLog(@"Farbe Kanal: %d Color: %@",i,[tempColor description]);
	tempColor=[NSColor blackColor];
	[tempColor retain];
	[GraphFarbeArray addObject:tempColor];
	[GraphArray addObject:tempGraph];
	[GraphKanalArray addObject:[NSNumber numberWithInt:0]];
	[GraphKanalOptionenArray addObject:[[NSMutableDictionary alloc]initWithCapacity:0]];
	[DatenArray addObject:[[NSMutableArray alloc]initWithCapacity:0]];
	/*
	NSRect tempRect=NSMakeRect(0,0,25,18);
	NSTextField* tempDatenFeld=[[NSTextField alloc]initWithFrame:tempRect];
	NSFont* DatenFont=[NSFont fontWithName:@"Helvetica" size: 9];

	[tempDatenFeld setEditable:NO];
	[tempDatenFeld setSelectable:NO];
	[tempDatenFeld setStringValue:@""];
	[tempDatenFeld setFont:DatenFont];
	[tempDatenFeld setAlignment:NSLeftTextAlignment];
	[tempDatenFeld setBordered:NO];
	[tempDatenFeld setDrawsBackground:NO];
	[self addSubview:tempDatenFeld];
	[DatenFeldArray addObject:tempDatenFeld];
	*/
	[[DatenFeldArray objectAtIndex:i]setStringValue:@""];
}//for i

[self setNeedsDisplay:YES];
}
@end
