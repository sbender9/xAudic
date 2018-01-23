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
#import <Foundation/NSObject.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>

@interface Skin : NSObject
{
  NSString *skinPath;
  NSImage *main;
  NSImage *cbuttons;
  NSImage *titlebar;
  NSImage *shufrep;
  NSImage *text;
  NSImage *volume;
  NSImage *balance;
  NSImage *monostereo;
  NSImage *playpause;
  NSImage *numbers;
  NSImage *posbar;
  NSImage *pledit;
  NSImage *eqmain;
  NSImage *eq_ex;
  NSColor *pledit_normal;
  NSColor *pledit_current;
  NSColor *pledit_normalbg;
  NSColor *pledit_selectedbg;
  NSImage *def_mask;
  NSImage *mask_main,*mask_main_ds;
  NSImage *mask_eq,*mask_eq_ds;
  NSImage *mask_shade,*mask_shade_ds;
@public
  unsigned char vis_color[24][3];
}

+ (void)loadSkin:(NSString *)pathName;
- initWithFile:(NSString *)fileName;
- initDefault;
- (BOOL)load_skin_viscolor:(NSString *)path  :(NSString *)file;

- (NSImage *)main;
- (NSImage *)cbuttons;
- (NSImage *)titlebar;
- (NSImage *)shufrep;
- (NSImage *)text;
- (NSImage *)volume;
- (NSImage *)balance;
- (NSImage *)monostereo;
- (NSImage *)playpause;
- (NSImage *)numbers;
- (NSImage *)posbar;
- (NSImage *)pledit;
- (NSImage *)eqmain;
- (NSImage *)eq_ex;
- (NSColor *)pledit_normal;
- (NSColor *)pledit_current;
- (NSColor *)pledit_normalbg;
- (NSColor *)pledit_selectedbg;


@end

extern Skin *currentSkin;

extern NSString *SkinChangedNotification;

char *read_ini_string(const char *filename,const char *section,const char *key);
