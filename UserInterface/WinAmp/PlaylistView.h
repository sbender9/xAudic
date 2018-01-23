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
#import <AppKit/NSView.h>
#import "PlaylistList.h"
#import "MainWindow.h"

@class Button;
@class TextBox;
@class MenuRow;
@class Slider;
@class MonoStereo;
@class Number;
@class EqGraph;
@class EqSlider;
@class NSPopUpButton;
@class Visualization;

@interface PlaylistView : WAView
{
  TextBox *info;
  TextBox *sinfo;
  Button *shade;
  Button *close;
  PlaylistList *playlistList;
  TextBox *time_min;
  TextBox *time_sec;
  Button *srew;
  Button *splay;
  Button *sstop;
  Button *sfwd;
  Button *seject;
  Button *sscroll_up;
  Button *sscroll_down;
  Button *spause;
  Slider *slider;
  NSPopUpButton *add_popup;
  NSPopUpButton *sub_popup;
  NSPopUpButton *misc_popup;
  NSPopUpButton *plist_popup;
  NSPopUpButton *sel_popup;
  Visualization *vis;
}

- (void)updateShaded:(BOOL)val updatePos:(BOOL)updatePos;

- (void)setTime:(int)time length:(int)length;

- (void)update_info;
- (void)update_sinfo;

@end

