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
#import <AppKit/AppKit.h>
#import "MonoStereo.h"
#import "Button.h"
#import "Skin.h"


@implementation MonoStereo

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
  NSSize size = [self frame].size;
  NSPoint p;
  
  switch(num_channels) {
  case 0:
    p = flipPoint(NSMakePoint(29,12), [self image], size);
    [[self image] compositeToPoint:NSMakePoint(0, 0)
			  fromRect:NSMakeRect(p.x, p.y, 27, 12)
			 operation:NSCompositeCopy];

    p = flipPoint(NSMakePoint(0, 12), [self image], size);
    [[self image] compositeToPoint:NSMakePoint(27, 0)
			  fromRect:NSMakeRect(p.x, p.y, 29, 12)
			 operation:NSCompositeCopy];
    break;

  case 1:
    p = flipPoint(NSMakePoint(29,0), [self image], size);
    [[self image] compositeToPoint:NSMakePoint(0, 0)
			  fromRect:NSMakeRect(p.x, p.y, 27, 12)
			 operation:NSCompositeCopy];

    p = flipPoint(NSMakePoint(0, 12), [self image], size);
    [[self image] compositeToPoint:NSMakePoint(27, 0)
			  fromRect:NSMakeRect(p.x, p.y, 29, 12)
			 operation:NSCompositeCopy];
    break;


  case 2:
    p = flipPoint(NSMakePoint(29,12), [self image], size);
    [[self image] compositeToPoint:NSMakePoint(0, 0)
			  fromRect:NSMakeRect(p.x, p.y, 27, 12)
			 operation:NSCompositeCopy];

    p = flipPoint(NSMakePoint(0, 0), [self image], size);
    [[self image] compositeToPoint:NSMakePoint(27, 0)
			  fromRect:NSMakeRect(p.x, p.y, 29, 12)
			 operation:NSCompositeCopy];
    break;
  }
}

- initPos:(NSPoint)pos :(SEL)_imageSel
{
  NSRect frame;

  frame.size = NSMakeSize(56, 12);
  frame.origin = pos;
  imageSel = _imageSel;
  [super initWithFrame:frame];
  return self;
}

- (void)setNumChannels:(int)val
{
  num_channels = val;
  [self setNeedsDisplay:YES];
}

@end
