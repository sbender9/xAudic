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
#import "Number.h"
#import <AppKit/AppKit.h>
#import "Button.h"
#import "Skin.h"

@implementation Number

- (NSImage *)image
{
  return [currentSkin performSelector:imageSel];
}

- (BOOL)isOpaque
{
  return YES;
}

- (void)drawRect:(NSRect)rect 
{
  NSPoint pos, p;
  NSSize size = [self frame].size;
  if( number <= 10) {
    pos = NSMakePoint(number*9,0);
  } else if ( number == 11 ) {
    if( [[self image] size].width >= 108 )
      pos = NSMakePoint(number*9, 0);
    else {
      pos = NSMakePoint(90,0);

      p = flipPoint(NSMakePoint(20,6), [self image], size);
      [[self image] compositeToPoint:NSMakePoint(2, 0)
			    fromRect:NSMakeRect(p.x, p.y, 5, 1)
			   operation:NSCompositeCopy];
    }
  } else
    pos = NSMakePoint(90, 0);

  p = flipPoint(pos, [self image], size);
  [[self image] compositeToPoint:NSMakePoint(0, 0)
			fromRect:NSMakeRect(p.x, p.y, 9, 13)
		       operation:NSCompositeCopy];
  
}

- initPos:(NSPoint)pos :(SEL)_imageSel
{
  NSRect frame;
  
  frame.size = NSMakeSize(9, 13);
  frame.origin = pos;
  number = 10;
  imageSel = _imageSel;
  return [super initWithFrame:frame];
}

- (void)setNumber:(int)val
{
  number = val;
  [self setNeedsDisplay:YES];
}


@end
