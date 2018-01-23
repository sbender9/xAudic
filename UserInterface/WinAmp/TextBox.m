/*  
 *  xAudic - an audio player for MacOS X
 *  Copyright (C) 1999-2001  Scott P. Bender (sbender@harmony-ds.com)
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; see the file COPYING if not, write to 
 *  the Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 *  Boston, MA 02111-1307, USA.
*/
#import "TextBox.h"
#import "Button.h"
#import "Skin.h"
#import "Configure.h"

@implementation TextBox

- (NSImage *)image
{
  return [currentSkin performSelector:imageSel];
}

- (BOOL)isOpaque
{
  return YES;
}


- (void)setScroll:(BOOL)val
{
  NSTimeInterval interval;

  scroll = val;

  if ( scrollTimer != nil ) {
    [scrollTimer invalidate];
    [scrollTimer release];
    scrollTimer = nil;
  }


  if ( val ) {
    interval = [config boolValueForKey:smooth_title_scroll] ? 0.05: 0.5;
    scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:interval
						    target:self 
						  selector:@selector(scroll:)
						  userInfo:nil
						   repeats:YES] retain];
  }
}

- (void)needsScroll:(BOOL)_needsScroll
{
  needsScroll = _needsScroll;
}

- initWithFrame:(NSRect)frame :_target :(SEL)_imageSel
{
  frame.size.height = 6;
  [super initWithFrame:frame];
  imageSel = _imageSel;
  target = _target;
  lock = [[NSLock alloc] init];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(skinChanged:)
	   name:SkinChangedNotification
	 object:nil];

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [lock release];
  [scrollTimer invalidate];
  [scrollTimer release];
  [imageText release];
  [text_image release];
  [text release];
  [super dealloc];
}

- (void)scroll:nothing
{
  if ( needsScroll ) {
    if ( [config boolValueForKey:smooth_title_scroll] )
      offset++;
    else
      offset+=5;
    if(offset >= [text_image size].width)
      offset -= [text_image size].width;
    [self setNeedsDisplay:YES];
  }
}

- (void)drawRect:(NSRect)rect 
{
  NSRect frame = [self frame];
  NSSize isize = [text_image size];
  int cw;

  if ( [text isEqualToString:imageText] == NO )
    [self generateImage];

  cw = isize.width - offset;
  
  if ( cw > frame.size.width )
    cw = frame.size.width;

  [text_image compositeToPoint:NSMakePoint(0,0)
		      fromRect:NSMakeRect(offset, 0, cw, frame.size.height)
		     operation:NSCompositeCopy];
  
  if ( cw < frame.size.width)
    [text_image compositeToPoint:NSMakePoint(cw, 0)
			fromRect:NSMakeRect(0, 0, frame.size.width-cw,
					    frame.size.height)
		       operation:NSCompositeCopy];
}

- (void)generateImage
{
  int length,i,x,y;
  char c;
  NSRect frame;
  NSImage *new_image;

  frame = [self frame];

  if ( text == nil ) {
    imageText = nil;
    return;
  }

  [lock lock];

  length = [text length];

  new_image = [[NSImage allocWithZone:[self zone]] 
			 initWithSize:NSMakeSize(length*5, 
						 frame.size.height)];

  [new_image lockFocus];
  PSgsave();
   
  for(i=0;i<length;i++)	{
    c = [text characterAtIndex:i];
    x = y = -1;
    if( c >= 'A' && c <= 'Z') {
      x=5*(c-'A');
      y=0;
    } else if (c>='0'&&c<='9') {
      x=5*(c-'0');
      y=6;
    } else {
      switch(c)	{
      case	'"':
	x=130;
	y=0;
	break;
      case	':':
	x=60;
	y=6;
	break;
      case	'(':
	x=65;
	y=6;
	break;
      case	')':
	x=70;
	y=6;
	break;
      case	'-':
	x=75;
	y=6;
	break;
      case	'`':
      case	'\'':
	x=80;
	y=6;
	break;
      case	'!':
	x=85;
	y=6;
	break;
      case	'_':
	x=90;
	y=6;
	break;
      case	'+':
	x=95;
	y=6;
	break;
      case	'\\':
	x=100;
	y=6;
	break;
      case	'/':
	x=105;
	y=6;
	break;
      case	'[':
	x=110;
	y=6;
	break;
      case	']':
	x=115;
	y=6;
	break;
      case	'^':
	x=120;
	y=6;
	break;
      case	'&':
	x=125;
	y=6;
	break;
      case	'%':
	x=130;
	y=6;
	break;
      case	'.':
      case	',':
	x=135;
	y=6;
	break;
      case	'=':
	x=140;
	y=6;
	break;
      case	'$':
	x=145;
	y=6;
	break;
      case	'#':
	x=150;
	y=6;
	break;
      case	'å':
      case	'Å':
	x=0;
	y=12;
	break;
      case	'ö':
      case	'Ö':
	x=5;
	y=12;
	break;
      case	'ä':
      case	'Ä':
	x=10;
	y=12;
	break;
      case	'ü':
      case	'Ü':
	x=100;
	y=0;
	break;
      case	'?':
	x=15;
	y=12;
	break;
      case	'*':
	x=20;
	y=12;
	break;
      default:
	x=25;
	y=12;
	break;
      }
    }
    
    [[self image] compositeToPoint:NSMakePoint(i*5,0)
			  fromRect:flipRect(NSMakeRect(x,y, 5, 6), 
					    [self image])
			 operation:NSCompositeCopy];

  }
  PSgrestore();
  [new_image unlockFocus];
  [text_image release];
  text_image = [new_image retain];
  [imageText release];
  imageText = [text retain];
  [lock unlock];
}

- (void)setStringValue:(NSString *)string
{
  NSRect frame = [self frame];
  int wl, i;
  NSMutableString *ms;

  [lock lock];

  wl = frame.size.width/5;
  if(wl * 5 != frame.size.width)
    wl++;

  offset = 0;
  string = [string uppercaseString];

  if( [string length] <= wl) {
    ms = [NSMutableString stringWithString:[string uppercaseString]];

    for ( i = [ms length]; i < wl; i++ )
      [ms insertString:@" " atIndex:i];
  
    text = [ms retain];
    [self needsScroll:NO];
  } else if ( [string length] * 5 > frame.size.width && scroll ) {
    text = [[string stringByAppendingString:@"  ***  "] retain];
    [self needsScroll:YES];
  } else {
    text = [string retain];
    [self needsScroll:NO];
  }

  [self setNeedsDisplay:YES];
  [lock unlock];
}

- (void)setIntValue:(int)val
{
  [self setStringValue:[NSString stringWithFormat:@"%d", val]];
}

- (void)skinChanged:(NSNotification *)notification
{
  [self generateImage];
  [self setNeedsDisplay:YES];
}

@end
