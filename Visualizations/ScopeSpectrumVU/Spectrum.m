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
#import <MXA/UserInterface.h>
#import "Spectrum.h"
#import "SSVConfigure.h"

static float vis_afalloff_speeds[]={0.34,0.5,1.0,1.3,1.6};
static float vis_pfalloff_speeds[]={1.1,1.16,1.23,1.3,1.4};
static int vis_redraw_delays[]={8,4,2,1};
static unsigned char vis_scope_colors[]={21,21,20,20,19,19,18,19,19,20,20,21,21};

@implementation Spectrum

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- (NSSize)defaultSize
{
  return NSMakeSize(76, 16);
}


- initWithDescription:(NSString *)desc
{
  [self clear];
  y_scale = 0.0;
  return [super initWithDescription:desc];
}

- init
{
  type = VIS_ANALYZER;
  inputType = INPUT_VIS_ANALYZER;
  return [self initWithDescription:[NSString stringWithFormat:@"Spectrum Visualization %@", getVersion()]];
}

- (int)numFREQChannelsWanted
{
  return 1;
}

- (void)renderFREQ:(short[2][256])mono_freq
{
  gint long_xscale[] = { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,
			 19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,
			 35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,
			 52,53,54,55,56,57,58,61,66,71,76,81,87,93,100,107,
			 114,122,131,140,150,161,172,184, 255 }; /* 76 values */
  gint short_xscale[] = { 0,1,2,3,4,5,6,7,8,11,15,20,27,36,47,62,82,107,141,184,255 }; /* 20 values */
  gint j, y, max, *xscale;
  gchar intern_vis_data[512];  
  int i;

  memset(intern_vis_data, 0, 75 * sizeof(gchar));
			
  if(y_scale == 0.0)
    y_scale = 20.0 / log(256);
  
  if([config intValueForKey:CFGAnalyzerType] == ANALYZER_BARS)
    {
      max = 19;
      xscale = short_xscale;
    }
  else
    {
      max = 75;
      xscale = long_xscale;
    }
			
  for (i = 0; i < max; i++)
    {
      for(j = xscale[i], y = 0; j < xscale[i + 1]; j++)
	{
	  if(mono_freq[0][j] > y)
	    y = mono_freq[0][j];
	}
      y >>= 7;
      if(y != 0)
	{
	  intern_vis_data[i] = (gchar)(log(y) * y_scale);
	  if(intern_vis_data[i] > 15)
	    intern_vis_data[i] = 15;
	}
      else
	intern_vis_data[i] = 0;
    }
  [self timeout:intern_vis_data];
}

- (void)timeout:(unsigned char *)newdata
{
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
	
  if ( type == VIS_ANALYZER ) {
    if(micros > fourteen_microseconds)
      falloff = TRUE;
    if(newdata || falloff)	{
      for(i = 0; i < 75; i++) {
	if(newdata && newdata[i] > data[i]) {
	  data[i] = newdata[i];
	  if(data[i] > peak[i])
	    {
	      peak[i]=data[i];
	      peak_speed[i]=0.01;
	      
	    }
	  else if(peak[i]>0.0)
	    {
	      peak[i] -= peak_speed[i];
	      peak_speed[i] *= vis_pfalloff_speeds[[config intValueForKey:CFGPeaksFalloff]];
	      if(peak[i] < data[i])
		peak[i] = data[i];
	      if(peak[i] < 0.0)
		peak[i] = 0.0;
	    }
	}
	else if(falloff)
	  {
	    if(data[i]>0.0)
	      {
		data[i] -= vis_afalloff_speeds[[config intValueForKey:CFGFalloffSpeed]];
		if(data[i] < 0.0)
		  data[i] = 0.0;
	      }
	    if(peak[i] > 0.0)
	      {
		peak[i] -= peak_speed[i];
		peak_speed[i] *= vis_pfalloff_speeds[[config intValueForKey:CFGPeaksFalloff]];
		if ( peak[i] < data[i] )
		  peak[i] = data[i];
		if ( peak[i] < 0.0 )
		  peak[i] = 0.0;
	      }
	  }
      }
    }
  } else if(data)  {
    for(i = 0; i < 75; i++)
      data[i] = newdata[i];
  }

  if(micros>fourteen_microseconds)
    {
      if(!refresh_delay)
	{
	  [self drawBitmap];
	  refresh_delay = vis_redraw_delays[[config intValueForKey:CFGRefreshRate]];
	}
      refresh_delay--;
    }
}


#define set_byte(data, x, y, coloridx) \
{ \
  *(data[0]+(76*y)+x) = (*vis_color)[coloridx][0];\
  *(data[1]+(76*y)+x) = (*vis_color)[coloridx][1];\
  *(data[2]+(76*y)+x) = (*vis_color)[coloridx][2];\
}

