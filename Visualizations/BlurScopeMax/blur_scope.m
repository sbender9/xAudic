/*  Blur Scope MAX- Visualization Plugin for XMMS.
 * by Matt Bardeen <mbardeen@gte.net> (and other copyright holders)
 * Copyright (C) 1998-1999  Peter Alm, Mikael Alm, Olle Hallnas, Thomas Nilsson and 4Front Technologies. 
 * Modified blur routines are Copyright (C) 1999 Matt Bardeen.
 * Cthugha functions are Copyright 1995-1997 by Harald Deischinger, and credit also goes to Cthugha and Torps Productions.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307  USA




Todo:
Keep running total of max value for all functions.
Any other bugs that pop up

*/
#include "blur_scope.h"
#include <math.h>
#include <AppKit/AppKit.h>

#define bscope_blur_8 max_bscope_blur_8

static BOOL datavalid = NO;
static NSLock *lock, *res_lock;
//static gboolean config_read = FALSE;
pthread_mutex_t blurscope_res_lock;
gboolean blurscope_have_mutex = FALSE;
static gint blurscope_need_draw = 0;	//Has the screen been updated?
static gint blurscope_stopped = TRUE;	//Has the music stopped?
static int blurscope_quit = 0;
static int dga_available =0;

static guint colors[256];

void bscope_changesize(void);
static void bscope_init(void);
static void bscope_cleanup(void);
static void bscope_playback_stop(void);
static void bscope_playback_start(void);
static void bscope_render_pcm(gint16 data[2][512]);
void bscope_read_config(void);

BlurScopeConfig bscope_cfg;

@implementation BlurScopeMax

- (int)numPCMChannelsWanted
{
  return 2;
}

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}


//This is the maximum array size. Change this if you want to draw over a 512x256 rectangle
#define WIDTH 514 
#define HEIGHT 386


- (BOOL)canEmbed
{
  return YES;
}

- (BOOL)allowsMultipleViews
{
  return NO;
}

- (BOOL)hasConfigure
{
  return NO;
}

#define min(x,y) ((x)<(y)?(x):(y))
#define addr(x,y)	(((x+1) + (y+1)*bscope_cfg.BPL))
#define BOTTOM		(height-1)
#define MID_Y		(height>>1)
#define MID_X		(width>>1)
#define LOW_LINE	(height - height/10)
#ifndef M_PI
#define M_PI  3.1519265
#endif


static guint width;
static guint height;
int numpresets;
int currentpreset;
//bitmap buffers
static guchar rgb_buf[(WIDTH + 2) * (HEIGHT + 2)];
static guchar rgb_buf_work[(WIDTH +2) * (HEIGHT +2)];
static unsigned char *bit_data[3];
	
//shift values and the number of pixels to be retrieved for each pixel in the buffers.	
static char shift[4][(WIDTH+2) * (HEIGHT+2)];
	
//Maximum value over time - this gets decayed over time
static int maxvalue[2];
//Maximum value of the current data set
static int currentmax[2];


//the buffer we are drawing right now
static guchar *active_buffer;
//the buffer we copy the blur to
static guchar *work_buffer;

//Presets get store here during running.
BlurScopeConfig presets[MAXPRESETS];

int sine[360];
double sin360[360];

static void inline draw_pixel_8(guchar *buffer,gint x, gint y, guchar c)
{
  buffer[(((y) * bscope_cfg.BPL) + (x))] = c;
}

static int inline get_pixel_8(guchar *buffer,gint x, gint y)
{
  return buffer[(((y) * bscope_cfg.BPL) + (x))];
}

- (NSSize)defaultSize
{
  return NSMakeSize(256, 128);
}

- (NSSize)maxSize
{
  return NSMakeSize(WIDTH, HEIGHT);
}

- (void)viewWasCreated:(VisualizationView *)view
{
  NSRect frame = [view frame];
  width = frame.size.width;
  height = frame.size.height;

  bscope_cfg.shape = 0;
  bscope_changesize();

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(viewFrameChanged:)
    name:NSViewFrameDidChangeNotification
    object:view];
}

- (void)viewFrameChanged:(NSNotification *)notification
{
  NSView *view = [notification object];
  width = [view frame].size.width;
  height = [view frame].size.height;
  bscope_changesize();
}

- init
{
  int i;

  lock = [[NSLock alloc] init];
	
	for(i=0; i < 360; i++)
		sin360[i]= sin( (double)i *(2.0 * M_PI /360.0));
	
	bscope_read_config();
	
	if (!blurscope_have_mutex) 
	  {
		res_lock = [[NSLock alloc] init];
		blurscope_have_mutex = TRUE;
	}
	bscope_changesize();
	
	
	generate_cmap(bscope_cfg.colormap, 0, bscope_cfg.colormap);
	
	memset(rgb_buf,0,(WIDTH + 2) * (HEIGHT + 2));
	memset(rgb_buf_work,0,(WIDTH+2) * (HEIGHT+2));
	
	active_buffer=rgb_buf;
	work_buffer=rgb_buf_work;

  return [super initWithDescription:[NSString stringWithFormat:@"Blur Scope Max 1.3"]];
}

// #define putat(x,y,val)	active_buffer[ addr( (x) , (y) ) ] = val
void putat(guchar *buffer, int x, int y, int val) {
	int a = addr(x,y);
	buffer[a] = val;
}

int getat(guchar *buffer, int x, int y) {
	int a = addr(x,y);
	return buffer[a];
}

void putat_cut(guchar *buffer, int x, int y,  int val) {
	if( (x < 0) || (x >= width)) return;
	if( (y < 0) || (y >= height+1)) return;
	putat(buffer, x,y,val);
}




static void draw_line(guchar *buffer, int x1, int y1, int x2, int y2, int c) {
	register int lx, ly, dx, dy;
	register int i, j, k;
	if (x1<0)	        x1=0;
	if (x1>width)	x1=width;
	if (x2<0)	        x2=0;
	if (x2>width)	x2=width;
	if (y1<0)	        y1=0;
	if (y1>height+1) 	y1=height+1;
	if (y2<0)	        y2=0;
	if (y2>height+1)	y2=height+1;
	
	lx = abs(x1-x2);
	ly = abs(y1-y2);
	dx = (x1>x2) ? -1 : 1;
	dy = (y1>y2) ? -1 : 1;
	
	if (lx>ly) {
		for (i=x1,j=y1,k=0;i!=x2;i+=dx,k+=ly) {
			if (k>=lx) {
				k -= lx;
				j += dy;
			}
			buffer[(i+j*bscope_cfg.BPL)] = c;
		}
	} else {
		for (i=y1,j=x1,k=0;i!=y2;i+=dy,k+=lx) {
			if (k>=ly) {
				k -= ly;
				j += dx;
			}
			buffer[j+i*bscope_cfg.BPL] = c;
		}
	}	
	
}






void do_vwave(guchar *buffer, int ystart, int yend, int x, int val) {
	int ys, ye;
	unsigned char * pos;
	
	if ( ystart > yend)	
		ys = yend, ye = ystart;
	else
		ys = ystart, ye = yend;		
	
	if ( ys <  0)		ys = 1;
	if ( ys > height+1)	ys = height+1 ;
	if ( ye <  0)		ye = 1;
	if ( ye > height+1)	ye = height+1 ;
	
	pos = buffer + addr(x,ys);
	for(; ys <= ye; ys ++) {
		*pos = (guchar)val;
		pos += bscope_cfg.BPL;
	}
}



void do_hwave(guchar *buffer, int xstart, int xend, int y, int val) {
	int xs, xe;
	unsigned char * pos;
	
	if ( xstart > xend)	
		xs = xend, xe = xstart;
	else
		xs = xstart, xe = xend;		
	
	while ( (xs < 0) && (xe < 0) )
		xs += width, xe += width;
	while ( (xs >= width) && (xe >= width))
		xs -= width, xe -= width;
	
	if ( xs <  0)		xs = 0;
	if ( xs >= width)	xs = width - 1;
	if ( xe <  0)		xe = 0;
	if ( xe >= width)	xe = width - 1;
	
	pos = buffer + addr(xs, y);
	for(; xs <= xe; xs ++) {
		*pos = (guchar)val;
		pos ++;
	}
}



//**************** Average **********************
int Average(gint16 data[2][512]) {
	//returns the average value of the data set
	long Average=0;
	int i;
	
	for (i=0; i < 512; i++) Average+=data[0][i];
	Average = Average/(512);
	
	return Average;
	
}

//**************** Max *************************
void Max(gint16 data[2][512]) {
	//loads the max value for each channel into the global maxvalue and currentmax arrays.
	int max=0;
	int i;
	
	//decay the max value over time
	maxvalue[0]--;
	maxvalue[1]--;
	//find the max for stereo channel 0 data
	for (i=0; i < 512; i++) if (abs(data[0][i]>>7)>max) max=abs(data[0][i]>>7);
	//if the max is greater then the current max, replace it
	if (maxvalue[0] < max) 
		maxvalue[0]=max;
	currentmax[0]=max;
	
	
	//find the max for stereo channel 1 data
	for (i=0; i < 512; i++) if (abs(data[1][i]>>7)>max) max=abs(data[1][i]>>7);
	//if the max is greater then the current max, replace it	
	if (maxvalue[1] < max) 
		maxvalue[1]=max;
	currentmax[1]=max;
	
	
	
	
	
}


/****************************************************************************
 * Line horizontal
  ***************************************************************************/
void wave_lineHor(gint16 data[2][512], guchar *buffer, guchar stereo, guchar color[2]) {	/* Line horizontal */
	guint16 x,y, scale;
	gint16 tmp; 
	static gint16 last=0;
	
	
	//Pick color to draw at based 
	
	if (!(bscope_cfg.doublesize && stereo)) {
		//Mono
		last = tmp = (height/2) + (data[0][0] >> 9);
		for(x=0; x < width; x++) {
			tmp = (MID_Y) + (data[0][x] >> 9);
			do_vwave( buffer,
				tmp, 
				last, 
				x, color[0]);
			last = tmp;
		}
	} else {		
		//Stereo
		last = ((height+2+ (maxvalue[0]/2))/2) + (data[0][0] >> 9);
		for(x=0; x < width; x++) {
			tmp = ((height+2+(maxvalue[0]/2))/2) + (data[0][x] >> 9);
			if (tmp < 0) tmp=0;
			do_vwave( buffer,
				tmp, 
				last, 
				x, color[0]);
			last = tmp;
		}
		
		last = ((height+2-maxvalue[1]/2)/2) - (data[1][0] >> 9);
		for(x=0; x < width; x++) {
			tmp = ((height+2-maxvalue[1]/2)/2) - (data[1][x] >> 9);
			if (tmp < 0) tmp=0;
			do_vwave( buffer,
				tmp, 
				last, 
				x, color[1]);
			last = tmp;
		}
	}
	
	
}



