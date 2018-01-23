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

#import "UITie.h"
#import "UserInterface.h"

@implementation UITie

- init
{
  return [super init];
}

- (void)eject:sender
{
  [[UserInterface ui] eject:sender];
}

- (void)play:sender
{
  [[UserInterface ui] play:sender];
}

- (void)stop:sender
{
  [[UserInterface ui] stop:sender];
}

- (void)pause:sender
{
  [[UserInterface ui] pause:sender];
}

- (void)next:sender
{
  [[UserInterface ui] next:sender];
}

- (void)previous:sender
{
  [[UserInterface ui] previous:sender];
}


- (void)volume_slider:sender
{
  [[UserInterface ui] volume_slider:sender];
}

- (void)songposition_slider:sender
{
  [[UserInterface ui] songposition_slider:sender];
}

- (void)shuffle:sender
{
  [[UserInterface ui] shuffle:sender];
}

- (void)repeat:sender
{
  [[UserInterface ui] repeat:sender];
}


- (void)playlistRemoveAll:sender
{
  [[UserInterface ui] playlistRemoveAll:sender];
}

- (void)playlistCropSelection:sender
{
  [[UserInterface ui] playlistCropSelection:sender];
}

- (void)playlistRemoveSelected:sender
{
  [[UserInterface ui] playlistRemoveSelected:sender];
}

- (void)playlistZeroSelection:sender
{
  [[UserInterface ui] playlistZeroSelection:sender];
}

- (void)playlistInvertSelection:sender
{
  [[UserInterface ui] playlistInvertSelection:sender];
}

- (void)playlistSelectAll:sender
{
  [[UserInterface ui] playlistSelectAll:sender];
}

- (void)playlistNew:sender
{
  [[UserInterface ui] playlistNew:sender];
}

- (void)playlistSave:sender
{
  [[UserInterface ui] playlistSave:sender];
}

- (void)playlistAddURL:sender
{
  [[UserInterface ui] playlistAddURL:sender];
}

- (void)playlistAddDir:sender
{
  [[UserInterface ui] playlistAddDir:sender];
}

- (void)playlistAddFile:sender
{
  [[UserInterface ui] playlistAddFile:sender];
}

- (void)playlistOpen:sender
{
  [[UserInterface ui] playlistOpen:sender];
}

- (void)playlistReverse:sender
{
  [[UserInterface ui] playlistReverse:sender];
}

- (void)playlistRandomize:sender
{
  [[UserInterface ui] playlistRandomize:sender];
}

- (void)playlistSortByPathPlusFileName:sender
{
  [[UserInterface ui] playlistSortByPathPlusFileName:sender];
}

- (void)playlistSortByFilename:sender
{
  [[UserInterface ui] playlistSortByFilename:sender];
}

- (void)playlistSortByTitle:sender
{
  [[UserInterface ui] playlistSortByTitle:sender];
}


- (void)showFileInfoBox:sender
{
  [[UserInterface ui] showFileInfoBox:sender];
}

- (void)toggleShuffle:sender
{
  [[UserInterface ui] toggleShuffle:sender];
}

- (void)toggleRepeat:sender
{
  [[UserInterface ui] toggleRepeat:sender];
}

- (void)toggleNoPlaylistAdvance:sender
{
  [[UserInterface ui] toggleNoPlaylistAdvance:sender];
}

- (void)showRemainingTime:sender
{
  [[UserInterface ui] showRemainingTime:sender];
}

- (void)showElapsedTime:sender
{
  [[UserInterface ui] showElapsedTime:sender];
}

- (void)openFilePanel:sender
{
  [[UserInterface ui] openFilePanel:sender];
}

@end
