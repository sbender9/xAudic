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
#import "PlayStatus.h"
#import "MainWindow.h"

@class Button;
@class TextBox;
@class MenuRow;
@class Slider;
@class MonoStereo;
@class Number;
@class PlayStatus;
@class NSMenuView;
@class Visualization;
@class VisualizationView;

@interface MainView : WAView
{
@public
  Button *menu;
  Button *minimize;
  Button *shade;
  Button *quit;
  Button *playlist_prev;
  Button *play;
  Button *pause;
  Button *stop;
  Button *fwd;
  Button *eject;
  Button *sprev;
  Button *splay;
  Button *spause;
  Button *sstop;
  Button *sfwd;
  Button *seject;
  Button *shuffle;
  Button *repeat;
  Button *playlist;
  Button *eq;

  TextBox *info_box;
  TextBox *freq_box;
  TextBox *rate_box;
  MenuRow *menurow;
  Slider *volume;
  Slider *balance;
  MonoStereo *monostereo;
  PlayStatus *playstatus;
  Number *minus_num;
  Number *tenmin_num;
  Number *min_num;
  Number *tensec_num;
  Number *sec_num;
  TextBox *stime_min;
  TextBox *stime_sec;

  Slider *posbar;
  Slider *sposbar;

  Visualization *visPlugin;
  VisualizationView *visView;

  Visualization *svisPlugin;
  VisualizationView *svisView;

  BOOL infoTextLocked;
  NSString *info_text;
}

- (void)setInfoText:(NSString *)string;
- (void)lockInfoText:(NSString *)string;
- (void)unlockInfoText;
- (void)updateInfoText;
- (void)loadVisualization;

- (void)setNumbers:(int)minus 
		  :(int)tenmin_num 
		  :(int)min_num 
		  :(int)tensec_num
		  :(int)sec_num;

- (void)setSNumbers:(NSString *)min :(NSString *)sec;

- (void)setRate:(int)rate
	  freq:(int)freq
   numChannels:(int)channels;

- (void)setPosbar:(int)val;
- (void)setSposbar:(int)val;

- (void)toggleShaded;

- (Button *)playlistButton;
- (Button *)eqButton;

+ (NSSize)calcSize;

@end
