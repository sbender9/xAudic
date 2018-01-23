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

#import "CAConfig.h"
#import <AppKit/AppKit.h>
#include <CoreAudio/AudioHardware.h>
#import <MXA/MXAConfig.h>

int GetAudioDevices (Ptr *devices, short *devicesAvailable);

@implementation CAConfig

- (void)awakeFromNib
{
  AudioDeviceID *devices;
  short devicesAvailable;

  [outputDevice removeAllItems];

  if ( GetAudioDevices((Ptr *)&devices, &devicesAvailable)  )
    {
      int i;
      for ( i = 0; i < devicesAvailable; i++ )
	{
	  char *str;
	  AudioStreamBasicDescription format;
	  UInt32 outSize;
	  BOOL writeable;

	  NSLog(@"deviceid: %d", (int)devices[i]);

	  memset(&format, 0, sizeof(format));
    
	  outSize = sizeof(format);
	  AudioDeviceGetProperty(devices[i],
				 0, 
				 false, 
				 kAudioDevicePropertyStreamFormat, 
				 &outSize, 
				 &format);

	  /*
	  float volume;
	  OSErr err;
	  outSize = sizeof(Float32);
	  err = AudioDeviceGetProperty(devices[i], 
				       0, 
				       false, 
				       kAudioDevicePropertyVolumeScalar,
				       &outSize,
				       &volume);
	  if ( err == noErr )
	    {
	      NSLog(@"%d has master", i);
	    }
	  */
        

	  if ( format.mChannelsPerFrame > 0 )
	    {
	      NSString *title;
	      AudioDeviceGetPropertyInfo(devices[i], 
					 0, 
					 false, 
					 kAudioDevicePropertyDeviceName, 
					 &outSize,
					 &writeable);

	      str = malloc(outSize);
	      AudioDeviceGetProperty(devices[i],
				     0, 
				     false, 
				     kAudioDevicePropertyDeviceName,
				     &outSize,
				     str);
	      title = [NSString stringWithCString:str];
	      free(str);

	      AudioDeviceGetPropertyInfo(devices[i], 
					 0, 
					 false, 
					 kAudioDevicePropertyDeviceManufacturer, 
					 &outSize,
					 &writeable);

	      title = [NSString stringWithCString:str];
	      free(str);

	      [outputDevice addItemWithTitle:title];
	    }
	}
    }
}

- (void)updateDisplay
{
  [outputDevice selectItemWithTitle:[config stringValueForKey:CFGOutputDeviceID]];
  [outputDevice synchronizeTitleAndSelectedItem];
}

- (void)ok:sender
{
  [config setStringValue:[[outputDevice selectedItem] title]
	  forKey:CFGOutputDeviceID];
  NSLog(@"device: %@", [config  stringValueForKey:CFGOutputDeviceID]);
  [config save_config];
  [super ok:sender];
}

@end

NSString *CFGOutputDeviceID = @"coreaudio.outputDeviceID";
