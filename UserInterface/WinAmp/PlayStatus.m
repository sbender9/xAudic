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
#import "PlayStatus.h"
#import "Skin.h"

@implementation PlayStatus

- (BOOL)isOpaque
{
  return YES;
}

- initWithPos:(NSPoint)pos
{
  status = STATUS_STOP;
  return [super initWithFrame:NSMakeRect(pos.x, pos.y, 11, 9)];
}

- (void)setStatus:(PStatus)val
{
  status = val;
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
  NSImage *image = [currentSkin playpause];
  NSRect frame = [self frame];
  
  if ( status == STATUS_PLAY )
    [image compositeToPoint:NSMakePoint(0,frame.size.height)
		   fromRect:NSMakeRect(36, 0, 3, 9)
		  operation:NSCompositeCopy];
  else
    [image compositeToPoint:NSMakePoint(0,frame.size.height)
		   fromRect:NSMakeRect(27, 0, 2, 9)
		  operation:NSCompositeCopy];
  switch(status)  {
  case STATUS_STOP:
    [image compositeToPoint:NSMakePoint(2,frame.size.height)
		   fromRect:NSMakeRect(18, 0, 9, 9)
		  operation:NSCompositeCopy];
    break;
  case STATUS_PAUSE:
    [image compositeToPoint:NSMakePoint(2,frame.size.height)
		   fromRect:NSMakeRect(9, 0, 9, 9)
		  operation:NSCompositeCopy];
    break;
  case STATUS_PLAY:
    [image compositeToPoint:NSMakePoint(3,frame.size.height)
		   fromRect:NSMakeRect(1, 0, 8, 9)
		  operation:NSCompositeCopy];
    break;
  }
}

@end
