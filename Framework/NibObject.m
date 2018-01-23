/*  
 *  xAudic - an audio player for MacOS X
 *  Copyright (C) 1999  Scott P. Bender (sbender@harmony-ds.com)
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
#import "NibObject.h"
#import <AppKit/AppKit.h>
#import "MXAConfig.h"

@implementation NibObject

- initWithNibName:(NSString *)name
{
  return [self initWithNibName:name bundle:nil];
}

- initWithNibName:(NSString *)name bundle:(NSBundle *)_bundle
{
  nibName = [name retain];
  bundle = _bundle;
  return [super init];
}

-(void)updateDisplay
{
}

- (BOOL)loadNib
{
  if ( nibLoaded == NO ) 
    {
      BOOL res;
      if (bundle != nil ) 
	{
	  NSMutableDictionary *context = [NSMutableDictionary dictionary];
	  [context setObject:self forKey:@"NSOwner"];
	  res = [bundle loadNibFile:[self nibName]
			externalNameTable:context
			withZone:[self zone]];
	} 
      else
	res = [NSBundle loadNibNamed:[self nibName] owner:self];    
      nibLoaded = res;
    
      if ( res == NO ) 
	{
	  NSLog(@"%@: error loading nib named '%@' for class '%@'",
		getPackageName(), [self nibName], 
		NSStringFromClass([self class]));
	  return NO;
	}
    }
  return YES;
}

- (void)show:sender
{
  if ( [self loadNib] == NO )
    return;

  if ( window == nil ) 
    {
      NSLog(@"%@: nib '%@' is not configured properly, window == nil",
	    getPackageName(), [self nibName]);
      return;
    }

  /*
    FIXME
  if ( [config boolValueForKey:always_on_top] )
    [window setLevel:2];
  else
    [window setLevel:NSNormalWindowLevel];
  */

  [self updateDisplay];

  [window makeKeyAndOrderFront:self];
}

- (void)show
{
  [self show:self];
}

- (NSString *)nibName
{
  return nibName != nil ? nibName : NSStringFromClass([self class]);
}

- (void)setNibName:(NSString *)name
{
  [nibName release];
  nibName = [name retain];
}

- (void)ok:sender
{
  [window orderOut:self];  
}

- (void)cancel:sender
{
  [window orderOut:self];  
}

- (NSWindow *)window
{
  return window;
}

@end
