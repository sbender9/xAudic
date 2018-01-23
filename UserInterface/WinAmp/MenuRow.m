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
#import "MenuRow.h"
#import "Button.h"
#import "Configure.h"
#import "Skin.h"

@implementation MenuRow

- (NSImage *)image
{
  return [currentSkin performSelector:imageSel];
}

- (BOOL)isOpaque
{
  return YES;
}

- (BOOL)isFlipped
{
  return YES;
}

- (void)drawRect:(NSRect)rect
{
  NSRect frame = [self frame];
  if ( selected_item == MENUROW_NONE) {
    if ( [config boolValueForKey:always_show_cb] )
      [[self image] 
	compositeToPoint:NSMakePoint(0,frame.size.height)
		fromRect:flipRect(NSMakeRect(normal.x, normal.y, 8, 43),
				  [self image])
	       operation:NSCompositeCopy];
    else
      [[self image] 
	compositeToPoint:NSMakePoint(0,frame.size.height)
		fromRect:flipRect(NSMakeRect(normal.x+8, normal.y, 8, 43),
				  [self image])
	       operation:NSCompositeCopy];
  } else {
    [[self image] 
      compositeToPoint:NSMakePoint(0,frame.size.height)
	      fromRect:flipRect(NSMakeRect(selected.x+((selected_item-1)*8), 
					   selected.y, 8, 43),
				[self image])
	     operation:NSCompositeCopy];
  }
  if ( [config boolValueForKey:always_show_cb] ) {
    if ( [config boolValueForKey:always_on_top] == YES  ) 
      [[self image] 
	compositeToPoint:NSMakePoint(0,18)
		fromRect:flipRect(NSMakeRect(selected.x+8,selected.y+10,
					     8, 8),
				  [self image])
	       operation:NSCompositeCopy];
  }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return YES;
}

- (BOOL)becomeFirstResponder
{
  return YES;
}

- (BOOL)resignFirstResponder
{
  return YES;
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (int)computeSelection:(NSPoint)p
{
  int sel = MENUROW_NONE;
  if ( p.x > 0 && p.x < 8 ) {
    if ( p.y >= 0 && p.y <= 10 )
      sel = MENUROW_OPTIONS;
    if ( p.y >= 10 && p.y <= 17) 
      sel = MENUROW_ALWAYS;
    if ( p.y >= 18 && p.y <= 25 ) 
      sel = MENUROW_FILEINFOBOX;
    if ( p.y >= 26 && p.y <= 33 ) 
      sel = MENUROW_DOUBLESIZE;
    if( p.y >= 34 && p.y <= 42 ) 
      sel = MENUROW_VISUALIZATION;
  }
  return sel;
}

- (void)mouseDown:(NSEvent *)theEvent
{
  NSPoint p;
  int sel, lsel = -1;

  p = [self convertPoint:[theEvent locationInWindow] fromView:nil];

  selected_item = sel = [self computeSelection:p];

  if ( sel != MENUROW_NONE ) {
    [self setNeedsDisplay:YES];
    if (selected_item == MENUROW_OPTIONS 
	|| selected_item == MENUROW_VISUALIZATION ) {
      if ( action != 0 && target != nil ) 
	[target performSelector:action withObject:self];
    } else {
      while (1) {
	theEvent = [[self window] nextEventMatchingMask:
		     (NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
	p = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	if ( [self computeSelection:p] != sel )
	  selected_item = MENUROW_NONE;
	else
	  selected_item = sel;
	if ( selected_item != lsel )
	[self setNeedsDisplay:YES];
	lsel = selected_item;

	if ([theEvent type] == NSLeftMouseUp)
	  break;
      }
      if ( action != 0 && target != nil && selected_item != MENUROW_NONE )
	[target performSelector:action withObject:self];

      selected_item = MENUROW_NONE;
      [self setNeedsDisplay:YES];
    }
  }
}

- (void)mouseUp:(NSEvent *)theEvent
{
}

- initWithPoint:(NSPoint)pos 
	       :(NSPoint)_normal 
	       :(NSPoint)_selected
	       :_target 
  	       :(SEL)_action
	       :(SEL)_imageSel
{
  NSRect frame;
  frame.origin = pos;
  frame.size = NSMakeSize(8, 43);
  [super initWithFrame:frame];
  imageSel = _imageSel;
  normal = _normal;
  selected = _selected;
  target = _target;
  action = _action;
  return self;
}

- (int)selectedMenuItem
{
  return selected_item;
}

- (void)clearSelection
{
  selected_item = MENUROW_NONE;
  [self setNeedsDisplay:YES];
}

@end
