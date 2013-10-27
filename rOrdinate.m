#import "rOrdinate.h"

@implementation rOrdinate
- (void) logRect:(NSRect)r
{
NSLog(@"logRect: origin.x %2.2f origin.y %2.2f size.heigt %2.2f size.width %2.2f",r.origin.x, r.origin.y, r.size.height, r.size.width);
}


- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) 
	{
		//// Add initialization code here
		//NSLog(@"rOrdinate Init");
      GrundlinienOffset  = 5;
      MaxOrdinate=[self frame].size.height-20;

		AchsenEcke=NSMakePoint(0.0,GrundlinienOffset);
		AchsenSpitze=AchsenEcke;
		AchsenSpitze.y += MaxOrdinate;
		EinheitenArray=[[[NSMutableArray alloc] initWithCapacity: 0]autorelease];
		[EinheitenArray retain];
		MajorTeile=4;
		MinorTeile=2;
		Max=2;
		Min=-2;
		Nullpunkt=0;
		Einheit=@"";
		Schriftgroesse=9;
      MaxOrdinate=[self frame].size.height-20;
		//NSLog(@"***   Ordinate init");
		//[self logRect:[self frame]];

	}
	return self;
}


- (void)setTag:(int)derTag
{
	Tag= derTag;
}

- (void)setOrdinatenlageY:(float)OrdinatenlageY
{
	float x=[self frame].origin.x;
	float y=[self frame].origin.y;
   
	[self setFrameOrigin:NSMakePoint(x,y+OrdinatenlageY)];
	
	NSLog(@"***   Ordinate setOrdinatenlageY");
	//[self logRect:[self frame]];

}

- (void)setGrundlinienOffset:(float)offset
{
   //NSLog(@"***   Ordinate setGrundlinienOffset start");
   //[self logRect:[self frame]];
	GrundlinienOffset +=offset;
	AchsenEcke.y += offset;
	NSRect r=[self frame];
	//r.size.height+=offset;
	[self setFrame:r];
	//NSLog(@"***   Ordinate setGrundlinienOffsetnach offset: %2.2f",offset);
	//[self logRect:[self frame]];

}


- (void)setMaxOrdinate:(int)laenge
{

	MaxOrdinate=laenge;
	NSLog(@"***   Ordinate setMaxOrdinate: %d",MaxOrdinate);
	//[self logRect:[self frame]];

}

- (void)drawRect:(NSRect)rect
{
	[[NSColor redColor]set];
	[NSBezierPath strokeRect:[self bounds]];

	[self AchseZeichnen];
}

