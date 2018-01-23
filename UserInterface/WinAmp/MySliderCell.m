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
#import "MySliderCell.h"

@implementation MySliderCell

- (BOOL)isSliding
{
  return isSliding;
}

- (BOOL)isVertical
{
  return isVertical;
}

- (void)setKnobSize:(NSSize)val
{
  knobSize = val;
}

- (int)knobThickness
{
  return [self isVertical] ? knobSize.height : knobSize.width;
}

- (void)setIntValue:(int)val
{
  value = val < max ? val : max;
  [[self controlView] setNeedsDisplay:YES];
}

- (int)intValue
{
  return value;
}

- (void)setDoubleValue:(double)val
{
  value = val < max ? val : max;
  [[self controlView] setNeedsDisplay:YES];
}

- (double)doubleValue
{
  return value;
}

- (void)setMinValue:(double)val
{
  min = val;
  if (value < min)
    [self setDoubleValue:min];
}

- (void)setMaxValue:(double)val
{
  max = val;
  if ( value > max )
    [self setDoubleValue:max];
}

- (double)minValue
{
  return min;
}

- (double)maxValue
{
  return max;
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped
{
}

- (void)drawKnob:(NSRect)knobRect
{
}

- (NSRect)calcKnobRect
{
  double barpos;
  NSRect knobRect;
  NSRect frame = [[self controlView] frame];

  knobRect.size = NSMakeSize(knobSize.width, knobSize.height);
  
  if ( [self isVertical] ) {
    barpos = max > 0  ? (max - [self doubleValue] - min) / (max - min) : 0;
    knobRect.origin.y = barpos * (frame.size.height-knobSize.height);
    knobRect.origin.x = (frame.size.width - knobSize.width)/2;
  } else {
    barpos =  max > 0 ? ([self doubleValue] - min) / (max - min) : 0;
    knobRect.origin.x = barpos * (frame.size.width-knobSize.width);
    knobRect.origin.y = (frame.size.height-knobSize.height)/2;
  }
  return knobRect;
}

- (int)pointToValue:(NSPoint)point
{
  double val;
  float pos, maxpos;
  NSRect frame = [[self controlView] frame];

  
  if ( [self isVertical] ) {
    pos = point.y - tracking_offset.y;
    maxpos = frame.size.height-knobSize.height;
    if ( pos > maxpos )
      pos = maxpos;
    else if ( pos < 0 )
      pos = 0;
    val = max - ((max - min) * (pos / maxpos));
  } else {
    pos = point.x - tracking_offset.x;
    maxpos = frame.size.width-knobSize.width;
    if ( pos > maxpos )
      pos = maxpos;
    else if ( pos < 0 )
      pos = 0;
    val = (max - min) * (pos / maxpos);
  }
  return val;
}


- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
  NSRect knobRect;
  
  knobRect = [self calcKnobRect];
  if ( startPoint.x >= knobRect.origin.x 
       && startPoint.y >= knobRect.origin.y
       && startPoint.x < (knobRect.origin.x+knobRect.size.width)
       && startPoint.y < (knobRect.origin.y+knobRect.size.height)) {
    if ( [self isVertical] )
      tracking_offset.y = startPoint.y - knobRect.origin.y;
    else
      tracking_offset.x = startPoint.x - knobRect.origin.x;
    isSliding = YES;
    return YES;
  } else {
    value = [self pointToValue:startPoint];
    [[self controlView] setNeedsDisplay:YES];
  }
  return NO;
}

- (BOOL)continueTracking:(NSPoint)lastPoint 
		      at:(NSPoint)currentPoint 
		  inView:(NSView *)controlView
{
  value = [self pointToValue:currentPoint];
  if ( [_target respondsToSelector:_action] )
    [_target performSelector:_action withObject:self];
  [[self controlView] setNeedsDisplay:YES];
  return YES;
}

- (void)stopTracking:(NSPoint)lastPoint 
		  at:(NSPoint)stopPoint 
	      inView:(NSView *)controlView 
	   mouseIsUp:(BOOL)flag
{
  isSliding = NO;
  [[self controlView] setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect )rect
{
  NSRect knobRect;
  
  [self drawBarInside:rect flipped:NO];
  knobRect = [self calcKnobRect];
  [self drawKnob:knobRect];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  if ( isVerticalSet == NO ) {
    isVertical = cellFrame.size.height > cellFrame.size.width;
    isVerticalSet = YES;
  }
  [controlView lockFocus];
  [self drawRect:cellFrame];
  [controlView unlockFocus];
}

#if 0
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  [controlView lockFocus];
  [self drawRect:cellFrame];
  [controlView unlockFocus];
}
#endif

@end