void wave_solidHor(gint16 data[2][512], guchar *buffer, guchar stereo, guchar color[2]) {	/* Solid horizontal */
	int x, tmp, y;
	int  midy;
	
	if (!(bscope_cfg.doublesize && stereo)) {
		//Mono
		
		for(x=0; x < width; x++) {
			tmp = data[0][x];
			y = (height/ 2) + (data[0][x] >> 9);
			do_vwave( buffer,
				MID_Y, 
				y, 
				x, color[0]);
		}
	} else {
		//Stereo
		midy = ((height+maxvalue[0]/2)/2);
		for(x=0; x < width; x++) {
			y = ((height+maxvalue[0]/2)/2) + (data[0][x] >> 9);
			do_vwave( buffer,
				midy,	
				y, 
				x, color[0]);
		}
		
		
		midy = ((height-maxvalue[1]/2)/2);
		for(x=0; x < width; x++) {
			y = ((height-maxvalue[1]/2)/2) - (data[1][x] >> 9);
			do_vwave( buffer,
				midy,	
				y, 
				x, color[1]);
		}
		
	}
}

/***************************************************************************** 
 * Dot horizontal
 *****************************************************************************/

void wave_dotHor(gint16 data[2][512], guchar *buffer, guchar stereo, guchar color[2]) {	/* dot horizontal */
	int x, tmp, y;
	
	
	if (!(bscope_cfg.doublesize && stereo)) {
		//Mono
		
		for(x=0; x < width; x++) {
			y = (height / 2) + (data[0][x] >> 9);
			draw_pixel_8(buffer, x, y, color[0]);
			
		}
	} else {
		//Stereo
		
		for(x=0; x < width; x++) {
			y = ((height+maxvalue[0]/2)/2) + (data[0][x]>>9);
			putat_cut(buffer, x, y, color[0]);
			
		}
		
		for(x=0; x < width; x++) {
			y = ((height-maxvalue[1]/2)/2) - (data[1][x]>>9);
			putat_cut(buffer, x, y, color[1]);
			
		}
		
		
		
	}
}




/****************************************************************************
 * Line vertical
 ****************************************************************************/
void wave_lineVert(gint16 data[2][512], guchar *buffer, guchar stereo, guchar color[2]) {	/* Line veritcal short */
	int tmp, x, last=0;
	
	if (!(bscope_cfg.doublesize && bscope_cfg.stereo)) {
		//Mono
		for(x=0; x < height-1; x++) {
			tmp = data[0][x]>>9;
			do_hwave( buffer,
				(width+2)/2 - tmp, 
				(width+2)/2 - last, x, color[0]);
			last = tmp;
		}
	} else {
		//Stereo
		last = ((width+maxvalue[0]/2)/2) - (data[0][0] >> 9);
		for(x=0; x <height-1; x++) {
			tmp = ((width+2+maxvalue[0]/2)/2) + (data[0][x] >> 9);
			do_hwave( buffer,
				tmp, 
				last, 
				x, color[0]);
			last = tmp;
		}
		
		last = ((width+2-maxvalue[1]/2)/2) - (data[1][0] >> 9);
		for(x=0; x < height-1; x++) {
			tmp = ((width+2-maxvalue[1]/2)/2) - (data[1][x] >> 9);
			do_hwave( buffer,
				tmp, 
				last, 
				x, color[1]);
			last = tmp;
		}
		
		
	}
	
}

void wave_solidVert(gint16 data[2][512], guchar *buffer, guchar stereo, guchar color[2]) {	/* soild vertical */
	int x, tmp, y, midy;
	
	if (!(bscope_cfg.doublesize && stereo)) {
		//mono
		for(x=0; x < height-1;x++) {
			tmp = data[0][x];
			y = ((width+2) / 2) + (data[0][x] >> 9);
			do_hwave( buffer, 
				y, 
				(width+2)/2, x, color[0]);
		}
	} else {
		//stereo
		midy = ((width+6+maxvalue[0]/2)/2);
		for(x=0; x < height-1; x++) {
			y = ((width+6+maxvalue[0]/2)/2) + (data[0][x] >> 9);
			do_hwave( buffer,
				midy,	
				y, 
				x, color[0]);
		}
		
		midy = ((width+2-maxvalue[1]/2)/2);
		for(x=0; x < height-1; x++) {
			y = ((width+2-maxvalue[1]/2)/2) - (data[1][x] >> 9);
			do_hwave( buffer,
				midy,	
				y, 
				x, color[1]);
		}
		
		
		
		
		
	}
}

/***************************************************************************** 
 * Dot vertical
 *****************************************************************************/

void wave_dotVert(gint16 data[2][512], guchar *buffer, guchar stereo, guchar color[2]) {	/* dot vertical */
	int x, tmp, y;
	
	if (!(bscope_cfg.doublesize && stereo)) {
		//Mono
		for(x=0; x < height-1; x++) {
			tmp = data[0][x];
			y = ((width+2) / 2) + (data[0][x >> 1] >> 9);
			draw_pixel_8(buffer, y, x, color[0]);
			
		}
	} else {
		//Stereo
		
		for(x=0; x < height-1; x++) {
			y = ((width+2+maxvalue[0]/2)/2) + (data[0][x]>>9);
			putat_cut(buffer,y, x, color[0]);
			
		}
		
		for(x=0; x < height-1; x++) {
			y = ((width+2-maxvalue[1]/2)/2) - (data[1][x]>>9);
			putat_cut(buffer, y, x, color[1]);
			
		}
	}
}




void wave_buff11(gint16 data[2][512], guchar *buffer) {		/* Lissa */
	int tmp, x, tmp2;
	
	for(x=0; x < width; x++) {
		tmp = (MID_Y)+(data[0][x] >> 9);
		tmp2 = (MID_Y)+(data[1][x] >>9);
		
		draw_pixel_8 (buffer, (tmp+32)%width, (tmp)%BOTTOM, 0xFF );
	}
}


//Lightning function
//borrowed from Cthugha, modified by Matt Bardeen.
void wave_buff15(gint16 data[2][512], guchar *buffer, guchar stereo) {		
	int tmp,x,last=(height/2);
	int max;
	
	
	max= Average(data);
	for(x=width/2; x < width; x++) {
		
		tmp = (data[0][x])/4096 + last;
		
		do_vwave(buffer,last,tmp,x,max);
		last = tmp;
	}
	
	last = (height/2);
	for(x=width/2; x > 0 ; x--) {
		
		
		tmp = (data[0][x])/4096 + last;
		
		do_vwave(buffer, last,tmp,x,max);
		last = tmp; 
	} 
	
}
double isin(int deg) {
	deg %= 360;
	if (deg < 0)
		deg += 360;
	
	return sin360[deg];
	
}
#define icos(deg)  isin((deg) + 90)



//Ring function - Matt Bardeen
void wave_matt(gint16 data[2][512], guchar *buffer, guchar stereo) {
	int x=0,y=0,i,color, avg, tmp; 
	static int maxavg=0;
	static int prevx;
	static int prevy;
	int cxl=(width+2)/2;
	int cyl=(height+2)/2;
	int txl=0,tyl=0,txr=0,tyr=0;
	
	if (bscope_cfg.doublesize) {
		if  (bscope_cfg.shape==4) 
			tmp=currentmax[0]<<2;
		else tmp=currentmax[0]<<1;
	}	
	avg=maxvalue[0]<<3;
	maxavg-=1;
	if (maxavg < avg) maxavg=avg;
	if (maxavg<1) color=0;
	else
		color=((255*avg)/maxavg);
	prevx=(int)(isin(0)*tmp)>>2;
	prevy=(int)(icos(0)*tmp)>>2;
	
	
	if( (height >= 128) && (width >= 128) ) {
		register int i,sx,sy;
		
		for( i=0;i<=360; i++) {
			if(y>=360) y-=360;
			if(x>=360) x-=360;
			
			sx = (int)(isin(i)*tmp)>>2;
			sy = (int)(icos(i)*tmp)>>2;
			
			draw_line(buffer, cxl+prevx, cyl+prevy, cxl+sx, cyl+sy, color);
			
			prevx=sx;
			prevy=sy;
			
			x++;
			y++;
			
		}	
	}
}



void wave_ringwave(gint16 data[2][512], guchar *buffer, guchar stereo, guchar color[2]) {
	int x=0,y=0,i, avg, tmp; 
	static int maxavg=0;
	static int prevx;
	static int prevy;
	int cxl=(width+2)/2;
	int cyl=(height+2)/2;
	int txl=0,tyl=0,txr=0,tyr=0;
	
	
	if (bscope_cfg.doublesize) {
		if  (bscope_cfg.shape==4) 
			tmp=currentmax[0]<<2;
		else tmp=currentmax[0]<<1;
	}
	else tmp=currentmax[0];	
	
	prevx=(int)(isin(0)*(tmp+((data[0][0])>>9)))>>2;
	prevy=(int)(icos(0)*(tmp+((data[0][0])>>9)))>>2;
	
	
	if( (height >= 128) && (width >= 128) ) {
		register int i,sx,sy;
		
		for( i=0;i<360; i++) {
			if(y>=360) y-=360;
			if(x>=360) x-=360;
			
			sx = (int)(isin(i)*(tmp+((data[0][(i*511)/360])>>9)))>>2;
			sy = (int)(icos(i)*(tmp+((data[0][(i*511)/360])>>9)))>>2;
			
			draw_line(buffer, cxl+prevx, cyl+prevy, cxl+sx, cyl+sy, color[0]);
			
			prevx=sx;
			prevy=sy;
			
			x++;
			y++;
			
		}
		//connect the ring
		draw_line(buffer, cxl+prevx, cyl+prevy, cxl+((int)(isin(i)*(tmp+((data[0][0])>>9)))>>2), cyl+((int)(icos(i)*(tmp+((data[0][0])>>9)))>>2), color[0]);
	}
	
	
}






#define maxWarps 15
#define maxWarpTrails 20

