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

#import "Scope.h"

@implementation Scope

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  type = VIS_SCOPE;
  inputType = INPUT_VIS_SCOPE;
  return [super initWithDescription:[NSString stringWithFormat:@"Scope Visualization %@", getVersion()]];
}

- (int)numPCMChannelsWanted
{
  return 1;
}

- (int)numFREQChannelsWanted
{
  return 0;
}

- (void)renderPCM:(short[2][512])mono_pcm
{
  /* Osciloscope */
  gchar intern_vis_data[512];  
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

@end
