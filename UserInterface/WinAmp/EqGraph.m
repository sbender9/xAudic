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
#import "EqGraph.h"
#import "Skin.h"
#import "Button.h"
#import <MXA/MXAConfig.h>

static void init_spline(float *x,float *y,int n,float *y2)
{
  int i,k;
  float p,qn,sig,un,*u;
	
  u=(float *)malloc(n*sizeof(float));
  
  y2[0]=u[0]=0.0;
  
  for(i=1;i<n-1;i++) 
    {
      sig=((float)x[i]-x[i-1])/((float)x[i+1]-x[i-1]);
      p=sig*y2[i-1]+2.0;
      y2[i]=(sig-1.0)/p;
      u[i]=(((float)y[i+1]-y[i])/(x[i+1]-x[i]))-(((float)y[i]-y[i-1])/(x[i]-x[i-1]));
      u[i]=(6.0*u[i]/(x[i+1]-x[i-1])-sig*u[i-1])/p;
    }
  qn=un=0.0;
  
  y2[n-1]=(un-qn*u[n-2])/(qn*y2[n-2]+1.0);
  for(k=n-2;k>=0;k--)
    y2[k]=y2[k]*y2[k+1]+u[k];
  free(u);
}

static float eval_spline(float xa[],float ya[],float y2a[],int n,float x)
{
  int klo,khi,k;
  float h,b,a;

  klo=0;
  khi=n-1; 
  while(khi-klo>1) 
    {
      k=(khi+klo)>>1;
      if(xa[k]>x)
	khi=k;
      else
	klo=k;
    }
  h=xa[khi]-xa[klo];
  a=(xa[khi]-x)/h;
  b=(x-xa[klo])/h;
  return (a*ya[klo]+b*ya[khi]+((a*a*a-a)*y2a[klo]+(b*b*b-b)*y2a[khi])*(h*h)/6.0);
}

@implementation EqGraph

- (BOOL)isOpaque
{
  return YES;
}

- (BOOL)isFlipped
{
  return YES;
}

- (void)drawRect:(NSRect)rect
{
  int i,y,ymin,ymax,py = 0;
  float x[]={0,11,23,35,47,59,71,83,97,109},yf[10];
  NSRect frame = [self frame];

  [[currentSkin eqmain] 
    compositeToPoint:NSMakePoint(0,frame.size.height)
	    fromRect:flipRect(NSMakeRect(0,294, frame.size.width, 
					 frame.size.height),
			      [currentSkin eqmain])
	   operation:NSCompositeCopy];

//  y = ([config equalizer_preamp]*10.0)/25.0;
  y = ([config equalizer_preamp]+20)*0.45;

  [[currentSkin eqmain] 
    compositeToPoint:NSMakePoint(0, y+1)
	    fromRect:flipRect(NSMakeRect(0,314, frame.size.width, 1),
			      [currentSkin eqmain])
	   operation:NSCompositeCopy];

  init_spline(x,[config eq_bands],10,yf);
  for(i=0;i<109;i++) {
    y=9-(int)((eval_spline(x,[config eq_bands],yf,10,i)*9.0)/20.0);
    if(y<0) y=0;
    if(y>18) y=18;
    if(!i) py=y;
    if(y<py) {
      ymin=y;
      ymax=py;
    } else {
      ymin=py;
      ymax=y;
    }
    py=y;
    for(y=ymin;y<=ymax;y++) {
      [[currentSkin eqmain] 
	compositeToPoint:NSMakePoint(i+2, y+1)
		fromRect:flipRect(NSMakeRect(115, 294+y, 1, 1),
				  [currentSkin eqmain])
	       operation:NSCompositeCopy];
    }
  }	
}

- initWithPoint:(NSPoint)pos
{
  NSRect r;
  r.origin = pos;
  r.size = NSMakeSize(113,19);
  return [super initWithFrame:r];
}


@end