typedef struct {
	int r,s,theta,omg,trails,col,rgrav;
} WarpRing;

void wave_warp(gint16 data[2][512], guchar *buffer, guchar stereo) {
	int i,x1,y1;
	static int first=1,cx,cy,maxRad,maxA;
	static WarpRing theWarps[maxWarps];
	
	
	if (first) {
		first = 0;
		
	/* intialize all the fire works to be inoperative */
		for (i=0;i<maxWarps;i++)
			theWarps[i].r = -1;
		
	}
	cx = (width+2)/2;
	cy = (height+2)/2;
	maxRad = (cx>cy) ? cx : cy;
	
	for (i=0;i<maxWarps;i++)
		
	/* if this warp is in flight, process it */
		if (theWarps[i].r != -1) {
			int r2 = theWarps[i].r + theWarps[i].s;
			int t2 = theWarps[i].theta + theWarps[i].omg;
			int j,x2,y2,tr = theWarps[i].trails;
			
	    /* draw the ring of warps */
			for (j=0; j<tr; j++) {
				x1 = (int)(cx + ((double)theWarps[i].r) * isin( (360 * j) / tr + theWarps[i].theta ));
				y1 = (int)(cy + ((double)theWarps[i].r) * icos( (360 * j) / tr + theWarps[i].theta));
				x2 = (int)(cx + (double)r2 * isin(360*j/tr+t2));
				y2 = (int)(cy + (double)r2 * icos(360*j/tr+t2));
				draw_line(buffer, x1,y1,x2,y2,theWarps[i].col);
			}
			
	    /* increment the radius and spiral */
			theWarps[i].r += theWarps[i].s;
			theWarps[i].theta += theWarps[i].omg;
			theWarps[i].s -= theWarps[i].rgrav;
			
			if (theWarps[i].r > maxRad || theWarps[i].r < 0)
				theWarps[i].r = -1;
			
		} else  {
			
	    /* maintain a maximum attack value for scaling purposes*/
			
			maxA = (maxvalue[0]);
			
			
			if (maxA < 1) {maxA=1;}; 
			
	    /* fire off a new warp ring */
			theWarps[i].r = 0;
			theWarps[i].s = 3+(currentmax[0]>>5)*20/maxA;
			theWarps[i].trails = 1+(currentmax[0])*maxWarpTrails/maxA;
			theWarps[i].theta = rand()%360;
			theWarps[i].omg = (rand()%16 - 8)*(currentmax[0]>>6)/maxA;
			theWarps[i].col = rand()%256;
			theWarps[i].rgrav = rand()%2;
	    /*				soundAnalyze.fire = soundAnalyze.fire * 2 / 3;*/
		}
}



//********************************************** Blur_Routines routines *********************************



#ifndef X86_ASM_OPT
void bscope_blur_8(guchar *ptr,gint w, gint h, gint bpl)
{
	register guint i,sum, sum1;
	register guchar *iptr, *iptr1;
	
	iptr = ptr + bpl + 1;
	iptr1 = ptr + bpl*(h+1) +  1 ;
	i = bpl*h/2-1;
	while(i--)
	{
		sum1 = (iptr1[-bpl] + iptr1[-1] + iptr1[1] + iptr1[0]) >>2;
		sum = (iptr[0] + iptr[1] + iptr[-1] + iptr[bpl]) >> 2;
		if(sum > 2)
			sum -= 2;
		if(sum1 >2)
			sum1 -= 2; 
		*(iptr++) = sum;
		*(iptr1--) = sum1;
	}
	
	
}
#else
extern void bscope_blur_8(guchar *ptr,gint w, gint h, gint bpl);
#endif

void bscope_mblur_8(guchar *ptr,guchar *draw,gint w, gint h, gint bpl, gint colorchange)
{
	register guint i,sum;
	register guchar *iptr, *dest;
	
	iptr = ptr+1;
	dest = draw +  1 ;
	i = bpl*(h+2);
	while(i--)
	{
		sum = (iptr[-bpl] + iptr[-1] + iptr[1] + iptr[bpl]) >>2;
		if(sum > colorchange)
			sum -= colorchange;
		*(dest++) = sum;
		iptr++;
		
	}
	
	
}


void bscope_clear_8(guchar *ptr, gint w, gint h, gint bpl)
{
	register guint i;
	register guchar *iptr;
	
	iptr = ptr;
	i = bpl*(h+2);
	while(i--)
	{
		*(iptr++) = 0;
	} 
}

void bscope_clearedges_8(guchar *ptr, gint w, gint h, gint bpl)
{
	register guint i;
	register guchar *bptr; //bottom / right
	register guchar *tptr; //top / left
	
	bptr = ptr;
	tptr = ptr+(bpl*(h+1));
	i = bpl;
	while(i--)
	{
		*(bptr++) = 0;
		*(tptr++) = 0;
		
	} 
	
	
	i = h+2;
	bptr=ptr;
	tptr=ptr+bpl-1;
	while (i--)
	{
		*bptr=0;
		*tptr=0;
		bptr+=bpl;
		tptr+=bpl;
	}
	
}


int bscope_empty (guchar *ptr, gint w, gint curr)
{
	int i;
	for (i=0; i<w; i++) {
		if (ptr[i]) {
			return 0;
		}  	
	}
	return 1;
}


#define B_UPLEFT 0
#define B_UP 1
#define B_UPRIGHT 2
#define B_LEFT 3
#define B_RIGHT 4
#define B_DOWNLEFT 5
#define B_DOWN 6
#define B_DOWNRIGHT 7
#define B_MIDDLE 8

void blur_pixel(int direction, int offset, int map) {
	//returns the blur mask associated with the direction given
	//direction is 0 1 2 
	//                    3     4
	//                    5 6 7
	shift[map][offset]=0;
	switch (direction) {
		case 0: //up left
			shift[map][offset] = shift[map][offset] | (1<<2);
			shift[map][offset] = shift[map][offset] | (1<<5);
			shift[map][offset] = shift[map][offset] | (1<<4);
			shift[map][offset] = shift[map][offset] | (1<<6); 
			break;
			
		case 1: //up 
			shift[map][offset] = shift[map][offset] | (1<<3);
			shift[map][offset] = shift[map][offset] | (1<<4);
			shift[map][offset] = shift[map][offset] | (1<<6);
			break;
			
		case 2: //up right
			
			shift[map][offset] = shift[map][offset] | (1<<0);
			shift[map][offset] = shift[map][offset] | (1<<7);
			shift[map][offset] = shift[map][offset] | (1<<3);
			shift[map][offset] = shift[map][offset] | (1<<6);
			break;
		case 3: //left
			shift[map][offset] = shift[map][offset] | (1<<1);
			shift[map][offset] = shift[map][offset] | (1<<6);
			shift[map][offset] = shift[map][offset] | (1<<4);			
			break;
		case 4: //right
			shift[map][offset] = shift[map][offset] | (1<<1);
			shift[map][offset] = shift[map][offset] | (1<<3);
			shift[map][offset] = shift[map][offset] | (1<<6);
			break;
		case 5: //down left
			shift[map][offset] = shift[map][offset] | (1<<0);
			shift[map][offset] = shift[map][offset] | (1<<7);
			shift[map][offset] = shift[map][offset] | (1<<4);
			shift[map][offset] = shift[map][offset] | (1<<1);
			break;
		case 6: //down
			//down
			shift[map][offset] = shift[map][offset] | (1<<3);
			shift[map][offset] = shift[map][offset] | (1<<4);
			shift[map][offset] = shift[map][offset] | (1<<1);
			break;
		case 7: //down right
			shift[map][offset] = shift[map][offset] | (1<<2);
			shift[map][offset] = shift[map][offset] | (1<<5);
			shift[map][offset] = shift[map][offset] | (1<<1);
			shift[map][offset] = shift[map][offset] | (1<<3);
			break;			
		case 8: //middle
			shift[map][offset] = shift[map][offset] | (1<<4);
			shift[map][offset] = shift[map][offset] | (1<<6);
			shift[map][offset] = shift[map][offset] | (1<<1);
			shift[map][offset] = shift[map][offset] | (1<<3);
			break;			
			
	}
	
	
}


void bscope_vblur_8(guchar *ptr,guchar *draw,gint w, gint h, gint bpl, gint colorchange)
{
	register guint i,sum, sum1;
	register guchar *iptr, *iptr1, *dest, *dest1;
	int empty;
	
	empty=0;
	iptr = ptr;
	dest = draw;
	iptr1 = ptr + bpl*(h/2);
	dest1 = draw + bpl*(h/2);
	i = (bpl*(h+2)/2);
	while((i--))
	{
		
		sum1 = (iptr1[0] + iptr1[1] + iptr1[-bpl] + iptr1[-1]) >>2;
		sum = (iptr[bpl] + iptr[0] + iptr[1] + iptr[-1]) >> 2;
		if(sum >  colorchange)
			sum -= colorchange;
		if(sum1 >colorchange)
			sum1 -= colorchange; 
		iptr++;
		*(dest++) = sum;
		iptr1++;
		*(dest1++) = sum1;
	}
	
}

int mround(double n) {
	if (n <=-.5) return -1;
	else  if (n >= .5) return 1;
	else return 0;
	
}
int opposite(int n) {
	if (n==0) return 1;
	else return 0;
}



