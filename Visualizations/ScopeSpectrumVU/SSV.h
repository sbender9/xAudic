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

#import <AppKit/NSView.h>
#import <MXA/Common.h>
#import <MXA/Plugins.h>
#import <MXA/Visualization.h>
#import "SSVConfigure.h"

@class NSMutableArray;
@class NSLock;
@class BaseV;

@interface BaseV : Visualization
{
  int vis_offset,vis_delta,prev_type,vis_sync_vu, vis_sync_delta;

@public
  VisType type;
  InputVisType inputType;
}

- (void)drawBitmap;

- (void)timeout:(unsigned char *)data;

- (void)clear;

@end