- (void)AchseZeichnen
{
	NSFont* AchseTextFont=[NSFont fontWithName:@"Helvetica" size: Schriftgroesse];

	NSMutableDictionary* AchseTextDic=[[NSMutableDictionary alloc]initWithCapacity:0];
	[AchseTextDic setObject:AchseTextFont forKey:NSFontAttributeName];
	NSMutableParagraphStyle* AchseStil=[[NSMutableParagraphStyle alloc]init];
	[AchseStil setAlignment:NSRightTextAlignment];
	[AchseTextDic setObject:AchseStil forKey:NSParagraphStyleAttributeName];
	//NSLog(@"AchseTextDic: %@",[AchseTextDic description]);
	NSRect AchsenRahmen=[self frame];//NSMakeRect(NetzEcke.x,NetzEcke.y,200,100);
	//AchsenRahmen.size.height-=14.9;
   AchsenRahmen.origin = AchsenEcke;

	//NSLog(@"NetzBoxRahmen x: %f y: %f h: %f w: %f",NetzBoxRahmen.origin.x,NetzBoxRahmen.origin.y,NetzBoxRahmen.size.height,NetzBoxRahmen.size.width);
	
	[[NSColor greenColor]set];
	[[NSColor grayColor]set];
	//[NSBezierPath strokeRect:AchsenRahmen];
	NSBezierPath* SenkrechteLinie=[NSBezierPath bezierPath];
	
	int i;
	NSPoint unten=AchsenEcke;
	//NSLog(@"AchsenEcke x: %2.2f y: %2.2f " ,AchsenEcke.x,AchsenEcke.y);
	unten.x+=AchsenRahmen.size.width-1;
	
	NSPoint oben=AchsenSpitze;
	oben.x=unten.x;
	//NSLog(@"Ordinate: height: %2.2f",AchsenRahmen.size.height);
	oben.y+= MaxOrdinate;
   
	[SenkrechteLinie moveToPoint:unten];
	[SenkrechteLinie lineToPoint:oben];
	[SenkrechteLinie stroke];

	NSBezierPath* WaagrechteLinie=[NSBezierPath bezierPath];
	[WaagrechteLinie setLineWidth:0.2];
	
	NSPoint rechts=unten;//
	NSPoint links=unten;
	
	//Nullpunkt += Offset*Zoom;
	float markbreite=6;
	float submarkbreite=3;
	float Bereich=Max-Min;
	//float Schrittweite=Bereich/(MajorTeile*MinorTeile);
	float Schrittweite=255.0/(MajorTeile*MinorTeile);	// Schrittweite fuer 255

   
	float delta=MaxOrdinate/255.0*Schrittweite;	// Schrittweite fuer reales Diagramm
	//NSLog(@"Ordinate MaxOrdinate: %d	MajorTeile: %d MinorTeile: %d delta: %2.2f",MaxOrdinate,MajorTeile,MinorTeile,delta);
	
	//rechts.x+=NetzBoxRahmen.size.width-10.0;
	//NSLog(@"rechts: %f",rechts.x);
	NSNumber* Zahl=[NSNumber numberWithInt:0];
	NSPoint MarkPunkt=links;
	NSRect Zahlfeld=NSMakeRect(links.x-54,links.y-3,45,10);
	//NSLog(@"MajorTeile: %d MinorTeile: %d ",MajorTeile,MinorTeile);
	for (i=0;i<(MajorTeile*MinorTeile+1);i++)
	{
		MarkPunkt.x=links.x;
		//NSLog(@"i: %d rest: %d",i,i%MajorTeile);
		if (i%MinorTeile)//Zwischenraum
		{
			//NSLog(@"i: %d ",i);
			MarkPunkt.x-=submarkbreite;
			[WaagrechteLinie moveToPoint:MarkPunkt];
		}
		
		else
		{
			MarkPunkt.x-=markbreite;
			[WaagrechteLinie moveToPoint:MarkPunkt];
			//	[NSBezierPath strokeRect: Zahlfeld];

//			Zahl=[NSNumber numberWithFloat:((Max-Min)/(MajorTeile)*i/MinorTeile-Nullpunkt)];
//			NSLog(@"i: %d Zahl: %22.2f",i,((Max-Min)/(MajorTeile)*i/MinorTeile-Nullpunkt));

			Zahl=[NSNumber numberWithFloat:(((Max-Min)/(MajorTeile)*i)/MinorTeile)+Min];
			//NSLog(@"i: %d Zahl: %22.2f",i,((Max-Min)/(MajorTeile)*i/MinorTeile));
			
			
			//Zahl=[NSNumber numberWithFloat:(MajorTeile)*i-Nullpunkt];
			NSString* ZahlString=[NSString stringWithFormat:@"%@%@",[Zahl stringValue], Einheit];
			[ZahlString drawInRect:Zahlfeld withAttributes:AchseTextDic];
		}
		[WaagrechteLinie lineToPoint:rechts];
		[WaagrechteLinie stroke];
		rechts.y+=delta;
		MarkPunkt.y+=delta;
		Zahlfeld.origin.y+=delta;
	}

}

- (void)setAchsenDic:(NSDictionary*)derAchsenDic
{
	//NSLog(@"setAchsenDic: %@",[derAchsenDic description]);
	NSRect AchsenRahmen=[self bounds];
if ([derAchsenDic objectForKey:@"einheit"])
{
	Einheit=[derAchsenDic objectForKey:@"einheit"];
}

if ([derAchsenDic objectForKey:@"majorteile"])
{
	MajorTeile=[[derAchsenDic objectForKey:@"majorteile"]intValue];
}

if ([derAchsenDic objectForKey:@"minorteile"])
{
MinorTeile=[[derAchsenDic objectForKey:@"minorteile"]intValue];
}

if ([derAchsenDic objectForKey:@"maxy"])
{
Max=[[derAchsenDic objectForKey:@"maxy"]floatValue];
}

if ([derAchsenDic objectForKey:@"miny"])
{
Min=[[derAchsenDic objectForKey:@"miny"]floatValue];
}

if ([derAchsenDic objectForKey:@"minorteile"])
{
	MinorTeile=[[derAchsenDic objectForKey:@"minorteile"]intValue];
	

}

if ([derAchsenDic objectForKey:@"nullpunkt"])
{

	Nullpunkt=[[derAchsenDic objectForKey:@"nullpunkt"]floatValue];
	

}

if ([derAchsenDic objectForKey:@"max"])
{
	Max=[[derAchsenDic objectForKey:@"max"]floatValue];
	

}

if ([derAchsenDic objectForKey:@"min"])
{
	Min=[[derAchsenDic objectForKey:@"min"]floatValue];
	

}
[self setNeedsDisplay:YES];
}

@end