// ******************** Prepare the circular smoke blur map
void blurmap_circle(int map) {
	
	//cy is Center Y
	//cx is Center X
	
	int i, y, x, ans, j, offset;
	int cx, cy;
	int salt;
	
	double d;
	
	double slope, slopey;
	
	/* Go through each pixel and build a blur map for the circular blur
	   Each pixel has a byte associated with it. The bit values of this byte correspond to the 
	   pixels adjacent to the pixel we are on in the following scheme
	    0 1 2
	    3    4
	    5 6 7
	
	The generic blur function then takes the color values of the corresponding pixels and sums them all together when it
	runs through the image. *** We assume that the middle pixel is always chosen (this makes the mask it fit into a byte value) *** 

	*/
	
	cx = (width)/2;
	cy = (height)/2;
	
	for(j=0; j < (height+2); j++) {
		
		// Set y relative to the middle y cord
		y=(cy)-j; 
		for (i=0; i < bscope_cfg.BPL; i++) {
			// Set x relative to the middle x coord
			x=i-cx;
			
			d=(sqrt(x*x+y*y));
			salt=rand()%2;
			
			if (salt==0) salt=-1;
			else salt=1;
			
			slope=(double)(x)/(double)(y) ;
			slopey=1/slope;
			
			slope=slope+((double)(rand()%(2))/2*salt);
			slopey=slopey+((double)(rand()%(2))/2*salt);
			
			offset=j*bscope_cfg.BPL+i;
			
			if (x>0 && y>0) {
				//first quadrent				
				//as we get closer to the Y axis use the inverse of the slope
				if (slope < 1) {
					slopey = 1/slope;
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<9)) {
						blur_pixel(B_UPRIGHT, offset, map);
					} else {
						//right 
						blur_pixel(B_UP, offset, map);
						
					} 
				} else {
					if (((int)slope>0) &&!(x % (int)(slope))  && (slope<9)) {
							//up right
						blur_pixel(B_UPRIGHT, offset, map);
					} else {
						blur_pixel(B_RIGHT, offset, map);	
					} 
				}
				
			}
			
			if (x>0 && y<0) {
				//second quadrent
				//as we get closer to the Y axis use the inverse of the slope
				slopey = -slopey;
				slope = -slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<15)) {
						blur_pixel(B_DOWNRIGHT, offset, map);
					} else {
						//right 
						blur_pixel(B_DOWN, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<15)) {
							//up right
						blur_pixel(B_DOWNRIGHT, offset, map);
					} else {
						blur_pixel(B_RIGHT, offset, map);	
					}
				}
			}
			
			if (x<0 && y<0) {
				//third quadrent
				//as we get closer to the Y axis use the inverse of the slope
				slopey = slopey;
				slope = slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<15)) {
						blur_pixel(B_DOWNLEFT, offset, map);
					} else {
						//right 
						blur_pixel(B_DOWN, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<15)) {
							//up right
						blur_pixel(B_DOWNLEFT, offset, map);
					} else {
						blur_pixel(B_LEFT, offset, map);	
					}
				}
				
			}
			if (x<0 && y>0) {
				//fourth quadrent
				//as we get closer to the Y axis use the inverse of the slope				
				slopey = -slopey;
				slope = -slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<9)) {
						blur_pixel(B_UPLEFT, offset, map);
					} else {
						//right 
						blur_pixel(B_UP, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<9)) {
							//up right
						blur_pixel(B_UPLEFT, offset, map);
					} else {
						blur_pixel(B_LEFT, offset, map);	
					}
				}
				
			}
			
			
			
			if (y==0) 
				if (x>0) blur_pixel(B_RIGHT, offset, map);
				else if (x < 0) blur_pixel(B_LEFT, offset, map);
				else blur_pixel(B_MIDDLE, offset, map);
			
			if (x==0) 
				if (y>0) blur_pixel(B_UP, offset, map);
				else if (y < 0) blur_pixel(B_DOWN, offset, map);
				else blur_pixel(B_MIDDLE, offset, map);
			
			
			
			
		}
	}
}





void blurmap_spiral_left(int map) {
	
	//set up the circle in the middle of the screen
	int i, y, x, ans, j, offset;
	int salt;
	double d;
	
	
	double slope, slopey;
	/* Go through each pixel and build a blur map for the circular blur
	   Each pixel has a byte associated with it. The bit values of this byte correspond to the 
	   pixels adjacent to the pixel we are on in the following scheme
	    0 1 2
	    3    4
	    5 6 7
	
	The generic blur function then takes the color values of the corresponding pixels and sums them all together when it
	runs through the image. *** We assume that the middle pixel is always chosen (this makes the mask it fit into a byte value) *** 

	*/
	for(j=0; j < (height+2); j++) {
		
		// Set y relative to the middle y cord
		y=(height/2)-j; 
		for (i=0; i < bscope_cfg.BPL; i++) {
			// Set x relative to the middle x coord
			x=i-bscope_cfg.BPL/2;
			
			d=(sqrt(x*x+y*y));
			salt=rand()%2;
			
			if (salt==0) salt=-1;
			else salt=1;
			
			slope=(double)(x)/(double)(y) ;
			slopey=1/slope;
			
			slope=slope+((double)(rand()%(2))/2*salt);
			slopey=slopey+((double)(rand()%(2))/2*salt);
			
			offset=j*bscope_cfg.BPL+i;
			
			shift[map][offset]=0;
			
			if (x>0 && y>0) {
				//first quadrent				
				//as we get closer to the Y axis use the inverse of the slope
				if (slope < 1) {
					slopey = 1/slope;
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<9)) {
						blur_pixel(B_UPLEFT, offset, map);
					} else {
						//right 
						blur_pixel(B_LEFT, offset, map);
						
					} 
				} else {
					if (((int)slope>0) &&!(x % (int)(slope))  && (slope<9)) {
							//up right
						blur_pixel(B_UPLEFT, offset, map);
					} else {
						blur_pixel(B_UP, offset, map);	
					} 
				}
				
			}
			
			if (x>0 && y<0) {
				//second quadrent
				//as we get closer to the Y axis use the inverse of the slope
				slopey = -slopey;
				slope = -slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<15)) {
						blur_pixel(B_UPRIGHT, offset, map);
					} else {
						//right 
						blur_pixel(B_RIGHT, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<15)) {
							//up right
						blur_pixel(B_UPRIGHT, offset, map);
					} else {
						blur_pixel(B_UP, offset, map);	
					}
				}
			}
			
			if (x<0 && y<0) {
				//third quadrent
				//as we get closer to the Y axis use the inverse of the slope
				slopey = slopey;
				slope = slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<15)) {
						blur_pixel(B_DOWNRIGHT, offset, map);
					} else {
						//right 
						blur_pixel(B_RIGHT, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<15)) {
							//up right
						blur_pixel(B_DOWNRIGHT, offset, map);
					} else {
						blur_pixel(B_DOWN, offset, map);	
					}
				}
				
			}
			if (x<0 && y>0) {
				//fourth quadrent
				//as we get closer to the Y axis use the inverse of the slope				
				slopey = -slopey;
				slope = -slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<9)) {
						blur_pixel(B_DOWNLEFT, offset, map);
					} else {
						//right 
						blur_pixel(B_LEFT, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<9)) {
							//up right
						blur_pixel(B_DOWNLEFT, offset, map);
					} else {
						blur_pixel(B_DOWN, offset, map);	
					}
				}
				
			}
			
			
			
			if (y==0) 
				if (x>0) blur_pixel(B_UP, offset, map);
				else if (x < 0) blur_pixel(B_DOWN, offset, map);
				else blur_pixel(B_MIDDLE, offset, map);
			
			if (x==0) 
				if (y>0) blur_pixel(B_LEFT, offset, map);
				else if (y < 0) blur_pixel(B_RIGHT, offset, map);
				else blur_pixel(B_MIDDLE, offset, map);		
			
		}
	}
}

void blurmap_spiral_right(int map) {
	
	//set up the circle in the middle of the screen
	int i, y, x, ans, j, offset;
	int salt;
	double d;
	
	
	double slope, slopey;
	/* Go through each pixel and build a blur map for the circular blur
	   Each pixel has a byte associated with it. The bit values of this byte correspond to the 
	   pixels adjacent to the pixel we are on in the following scheme
	    0 1 2
	    3    4
	    5 6 7
	
	The generic blur function then takes the color values of the corresponding pixels and sums them all together when it
	runs through the image. *** We assume that the middle pixel is always chosen (this makes the mask it fit into a byte value) *** 

	*/
	for(j=0; j < (height+2); j++) {
		
		// Set y relative to the middle y cord
		y=(height/2)-j; 
		for (i=0; i < bscope_cfg.BPL; i++) {
			// Set x relative to the middle x coord
			x=i-bscope_cfg.BPL/2;
			
			d=(sqrt(x*x+y*y));
			salt=rand()%2;
			
			if (salt==0) salt=-1;
			else salt=1;
			
			slope=(double)(x)/(double)(y) ;
			slopey=1/slope;
			
			slope=slope+((double)(rand()%(2))/2*salt);
			slopey=slopey+((double)(rand()%(2))/2*salt);
			
			offset=j*bscope_cfg.BPL+i;
			
			shift[map][offset]=0;
			
			if (x>0 && y>0) {
				//first quadrent				
				//as we get closer to the Y axis use the inverse of the slope
				if (slope < 1) {
					slopey = 1/slope;
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<9)) {
						blur_pixel(B_DOWNRIGHT, offset, map);
					} else {
						//right 
						blur_pixel(B_RIGHT, offset, map);
						
					} 
				} else {
					if (((int)slope>0) &&!(x % (int)(slope))  && (slope<9)) {
							//up right
						blur_pixel(B_DOWNRIGHT, offset, map);
					} else {
						blur_pixel(B_DOWN, offset, map);	
					} 
				}
				
			}
			
			if (x>0 && y<0) {
				//second quadrent
				//as we get closer to the Y axis use the inverse of the slope
				slopey = -slopey;
				slope = -slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<15)) {
						blur_pixel(B_DOWNLEFT, offset, map);
					} else {
						//right 
						blur_pixel(B_LEFT, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<15)) {
							//up right
						blur_pixel(B_DOWNLEFT, offset, map);
					} else {
						blur_pixel(B_DOWN, offset, map);	
					}
				}
			}
			
			if (x<0 && y<0) {
				//third quadrent
				//as we get closer to the Y axis use the inverse of the slope
				slopey = slopey;
				slope = slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<15)) {
						blur_pixel(B_UPLEFT, offset, map);
					} else {
						//right 
						blur_pixel(B_LEFT, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<15)) {
							//up right
						blur_pixel(B_UPLEFT, offset, map);
					} else {
						blur_pixel(B_UP, offset, map);	
					}
				}
				
			}
			if (x<0 && y>0) {
				//fourth quadrent
				//as we get closer to the Y axis use the inverse of the slope				
				slopey = -slopey;
				slope = -slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<9)) {
						blur_pixel(B_UPRIGHT, offset, map);
					} else {
						//right 
						blur_pixel(B_RIGHT, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<9)) {
							//up right
						blur_pixel(B_UPRIGHT, offset, map);
					} else {
						blur_pixel(B_UP, offset, map);	
					}
				}
				
			}
			
			
			
			if (y==0) 
				if (x>0) blur_pixel(B_DOWN, offset, map);
				else if (x < 0) blur_pixel(B_UP, offset, map);
				else blur_pixel(B_MIDDLE, offset, map);
			
			if (x==0) 
				if (y>0) blur_pixel(B_RIGHT, offset, map);
				else if (y < 0) blur_pixel(B_LEFT, offset, map);
				else blur_pixel(B_MIDDLE, offset, map);		
			
		}
	}
}


