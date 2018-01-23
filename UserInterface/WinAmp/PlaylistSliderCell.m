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
#import "PlaylistSliderCell.h"
#import "Configure.h"
#import "Button.h"
#import "Skin.h"


@implementation PlaylistSliderCell

- (NSImage *)image
{
  return [currentSkin pledit];
}

- (void)handleAction
{
  [[self controlView] setNeedsDisplay:YES];
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
  int i, h = [config sizeValueForKey:playlist_size].height;
  
  for(i=0;i<(h-58)/29;i++) {
    [[self image] compositeToPoint:NSMakePoint(0, frame.size.height-(i*29))
			  fromRect:flipRect(NSMakeRect(36, 42, 8, 29), 
					    [self image])
			 operation:NSCompositeCopy];
  }
}

- (void)drawKnob:(NSRect)knobRect
{
  if ( [self isSliding] ) { 
    [[self image] compositeToPoint:NSMakePoint(knobRect.origin.x,
					       knobRect.origin.y+
					       knobRect.size.height)
			  fromRect:NSMakeRect(knob_pushed.x, knob_pushed.y, 
					      knob_size.width, 
					      knob_size.height)
			 operation:NSCompositeCopy];
  } else {
    [[self image] compositeToPoint:NSMakePoint(knobRect.origin.x,
				knobRect.origin.y + knobRect.size.height)
		   fromRect:NSMakeRect(knob_normal.x, knob_normal.y, 
				       knob_size.width,
				       knob_size.height)
		  operation:NSCompositeCopy];
  }
}

- initCell:(NSRect)_frame
{
  [super init];
  frame = _frame;
  knob_size = NSMakeSize(8,18);
  knob_normal = NSMakePoint(52, 53);
  knob_pushed = NSMakePoint(61, 53);

  knob_pushed.y = [[self image] size].height - 
    knob_pushed.y - knob_size.height;
  knob_normal.y = [[self image] size].height - 
    knob_normal.y - knob_size.height;

  [self setKnobSize:knob_size];
  
  return self;
}


@end
