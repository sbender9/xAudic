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

#import "UserInterface.h"
#import <AppKit/NSWindow.h>
#import <InterfaceBuilder/IBObjectProtocol.h>

@class NSTimer;
@class NSView;
@class PlaylistEditor;
@class Visualization;

@interface NibUserInterface : UserInterface <NSCoding>
{
  id window;

  id songTitle;
  id timeText;
  id volumeSlider;
  id bitRateText;
  id sampleRateText;

  id stereoText;
  id stereoCheckBox;
  id stereoRadioBox;

  id pauseButton;
  id stopButton;
  id playButton;
  id prevButton;
  id nextButton;

  id shuffleCheckBox;
  id repeatCheckBox;
  id songPositionSlider;

  NSString *nibFile;

  NSTimer *timer;

  BOOL noTitleBar;
  BOOL clickToMove;
  BOOL windowOpaque;
  NSColor *windowBackgroundColor;
  float windowAlpha;
  NSString *pluginName;

  BOOL buttonShowsBorderOnlyWhileMouseInside;
  BOOL buttonImageDimsWhenDisabled;
  int buttonHighlightsBy;
  int buttonShowsStateBy;
  int buttonOptionsApplyTo;
}

- init;
+ (void)loadPlugin:(NSString *)path;

- (void)setNoTitleBar:(BOOL)val;
- (BOOL)getNoTitleBar;

- (void)setClickAnywhereToMove:(BOOL)val;
- (BOOL)getClickAnywhereToMove;

- (void)setWindowBackgroundColor:(NSColor *)val;
- (NSColor *)getWindowBackgroundColor;

- (void)setWindowAlpha:(float)alpha;
- (float)getWindowAlpha;

- (void)setPluginName:(NSString *)name;
- (NSString *)getPluginName;

- (void)setWindowOpaque:(BOOL)vale;
- (BOOL)getWindowOpaque;

- (void)setButtonShowsBorderOnlyWhileMouseInside:(BOOL)val;
- (BOOL)getButtonShowsBorderOnlyWhileMouseInside;

- (void)setButtonImageDimsWhenDisabled:(BOOL)val;
- (BOOL)getButtonImageDimsWhenDisabled;

- (void)setButtonHighlightsBy:(int)val;
- (int)getButtonHighlightsBy;

- (void)setButtonShowsStateBy:(int)val;
- (int)getButtonShowsStateBy;

- (void)setButtonOptionsApplyTo:(int)mask;
- (int)getButtonOptionsApplyTo;

@end

//buttonOptionsApplyTo masks
enum
{
  BUTTON_PREV = 1,
  BUTTON_PAUSE = 2,
  BUTTON_PLAY = 4,
  BUTTON_STOP = 8,
  BUTTON_NEXT = 16
};


