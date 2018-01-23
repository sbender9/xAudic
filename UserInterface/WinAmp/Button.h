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


@interface Button : NSButton
{
  NSPoint normal, snormal;
  NSPoint pushed, spushed;
  SEL imageSel;
  BOOL allowDraw;
  BOOL toggle;
  BOOL drewPushed;
}

- (void)setNormal:(NSPoint)_normal;
- (void)setPushed:(NSPoint)_pushed;
- (void)setSpushed:(NSPoint)_spushed;
- (void)setSnormal:(NSPoint)_snormal;

- init:(NSRect)frame 
      :(NSPoint)_pushed
      :(NSPoint)_normal
      :(id)target
      :(SEL)cb
      :(SEL)_imageSel;


- init:(NSRect)frame 
      :(NSPoint)_pushed
      :(NSPoint)_normal
      :(NSPoint)_spushed
      :(NSPoint)_snormal
      :(id)target
      :(SEL)cb
      :(SEL)_imageSel;

- init:(NSRect)frame 
      :(NSPoint)_pushed
      :(NSPoint)_normal
      :(NSPoint)_spushed
      :(NSPoint)_snormal
      :(id)target
      :(SEL)cb
      :(SEL)_imageSel
      :(BOOL)toggleButton;

- init:(NSRect)frame :(id)target :(SEL)cb;

- (void)setAllowDraw:(BOOL)val;
- (void)toggle:(BOOL)val;

@end

static inline NSPoint flipPoint(NSPoint p, NSImage *image, NSSize size)
{
  NSPoint np = p;
  float height = [image size].height;
  np.y = height - p.y - size.height;  
  return np;
}


static inline NSRect flipRect(NSRect r, NSImage *image)
{
  r.origin = flipPoint(r.origin, image, r.size);
  return r;
}
