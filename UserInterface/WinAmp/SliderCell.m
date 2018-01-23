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
#import "SliderCell.h"
#import "Button.h"
#import "Skin.h"

@implementation SliderCell

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

  if ( release_cb != 0 )
    [mtarget performSelector:release_cb withObject:[self controlView]];

  return res;
}

- (BOOL)isOpaque
{
  return YES;
}

- (void)handleAction
{
  if ( frame_cb != 0 ) {
    frame_val = (int)[mtarget performSelector:frame_cb withObject:(id)[self intValue]];
    [[self controlView] setNeedsDisplay:YES];
  }
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
  int nf;

  nf = [[self image] size].height - 
    (frame_val*frame_height) - frame.size.height;  

  [[self image] compositeToPoint:NSMakePoint(0,frame.size.height)
			fromRect:NSMakeRect(frame_offset, nf, 
					    frame.size.width,
					    frame.size.height)
		       operation:NSCompositeCopy];
}

- (void)drawKnob:(NSRect)knobRect
{
  if ( [self isSliding] ) { 
    [[self image] compositeToPoint:NSMakePoint(knobRect.origin.x,
					       frame.size.height-
					       knobRect.origin.y)
			  fromRect:NSMakeRect(knob_pushed.x, knob_pushed.y, 
					      knob_size.width, 
					      knob_size.height)
			 operation:NSCompositeCopy];
  } else {
    [[self image] compositeToPoint:NSMakePoint(knobRect.origin.x,
					       frame.size.height-
					       knobRect.origin.y)
			  fromRect:NSMakeRect(knob_normal.x, knob_normal.y, 
					      knob_size.width,
					      knob_size.height)
			 operation:NSCompositeCopy];
  }
}

- initCell:(NSRect)_frame
	  :(NSPoint)_knob_normal
	  :(NSPoint)_knob_pushed
	  :(NSSize)_knob_size
	  :(int)_frame_height
	  :(int)_frame_offset
	  :(int)_min
	  :(int)_max
	  :_mtarget
	  :(SEL)_frame_cb
	  :(SEL)_release_cb
	  :(SEL)_imageSel;
{
  [super init];
  frame = _frame;
  imageSel = _imageSel;
  knob_pushed = flipPoint(_knob_pushed, [self image], frame.size);
  knob_normal = flipPoint(_knob_normal, [self image], frame.size);
  knob_size = _knob_size;
  frame_height = _frame_height;
  frame_offset = _frame_offset;
#if 0
  min = _min;
  max = _max;
#endif
  mtarget = _mtarget;
  frame_cb = _frame_cb;
  release_cb = _release_cb;
  if ( frame_cb != 0 )
    frame_val = (int)[mtarget performSelector:frame_cb withObject:(id)0];
  [self setKnobSize:knob_size];
  
  return self;
}

- (void)setIntValue:(int)anInt
{
  [super setIntValue:anInt];
  if ( frame_cb != 0 )
    frame_val = (int)[mtarget performSelector:frame_cb 
				   withObject:(id)[self intValue]];
}


@end
