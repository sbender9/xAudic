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
#import "VU.h"
#import <MXA/UserInterface.h>
#import "SSVConfigure.h"

static int svis_redraw_delays[]={8,4,2,1};
static unsigned char svis_scope_colors[]={21,20,19,18,19,20,21};
static unsigned char svis_vu_normal_colors[] = { 17, 17, 17, 12, 12, 12, 2,2 };	

@implementation VU

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  type = VIS_ANALYZER;
  inputType = INPUT_VIS_VU;
  [self clear];
  return [self initWithDescription:[NSString stringWithFormat:@"VU Visualization %@", getVersion()]];
}


- (NSSize)defaultSize
{
  return NSMakeSize(38, 7);
}

#define DRAW_DS_PIXEL(ptr,value) \
	*(ptr) = (value); \
	*((ptr) + 1) = (value); \
	*((ptr) + 76) = (value); \
	*((ptr) + 77) = (value);


#define set_byte(data, x, y, coloridx) \
{ \
  *(data[0]+(38*y)+x) = (*vis_color)[coloridx][0];\
  *(data[1]+(38*y)+x) = (*vis_color)[coloridx][1];\
  *(data[2]+(38*y)+x) = (*vis_color)[coloridx][2];\
}

#define set_byteoff(data, off, coloridx)\
{\
  *(data[0]+off) = (*vis_color)[coloridx][0];\
  *(data[1]+off) = (*vis_color)[coloridx][1];\
  *(data[2]+off) = (*vis_color)[coloridx][2];\
}

- (void)drawInView:(VisualizationView *)view
{
  int x,y,h;
  unsigned char c;
  unsigned char *bit_data[3];
  int bit_width = 38;
  NSRect frame = [view frame];
  int bit_size = sizeof(unsigned char)*bit_width*frame.size.height;
  int off = 0;
  unsigned char (*vis_color)[24][3];

  bit_data[0] = malloc(bit_size);
  bit_data[1] = malloc(bit_size);
  bit_data[2] = malloc(bit_size);

  vis_color = [[UserInterface ui] getVisualizationColors];

  memset(bit_data[0], (*vis_color)[0][0], bit_size);
  memset(bit_data[1], (*vis_color)[0][1], bit_size);
  memset(bit_data[2], (*vis_color)[0][2], bit_size);  

  if ( [Visualization pluginWithName:@"Scope"]
       == [Visualization defaultVisualization]  )
    {
      type = VIS_SCOPE;
    }
  else
    type = VIS_ANALYZER;

	
  //    memset(rgb_data,0,38*7);
  if ( type == VIS_ANALYZER ) 
    {
      switch ([config intValueForKey:CFGVUMode]) 
	{
	case VU_NORMAL:
	  for(y = 0; y < 2; y++) 
	    {
	      off = (((y * 3) + 1) * 38);
	      h = (data[y] * 7) / 37;
	      for(x = 0; x < h; x++, off += 5) 
		{
		  c = svis_vu_normal_colors[x];
		  set_byteoff(bit_data, off, c);
		  set_byteoff(bit_data, off+1, c);
		  set_byteoff(bit_data, off+2, c);
		  set_byteoff(bit_data, off+38, c);
		  set_byteoff(bit_data, off+39, c);
		  set_byteoff(bit_data, off+40, c);
		}
	    }
	  break;
	case VU_SMOOTH:
	  for ( y = 0; y < 2; y++ ) 
	    {
	      off = (((y * 3) + 1) * 38);
	      for ( x = 0; x < data[y]; x++, off++)  
		{
		  c = 17 - ((x * 15) / 37);
		  set_byteoff(bit_data, off, c);
		  set_byteoff(bit_data, off+38, c);
		}
	    }
	  break;
	}
    }
  else if ( type == VIS_SCOPE ) 
    {
      for ( x = 0; x < 38; x++ ) 
	{
	  h = data[x<<1] >> 1;
	  off = ((6-h)*38)+x;
	  set_byteoff(bit_data, off, svis_scope_colors[h]);
	}
    }
    
  if ( [view lockFocusIfCanDraw] ) 
    {
      NSDrawBitmap(NSMakeRect(0, 0, frame.size.width, frame.size.height),
		   frame.size.width, frame.size.height, 8, 3, 8, bit_width,
		   YES, NO, NSDeviceRGBColorSpace, bit_data);
      [view unlockFocus];
    }

  free(bit_data[0]);
  free(bit_data[1]);
  free(bit_data[2]);
}

- (int)numPCMChannelsWanted
{
  return 1;
}

- (void)renderPCM:(short[2][512])mono_pcm
{
  gchar intern_vis_data[512];  
  /* Osciloscope */
  gint pos, step;
  int i;

  step = (512 << 8) / 74;
  for (i = 0, pos = 0; i < 75; i++, pos += step)
    {
      intern_vis_data[i] = ((mono_pcm[0][pos >> 8]) >> 11) + 6;
      if (intern_vis_data[i] > 12)
	intern_vis_data[i] = 12;
      if (intern_vis_data[i] < 0)
	intern_vis_data[i] = 0;
    }

  [self timeout:intern_vis_data];
}

- (void)timeout:(unsigned char *)newdata
{
  static NSDate *lastTime = nil;
  NSTimeInterval micros=9999999;
  BOOL falloff = FALSE;
  int i;
#define fourteen_microseconds 0.00014

  if ( lastTime == nil ) {
    lastTime = [[NSDate date] retain];
  } else {
    micros = [[NSDate date] timeIntervalSinceDate:lastTime];
    if(micros > fourteen_microseconds)
      lastTime = [[NSDate date] retain];
  }

  if ( type == VIS_ANALYZER ) 
    {
      if(micros > fourteen_microseconds)
	falloff = TRUE;
		
    for(i = 0; i < 2; i++) {
      if (falloff || newdata ) {
	if ( newdata && newdata[i] > data[i] )
	  data[i] = newdata[i];
	else if ( falloff ) {
	  if( data[i] >= 2 )
	    data[i] -= 2;
	  else
	    data[i] = 0;
	}
      }
      
    }
  } else if ( newdata ) {
    for(i = 0; i < 75; i++)
      data[i] = newdata[i];
  }

  if(micros>fourteen_microseconds)
    {
      if(!refresh_delay)
	{
	  [self drawBitmap];
	  refresh_delay = svis_redraw_delays[[config intValueForKey:CFGRefreshRate]];
	  
	}
      refresh_delay--;
    }
}

- (void)clear
{
  int i;
  
  for(i=0;i<75;i++) {
    data[i] = (type == VIS_SCOPE) ? 6 : 0;
  }
}

- (BOOL)isPublic
{
  return NO;
}

- (BOOL)goodForSmallView
{
  return YES;
}

@end

