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
#import "PlaylistEditor.h"
#import "PlaylistEntry.h"
#import "UserInterface.h"
#import "Control.h"
#import "MXAConfig.h"

@implementation PlaylistEditor


- (unsigned int)getNumberRowsInTable
{
  NSRange range;
  NSRect frame;

  frame = [tableView frame];
  //NSLog(@"%f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width,
  //frame.size.height);

  frame = [tableScrollView frame];
  range = [tableView rowsInRect:frame];
  return range.length - range.location ;
}

- (void)updateInfo
{
  int start, rows = [self getNumberRowsInTable];

  start = [[tableScrollView verticalScroller] floatValue]
    * (float)([Control getPlaylistLength]-rows);

  [Control updatePlaylistInfoInThread:start :start+rows :tableView];
}

- (void)scrollAction:sender
{
  [oldScrollerTarget performSelector:oldScrollerAction withObject:sender];
  [self updateInfo];
}

- (void)awakeFromNib
{
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(songStarted:)
	   name:SongStartedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(playlistChanged:)
	   name:PlaylistChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(playlistChanged:)
	   name:NewPlaylistNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(selectionChanged:)
	   name:PlaylistSelectionChangedNotification
	 object:nil];

  [tableView setDoubleAction:@selector(tableViewDoubleAction:)];
  [tableView setAutosaveName:@"PlaylistEditor"];

  /*
  [window setFrameAutosaveName:@"PlaylistEditor"];
  [[self window] registerForDraggedTypes:
		   [NSArray arrayWithObject:NSFilenamesPboardType]];
  */

  {
    NSScroller *scroller;
    scroller = [tableScrollView verticalScroller];
    oldScrollerAction = [scroller action];
    oldScrollerTarget = [scroller target];
    [scroller setTarget:self];
    [scroller setAction:@selector(scrollAction:)];
  }
      
  [tableView scrollRowToVisible:[Control getPlaylistPosition]];
  [self updateInfo];
}

- (void)tableViewAction:sender
{
}

- (void)tableViewDoubleAction:sender
{
  if ( [sender selectedRow] != -1 ) 
    {
      //FIXME: need a control method
      [config setplaylist_position:[sender selectedRow]];
      [Control play];
    }
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [Control getPlaylistLength];
}

- (id)tableView:(NSTableView *)tableView 
   objectValueForTableColumn:(NSTableColumn *)tableColumn 
	    row:(int)row
{
  NSString *val;
  PlaylistEntry *entry = [Control getPlaylistEntryAt:row];

  
  if ( [[tableColumn identifier] isEqualToString:@"title"] )
    {
      val = [entry title];
      if( val == nil ) 
	{
	  val = [[entry filename] lastPathComponent];
	}
      if ( [config show_numbers_in_pl] )
	val = [NSString stringWithFormat:@"%d. %@", row+1, val];
    }
  else
    {
      if ( [entry length] != -1 ) 
	{
	  val = [NSString stringWithFormat:@"%d:%-2.2d",
			  [entry length]/60000,
			  ([entry length]/1000)%60];
	}
      else
	val = @"";
    }
  return val;
}

- (void)songStarted:(NSNotification *)notification
{
  if ( [[self window] isVisible] )
    {
      [tableView scrollRowToVisible:[Control getPlaylistPosition]];
      [tableView setNeedsDisplay:YES];
    }
}

- (void)playlistChanged:(NSNotification *)notification
{
  if ( [[self window] isVisible] )
    [tableView reloadData];
}

- (void)updateSelection
{
  int i;

  [tableView deselectAll:self];
  
  for ( i = 0; i < [Control getPlaylistLength]; i++ )
    {
      PlaylistEntry *entry = [Control getPlaylistEntryAt:i];
      if ( [entry selected] )
	[tableView selectRow:i byExtendingSelection:i != 0];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
  NSEnumerator *e;
  NSNumber *idx;
  NSMutableArray *array = [NSMutableArray array];

  if ( disableSelectionNotification == NO )
    {
      disableSelectionNotification = YES;

      e = [tableView selectedRowEnumerator];
      
      while ( (idx = [e nextObject]) != nil )
	{
	  [array addObject:idx];
	}
      
      [Control selectPlaylistEntriesWithIndexes:array];

      disableSelectionNotification = NO;
    }
}

- (void)selectionChanged:(NSNotification *)notification
{
  if ( [[self window] isVisible] && disableSelectionNotification == NO )
    {
      disableSelectionNotification = YES;
      [self updateSelection];
      disableSelectionNotification = NO;
    }
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
  return NSDragOperationCopy;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
  return [self draggingUpdated:sender];
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  NSArray *files;
  
  files = [pb propertyListForType:NSFilenamesPboardType];

  if ( [files count] ) 
    {
      [Control addFilesToPlaylist:files];
      //FIXME: Control interface...
      [Input playFile:[files objectAtIndex:0]];
    }

  return YES;
}

- (void)tableView:(NSTableView *)tableView 
  willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn *)tableColumn 
	      row:(int)row
{
  if ( row == [Control getPlaylistPosition] )
    [cell setTextColor:[NSColor selectedMenuItemColor]];
  else
    [cell setTextColor:[NSColor controlTextColor]];
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

@end
