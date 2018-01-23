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
#import "Button.h"
#import "Skin.h"


@implementation Button

- (BOOL)isOpaque
{
  return YES;
}

- (void)setAllowDraw:(BOOL)val
{
  allowDraw = val;
}

- (void)toggle:(BOOL)val
{
  [self setState:val];
  [self setNeedsDisplay:YES];
}

- init:(NSRect)frame 
      :(NSPoint)_normal
      :(NSPoint)_pushed
      :(id)target
      :(SEL)cb
      :(SEL)_imageSel;
{
  return [self init:(NSRect)frame 
		   :_normal
		   :_pushed
		   :NSMakePoint(-1,-1)
		   :NSMakePoint(-1,-1)
		   :target
		   :cb
		   :_imageSel
		   :NO];
}

- init:(NSRect)frame :(id)target :(SEL)cb
{
  return [self init:frame 
		   :NSMakePoint(-1,-1)
		   :NSMakePoint(-1,-1)
		   :NSMakePoint(-1,-1)
		   :NSMakePoint(-1,-1)
		   :target
		   :cb
		   :0
		   :NO];
}

- init:(NSRect)frame 
      :(NSPoint)_normal
      :(NSPoint)_pushed
      :(NSPoint)_spushed
      :(NSPoint)_snormal
      :(id)target
      :(SEL)cb
      :(SEL)_imageSel;
{
  return [self init:frame
		   :_normal
		   :_pushed
		   :_spushed
		   :_snormal
		   :target
		   :cb
		   :_imageSel
		   :YES];
}

- (NSImage *)image
{
  return imageSel != 0 ? [currentSkin performSelector:imageSel] : nil;
}

- (void)setNormal:(NSPoint)_normal
{
  NSSize size = [self frame].size;
  normal = flipPoint(_normal, [self image], size);
}
  
- (void)setPushed:(NSPoint)_pushed;
{
  NSSize size = [self frame].size;
  pushed = flipPoint(_pushed, [self image], size);
}

- (void)setSpushed:(NSPoint)_spushed;
{
  NSSize size = [self frame].size;
  spushed = flipPoint(_spushed, [self image], size);
}

- (void)setSnormal:(NSPoint)_snormal;
{
  NSSize size = [self frame].size;
  snormal = flipPoint(_snormal, [self image], size);
}

- init:(NSRect)frame 
      :(NSPoint)_normal
      :(NSPoint)_pushed
      :(NSPoint)_snormal
      :(NSPoint)_spushed
      :(id)target
      :(SEL)cb
      :(SEL)_imageSel
      :(BOOL)toggleButton
{
  [super initWithFrame:frame];
  imageSel = _imageSel;
  [self setNormal:_normal];
  [self setPushed:_pushed];
  [self setSnormal:_snormal];
  [self setSpushed:_spushed];
  allowDraw = YES;
  toggle = toggleButton;
  if ( toggleButton == NO )
    [self setButtonType:NSMomentaryPushButton];
  else
    [self setButtonType:NSToggleButton];
  [self setBordered:NO];
  [self setTarget:target];
  [self setAction:cb];
  return self;
}

- (void)drawRect:(NSRect)rect 
{
  NSRect frame = [self frame];

  if ( [self image] != nil ) 
    {
      NSPoint src;
      
      if ( allowDraw == NO 
	   && (toggle == NO && [[self cell] isHighlighted] == NO) 
	   && drewPushed == NO )
	{
	  return;
	}
    
      if ( toggle == NO ) 
	{
	  if ( [[self cell] isHighlighted] ) 
	    {
	      src = pushed;
	      drewPushed = YES;
	    } 
	  else 
	    {
	      src = normal;
	      drewPushed = NO;
	    }
	} 
      else 
	{
	  if ( [[self cell] isHighlighted] ) 
	    {
	      src = [self state] ? spushed : pushed;
	    } 
	  else 
	    {
	      src = [self state] ? snormal : normal;
	    }
	}
      [[self image] compositeToPoint:NSMakePoint(0,frame.size.height)
		    fromRect:NSMakeRect(src.x, src.y, 
					frame.size.width,
					frame.size.height)
		    operation:NSCompositeCopy];
    }
}


@end
