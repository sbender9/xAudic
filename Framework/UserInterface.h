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

#import "Plugins.h"

@class NSMenuItem;

@class NSMutableArray;

@interface UserInterface : Plugin
{
  NSMutableArray *addedOptionMenuItems;
  NSMutableArray *addedWindowMenuItems;
}

+ (void)registerPlugin:(Plugin *)op;
+ (NSArray *)plugins;
+ (UserInterface *)ui;
+ (void)updateSelectedUIPlugin;

- (void)addOptionMenuItem:(NSMenuItem *)item;
- (void)addWindowMenuItem:(NSMenuItem *)item;
- (BOOL)enabledByDefault;

- (void)run;
- (void)stop;

- (void)vis_timeout:(unsigned char *)data;
- (void)vis_clear;
- (unsigned char (*)[24][3])getVisualizationColors;

- (void)setInfoText:(NSString *)string;
- (void)lockInfoText:(NSString *)string;
- (void)unlockInfoText;
- (void)updateInfoText;

- (void)eject:sender;
- (void)play:sender;
- (void)stop:sender;
- (void)pause:sender;
- (void)next:sender;
- (void)previous:sender;

- (void)toggleShuffle:sender;
- (void)toggleRepeat:sender;
- (void)toggleNoPlaylistAdvance:sender;

- (void)showRemainingTime:sender;
- (void)showElapsedTime:sender;

- (void)volume_slider:sender;
- (void)songposition_slider:sender;
- (void)shuffle:sender;
- (void)repeat:sender;

- (void)playlistRemoveAll:sender;
- (void)playlistCropSelection:sender;
- (void)playlistRemoveSelected:sender;
- (void)playlistZeroSelection:sender;
- (void)playlistInvertSelection:sender;
- (void)playlistSelectAll:sender;
- (void)playlistNew:sender;
- (void)playlistSave:sender;
- (void)playlistAddURL:sender;
- (void)playlistAddDir:sender;
- (void)playlistAddFile:sender;
- (void)playlistOpen:sender;

- (void)playlistReverse:sender;
- (void)playlistRandomize:sender;
- (void)playlistSortByPathPlusFileName:sender;
- (void)playlistSortByFilename:sender;
- (void)playlistSortByTitle:sender;

- (void)showFileInfoBox:sender;
- (void)openFilePanel:sender;
- (BOOL)savePlaylist;

@end
