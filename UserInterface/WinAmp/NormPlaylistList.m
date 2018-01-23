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
#import "NormPlaylistList.h"
#import <MXA/PlaylistEntry.h>
#import <MXA/MXAConfig.h>
#import <MXA/Control.h>
#import "Skin.h"

@implementation NormPlaylistList


- initWithFrame:(NSRect)frame target:_target action:(SEL)_action 
					     slider:_slider
{
  [super initWithFrame:frame];
  last_selection = -1;
  target = _target;
  action = _action;
  infoUpdaterLock = [[NSLock alloc] init];
  slider = _slider;
  first = -1;

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(selectionChanged:)
	   name:PlaylistSelectionChangedNotification
	 object:nil];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(playlistChanged:)
	   name:PlaylistChangedNotification
	 object:nil];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(newPlaylist:)
	   name:NewPlaylistNotification
	 object:nil];

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [infoUpdaterLock release];
  [super dealloc];
}

- (void)mouseUp:(NSEvent *)theEvent
{
}


#define startTimer() \
  if ( doingPeriodicEvents == NO ) { \
    [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1]; \
    doingPeriodicEvents = YES; \
    autoScrollEvent = [theEvent retain]; \
  }

#define stopTimer() \
  [NSEvent stopPeriodicEvents]; \
  doingPeriodicEvents = NO; \
  [autoScrollEvent release]; \
  autoScrollEvent = nil;


- (void)mouseDown:(NSEvent *)theEvent
{
  NSPoint point;
  int idx;
  PlaylistEntry *entry;
  int i;

  if ( [Control getPlaylistLength]  == 0 )
    return;

  point = [self convertPoint:[theEvent locationInWindow] fromView:nil];

  idx = first + (num_visible - (point.y / fheight));
  entry = [Control getPlaylistEntryAt:idx];
  
  if ( [theEvent modifierFlags] & NSCommandKeyMask ) {
    [entry setSelected:![entry selected]];
  } else if ( [theEvent modifierFlags] & NSShiftKeyMask ) {
    if ( last_selection == -1 ) {
      [entry setSelected:YES];
    } else {
      int start, stop;
      start = idx > last_selection ? last_selection : idx;
      stop = idx > last_selection ? idx : last_selection;
      for ( i = start; i <= stop; i++ )
	[[Control getPlaylistEntryAt:i] setSelected:YES];
    }
  } else if ( [theEvent modifierFlags] & NSControlKeyMask ) {
    NSPoint curPoint;
    int moveCurTo = idx, minSel, maxSel;
    int moveTo;
    BOOL doingPeriodicEvents = NO;
    NSRect frame = [self frame];
    NSEvent *autoScrollEvent = nil;
    
    if ( [entry selected] ) {
      while (1) {

	theEvent = [[self window] nextEventMatchingMask:
		     (NSLeftMouseDraggedMask | NSLeftMouseUpMask
		      | NSPeriodicMask)];

	if ([theEvent type] == NSLeftMouseUp)
	  break;

	curPoint = [theEvent locationInWindow];
	curPoint = [self convertPoint:curPoint fromView:nil];

	if ( [theEvent type] == NSPeriodic  ) {
	  curPoint = [self convertPoint:[autoScrollEvent locationInWindow]
			       fromView:nil];
	}
	
	if ( curPoint.y < 0 ) {
	  moveCurTo++;
	  first = moveCurTo-num_visible+1;
	  if ( first < 0 )
	    first = 0;
	  startTimer();
	} else if ( curPoint.y > frame.size.height ) {
	  moveCurTo--;
	  first = moveCurTo;
	  startTimer();
	} else {
	  moveCurTo = first + (num_visible - (curPoint.y /fheight));
	  stopTimer();
	}

	minSel = [Playlist minSelectedIndex];
	maxSel = [Playlist maxSelectedIndex];
	moveTo = moveCurTo - (idx - minSel);

	if ( moveTo < 0 ) {
	  moveCurTo = idx;
	  continue;
	} else if ( moveTo + (maxSel-minSel) >= [Playlist count] ) {
	  moveCurTo = idx;
	  continue;
	}

	[Playlist moveSelectionToIndex:moveTo];
	idx = moveCurTo;
      }
      if ( doingPeriodicEvents )
	stopTimer();
    }
  } else {
    NSArray *cur = [Control getPlaylistSelection];
    for ( i = 0; i < [cur count]; i++ )
      [[cur objectAtIndex:i] setSelected:NO];
    [entry setSelected:YES];

    if ( [theEvent clickCount] > 1 )
      [target performSelector:action withObject:self];
  }
  last_selection = idx;
  
  [Playlist selectionChanged];
}

- (int)selected
{
  return last_selection;
}

- (void)scrollUp
{
  if ( first > 0 ) {
    [self scrollTo:first-1];
  }
}

- (void)scrollDown
{
  if ( first + num_visible + 1 < [Control getPlaylistLength] ) {
    [self scrollTo:first+1];
  }
}