void blurmap_suck(int map) {
	
	//cy is Center Y
	//cx is Center X
	
	int i, y, x, ans, j, offset;
	int cx, cy;
	int salt;
	
	double d;
	
	double slope, slopey;
	
	/* Go through each pixel and build a blur map for the circular blur
	   Each pixel has a byte associated with it. The bit values of this byte correspond to the 
	   pixels adjacent to the pixel we are on in the following scheme
	    0 1 2
	    3    4
	    5 6 7
	
	The generic blur function then takes the color values of the corresponding pixels and sums them all together when it
	runs through the image. *** We assume that the middle pixel is always chosen (this makes the mask it fit into a byte value) *** 

	*/
	
	cx = (width)/2;
	cy = (height)/2;
	
	for(j=0; j < (height+2); j++) {
		
		// Set y relative to the middle y cord
		y=(cy)-j; 
		for (i=0; i < bscope_cfg.BPL; i++) {
			// Set x relative to the middle x coord
			x=i-cx;
			
			d=(sqrt(x*x+y*y));
			salt=rand()%2;
			
			if (salt==0) salt=-1;
			else salt=1;
			
			slope=(double)(x)/(double)(y) ;
			slopey=1/slope;
			
			slope=slope+((double)(rand()%(2))/2*salt);
			slopey=slopey+((double)(rand()%(2))/2*salt);
			
			offset=j*bscope_cfg.BPL+i;
			
			if (x>0 && y>0) {
				//first quadrent				
				//as we get closer to the Y axis use the inverse of the slope
				if (slope < 1) {
					slopey = 1/slope;
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<9)) {
						blur_pixel(B_DOWNLEFT, offset, map);
					} else {
						//right 
						blur_pixel(B_DOWN, offset, map);
						
					} 
				} else {
					if (((int)slope>0) &&!(x % (int)(slope))  && (slope<9)) {
							//up right
						blur_pixel(B_DOWNLEFT, offset, map);
					} else {
						blur_pixel(B_LEFT, offset, map);	
					} 
				}
				
			}
			
			if (x>0 && y<0) {
				//second quadrent
				//as we get closer to the Y axis use the inverse of the slope
				slopey = -slopey;
				slope = -slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<15)) {
						blur_pixel(B_UPLEFT, offset, map);
					} else {
						//right 
						blur_pixel(B_UP, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<15)) {
						blur_pixel(B_UPLEFT, offset, map);
					} else {
						blur_pixel(B_LEFT, offset, map);	
					}
				}
			}
			
			if (x<0 && y<0) {
				//third quadrent
				//as we get closer to the Y axis use the inverse of the slope
				slopey = slopey;
				slope = slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<15)) {
						blur_pixel(B_UPRIGHT, offset, map);
					} else {
						//right 
						blur_pixel(B_UP, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<15)) {
						blur_pixel(B_UPRIGHT, offset, map);
					} else {
						blur_pixel(B_RIGHT, offset, map);	
					}
				}
				
			}
			if (x<0 && y>0) {
				//fourth quadrent
				//as we get closer to the Y axis use the inverse of the slope				
				slopey = -slopey;
				slope = -slope;
				if (slope < 1) {
					if (((int)slopey>0) && !(y % (int)(slopey)) && (slopey<9)) {
						blur_pixel(B_DOWNRIGHT, offset, map);
					} else {
						//right 
						blur_pixel(B_DOWN, offset, map);
					}
				} else {
					if (((int)slope>0) &&!(x % (int)(slope)) && (slope<9)) {
							//up right
						blur_pixel(B_DOWNRIGHT, offset, map);
					} else {
						blur_pixel(B_RIGHT, offset, map);	
					}
				}
				
			}
			
			
			
			if (y==0) 
				if (x>0) blur_pixel(B_LEFT, offset, map);
				else if (x < 0) blur_pixel(B_RIGHT, offset, map);
				else blur_pixel(B_MIDDLE, offset, map);
			
			if (x==0) 
				if (y>0) blur_pixel(B_DOWN, offset, map);
				else if (y < 0) blur_pixel(B_UP, offset, map);
				else blur_pixel(B_MIDDLE, offset, map);
			
			
			
			
		}
	}
}







void bscope_prepareblurmap() {
	
	static int oldshape;
	static int doublesize;
	static int first=1;
	if ( (first) || (oldshape!=bscope_cfg.shape) || (doublesize!=bscope_cfg.doublesize) )  {
		blurmap_circle(0);
		blurmap_spiral_left(1);
		blurmap_suck(2);
		blurmap_spiral_right(3);
		first=0;
		oldshape=bscope_cfg.shape;
		doublesize=bscope_cfg.doublesize;
	}
}



void bscope_cblur_8(guchar *ptr,guchar *draw,gint w, gint h, gint bpl, gint fade, int map)
{
	// Generalized blur function
	
	register int sum;
	register unsigned char *iptr;
	register unsigned char *dest;
	//register unsigned char *pixel;
	register unsigned char *shifts;
	register unsigned char i;
	register unsigned int j; 
	
	
	//	pixel=pixels[map];
	shifts=shift[map];
	iptr = ptr+1;
	dest = draw +  1 ;
	
	for (j=0; j<(h+2)*(bpl); j++) {
		
		// Grab the color value of the pixel we are on
		
		
		// Grab the blur map value from the array
		i=shifts[0];
		// If the bit representing the adjacent pixel is 1, grab the color value for that pixel
		switch (i) {
			case  88:
				//up
				sum = iptr[0] + iptr[-1] + iptr[1] + iptr[bpl];
				sum = sum>>2;
				break;
			case 82:	
				//left
				sum = iptr[0]+ iptr[-(bpl)] + iptr[1] + iptr[bpl];
				sum = sum >>2;
				break;
			case 74 :
				//right
				sum = iptr[0]+ iptr[-(bpl)] + iptr[-1] + iptr[bpl];
				sum = sum >>2;
				break;
			case 26 :
				//down
				sum = iptr[0] + iptr[-1] + iptr[1] + iptr[-bpl];
				sum = sum >>2;
				break;
			case 201 :
				//up right
				sum = iptr[0] + iptr[-(bpl+1)]+ iptr[(bpl+1)] +  iptr[-1] +iptr[bpl];
				sum = sum/5;
				break;
			case 116 :
				//up left
				sum = iptr[0] + iptr[-(bpl-1)] +iptr[bpl-1]+ iptr[1] + iptr[bpl];
				sum = sum /5;
				break;
			case 147 :
				//down left
				sum = iptr[0] + iptr[-(bpl+1)]+ iptr[(bpl+1)] + iptr[1] + iptr[-bpl];
				sum = sum/5;
				break;
			case 46 :
				//down right
				sum = iptr[0] + iptr[-(bpl-1)] +iptr[bpl-1]+iptr[-bpl]+iptr[-1];
				sum = sum/5;
				break;
				
			case 90 :
				//middle
				sum = iptr[0] + iptr[-1] + iptr[1] + iptr[-bpl] + iptr[bpl];
				sum = sum/5;
				break;
				
				
		}
		
		//if fade is 0 then skip this step 
		if((fade) && (sum >  2) )
			sum -= fade;
		
		shifts++; 
		iptr++;
		*(dest++)=sum;
		
	}
	
}

void bscope_hblur_8(guchar *ptr,guchar *draw,gint w, gint h, gint bpl, gint colorchange)
{
	register guint i,sum, sum1, j;
	register guchar *iptr, *iptr1, *dest, *dest1;
	int offset;
	
	sum1=0;
	for (j=0; j<(h+2); j++) {
		offset = bpl*j+1;
		iptr = ptr + offset;
		iptr1 = ptr +offset+bpl;
		
		dest = draw +offset;
		dest1 = draw+ offset + bpl;
		
		for (i=0; i<=(bpl); i++) {
		// right
			sum1 = (iptr1[-bpl+1] + iptr1[0] + iptr1[0] + iptr1[bpl+1]) >>2;
	         // left
			sum = (iptr[-bpl-1] + iptr[0] + iptr[0] + iptr[bpl-1]) >> 2;
			
			
			if(sum >  colorchange)
				sum -= colorchange;
			if (sum1 > colorchange)
				sum1 -= colorchange;
			
			iptr++;
			*(dest++) = sum;
			iptr1--;
			*(dest1--) = sum1;
			
		}
		
	}
	
	
}



//*********************************  Blur Scope ************************************


void bscope_read_config(void)
{
  bscope_cfg.color = 0xFF3F7F;
  bscope_cfg.effect=1;
  bscope_cfg.blur=1;
  bscope_cfg.fade=1;
  bscope_cfg.shape=0;
  bscope_cfg.doublesize=0;
  bscope_cfg.colormap=0;
  bscope_cfg.colorcycle=0;		
  bscope_cfg.stereo=0;
  numpresets=0;
  currentpreset=0;
		
  
  bscope_cfg.BPL=width;
  bscope_cfg.doublesize=1;
}
  




void bscope_changesize(void){
	static int doublesize;
	static int shape;
	static int first=TRUE;
	
	if (first) {
		doublesize=bscope_cfg.doublesize;
		shape=bscope_cfg.shape;
		first=FALSE;
	}

	/*
	switch (bscope_cfg.shape) {
			//horizontal rectangle
		case 0 : 
			if (bscope_cfg.doublesize) {
				width=512;
				height=250;
			} else {
				width=256;
				height=128;
			}
			break;
			//square
		case 1 :
			if (bscope_cfg.doublesize) {
				width=300;
				height=300;
			} else {
				width=150;
				height=150;
			}
			break;
			
			//vertical rectangle
		case 2 :
			if (bscope_cfg.doublesize) {
				width=250;
				height=512;
			} else {
				width=128;
				height=256;
			}
			break;
		case 3 :
			width=320;
			height=200;
			bscope_cfg.doublesize=1;
			break;
		case 4 :
			width=512;
			height=384;
			bscope_cfg.doublesize=1;
			break;
			
	}
	*/
	
	//gtk_widget_set_usize(window, width, height);
	bscope_cfg.BPL = width+2;
	if ((bscope_cfg.doublesize!=doublesize) || (bscope_cfg.shape!=shape)) {
		bscope_clear_8(rgb_buf, width, height, bscope_cfg.BPL);
		bscope_clear_8(rgb_buf_work, width, height, bscope_cfg.BPL);
		doublesize=bscope_cfg.doublesize;
		doublesize=bscope_cfg.shape;
	}
	
	bscope_prepareblurmap();
	
	
}
//------------------------- Color conversion functions -------------------------

