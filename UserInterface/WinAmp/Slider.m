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
#import "Slider.h"
#import "Button.h"
#import "SliderCell.h"

@implementation Slider

- (BOOL)isOpaque
{
  return YES;
}

- (void)action:sender
{
  SliderCell *acell = [self cell];
  [acell handleAction];
  if ( motion_cb != 0 )
    [target performSelector:motion_cb withObject:self];
}

- initWithFrame:(NSRect)frame 
	       :(NSPoint)_knob_normal
	       :(NSPoint)_knob_pushed
	       :(NSSize)_knob_size
	       :(int)_frame_height
	       :(int)_frame_offset
	       :(int)_min
	       :(int)_max
	       :_target
	       :(SEL)frame_cb
	       :(SEL)_motion_cb
	       :(SEL)release_cb
	       :(SEL)_imageSel
{
  SliderCell *acell;
  [super initWithFrame:frame];

  acell = [[SliderCell alloc] initCell:frame
				     :_knob_normal 
				     :_knob_pushed 
				     :_knob_size
				     :_frame_height
				     :_frame_offset
				     :_min
				     :_max
				     :_target
				     :frame_cb
				     :release_cb
				     :_imageSel];
  [self setCell:acell];
  [self setTarget:self];
  [self setAction:@selector(action:)];
  motion_cb = _motion_cb;
  target = _target;

  [self setMinValue:_min];
  [self setMaxValue:_max];
  return self;
}

@end
