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
#import "EqSlider.h"
#import "Button.h"
#import "EqSliderCell.h"

@implementation EqSlider

- (int)band
{
  return band;
}

- (float)position
{
  return 20.0-(((float)([self maxValue]-[self intValue])*20.0)/25.0);
}

- (void)setPosition:(float)pos
{
  int val;
  
  val=25-(int)((pos*25.0)/20.0);
  if ( val < 0 ) 
    val = 0;
  if ( val > 50)
    val = 50;
  if ( val >= 24 && val <= 26) 
    val = 25;
  [self setIntValue:[self maxValue]-val];
  [self setNeedsDisplay:YES];
}
  

- (void)action:sender
{
  EqSliderCell *acell = [self cell];
  [acell handleAction];

  if ( motion_cb != 0 )
    [target performSelector:motion_cb withObject:self];
}

- initWithPos:(NSPoint)pos band:(int)_band target:atarget cb:(SEL)_motion_cb
{
  NSRect frame;
  EqSliderCell *acell;

  target = atarget;
  motion_cb = _motion_cb;
  band = _band;
  frame.origin = pos;
  frame.size = NSMakeSize(14, 63);
  
  [super initWithFrame:frame];

  acell = [[EqSliderCell alloc] initCell:frame];
  
  [self setCell:acell];
  [self setTarget:self];
  [self setAction:@selector(action:)];

  [self setMinValue:0];
  [self setMaxValue:50];
  return self;
}

- (void)setIntValue:(int)anInt
{
  [super setIntValue:anInt];
  [self setNeedsDisplay:YES];
}

@end
