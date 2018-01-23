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

#import "Plugins.h"
#import <Foundation/NSGeometry.h>
#import <Foundation/NSDate.h>
#import <AppKit/NSView.h>

@class NSTimer;
@class VisualizationView;

@interface Visualization : Plugin
{
  BOOL isRunning;
  NSMutableArray *views;
  NSWindow *window;
}

+ (void)initializeVisualizations;
+ (void)registerPlugin:(Plugin *)op;
+ (NSArray *)plugins;

+ (Visualization *)pluginWithName:(NSString *)name;

+ (void)addVisPcmTime:(int)time 
	       format:(AFormat)fmt
	  numChannels:(int)nch
	      length:(int)length
                data:(void *)ptr;

+ (Visualization *)defaultVisualization;
+ (void)setDefaultVisualization:(Visualization *)vis;

- (NSRect)visFrameForRect:(NSRect)rect;
- (NSSize)defaultSize;
- (NSSize)maxSize;
- (NSSize)minSize;
- (BOOL)isSizable;
- (BOOL)embedOnly;
- (BOOL)canEmbed;
- (BOOL)isRunning;
- (BOOL)isPublic;
- (BOOL)allowsMultipleViews;
- (BOOL)goodForSmallView;

- (int)numPCMChannelsWanted;
- (int)numFREQChannelsWanted;
- (void)renderPCM:(short[2][512])data;
- (void)renderFREQ:(short[2][256])data;

+ (void)timer:nothing;

- (void)songStarted:(NSNotification *)notification;
- (void)songEnded:(NSNotification *)notification;

- (VisualizationView *)getViewWithFrame:(NSRect)frame owner:(id)owner;
- (VisualizationView *)getViewWithFrame:(NSRect)frame owner:(id)owner 
                  autohide:(BOOL)autohide;
- (void)removeView:(VisualizationView *)view;

- (void)addView:(VisualizationView *)view; //for subclasses only
- (void)viewStatusChanged:(VisualizationView *)view;

- (void)startInWindow;
- (void)stopInWindow;
- (void)start;
- (void)stop;
- (void)drawInView:(VisualizationView *)view;
- (BOOL)anyVisableViews;

+ (void)addVisPcmTime:(int)time 
	       format:(AFormat)fmt
	  numChannels:(int)nch
	      length:(int)length
	        data:(void *)ptr;

@end


@interface VisualizationView : NSView
{
  NSView *prevSuperview;
  NSWindow *prevWindow;
  Visualization *plugin;
  BOOL autohide;
  id owner;
}

- initWithFrame:(NSRect)frame 
         plugin:(Visualization *)plugina
          owner:(id)owner
       autohide:(BOOL)autohide;

- (void)setAutohide:(BOOL)val;
- (id)owner;

@end

extern NSString *UIWindowDidShow;


//helpfull for porting xmms plugins

#define GUINT16_SWAP_LE_BE(val)        ((unsigned short) ( \
    (((unsigned short) (val) & (unsigned short) 0x00ffU) << 8) | \
    (((unsigned short) (val) & (unsigned short) 0xff00U) >> 8)))

#define GUINT16_TO_LE(val)  ((unsigned short) (val))
#define GUINT16_TO_BE(val)  ((unsigned short) GUINT16_SWAP_LE_BE (val))
#define GINT16_TO_LE(val)  ((short) (val))
#define GINT16_TO_BE(val)  ((short) GUINT16_SWAP_LE_BE (val))
#define GUINT16_FROM_LE(val)    (GUINT16_TO_LE (val))
#define GUINT16_FROM_BE(val)    (GUINT16_TO_BE (val))
#define GINT16_FROM_LE(val)    (GINT16_TO_LE (val))
#define GINT16_FROM_BE(val)    (GINT16_TO_BE (val))

typedef signed char gint8;
typedef unsigned char guint8;
typedef signed short gint16;
typedef unsigned short guint16;
typedef signed int gint32;
typedef unsigned int guint32;
typedef int gint;
typedef void *gpointer;
typedef float gfloat;
typedef gint gboolean;
typedef char gchar;
typedef unsigned char guchar;
typedef unsigned int guint;
typedef double gdouble;


