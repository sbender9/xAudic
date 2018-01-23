/*  XMMS - Cross-platform multimedia player
 *  Copyright (C) 1998-2000  Peter Alm, Mikael Alm, Olle Hallnas, Thomas Nilsson and 4Front Technologies
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
 *  w
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */
#import "blur_scope.h"
#import <AppKit/AppKit.h>
#include <stdlib.h>

#define WIDTH 256 
#define HEIGHT 128
#define min(x,y) ((x)<(y)?(x):(y))
//#define BPL	((WIDTH + 2))
#define BPL	((WIDTH))

static unsigned char colors[256][3];
static unsigned char *bit_data[3];
static guchar rgb_buf[(WIDTH + 2) * (HEIGHT + 2)];
static BOOL datavalid;
static NSLock *lock;

/*
#define set_byte(x, y, coloridx) \
{ \
  *(bit_data[0]+(BPL*y)+x) = colors[coloridx][0];\
  *(bit_data[1]+(BPL*y)+x) = colors[coloridx][1];\
  *(bit_data[2]+(BPL*y)+x) = colors[coloridx][2];\
}
*/

//#define set_byte(x,  y,  c) rgb_buf[((y + 1) * BPL) + (x + 1)] = c
#define set_byte(x,  y,  c) rgb_buf[((y) * BPL) + (x)] = c

@implementation BlurScope

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  lock = [[NSLock alloc] init];
  [self generate_colors];
  return [super initWithDescription:[NSString stringWithFormat:@"Blur Scope %@", getVersion()]];
}

- (NSSize)defaultSize
{
  return NSMakeSize(WIDTH, HEIGHT);
}

- (BOOL)isSizable
{
  return NO;
}

- (BOOL)canEmbed
{
  return NO;
}

- (BOOL)allowsMultipleViews
{
  return NO;
}

- (int)numPCMChannelsWanted
{
  return 1;
}

- (BOOL)hasConfigure
{
  return NO;
}

void bscope_blur_8(gint w, gint h, gint bpl)
{
  register guint i,sum;
  register guchar *iptr;


  iptr = rgb_buf + bpl + 1;
  i = bpl * h;
  while(i--)
    {
      sum = (iptr[-bpl] + iptr[-1] + iptr[1] + iptr[bpl]) >> 2;
      if(sum > 2)
	sum -= 2;
      *(iptr++) = sum;
    }
}

- (void)generate_colors
{
  NSColor *color = [NSColor redColor];
  unsigned int red, blue, green;
  int i;

  red = [color redComponent] * 255.0;
  green = [color greenComponent] * 255.0;
  blue = [color blueComponent] * 255.0;

  for(i = 255; i > 0; i--)
    {
      colors[i][0] = i*red/256;
      colors[i][1] = i*green/256;
      colors[i][2] = i*blue/256;
    }
  colors[0][0] = 0;
  colors[0][1] = 0;
  colors[0][2] = 0;
}

static inline void draw_vert_line(gint x, gint y1, gint y2)
{
  int y;
  if(y1 < y2)
    {
      for(y = y1; y <= y2; y++)
	set_byte(x, y, 0xFF);
    }
  else if(y2 < y1)
    {
      for(y = y2; y <= y1; y++)
	set_byte(x, y, 0xFF);
    }
  else
    set_byte(x,y1,0xFF);
}


- (void)renderPCM:(short[2][512])data
{
  gint i,y, prev_y;
  int bit_size = sizeof(unsigned char)*BPL*HEIGHT;
	
  [lock lock];

  if ( bit_data[0] == 0 )
    {
      bit_data[0] = malloc(bit_size);
      bit_data[1] = malloc(bit_size);
      bit_data[2] = malloc(bit_size);

      memset(bit_data[0], 0, WIDTH);
      memset(bit_data[1], 0, WIDTH);
      memset(bit_data[2], 0, WIDTH);  
      memset(rgb_buf, 0, WIDTH*HEIGHT);
    }

  bscope_blur_8(WIDTH, HEIGHT, BPL);
  prev_y = y = (HEIGHT / 2) + (data[0][0] >> 9);
  for(i = 0; i < WIDTH; i++)
    {
      y = (HEIGHT / 2) + (data[0][i >> 1] >> 9);
      if(y < 0)
	y = 0;
      if(y >= HEIGHT)
	y = HEIGHT - 1;
      draw_vert_line(i,prev_y,y);
      prev_y = y;
    }

  /*
  for ( i = 0; i < WIDTH; i++ )
    {
      set_byte(i, 60, 0xFF);
    }
  */


  for ( i = 0; i < (BPL*HEIGHT); i++ )
    {
      bit_data[0][i] = colors[rgb_buf[i]][0];
      bit_data[1][i] = colors[rgb_buf[i]][1];
      bit_data[2][i] = colors[rgb_buf[i]][2];
    }

  datavalid = YES;
  [lock unlock];


  for ( i = 0 ; i < [views count]; i++ )
    {
      NSView *view = [views objectAtIndex:i];
      if ( [view superview] != nil )
	[view setNeedsDisplay:YES];
    }

  return;			
}

- (void)drawInView:(VisualizationView *)view
{
  if ( datavalid )
    {
      if ( [view lockFocusIfCanDraw] ) 
	{
	  [lock lock];

	  NSDrawBitmap(NSMakeRect(0, 0, WIDTH, HEIGHT),
		       WIDTH, HEIGHT, 8, 3, 8, BPL,
		       YES, NO, NSDeviceRGBColorSpace, bit_data);
	  [view unlockFocus];
	  [lock unlock];
	}
    }
}

@end

