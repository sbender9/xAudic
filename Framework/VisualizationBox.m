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

#import <Foundation/Foundation.h>
#import <AppKit/NSWindow.h>
#import "VisualizationBox.h"
#import "Visualization.h"
#import "Control.h"

@implementation VisualizationBox

- (void)removeVisualization
{
  if ( plugin != nil )
    {
      [plugin removeView:view];

      if ( [view superview] != nil )
	[view removeFromSuperview];
      
      [view release];
      view = nil;
    }

  [plugin release];
  plugin= nil;
}

- (void)loadVisualization
{
  [self removeVisualization];

  plugin = [Visualization defaultVisualization];
  if ( plugin != nil && [plugin canEmbed] )
    {
      NSRect frame = [self frame];
      frame.origin.x = 0;
      frame.origin.y = 0;
      frame = [plugin visFrameForRect:frame];
      view = [plugin getViewWithFrame:frame owner:self];
      [view retain];
      [self addSubview:view];
      [plugin retain];
    }
  else
    plugin = nil;
}

- (void)visTypeChanged:(NSNotification *)notification
{
  [self loadVisualization];
}

- (void)uiWindowDidShow:(NSNotification *)notification
{
  [plugin start]; //let the plugin now we're now visible
}

- (void)dealloc
{
  [self removeVisualization];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(visTypeChanged:)
	   name:DefaultVisualizationChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(uiWindowDidShow:)
	   name:UIWindowDidShow
	 object:nil];

  [self loadVisualization];
}

@end
