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
#import <Foundation/NSObject.h>

@class NSBundle;
@class NSWindow;

@interface NibObject : NSObject
{
  BOOL nibLoaded;
  id window;
  NSString *nibName;
  NSBundle *bundle;
}

- initWithNibName:(NSString *)name;
- initWithNibName:(NSString *)name bundle:(NSBundle *)bundle;

- (BOOL)loadNib;

- (void)show:sender;
- (void)show;

- (void)ok:sender;
- (void)cancel:sender;

- (NSString *)nibName;
- (void)setNibName:(NSString *)name;
- (void)updateDisplay;

- (NSWindow *)window;

@end

