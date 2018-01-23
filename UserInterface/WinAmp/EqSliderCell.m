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
#import "EqSliderCell.h"
#import "Button.h"
#import "Skin.h"
#import "WinAmp.h"

@implementation EqSliderCell

- (NSImage *)image
{
  return [currentSkin performSelector:imageSel];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag;
{
  BOOL res = [super trackMouse:theEvent 
			inRect:cellFrame 
			ofView:controlView 
		  untilMouseUp:flag];

  [[WinAmp instance] unlockInfoText];
  return res;
}

- (void)handleAction
{
  [[self controlView] setNeedsDisplay:YES];
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
  int nf;
  int nframe;

  nframe=27-(((50-[self intValue])*27)/50);
  if(nframe<14) {
    nf = [[self image] size].height - 164 - frame.size.height;
    [[self image] compositeToPoint:NSMakePoint(0,frame.size.height)
			  fromRect:NSMakeRect((nframe*15)+13, nf, 
					      frame.size.width,
					      frame.size.height)
			 operation:NSCompositeCopy];

  } else {
    nf = [[self image] size].height - 229 - frame.size.height;
    [[self image] compositeToPoint:NSMakePoint(0,frame.size.height)
			  fromRect:NSMakeRect(((nframe-14)*15)+13, nf, 
					      frame.size.width,
					      frame.size.height)
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
					       knobRect.origin.y + 
					       knobRect.size.height)
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
  imageSel = @selector(eqmain);
  knob_pushed = NSMakePoint(0, 176);
  knob_normal = NSMakePoint(0, 164);
  knob_size = NSMakeSize(11, 11);

  knob_pushed.y = [[self image] size].height - 
    knob_pushed.y - knob_size.height;
  knob_normal.y = [[self image] size].height - 
    knob_normal.y - knob_size.height;

  [self setKnobSize:knob_size];

  return self;
}


@end
