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

#import <MXA/Plugins.h>

#import "mhead.h"
#import "dxhead.h"

@interface xing : Input
{
  FILE *fp;
  NSString *playingFileName;
  unsigned char *buffer;
  unsigned char *outputBuffer;
  unsigned char *currentInputBuffer;
  unsigned int inputBytes;
  int framebytes;
  int bitrate;
  int outputTrigger;
  int outputBytes;
  int inputTrigger;
  MPEG mpeg;
  MPEG_HEAD head;
  XHEADDATA xingHeader;
  BOOL hasXingHeader;
  DEC_INFO decinfo;
  IN_OUT mpg_out;
  NSLock *decoding_lock;
  BOOL stop, playing;
  int totalSeconds;
  BOOL eq_active;
  float eq_mul[32];
  BOOL playing_http;
  unsigned int BufferSize;
  int reduction_code, convert_code;
  double current_tpf;
  double current_bpf;
  int seekTo;
  int totalFrames;
  int file_length;
}

- (BOOL)playing;

@end

#define UBYTE unsigned char
#define ULONG unsigned long

typedef struct
{
  UBYTE riff[4];
  ULONG size;
  UBYTE wave[4];
  ULONG fmt;
  ULONG fmtsize;
  UBYTE tag[2];
  UBYTE nChannels[2];
  UBYTE nSamplesPerSec[4];
  UBYTE nAvgBytesPerSec[4];
  UBYTE nBlockAlign[2];
  UBYTE nBitsPerSample[2];
  ULONG data;
  ULONG pcm_bytes;
}
WAVE_HEAD;


float *xing_eq();
int xing_eq_active();
void xing_addvis(unsigned char *spectrum);
int xing_analyzer_vis();

extern xing *xip;
