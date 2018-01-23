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
#import <AppKit/NSPopUpButton.h>

#define MAX_ITEMS 4

@interface PlaylistPopup : NSView
{
  int num_items;
  int nx[MAX_ITEMS], ny[MAX_ITEMS], sx[MAX_ITEMS], sy[MAX_ITEMS];
  int barx, bary;
  SEL actions[MAX_ITEMS];
  id target;
  BOOL popped;
  int active_item;
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
	     :(id)target;

@end
