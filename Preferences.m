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

#import <MXA/Common.h>
#import "Preferences.h"
#import <AppKit/AppKit.h>
#import <MXA/MXAConfig.h>
#import <MXA/UserInterface.h>
#import "AppDelegate.h"
#import "TabView.h"
#import "PluginPreference.h"

@implementation Preferences

- (void)setupPreferences
{
  generalView = [tabView tab1];
  inputView = [tabView tab2];

  [self fillPluginLists];
  [self fillUIPopup];

  [input_p setPluings:[Input plugins]];
  [effect_p setPluings:[Effect plugins]];
  [general_p setPluings:[General plugins]];
  [vis_p setPluings:[Visualization plugins]];
}

- (void)updateDisplay
{
  [slowCPU setState:[config slow_cpu]];
  [defaultExtension setStringValue:[config default_extension]];
}

- (void)awakeFromNib
{
  [self setupPreferences];
}

- (void)show:sender
{
  orig_ui = [UserInterface ui];
  [super show:sender];
}

- (void)ok:sender
{
  [window orderOut:self];
  [Output updateOutputPlugin];

  [config setslow_cpu:[slowCPU state]];
  [config setdefault_extension:[defaultExtension stringValue]];

  [UserInterface updateSelectedUIPlugin];
  if ( orig_ui != [UserInterface ui] )
    {
      [[NSApp delegate] changeUI:orig_ui];
    }

  [config save_config];
}

- (void)configureOutputPlugin:sender
{
  int sel = [o_plugin_popup indexOfSelectedItem];
  
  if ( sel != -1 )
    [[[Output plugins] objectAtIndex:sel] configure];
}

- (void)aboutOutputPlugin:sender
{
  int sel = [o_plugin_popup indexOfSelectedItem];
  
  if ( sel != -1 )
    [[[Output plugins] objectAtIndex:sel] about];
}

- (void)o_plugin_action:sender
{
  int sel, i;
  sel = [o_plugin_popup indexOfSelectedItem];
  
  if ( sel != -1 ) {
    for ( i = 0;i < [[Output plugins] count]; i++ )
      {
	Output *plugin = [[Output plugins] objectAtIndex:i];
	[plugin setEnabled:sel == i];
	if ( sel == i )
	  {
	    [[o_button_matrix cellWithTag:0] setEnabled:[plugin hasConfigure]];
	    [[o_button_matrix cellWithTag:1] setEnabled:[plugin hasAbout]];
	  }
      }
  }
}

- (void)fillPluginLists
{
  NSArray *outputs;
  Output *plugin;
  int i;

  outputs = [Output plugins];
  [o_plugin_popup removeAllItems];

  for ( i = 0; i < [outputs count]; i++ ) {
    plugin = [outputs objectAtIndex:i];
    [o_plugin_popup addItemWithTitle:[plugin description]];
    [[o_plugin_popup itemAtIndex:i] setTag:i];
    if ( [plugin enabled] ) {
      [o_plugin_popup selectItemAtIndex:i];
      [[o_button_matrix cellWithTag:0] setEnabled:[plugin hasConfigure]];
      [[o_button_matrix cellWithTag:1] setEnabled:[plugin hasAbout]];
    }
  }

  [o_plugin_popup synchronizeTitleAndSelectedItem];
}

- (void)fillUIPopup
{
  NSArray *uis;
  UserInterface *plugin;
  int i;

  uis = [UserInterface plugins];
  [ui_popup removeAllItems];

  for ( i = 0; i < [uis count]; i++ ) 
    {
    plugin = [uis objectAtIndex:i];
    [ui_popup addItemWithTitle:[plugin description]];
    [[ui_popup itemAtIndex:i] setTag:i];
    if ( [plugin enabled] ) 
      {
	[ui_popup selectItemAtIndex:i];
	[ui_config setEnabled:[plugin hasConfigure]];
	[ui_about setEnabled:[plugin hasAbout]];
      }
    }
  
  [ui_popup synchronizeTitleAndSelectedItem];
}

- (void)configureUI:sender
{
  int sel = [ui_popup indexOfSelectedItem];
  
  if ( sel != -1 )
    {
      [[[UserInterface plugins] objectAtIndex:sel] configure];
    }
}

- (void)aboutUI:sender
{
  int sel = [ui_popup indexOfSelectedItem];
  
  if ( sel != -1 )
    [[[UserInterface plugins] objectAtIndex:sel] about];
}

- (void)uiAction:sender
{
  int sel, i;
  sel = [ui_popup indexOfSelectedItem];
  
  if ( sel != -1 ) 
    {
      for ( i = 0;i < [[UserInterface plugins] count]; i++ )
	{
	  UserInterface *pl = [[UserInterface plugins] objectAtIndex:i];
	  [pl setEnabled:sel == i];
	  if ( sel == i )
	    {
	      [ui_config setEnabled:[pl hasConfigure]];
	      [ui_about setEnabled:[pl hasAbout]];
	    }
	}
    }
}


@end

