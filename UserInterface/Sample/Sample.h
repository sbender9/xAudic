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

#import <MXA/UserInterface.h>


@class NSWindow;
@class NSTimer;
@class NSView;
@class PlaylistEditor;
@class Visualization;

@interface Sample : UserInterface
{
  id mainWindow;

  id title;
  id time;
  id volume;
  id bit_rate;
  id sample_rate;
  id stereo;
  id shuffle;
  id repeat;
  id song_position;
  id pause;
  id visbox;
  id playlistbox;

  NSView *visView;
  Visualization *visPlugin;
  PlaylistEditor *editor;

  NSTimer *timer;
  BOOL nibLoaded;
}
@end