typedef struct
{
	double  hue, saturation, value;
} hsv_t;


/* Convert a color from RGB format to HSV format */
hsv_t *rgb_to_hsv(guint32 rgb)
{
	static hsv_t	hsv;	/* HSV value (saved between invocations */
	double		r, g, b;/* the RGB components, in range 0.0 - 1.0 */
	double		max, min;/* extremes from r, g, b */
	double		delta;	/* difference between max and min */
	
	/* extract the RGB components from rgb */
	r = (double)((rgb >> 16) & 0xff) / 255.0;
	g = (double)((rgb >> 8) & 0xff) / 255.0;
	b = (double)(rgb & 0xff) / 255.0;
	
	/* find max and min */
	if (r > g)
	{
		max = (b > r) ? b : r;
		min = (g > b) ? b : g;
	}
	else
	{
		max = (b > g) ? b : g;
		min = (r > b) ? b : r;
	}
	
	/* compute "value" */
	hsv.value = max;
	
	/* compute "saturation" */
	hsv.saturation = (max > 0.0) ? (max - min) / max : 0;
	
	/* compute "hue".  This is the hard one */
	delta = max - min;
	if (delta <= 0.001)
	{
		/* gray - any hue will work */
		hsv.hue = 0.0;
	}
	else
	{
		/* divide hexagonal color wheel into three sectors */
		if (max == r)
			/* color is between yellow and magenta */
			hsv.hue = (g - b) / delta;
		else if (max == g)
			/* color is between cyan and yellow */
			hsv.hue = 2.0 + (b - r) / delta;
		else /* max == b */
			/* color is between magenta and cyan */
			hsv.hue = 4.0 + (r - g) / delta;
		
		/* convert hue to degrees */
		hsv.hue *= 60.0;
		
		/* make sure hue is not negative */
		if (hsv.hue < 0.0)
			hsv.hue += 360.0;
	}
	
	/* return the computed color */
	return &hsv;
}


/* convert a color from HSV format to RGB format */
guint32 hsv_to_rgb(hsv_t *hsv)
{
	guint32	r, g, b;/* RGB color components */
	double	h;	/* copy of the "hsv.hue" */
	double	i, f;	/* integer and fractional parts of "h" */
	int	p, q, t;/* permuted RGB values, in integer form */
	int	v;	/* "hsv.value", in integer form */
	
	if (hsv->saturation < 0.01)
	{
		/* simple gray conversion */
		r = g = b = (guint32)(hsv->value * 255.0);
	}
	else
	{
		/* convert hue to range [0,6) */
		h = hsv->hue / 60.0;
		while (h >= 6.0)
			h -= 6.0;
		
		/* break "h" down into integer and fractional parts. */
		i = floor(h);
		f = h - i;
		
		/* compute the permuted RGB values */
		v = (int)(hsv->value * 255.0);
		p = (int)((hsv->value * (1.0 - hsv->saturation)) * 255.0);
		q = (int)((hsv->value * (1.0 - (hsv->saturation * f))) * 255.0);
		t = (int)((hsv->value * (1.0 - (hsv->saturation * (1.0 - f)))) * 255.0);
		
		/* map v, p, q, and t into red, green, and blue values */
		switch ((int)i)
		{
			case 0:   r = v, g = t, b = p;	break;
			case 1:   r = q, g = v, b = p;	break;
			case 2:   r = p, g = v, b = t;	break;
			case 3:   r = p, g = q, b = v;	break;
			case 4:   r = t, g = p, b = v;	break;
			case 5:   r = v, g = p, b = q;	break;
		}
	}
	
	/* return the RGB value as a guint32 */
	return ((((guint32)r & 0xff) << 16)
		| (((guint32)g & 0xff) << 8)
		| ((guint32)b & 0xff));
}



/* ----------------- colormaps -----------------*/



int colormap_normal(int j, int r, int g, int b) {
	return ((j*r/256) << 16) | ((j*g/256) << 8) | ((j*b/256)) ;
}


int colormap_inverse(int j, int r, int g, int b) {
	int i;
	
	i=j;
	
	//alias the edges of the colormap, so it looks smooth
	if (j<6) i=256;
	if (j==6) i=224;
	if (j==7) i=192;
	if (j==8) i=160;
	if (j==9) i=128;
	if (j==10) i=96;
	if (j==11) i=64;
	if (j==12) i=32;
	return (((256-i)*r>>8) << 16) | (((256-i)*g>>8) << 8) | (((256-i)*b>>8));
}


int colormap_milky(int j, int r, int g, int b) {
	
	int i;	
	
	if (j<128){
		i=j;
		return ((i * r /128) << 16)
		| ((i * g / 128) << 8)
		| ((i * b / 128));	
	} else {
		i = 255 - j;
		return ((255 - (255 - r)*i / 128) << 16)
		| ((255 - (255 - g) * i/128) << 8)
		| (255 - (255 - b) * i/128);	
	}
	
}


int colormap_colorlayers(int j, int r, int g, int b) {
	
	int i;
	int tmp;
	i=j;
					        /* shift the hue */
	switch (i & 0xc0)
	{
		case 0x00:
			tmp = r;
			r = (r + g * 2) / 3;
			g = (g + b * 2) / 3;
			b = (b + tmp * 2) / 3;
				    /* fallthrough, so color gets shifted twice... */
			
		case 0x40:
			tmp = r;
			r = (r + g * 2) / 3;
			g = (g + b * 2) / 3;
			b = (b + tmp * 2) / 3;
			break;
	}
	
			      	  /* compute the brightness */
	if (i < 0x80)
		tmp = (i << 2) & 0xff;
	else
		tmp = (i << 1) & 0xff;
					// alias the transitions between the layers
	if (j == 61) tmp=192; 
	if (j == 62) tmp=128; 
	if (j == 63) tmp=64;
	if (j == 125) tmp=192; 	
	if (j == 126) tmp=128; 
	if (j == 127) tmp=64; 
	
				 /* set this color */
	return ((tmp*r/256) << 16) | ((tmp*g/256) << 8) | ((tmp*b/256)) ;
	
}




int colormap_layers(int j, int r, int g, int b) {
	
	int i;
	i=j;
	
					/*brightness*/
	if (i < 0x80)
		i = (i << 2) & 0xff;
	else
		i = (i << 1) & 0xff;
	
					// alias the transitions between the layers
	if (j == 61) i=192; 
	if (j == 62) i=128; 
	if (j == 63) i=64;
	if (j == 125) i=192; 	
	if (j == 126) i=128; 
	if (j == 127) i=64; 
	
	return ((i*r/256) << 16) | ((i*g/256) << 8) | ((i*b/256)) ;
	
}


int colormap_rainbow(guint32 i, int r, int g, int b)
{
	hsv_t	hsv;
	
	/* Get the base color */
	hsv = *rgb_to_hsv(bscope_cfg.color);
	
	/* Change the hue, and maybe brightness, depending on i */
	hsv.hue += 2 * (255 - i);
	if (hsv.hue >= 360.0)
		hsv.hue -= 360.0;
	if (i < 64)
		hsv.value *= (double)i / 64.0;
	
	/* Convert it back to RGB */
	return hsv_to_rgb(&hsv);
}


int colormap_standoff(guint32 i, int red, int green, int blue)
{
	/* compute the brightness */
	if (i >= 128)
		i = 0;
	else
	{
		if (i >= 64)
			i = (128 - i) * 3;
		else
			i *= 3;
		if (i > 254)
			i = 254;
	}
	
	/* set this color */
	return (((guint32)(i * red / 256) << 16)
		| ((guint32)(i * green / 256) << 8)
		| ((guint32)(i * blue / 256)));
}


int colormap_stripes(guint32 i, int red, int green, int blue)
{
	guint32	tmp;
	
	/* compute the brightness */
	if (i >= 0xd0)
		tmp = 254;
	else
	{
		switch (i & 0x18)
		{
			case 0x00: tmp = (i & 0x7) << 5;	break;
			case 0x18: tmp = ((~i) & 0x7) << 5;	break;
			default: tmp = 254;
		}
		if (i < 64)
			tmp = (tmp * i) >> 6;
	}
	
	/* set this color */
	return (((guint32)(tmp * red / 256) << 16)
		| ((guint32)(tmp * green / 256) << 8)
		| ((guint32)(tmp * blue / 256)));
}

int colormap_colorstripes(guint32 i, int red, int green, int blue)
{
	guint32	r, g, b, tmp;
	static guint32 brightness[] = {0, 64, 128, 192, 254, 254, 254, 254, 254, 254, 254, 254, 254, 192, 128, 64};
	
	/* compute the hue */
	tmp = i & 0x30;
	switch (i & 0xc0)
	{
		case 0x40:
			r = (green * tmp + red * (0x3f - tmp)) >> 6;
			g = (blue * tmp + green * (0x3f - tmp)) >> 6;
			b = (red * tmp + blue * (0x3f - tmp)) >> 6;
			break;
			
		case 0x80:
			r = (blue * tmp + green * (0x3f - tmp)) >> 6;
			g = (red * tmp + blue * (0x3f - tmp)) >> 6;
			b = (green * tmp + red * (0x3f - tmp)) >> 6;
			break;
			
		default:
			r = (red * tmp + blue * (0x3f - tmp)) >> 6;
			g = (green * tmp + red * (0x3f - tmp)) >> 6;
			b = (blue * tmp + green * (0x3f - tmp)) >> 6;
	}
	
	/* compute the brightness */
	if (i >= 0xf0)
		tmp = 254;
	else
	{
		tmp = brightness[i & 0xf];
		if (i < 64)
			tmp = (tmp * i) >> 6;
	}
	
	/* set this color */
	return (((guint32)(tmp * r / 256) << 16)
		| ((guint32)(tmp * g / 256) << 8)
		| ((guint32)(tmp * b / 256)));
}

