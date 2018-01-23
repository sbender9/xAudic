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

#import <AppKit/AppKit.h>
#import "SSVConfigure.h"

NSString *CFGAnalyzerMode = @"ssv.AnalyzerMode";
NSString *CFGAnalyzerType = @"ssv.AnalyzerType";
NSString *CFGScopeMode = @"ssv.ScopeMode";
NSString *CFGVUMode = @"ssv.VUMode";
NSString *CFGRefreshRate = @"ssv.RefreshRate";
NSString *CFGFalloffSpeed = @"ssv.FalloffSpeed";
NSString *CFGAnalyzerPeaks = @"ssv.AnalyzerPeaks";
NSString *CFGPeaksFalloff = @"ssv.PeaksFalloff";

@implementation SSVConfigure

+ (void)initConfiguration
{
  static BOOL didit = NO;
  if ( didit == NO )
    {
      [config setIntValue:FALLOFF_FAST forKey:CFGPeaksFalloff];
      [config setIntValue:FALLOFF_FAST forKey:CFGFalloffSpeed];
      [config setIntValue:REFRESH_FULL forKey:CFGRefreshRate];
      [config setIntValue:ANALYZER_LINES forKey:CFGAnalyzerType];
      [config setIntValue:ANALYZER_FIRE forKey:CFGAnalyzerMode];
      [config setBoolValue:YES forKey:CFGAnalyzerPeaks];
      [config setIntValue:SCOPE_DOT forKey:CFGScopeMode];
      [config setIntValue:VU_SMOOTH forKey:CFGVUMode];
      didit = YES;
    }
}

- (void)updateDisplay
{
  [style selectCellWithTag:[config intValueForKey:CFGAnalyzerMode]];
  [peaks setState:[config boolValueForKey:CFGAnalyzerPeaks]];
  [linesOrBars selectCellWithTag:[config intValueForKey:CFGAnalyzerType]];
  [scopeMode selectCellWithTag:[config intValueForKey:CFGScopeMode]];
  [vuMode selectCellWithTag:[config intValueForKey:CFGVUMode]];
  [falloff setIntValue:[config intValueForKey:CFGFalloffSpeed]];
  [peaksFalloff setIntValue:[config intValueForKey:CFGPeaksFalloff]];
  [refreshRate setIntValue:[config intValueForKey:CFGRefreshRate]];
}

- (void)ok:sender
{
  [config setIntValue:[peaksFalloff intValue]  forKey:CFGPeaksFalloff];

  [config setIntValue:[falloff intValue]  forKey:CFGFalloffSpeed];

  [config setIntValue:[refreshRate intValue] forKey:CFGRefreshRate];

  [config setIntValue:[[linesOrBars selectedCell] tag]
	  forKey:CFGAnalyzerType];

  [config setIntValue:[[style selectedCell] tag] forKey:CFGAnalyzerMode];

  [config setBoolValue:[peaks intValue] forKey:CFGAnalyzerPeaks];

  [config setIntValue:[[scopeMode selectedCell] tag] forKey:CFGScopeMode];

  [config setIntValue:[[vuMode selectedCell] tag] forKey:CFGVUMode];
  [super ok:sender];
}

@end
