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
#import "WindowMovingView.h"
#import <AppKit/AppKit.h>

@implementation WindowMovingView

- (void)setMovingEnabled:(BOOL)val
{
  enabled = val;
}

- (BOOL)movingEnabled
{
  return enabled;
}


- (void)mouseDown:(NSEvent *)theEvent 
{
  if ( enabled )
    {
      id window = [self window];
      NSPoint startPoint, curPoint;
      NSRect frame;
      int xdif, ydif;

      startPoint = [theEvent locationInWindow];
      frame = [window frame];
      startPoint = [window convertBaseToScreen:startPoint];
      xdif = startPoint.x - frame.origin.x;
      ydif = startPoint.y - frame.origin.y;

      while (1) 
	{

	  theEvent = [window nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
	  curPoint = [theEvent locationInWindow];
	  curPoint = [window convertBaseToScreen:curPoint];
	  curPoint.x = curPoint.x-xdif;
	  curPoint.y = curPoint.y-ydif;

	  [window setFrameOrigin:curPoint];

	  if ([theEvent type] == NSLeftMouseUp)
	    break;
	}
    }
}

- (void)setDefaults
{
  [self setMovingEnabled:YES];
}

- initWithFrame:(NSRect)rect
{
  [self setDefaults];
  return [super initWithFrame:rect];
}

- (void)awakeFromNib
{
  [self setDefaults];
}


/*
- (void)mouseEntered:(NSEvent *)e
{
  mouseIn = YES;
  [self setNeedsDisplay:YES];
  //NSLog(@"mouseEntered");
}

- (void)mouseExited:(NSEvent *)e
{
  mouseIn = NO;
  [self setNeedsDisplay:YES];
  NSLog(@"mouseExited");
}
*/

/*
- (void)drawRect:(NSRect)rect
{
  if ( [image isKindOfClass:[NSImage class]] && mouseIn )
    {
      if ( [self lockFocusIfCanDraw] )
	{
	  [image compositeToPoint:NSMakePoint(0,0) operation:NSCompositeCopy];
	  [self unlockFocus];
	}
    }
}
*/

@end
