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

#import <MXA/NibObject.h>
#import <MXA/MXAConfig.h>

@interface SSVConfigure : NibObject
{
  id style;
  id peaks;
  id linesOrBars;

  id scopeMode;
  id vuMode;
  id falloff;
  id peaksFalloff;

  id refreshRate;
}

+ (void)initConfiguration;

@end

typedef enum
{
	VIS_ANALYZER,VIS_SCOPE,VIS_OFF
} VisType;

typedef enum
{
	ANALYZER_NORMAL,ANALYZER_FIRE,ANALYZER_VLINES
} AnalyzerMode;
	

typedef enum
{
	ANALYZER_LINES,ANALYZER_BARS
} AnalyzerType;

	
typedef enum
{
  SCOPE_DOT,SCOPE_LINE,SCOPE_SOLID
} ScopeMode;
	
typedef enum
{
  VU_NORMAL,VU_SMOOTH
} VUMode;
	
typedef enum
{
  REFRESH_EIGTH, REFRESH_QUARTER, REFRESH_HALF, REFRESH_FULL
} RefreshRate;
	
typedef enum
{
  FALLOFF_SLOWEST,FALLOFF_SLOW,FALLOFF_MEDIUM,FALLOFF_FAST,FALLOFF_FASTEST
} FalloffSpeed;

typedef enum
{
  INPUT_VIS_ANALYZER,INPUT_VIS_SCOPE,INPUT_VIS_VU,INPUT_VIS_OFF
} InputVisType;

extern NSString *CFGAnalyzerMode;
extern NSString *CFGAnalyzerType;
extern NSString *CFGScopeMode;
extern NSString *CFGVUMode;
extern NSString *CFGRefreshRate;
extern NSString *CFGFalloffSpeed;
extern NSString *CFGPeaksFalloff;
extern NSString *CFGAnalyzerPeaks;