- (void)startUpdaterThread
{
  [Control updatePlaylistInfoInThread:first :first+num_visible :self];
}

- (void)scrollTo:(int)pos
{
  int range = [Control getPlaylistLength] > num_visible
    ? [Control getPlaylistLength] - num_visible : 0;
  int scroller;

  first = pos > range ? range : pos;
  scroller = ((float)first / (float)range) * 100.0;

  [self startUpdaterThread];

  [self setNeedsDisplay:YES];
}

- (void)sliderAction
{
  float pos = (100-[slider intValue]) / 100.0;
  int range = [Control getPlaylistLength] > num_visible 
    ? [Control getPlaylistLength] - num_visible : 0;

  if ( range > 0 )
    {
      first = range * pos;

      [self startUpdaterThread];
      
      [self setNeedsDisplay:YES];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return YES;
}

- (BOOL)becomeFirstResponder
{
  return YES;
}

- (BOOL)resignFirstResponder
{
  return YES;
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)centerCurrentIfNeeded
{
  [self centerCurrent:NO];
}

- (void)centerCurrent:(BOOL)force
{
  int pos = [config playlist_position];
  if ( force == YES || pos < first || pos > (first+num_visible-1) ) {
    int new_first;
    new_first = [config playlist_position] - (num_visible/2);
    if ( new_first < 0 )
      new_first = 0;
    [self scrollTo:new_first];
  }
}

- (void)drawRect:(NSRect)rect
{
  NSFont *font=NULL;
  int width,height;
  PlaylistEntry *entry;
  NSString *text,*title, *length;
  int i, tw;
  NSColor *textColor;
  NSMutableDictionary *font_attrs;

  width = [self frame].size.width;
  height = [self frame].size.height;
	
  [[currentSkin pledit_normalbg] set];
  NSRectFill(rect);

  font = [NSFont fontWithName:@"Ohlfs" size:10.0];
  font_attrs = [[[NSMutableDictionary alloc] initWithCapacity:2] autorelease];
  [font_attrs setObject:font forKey:NSFontAttributeName];

  
  fheight = [font boundingRectForFont].size.height + 1;
  num_visible = height / fheight;

  if ( first == -1 )
    [self centerCurrent:YES];

  for ( i = first; i < [Control getPlaylistLength] 
	  && i < first+num_visible; i++ ) {   
    entry = [Control getPlaylistEntryAt:i];
    if ( [entry selected] ) {
      [[currentSkin pledit_selectedbg] set];
      NSRectFill(NSMakeRect(0, height-((i-first)*fheight)-fheight-3,width,fheight));
    }
    if(i == [config playlist_position])
      textColor = [currentSkin pledit_current];
    else
      textColor = [currentSkin pledit_normal];

    [font_attrs setObject:textColor forKey:NSForegroundColorAttributeName];

    title = [entry title];
    if( title == nil ) {
      title = [[entry filename] lastPathComponent];
    }
			
    if([entry length] != -1) {
      NSPoint pos;
      length = [NSString stringWithFormat:@"%d:%-2.2d",[entry length]/60000,
		 ([entry length]/1000)%60];

      tw = [font widthOfString:length];

      pos = NSMakePoint(width-tw-2, height -((i-first)*fheight)-fheight-3);

      if ( [self lockFocusIfCanDraw] )
	{
	  [length drawAtPoint:pos withAttributes:font_attrs];
	  [self unlockFocus];
	}

      tw = width - tw - 5;
    } else {
      tw=width;
    }
    if([config show_numbers_in_pl])
      text = [NSMutableString stringWithFormat:@"%d. %@", i+1, title];
    else
      text = [NSMutableString stringWithString:title];

#if 0
    if(config.convert_underscore)
      while(tmp=strchr(text,'_'))
	*tmp=' ';
    if(config.convert_twenty)
      while(tmp=strstr(text,"%20")) {
	tmp2=tmp+3;
	*(tmp++)=' ';
	while(*tmp2)
	  *(tmp++)=*(tmp2++);
	*tmp='\0';
      }
    len=strlen(text);
    while((font,text,len)>tw&&len>4) 
      {
	len--;
	text[len-3]='.';
	text[len-2]='.';
	text[len-1]='.';
	text[len]='\0';
      }
#endif

    while ( ([font widthOfString:text] > tw) && [text length] )
      text = [text substringToIndex:[text length]-1];


    {
      NSPoint pos = NSMakePoint(0, height-((i-first) * fheight)-fheight-3);

      if ( [self lockFocusIfCanDraw] )
	{
	  [text drawAtPoint:pos withAttributes:font_attrs];
	  [self unlockFocus];
	}
    }
  }
}

- (void)newPlaylist:(NSNotification *)notification
{
  first = -1;
  [self setNeedsDisplay:YES];
}

- (void)playlistChanged:(NSNotification *)notification
{
  [self startUpdaterThread];
  [self setNeedsDisplay:YES];
}

- (void)selectionChanged:(NSNotification *)notification
{
  [self setNeedsDisplay:YES];
}
@end