#define set_byteoff(data, off, coloridx)\
{\
  *(data[0]+off) = (*vis_color)[coloridx][0];\
  *(data[1]+off) = (*vis_color)[coloridx][1];\
  *(data[2]+off) = (*vis_color)[coloridx][2];\
}


- (void)drawInView:(VisualizationView *)view
{
  int x,y,h=0,h2;
  unsigned char *ptr,c;
  NSRect frame = [view frame];
  int bit_width = 76; //(7 + (frame.size.width * 8)) / 8;
  int bit_size = sizeof(unsigned char)*bit_width*frame.size.height;
  int off = 0;
  unsigned char (*vis_color)[24][3] = [[UserInterface ui] getVisualizationColors];
  static unsigned char *bit_data[3] = {0,0,0};

  if ( bit_data[0] == 0 )
    {
      bit_data[0] = malloc(bit_size);
      bit_data[1] = malloc(bit_size);
      bit_data[2] = malloc(bit_size);
    }

  memset(bit_data[0], (*vis_color)[0][0], bit_size);
  memset(bit_data[1], (*vis_color)[0][1], bit_size);
  memset(bit_data[2], (*vis_color)[0][2], bit_size);  

  for(y=1;y<16;y+=2) 
    {
      for(x=0;x<76;x+=2,ptr+=2)
	set_byte(bit_data, x, y, 1);
    }	

  if(type == VIS_ANALYZER) 
    {
      for(x=0;x<75;x++) {
	if(([config intValueForKey:CFGAnalyzerType] == ANALYZER_BARS&&(x%4)==0)
	   ||[config intValueForKey:CFGAnalyzerType] == ANALYZER_LINES)
	  h=(int)data[x];
	  
	if(h&&([config intValueForKey:CFGAnalyzerType]==ANALYZER_LINES||(x%4)!=3)) {
	  off = ((16-h)*bit_width)+x;
	  switch([config intValueForKey:CFGAnalyzerMode]) {
	  case	ANALYZER_NORMAL:		
	    for(y=0;y<h;y++,off+=bit_width)
	      set_byteoff(bit_data, off, 18-h+y);
	    break;
	  case	ANALYZER_FIRE:
	    for(y=0;y<h;y++,off+=bit_width)
	      set_byteoff(bit_data, off, y+2);
	    break;
	  case	ANALYZER_VLINES:
	    for(y=0;y<h;y++,off+=bit_width)
	      set_byteoff(bit_data, off, 18-h);
	    break;
	  }
	}
      }
      if([config boolValueForKey:CFGAnalyzerPeaks]) {
	for(x=0;x<75;x++)	{
	  if(([config intValueForKey:CFGAnalyzerType] == ANALYZER_BARS&&(x%4)==0)
	     ||[config intValueForKey:CFGAnalyzerType] == ANALYZER_LINES)
	    h=(int)peak[x];
	  if(h&&([config intValueForKey:CFGAnalyzerType] == ANALYZER_LINES||(x%4)!=3))
	    set_byteoff(bit_data, (16-h)*bit_width+x, 23);
	}
      }
    } else if(type == VIS_SCOPE) {
      for(x=0;x<75;x++) {
	switch([config intValueForKey:CFGScopeMode]) {
	case	SCOPE_DOT:
	  h=(int)data[x];
	  set_byteoff(bit_data, ((15-h)*bit_width)+x, vis_scope_colors[h]);
	  break;
	case	SCOPE_LINE:
	  if(x!=74) {
	    h=15-(int)data[x];
	    h2=15-(int)data[x+1];
	    if(h>h2) {
	      y=h;
	      h=h2;
	      h2=y;
	    }
	    off = (h*bit_width)+x;
	    for(y=h;y<=h2;y++,off+=bit_width)
	      set_byteoff(bit_data, off, vis_scope_colors[y-3]);
	  } else {
	    h=15-(int)data[x];
	    set_byteoff(bit_data, (h*bit_width)+x, vis_scope_colors[h]);
	  }
	  break;
	case	SCOPE_SOLID:
	  h=15-(int)data[x];
	  h2=9;
	  c=vis_scope_colors[(int)data[x]];
	  if(h>h2) {
	    y=h;
	    h=h2;
	    h2=y;
	  }
	  off=(h*bit_width)+x;
	  for(y=h;y<=h2;y++,off+=bit_width)
	    set_byteoff(bit_data, off, c);
	  break;
	}
      }
    }
  
  if ( [view lockFocusIfCanDraw] ) 
    {
      NSDrawBitmap(NSMakeRect(0, 0, frame.size.width, frame.size.height),
		   frame.size.width, frame.size.height, 8, 3, 8, bit_width,
		   YES, NO, NSDeviceRGBColorSpace, bit_data);
      [view unlockFocus];
    }
}


- (void)clear
{
  int i;
  
  for(i=0;i<75;i++) {
    data[i] = (type == VIS_SCOPE) ? 6 : 0;
    peak[i]=0;
  }
}


@end



