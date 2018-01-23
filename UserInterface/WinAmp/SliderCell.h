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
#import <AppKit/NSSliderCell.h>
#import "MySliderCell.h"

@interface SliderCell : MySliderCell
{
  NSRect frame;
  NSPoint knob_normal;
  NSPoint knob_pushed;
  NSSize knob_size;
  int frame_height;
  int frame_offset;
  int frame_val;
#if 0
  int min;
  int max;
#endif
  id mtarget;
  SEL imageSel;
  SEL frame_cb;
  SEL release_cb;
}

- (void)handleAction;

- initCell:(NSRect)frame
	  :(NSPoint)_knob_normal
	  :(NSPoint)_knob_pushed
	  :(NSSize)_knob_size
	  :(int)_frame_height
	  :(int)_frame_offset
	  :(int)_min
	  :(int)_max
	  :_target
	  :(SEL)frame_cb
	  :(SEL)release_cb
	  :(SEL)_imageSel;


@end
