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
#import "PlaylistPopup.h"
#import "Skin.h"
#import "Button.h"

@implementation PlaylistPopup

- (void)drawRect:(NSRect)rect
{
  if ( popped ) {
    NSImage *image = [currentSkin pledit];
    int i;
    NSRect frame = [self frame];

    [image
      compositeToPoint:NSMakePoint(0,0)
	      fromRect:flipRect(NSMakeRect(barx, bary, 3, num_items*18),image)
	     operation:NSCompositeCopy];
    for ( i = 0; i < num_items; i++ ) {
      if( i == active_item )
	[image
	  compositeToPoint:NSMakePoint(3, frame.size.height-(i*18)-18)
		  fromRect:flipRect(NSMakeRect(sx[i], sy[i], 22, 18), image)
		 operation:NSCompositeCopy];
      else
	[image
	  compositeToPoint:NSMakePoint(3, frame.size.height-(i*18)-18)
		  fromRect:flipRect(NSMakeRect(nx[i], ny[i], 22, 18), image)
		 operation:NSCompositeCopy];
    }
  }
}

- (int)itemForPoint:(NSPoint)point
{
  NSRect frame = [self frame];
  int i;
  
  if ( point.x >= 0 && point.x < frame.size.width 
    && point.y >= 0 && point.y < frame.size.height ) {
    for ( i = 0; i < num_items; i++ ) {
      if ( point.y >= (i*18) && point.y < (i*18)+18 )
	return num_items - i - 1;
    }
  }
  return -1;
}

- (void)mouseDown:(NSEvent *)theEvent
{
  NSPoint p;
  NSRect frame;
  int orig_height, orig_y, last_item = -1, sel_item;
  
  popped = YES;
  active_item = num_items-1;
  frame = [self frame];
  orig_height = frame.size.height;
  orig_y = frame.origin.y;
  frame.size.height = num_items*18;
  frame.origin.y -= (num_items*18) - 18;
  [self setFrame:frame];
  [self setNeedsDisplay:YES];

  while ( 1 ) {
    theEvent = [[self window] nextEventMatchingMask:
		 (NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
    p = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    active_item = [self itemForPoint:p];
    if ( active_item != last_item ) 
      [self setNeedsDisplay:YES];
    last_item = active_item;

    if ([theEvent type] == NSLeftMouseUp)
      break;
  }

  popped = NO;
  sel_item = active_item;
  active_item = -1;
  frame.size.height = orig_height;
  frame.origin.y = orig_y;
  [self setFrame:frame];
  [self setNeedsDisplay:YES];
  [[self superview] setNeedsDisplay:YES];

  if ( sel_item != -1 && target != 0 && actions[sel_item] != 0  ) {
    [target performSelector:actions[num_items-sel_item-1]];
  }
}

- (void)mouseUp:(NSEvent *)theEvent
{
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


- initWithPos:(NSPoint)pos
	     :(int)_num_items
	     :(int *)_nx
	     :(int *)_ny
	     :(int *)_sx
	     :(int *)_sy
	     :(SEL *)_actions
	     :(int)_barx
	     :(int)_bary
	     :(id)_target
{
  NSRect frame;
  
  frame = NSMakeRect(pos.x, pos.y, 25, 18);
  [super initWithFrame:frame];
  num_items = _num_items;
  memcpy(nx, _nx, num_items*sizeof(int));
  memcpy(ny, _ny, num_items*sizeof(int));
  memcpy(sx, _sx, num_items*sizeof(int));
  memcpy(sy, _sy, num_items*sizeof(int));
  memcpy(actions, _actions, num_items*sizeof(SEL));
  barx = _barx;
  bary = _bary;

  target = _target;
  active_item = -1;
  
  return self;
}

@end
