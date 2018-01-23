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

#import "SSV.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSLock.h>
#import <stdlib.h>
#import "SSVConfigure.h"

@implementation BaseV

- (BOOL)hasConfigure
{
  return YES;
}

- (BOOL)isSizable
{
  return FALSE;
}

- (BOOL)containedOnly
{
  return TRUE;
}

- (BOOL)canEmbed
{
  return YES;
}

- (void)configure
{
  static SSVConfigure *configure = nil;
  
  if ( configure == nil )
    configure = [[SSVConfigure alloc] init];
  
  [configure show];
}

- (void)stop
{
  [super stop];
  [self clear];
}

- (void)songEnded:(NSNotification *)notification
{
  [self clear];
  [super songEnded:notification];
}

- (void)clear
{
}

- initWithDescription:(NSString *)desc
{
  [SSVConfigure initConfiguration];
  vis_offset=0;
  vis_delta=1;
  prev_type=-1;
  vis_sync_vu = 0;
  vis_sync_delta = 1;

  return [super initWithDescription:desc];
}

- (void)drawBitmap
{
  int i;
  for ( i = 0 ; i < [views count]; i++ )
    {
      NSView *view = [views objectAtIndex:i];
      if ( [view superview] != nil && [[view window] isVisible] )
	{
	  //NSLog(@"draw in %@", view);
	  //[self drawInView:view];
	  [view setNeedsDisplay:YES];
	}
    }
}

- (void)timeout:(unsigned char *)data
{
}

@end

