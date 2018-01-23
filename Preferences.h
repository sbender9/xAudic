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
#import <MXA/NibObject.h>

@class Config;
@class UserInterface;

@interface Preferences : NibObject
{
  id tabView;

  id generalView;
  id inputView;

  Config *tmp_config;

  id ui_popup;
  id ui_config;
  id ui_about;

  id o_plugin_popup;
  id o_button_matrix;

  id input_p;
  id effect_p;
  id general_p;
  id vis_p;

  id slowCPU;
  id defaultExtension;

  UserInterface *orig_ui;
}

- (void)ok:sender;

- (void)configureUI:sender;
- (void)aboutUI:sender;
- (void)uiAction:sender;

- (void)configureOutputPlugin:sender;
- (void)aboutOutputPlugin:sender;

- (void)o_plugin_action:sender;

- (void)fillPluginLists;
- (void)fillUIPopup;


@end


