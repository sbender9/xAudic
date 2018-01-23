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
#import "PluginPreference.h"
#import <MXA/Plugins.h>
#import <MXA/Visualization.h>

@implementation PluginPreference

- (void)awakeFromNib
{
  [browser setDoubleAction:@selector(browser_doubleaction:)];
}

- (void)setPluings:(NSArray *)_plugins
{
  plugins = _plugins;
}


- (void)enabled:sender
{
  int sel = [browser selectedRowInColumn:0];
  
  if ( sel != -1 )
    [[plugins objectAtIndex:sel] setEnabled:[sender state]];
}


- (void)configure:sender
{
  int sel = [browser selectedRowInColumn:0];
  
  if ( sel != -1 )
    [[plugins objectAtIndex:sel] configure];
}

- (void)about:sender
{
  int sel = [browser selectedRowInColumn:0];
  
  if ( sel != -1 )
    [[plugins objectAtIndex:sel] about];
}

- (void)start:sender
{
  int sel = [browser selectedRowInColumn:0];
  
  if ( sel != -1 )
    [[plugins objectAtIndex:sel] startInWindow];
}

- (void)stop:sender
{
  int sel = [browser selectedRowInColumn:0];
  
  if ( sel != -1 )
    [((Visualization *)[plugins objectAtIndex:sel]) stopInWindow];
}

- (void)browser_action:sender
{
  int sel = [sender selectedRowInColumn:0];
  if ( sel != -1 )
    {
      Plugin *plugin;
      plugin = [plugins objectAtIndex:sel];
      if ( enabled_box != nil )
	{
	  [enabled_box setEnabled:YES];
	  [enabled_box setState:[plugin enabled]];
	}
      [[button_matrix cellWithTag:0] setEnabled:[plugin hasConfigure]];
      [[button_matrix cellWithTag:1] setEnabled:[plugin hasAbout]];
      [[button_matrix cellWithTag:2] setEnabled:YES];
      [[button_matrix cellWithTag:3] setEnabled:YES];
    }
  else
    {
      [enabled_box setEnabled:NO];
      [[button_matrix cellWithTag:0] setEnabled:NO];
      [[button_matrix cellWithTag:1] setEnabled:NO];
      [[button_matrix cellWithTag:2] setEnabled:NO];
      [[button_matrix cellWithTag:3] setEnabled:NO];
    }
}

- (void)browser_doubleaction:sender
{
  [self configure:sender];
}

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
  return [plugins count];
}

- (void)browser:(NSBrowser *)sender 
willDisplayCell:(id)cell 
	  atRow:(int)row 
	 column:(int)column
{
  Plugin *plugin;
  plugin = [plugins objectAtIndex:row];
  [cell setStringValue:[plugin description]];
  [cell setLeaf:YES];
}


@end