int colormap_colorbands(guint32 i, int red, int green, int blue)
{
	guint32	r, g, b, tmp;
	
	/* compute the hue */
	tmp = i & 0x20;
	switch (i & 0xc0)
	{
		case 0x40:
			r = (green * tmp + red * (0x3f - tmp)) >> 6;
			g = (blue * tmp + green * (0x3f - tmp)) >> 6;
			b = (red * tmp + blue * (0x3f - tmp)) >> 6;
			break;
			
		case 0x80:
			r = (blue * tmp + green * (0x3f - tmp)) >> 6;
			g = (red * tmp + blue * (0x3f - tmp)) >> 6;
			b = (green * tmp + red * (0x3f - tmp)) >> 6;
			break;
			
		default:
			r = (red * tmp + blue * (0x3f - tmp)) >> 6;
			g = (green * tmp + red * (0x3f - tmp)) >> 6;
			b = (blue * tmp + green * (0x3f - tmp)) >> 6;
	}
	
	/* compute the brightness */
	if (i >= 0x40)
		tmp = 254;
	else
		tmp = i * 4;
	
	/* set this color */
	return (((guint32)(tmp * r / 256) << 16)
		| ((guint32)(tmp * g / 256) << 8)
		| ((guint32)(tmp * b / 256)));
}

int colormap_cloud(guint32 i, int red, int green, int blue)
{
	guint32	faded;	/* r/g/b level of gray version of color */
	guint32 r, g, b;
	
	/* Compute the gray version */
	faded = (red * 4 + green * 5 + blue * 3) / 12;
	
	/* handle a few specific colors */
	if (i == 128)
	{
		/* Use the given color */
		r = red;
		g = green;
		b = blue;
	}
	else if (i == 129 || i == 127)
	{
		/* Use a faded version of the color */
		r = (red + faded) / 2;
		g = (green + faded) / 2;
		b = (blue + faded) / 2;
	}
	else if (i > 192)
	{
		/* transition between the given color and white */
		i -= 192;
		r = (red * i + 255 * (63 - i)) / 64;
		g = (green * i + 255 * (63 - i)) / 64;
		b = (blue * i + 255 * (63 - i)) / 64;
	}
	else if (i > 128)
	{
		/* transition between white and faded */
		i -= 128;
		r = g = b = (255 * i + faded * (63 - i)) / 64;
	}
	else
	{
		/* transition between faded and black */
		r = g = b = faded * i / 128;
	}
	
	/* Construct a color value from r/g/b, and return it */
	return (r << 16) | (g << 8) | b;
}


int colormap_graying(guint32 i, int red, int green, int blue)
{
	guint32 faded, tmp;
	
	/* Compute the fully faded color's intensity.  Note that we actually
	 * make it slightly dimmer than the base color, because it seems to
	 * look better that way.
	 */
	faded = (red * 4 + green * 5 + blue * 3) / 16;
	
	/* colormap is divided into two phases: fading and dimming */
	if (i < 64)
	{
		/* full gray, becoming dimmer */
		return ((faded * i * 4) >> 8) * 0x010101;
	}
	else
	{
		/* full brightness, but fading to gray */
		i -= 64;
		tmp = 192 - i;
		return (((i * red + tmp * faded) / 192) << 16)
		| (((i * green + tmp * faded) / 192) << 8)
		| ((i * blue + tmp * faded) / 192);
	}
}



void generate_cmap(guint currentcolormap, guint tocolor, guint nextcolormap)
{
	{
	  NSColor *color = [NSColor redColor];
		guint32 i,red,blue,green, max, j;
		guint32 r, g, b, tmp;
		guint32 colormap;

		r = [color redComponent] * 255.0;
		g = [color greenComponent] * 255.0;
		b = [color blueComponent] * 255.0;
		
		for(j = 255; j > 0; j--) {
			
			if ((j >tocolor)) colormap=nextcolormap; 
			else colormap=currentcolormap;
			
			switch (colormap) {
				
				case 1 :  //normal 
					colors[j] = colormap_normal(j, r, g, b);
					break;
					
				case 2: //inverted
					colors[j] = colormap_inverse(j, r, g, b);
					break;
					
				case 3 : //milky
					colors[j] = colormap_milky(j, r, g, b);
					break;
					
				case 4 : //layers
					colors[j] =  colormap_layers(j, r, g, b);
					break;
					
				case 5 : //color layers
					colors[j] =  colormap_colorlayers(j, r, g, b);
					break;
					
				case 6 : //rainbow
					colors[j] =  colormap_rainbow(j, r, g, b);
					break;
					
				case 7 : //standoff
					colors[j] =  colormap_standoff(j, r, g, b);
					break;
					
				case 8 : //stripes
					colors[j] =  colormap_stripes(j, r, g, b);
					break;
					
				case 9 : //color stripes
					colors[j] =  colormap_colorstripes(j, r, g, b);
					break;
					
				case 10 : //colorbands
					colors[j] =  colormap_colorbands(j, r, g, b);
					break;
					
					
					
			}
			
		}
		//always set the lowest intensities to 0
		colors[0]=0;
		colors[1]=0;
		colors[2]=0;
	
		
	}
}


/* rgb <-> hsv conversion from gtkcolorsel.c */
static void blurscope_rgb_to_hsv (guint32 color,
	gdouble *h, gdouble *s, gdouble *v)
{
	gdouble max, min, delta, r, g, b;
	
	r = (gdouble)(color>>16) / 255.0;
	g = (gdouble)((color>>8)&0xff) / 255.0;
	b = (gdouble)(color&0xff) / 255.0;
	
	max = r;
	if (g > max) max = g;
	if (b > max) max = b;
	
	min = r;
	if (g < min) min = g;
	if (b < min) min = b;
	
	*v = max;
	
	if (max != 0.0) *s = (max - min) / max;
	else *s = 0.0;
	
	if (*s == 0.0) *h = 0.0;
	else
	{
		delta = max - min;
		
		if (r == max) *h = (g - b) / delta;
		else if (g == max) *h = 2.0 + (b - r) / delta;
		else if (b == max) *h = 4.0 + (r - g) / delta;
		
		*h = *h * 60.0;
		
		if (*h < 0.0) *h = *h + 360;
	}
}

static void blurscope_hsv_to_rgb (gdouble  h, gdouble  s, gdouble  v,
	guint32 *color)
{
	gint i;
	gdouble f, w, q, t, r, g, b;
	
	if (s == 0.0)
		s = 0.000001;
	
	if (h == -1.0)
	{
		r = v; g = v; b = v;
	}
	else
	{
		if (h == 360.0) h = 0.0;
		h = h / 60.0;
		i = (gint) h;
		f = h - i;
		w = v * (1.0 - s);
		q = v * (1.0 - (s * f));
		t = v * (1.0 - (s * (1.0 - f)));
		
		switch (i)
		{
			case 0: r = v; g = t; b = w; break;
			case 1: r = q; g = v; b = w; break;
			case 2: r = w; g = v; b = t; break;
			case 3: r = w; g = q; b = v; break;
			case 4: r = t; g = w; b = v; break;
        /*case 5: use default to keep gcc from complaining */
			default: r = v; g = w; b = q; break;
		}
	}
	
	*color = ((guint32)((gdouble)r*255)<<16) | ((guint32)((gdouble)g*255)<<8) | ((guint32)((gdouble)b*255));
}



static void color_cycle(){
	gdouble h;
	gdouble s;
	gdouble v;
	
	
	blurscope_rgb_to_hsv (bscope_cfg.color, &h, &s, &v);
	h+=(rand()%4);
	if (rand()%3) s+=(rand()%10)/100;
	else s-=(rand()%10)/100;
	if (rand()%2) v+=(rand()%10)/100;
	else v-=(rand()%10)/100;
	
	if (h>360) h=h-360;
	if (h<0) h=h+360;
	
	if (s>1) s=s-1;
	if (s<0) s=s+1;
	
	if (v>1) v=v-1;
	if (v<0) v=v+1;
	
	blurscope_hsv_to_rgb (h,s, v, &bscope_cfg.color);	
}



static inline void draw_vert_line(guchar *buffer, gint x, gint y1, gint y2)
{
	int y;
	if(y1 < y2)
	{
		for(y = y1; y <= y2; y++)
			draw_pixel_8(buffer,x,y,0xFF);
	}
	else if(y2 < y1)
	{
		for(y = y2; y <= y1; y++)
			draw_pixel_8(buffer,x,y,0xFF);
	}
	else
		draw_pixel_8(buffer,x,y1,0xFF);
}


static void swap_buffers()
{
	guchar *tmp;
	tmp = active_buffer;
	active_buffer = work_buffer;
	work_buffer = tmp;
	
}


static void bscope_blurf(int blur, int time, int fade) {
	BUMP_LOCK();
	switch (blur) {
		case 1 :
			// vertical smoke
			bscope_vblur_8(active_buffer, work_buffer, width, height, bscope_cfg.BPL, fade);
			
			break;
		case 2 :
			//horizontal smoke
			bscope_hblur_8(active_buffer, work_buffer, width, height, bscope_cfg.BPL, fade);
			break;
		case 3 :
			//circular smoke
			bscope_cblur_8(active_buffer, work_buffer,  width, height, bscope_cfg.BPL,fade, 0);
			break;
		case 4 :
			//Spiral Left
			bscope_cblur_8(active_buffer, work_buffer,  width, height, bscope_cfg.BPL,fade, 1);
			break;
			
			
		case 5 :
			//Spiral right
			bscope_cblur_8(active_buffer, work_buffer,  width, height, bscope_cfg.BPL,fade, 3);
			
			break;
			
		case 6 :
			//suck
			bscope_cblur_8(active_buffer, work_buffer,  width, height, bscope_cfg.BPL,fade, 2);
			
			
			break;
		case 7 :
			//Orginal Blur (with exception of the fade)
			bscope_mblur_8(active_buffer, work_buffer, width, height, bscope_cfg.BPL, fade);
			break;
			
		case 8 :
			//Clear screen
			bscope_clear_8(work_buffer, width, height, bscope_cfg.BPL);
			break;
	}
	BUMP_UNLOCK();
	
	
}


