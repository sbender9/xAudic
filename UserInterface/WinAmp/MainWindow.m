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
#import "MainWindow.h"
#import <MXA/Common.h>
#import <MXA/Plugins.h>
#import <MXA/PlaylistEntry.h>
#import "Configure.h"
#import "Skin.h"
#import "WinAmp.h"
#import "EqView.h"

@implementation MainWindow

- (id)initWithContentRect:(NSRect)contentRect 
		styleMask:(unsigned int)aStyle 
		  backing:(NSBackingStoreType)bufferingType 
		    defer:(BOOL)flag
		     name:(NSString *)_name
{
  [super initWithContentRect:contentRect 
		   styleMask:aStyle 
		     backing:bufferingType 
		       defer:flag];
  [self setAcceptsMouseMovedEvents:YES];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(keyWindow:)
	   name:NSWindowDidBecomeKeyNotification
	 object:self];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(keyWindow:)
	   name:NSWindowDidResignKeyNotification
	 object:self];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(thingsChanged:)
	   name:SkinChangedNotification
	 object:nil];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(thingsChanged:)
	   name:PreferencesChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(windowDidMove:)
	   name:NSWindowDidMoveNotification
	 object:self];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(windowDidResize:)
	   name:NSWindowDidResizeNotification
	 object:self];

  /*
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(windowDidExposeNotification:)
	   name:NSWindowDidExposeNotification
	 object:nil];
  */

  name = [_name retain];

  //[self setFrameAutosaveName:name];
  [self setFrameUsingName:name];

  [self updateAlwaysOnTop];

  [self registerForDraggedTypes:
       [NSArray arrayWithObject:NSFilenamesPboardType]];

  return self;
}

- (void)windowDidMove:(NSNotification *)notification
{
  //NSLog(@"windowDidMove: %@", name);
  [self saveFrame];
}

- (void)windowDidResize:(NSNotification *)notification
{
  //NSLog(@"windowDidResize: %@", name);
  [self saveFrame];
}

- (void)dealloc
{
  [name release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (void)keyDown:(NSEvent *)theEvent
{
  NSString *chars = [theEvent charactersIgnoringModifiers];

  if ( [chars characterAtIndex:0] == ' ' )
    [[WinAmp instance] pause:self];
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

- (void)addFilesToPlaylist:(NSArray *)files
{
  if ( [files count] ) 
    {
      [Playlist addFiles:files];
      [Input playFile:[files objectAtIndex:0]];
    }
  [files release];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  NSArray *files;
  
  files = [pb propertyListForType:NSFilenamesPboardType];

  NSLog(@"%p", files);

  [self performSelector:@selector(addFilesToPlaylist:)
	withObject:[files retain]
	afterDelay:1];

  return YES;
}

- (void)keyWindow:notification
{
  [[self contentView] setNeedsDisplay:YES];
}

- (BOOL)canBecomeKeyWindow
{
  return YES;
}

- (void)updateAlwaysOnTop
{
  if ( [config boolValueForKey:always_on_top] && [self level] != 1 )
    [self setLevel:1];
  else if ( [config boolValueForKey:always_on_top] == NO && [self level] != NSNormalWindowLevel)
    [self setLevel:NSNormalWindowLevel];
}

- (void)thingsChanged:(NSNotification *)notification
{
  [self updateAlwaysOnTop];
  [self display];
}

- (NSString *)name
{
  return name;
}

- (void)saveFrame
{
  [self saveFrameUsingName:name];
}

@end


@implementation WAView

- (BOOL)isDockedTo:(WAView *)view
{
  if ( [self isVisible] && [view isVisible] )
    {
      NSRect myFrame = [[view window] frame];
      NSRect hisFrame = [[self window] frame];
      if ( myFrame.origin.x != hisFrame.origin.x 
	   || myFrame.origin.y != hisFrame.origin.y )
	{
	  return is_docked(myFrame.origin.x, myFrame.origin.y,
			   myFrame.size.width, myFrame.size.height,
			   hisFrame.origin.x, hisFrame.origin.y,
			   hisFrame.size.width, hisFrame.size.height);
	}
    }
  return NO;
}

- (BOOL)isDockedToBotton:(WAView *)view
{
  if ( [self isVisible] && [view isVisible] )
    {
      NSRect myFrame = [[self window] frame];
      NSRect hisFrame = [[view window] frame];
      if ( myFrame.origin.x != hisFrame.origin.x 
	   || myFrame.origin.y != hisFrame.origin.y )
	{
	  return myFrame.origin.y + myFrame.size.height == hisFrame.origin.y
	    && myFrame.origin.x >= hisFrame.origin.x-myFrame.size.width
	    && myFrame.origin.x <= hisFrame.origin.x+hisFrame.size.width;
	}
    }
  return NO;
}

- (BOOL)isVisible
{
  //[self  subclassResponsibility:@selector(isVisible)];
  return NO;
}

@end
