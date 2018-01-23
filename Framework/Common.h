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

#import <Foundation/NSString.h>

NSString *getPackageName();
NSString *getVersion();

typedef enum
{
  STATUS_STOP,STATUS_PAUSE,STATUS_PLAY
} PStatus;

typedef enum { TIMER_ELAPSED, TIMER_REMAINING } TimerMode;


char *read_ini_string(const char *filename,
		      const char *section,
		      const char *key);



@class NSRunLoop;

@interface NSObject(AppDelegateMethods)
- (void)eject_pressed:sender;
- (void)play_pressed:sender;
- (void)stop_pressed:sender;
- (void)pause_pressed:sender;
- (void)fwd_pressed:sender;
- (void)prev_pressed:sender;
- (void)savePlaylist;
- (NSRunLoop *)getMainRunLoop;
@end