static void bscope_effect(gint16 data[2][512], int effect, guchar stereo) {
	guchar color[2];
	BUMP_LOCK();
	Max(data);
	
	
	
	//set colors based on a floating percentage operation
	if (maxvalue[0]<1) color[0]=0;
	else color[0]=((255*currentmax[0])/maxvalue[0]);	
	
	if (maxvalue[1]<1) color[1]=0;
	else color[1]=((255*currentmax[1])/maxvalue[1]);	
	
	switch (effect) {
		case 1 :
			wave_lineHor(data, active_buffer, stereo, color);
			break;
		case 2 :
			wave_dotHor(data, active_buffer, stereo, color);
			break;
		case 3 :
			wave_solidHor(data, active_buffer, stereo, color);
			break;
		case 4 :
			wave_lineVert(data, active_buffer, stereo, color);
			break;
		case 5 :
			wave_dotVert(data, active_buffer, stereo, color);
			break;			
		case 6 :
			wave_solidVert(data, active_buffer, stereo, color);
			break;
		case 7 :
			wave_buff15(data, active_buffer, stereo);
			break;
		case 8 :
			wave_matt(data, active_buffer, stereo);
			break;
		case 9 :
			wave_warp(data, active_buffer, stereo);
			break;
		case 10 :
			wave_ringwave(data, active_buffer, stereo, color);
			break;
	}
	bscope_clearedges_8(active_buffer, width, height, bscope_cfg.BPL);
	bscope_clearedges_8(work_buffer, width, height, bscope_cfg.BPL);
	BUMP_UNLOCK();
	
}



static void bscope_animateblur(guint time) {
	static int previousmaxleft;
	static int previousmaxright;
	static int currentblur;
	static int nextblur;
	
	double sine, slope, slopey, cosine;
	
	static int mod1=-1;
	static int k=4;
	static int l=5;
	int temp;
	int fade=1;
	
	
	sine = isin(time%360);
	cosine = icos(time%360);
	
	slope=cosine/sine;
	slopey=sine/cosine;
	
	if (sine>0 && cosine>0) {
				//first quadrent				
			//as we get closer to the Y axis use the inverse of the slope
		if (((int)slopey>0) && !(time % (int)(slopey)) && (slopey<9)) {
				//blur
			nextblur=3;
		} else nextblur=7;
	}
	
	
	
	/*	
	if (currentmax[0]-previousmaxleft > 10) {
		nextblur=7;
				//triggerexpand
	} else if (currentmax[0]-previousmaxleft  < 0) {
				//triggercontract
		nextblur=6;
	} else {
				//trigerblur
		nextblur=7;
	}
*/
	/*
	if (!(time%(k+1))) {
		if (k>4) {
			mod1=-1;
			k=4;
			if (currentmax[0]-previousmaxleft > 0) {
				nextblur=3;
				//triggerexpand
			} else if (currentmax[0]-previousmaxleft < 0) {
				//triggercontract
				nextblur=7;
			} else {
				//trigerblur
				nextblur=7;
			}
			
		} else {
			if ((k ==1) && (l==0)) {
				mod1=1;
				//swap effects
				temp=nextblur;
				nextblur=currentblur;
				currentblur=temp;
				
			} 
			bscope_blurf(nextblur, time, fade);
			
			//write like this a few times to smooth the transitions.
			if ( (l==0)) {
				k+=mod1;
				l=5;
			} else l--; 
			
		}
	} else bscope_blurf(currentblur, time, fade);*/
	bscope_blurf(nextblur, time, fade);
	/*

	switch(time%4) {
		case 0 :
			bscope_blurf(6, time, fade);
			break;
		case 1 :
			bscope_blurf(4, time, fade);
			
			break;
		case 2 :
			bscope_blurf(3, time, fade);
			break;
		case 3 :
			bscope_blurf(5, time, fade);
			break;
	}
	
	*/
	/*
	if (currentmax[0] > 128) {
		bscope_blurf(6, time, fade);
		//triggerexpand
	} else if (currentmax[0] < 128) {
		//triggercontract
		bscope_blurf(3, time, fade);
	} else {
		//trigerblur
		bscope_blurf(7, time, fade);
	}
	
	*/
	
	
	previousmaxleft=currentmax[0];
	previousmaxright=currentmax[1];
	
	
	
	
}


- (void)renderPCM:(gint16[2][512])data
{
	static guint time = 0;
	static BlurScopeConfig current;
	static BlurScopeConfig next;	
	static int transitioneffect=FALSE;
	static int transitionblur=FALSE;
	static int transitioncolormap=FALSE;
	
	static int tocolor=0;
	
	static int mod=-1;
	static int mod1=-1;
	static int i=3;
	static int j=3;
	static int k=3;
	static int l=3;
	int temp;

  if ( bit_data[0] == 0 )
    {
      bit_data[0] = malloc(WIDTH*HEIGHT);
      bit_data[1] = malloc(WIDTH*HEIGHT);
      bit_data[2] = malloc(WIDTH*HEIGHT);
    }
	
	
	//to achieve smooth transitions between effects, start drawing the new effect every so often, decrementing the counter each time,
	// eventually drawing it every other frame. At that point, swap the current and the next effect, and increment the counter 
	//to achieve a fade out of the old effect.
	
	//write the transition effect before we blur, that way it's always apparent which is playing.
	if (transitioneffect) 
		if (!(time%(i+1))) {
			if (i>3) {
				//end the transition
				mod=-1;
				transitioneffect=FALSE;
				i=3;
			} else {
			//if i=the base value, swap the effects, then go on with life. Nexteffect and nextstereo will just be overwritten
			//by the random or user choice.
				if ((i ==1) && (j!=0) ) {
					mod=1;
				//swap effects
					temp=next.effect;
					next.effect=current.effect;
					current.effect=temp;
					temp=next.stereo;
					next.stereo=current.stereo;
					current.stereo=temp;
					
				}
				
			//write the effect out
				bscope_effect(data, next.effect, next.stereo);
				
				
			//use j to allow for finer control of fade.
				if (j==0) {
					i+=mod;
					j=3;
				} else j--; 
				
				
				
			}
		} else 	bscope_effect(data, current.effect, current.stereo);
	if (bscope_cfg.bgeffect==0)  {
		if (!(time%900)) {
			current.bgeffect=rand()%10+1;
			current.bgstereo=rand()%2+1;
		} else if (!(time%3)  && (current.bgeffect != current.effect)) 
			bscope_effect(data, current.bgeffect, current.bgstereo);
		
		
	} else if (!(time%3) && (bscope_cfg.bgeffect != bscope_cfg.effect)) 
		bscope_effect(data, bscope_cfg.bgeffect, bscope_cfg.bgstereo);
	
	
	
	//blur the active buffer and put the results in the working buffer
	
	
	//	bscope_animateblur(time);
	
	
	//randomize the blur if needed
	if ((bscope_cfg.blur==0) && (!transitionblur)) {
		if (!(time%200)) {
			next.blur=rand()%7+1;
			
			//currentblur=rand()%7+1;
			next.fade=rand()%3;
			transitionblur=TRUE;
			//currentfade=rand()%3;
		} else {
			bscope_blurf(current.blur, time, current.fade);
		}
		
	} else bscope_blurf(bscope_cfg.blur, time, bscope_cfg.fade);
	
	if (transitionblur) 
		if (!(time%(k+1))) {
			if (k>3) {
				mod1=-1;
				transitionblur=FALSE;
				k=3;
			} else {
				if ((k ==1) && (l==0)) {
					mod1=1;
				//swap effects
					temp=next.blur;
					next.blur=current.blur;
					current.blur=temp;
					temp=next.fade;
					next.fade=current.fade;
					current.fade=temp;
				} 
				bscope_blurf(next.blur, time, next.fade);
				
			//write like this a few times to smooth the transitions.
				if ( (l==0)) {
					k+=mod1;
					l=3;
				} else l--; 
				
			}
		} else  bscope_blurf(current.blur, time, current.fade);
	
	
	
		//swap to the work buffer to be the active buffer
	swap_buffers();
	
	BUMP_LOCK();
	if (transitioncolormap && !bscope_cfg.colormap) {
		if (tocolor > 0) {
			//generate the colormap, with the high values as the next colormap
			tocolor--;
			generate_cmap(current.colormap, tocolor, next.colormap);
			
		} else {
			//we are done
			transitioncolormap=FALSE;
			current.colormap=next.colormap;
			generate_cmap(current.colormap, 0, next.colormap);
		}
		
	}	
	
	
	
	if (!transitioncolormap)
		if ((bscope_cfg.colormap==0)) {
			if (!(time%900)) {
				next.colormap=rand()%10+1;
				transitioncolormap=TRUE;
				tocolor=254;
			} else {
				if (bscope_cfg.colorcycle) {
					if (!(time%10)) {
						color_cycle();
						generate_cmap(current.colormap, 0, current.colormap);
					}
				} 
			}
		} else if (bscope_cfg.colorcycle) {
			if (!(time%10)) {
				
				color_cycle();
				generate_cmap(bscope_cfg.colormap,0, bscope_cfg.colormap);
				
				
			}
		}
		
	BUMP_UNLOCK();	
	
	
	//draw the effect on the active buffer
	if ((bscope_cfg.effect==0) && (!transitioneffect)) {
		if (!(time%300)) {
			next.stereo=rand()%2;
			next.effect=rand()%10+1;
			transitioneffect=TRUE;
		} else {
			bscope_effect(data, current.effect, current.stereo);
		}
		
	} else bscope_effect(data, bscope_cfg.effect, bscope_cfg.stereo);
	
	
	blurscope_need_draw = 1;
	
	time++;

  for ( i = 0; i < (bscope_cfg.BPL*HEIGHT); i++ )
    {
      guint32 red,blue,green, color;
      color = colors[active_buffer[i]];
      red = (guint32)(color / 0x10000);
      green = (guint32)((color % 0x10000)/0x100);
      blue = (guint32)(color % 0x100);
      bit_data[0][i] = red;
      bit_data[1][i] = green;
      bit_data[2][i] = blue;
    }

  datavalid = YES;
  [lock unlock];


  for ( i = 0 ; i < [views count]; i++ )
    {
      NSView *view = [views objectAtIndex:i];
      if ( [view superview] != nil )
	    [view setNeedsDisplay:YES];
    }
}

- (void)drawInView:(VisualizationView *)view
{
  if ( datavalid )
    {
      if ( [view lockFocusIfCanDraw] ) 
	{
	  [lock lock];

	  NSDrawBitmap(NSMakeRect(0, 0, width, height),
		       width, height, 8, 3, 8, bscope_cfg.BPL,
		       YES, NO, NSDeviceRGBColorSpace, bit_data);
	  [view unlockFocus];
	  [lock unlock];
	}
    }
}


@end
