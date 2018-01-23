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
#import "PlaylistSlider.h"
#import "Button.h"
#import "PlaylistSliderCell.h"

@implementation PlaylistSlider

- (void)action:sender
{
  if ( motion_cb != 0 )
    [target performSelector:motion_cb withObject:self];
}

- initWithParentFrame:(NSRect)pframe target:atarget cb:(SEL)_motion_cb;
{
  NSRect frame;
  PlaylistSliderCell *acell;

  motion_cb = _motion_cb;
  target = atarget;
  frame = NSMakeRect(pframe.size.width-15, 20,
		     8, pframe.size.height-58);
  
  [super initWithFrame:frame];

  acell = [[PlaylistSliderCell alloc] initCell:frame];
  
  [self setCell:acell];
  [self setTarget:self];
  [self setAction:@selector(action:)];

  return self;
}

#if 0
- (void)setIntValue:(int)anInt
{
  [super setIntValue:anInt];
  [self setNeedsDisplay:YES];
}
#endif

@end
