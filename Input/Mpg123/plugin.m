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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Plugins.h"
#include "mpg123.h"
#include "mpglib.h"

@interface mpg123 : Input
{
  BOOL stop, playing;
  struct mpstr mp;
  FILE *fp;
  unsigned char *buffer;
  unsigned char *outputBuffer;
  unsigned char *currentInputBuffer;
  unsigned int BufferSize;
  int inputTrigger;
  int outputTrigger;
}
@end

@implementation mpg123


- init
{
  return [super initWithDescription:@"mpg123 Decoder"];
}

- (BOOL)isOurFile:(NSString *)filename
{
  NSString *ext;
  
  ext = [filename pathExtension];
  if ( ext ) 
    {
      if ( [ext isEqualToString:@"mp3"] )
	{
	  return YES;
	}
    }

  return NO;
}


- (NSDictionary *)getSongInfoForFile:(NSString *)filename
{
  return nil;
}

/*
- (BOOL)fillBuffer
{
  if ( inputBytes < inputTrigger ) {
    int nread;

    memmove(buffer, currentInputBuffer, inputBytes);
    if ( playing_http )
      nread = http_read(buffer+inputBytes, BufferSize-inputBytes);
    else
      nread = fread(buffer+inputBytes, 1, BufferSize-inputBytes, fp);
    if ( nread <= 0 )
      return NO;

    inputBytes += nread;
    currentInputBuffer = buffer;
  }
  return YES;
}
*/

- (BOOL)open_file:(NSString *)fileName
{
  BOOL res = NO;

  fp = fopen([fileName cString], "r");
  if ( fp != NULL ) 
    {
      res = YES;
    }

  if ( res ) {
    NSDictionary *info;
    unsigned int pos;
    BOOL found;
    BOOL force8 = NO;
    int tries = 0, max_retries = 32;

    BufferSize = 32768*2;

    buffer = malloc(BufferSize);
    outputBuffer = malloc(BufferSize*2);
    currentInputBuffer = buffer;
    
    InitMP3(&mp);

    /*
    playingFileName = [fileName retain];
    info = [self getSongInfoForFile:fileName];
    [Input setInfoTitle:[info objectForKey:@"title"]
	         length:[[info objectForKey:@"length"] intValue]
		   rate:bitrate
	      frequency:decinfo.samprate
	    numChannels:decinfo.channels];
    */

    /*
    if ( [config slow_cpu] )
      outputTrigger = BufferSize - 2500 * sizeof(short);
    else
    */
      outputTrigger = 2500;
      //inputTrigger =  framebytes < 2500 ? framebytes : 2500;
      //outputBytes = 0;
    return YES;
  } else {
    NSRunAlertPanel(@"%@", @"Could not open File: %@", @"OK", nil, 
		    getPackageName(), nil, fileName);      
  }

  return NO;
}

- (void)decode_loop:(NSString *)filename
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int size;
  char out[8192];
  int len, ret;
  BOOL audioOpen = NO, eof = NO;
  int totalRead = 0;
  int totalDecoded = 0;
  int totalOutput = 0;

  if ( [self open_file:filename] == NO )
    {
      playing = NO;
      return;
    }

  InitMP3(&mp);

  while ( stop == NO  && eof == NO )
    {
      len = fread(buffer, 1, BufferSize, fp);
      if(len <= 0)
	{
	  perror("fuck");
	  eof = YES;
	  NSLog(@"EOF: %d", totalRead);
	  break;
	}
      totalRead += len;
      //NSLog(@"read: %d", len);
      
      ret = decodeMP3(&mp, 
		      buffer, 
		      len, 
		      outputBuffer, 
		      BufferSize*2,
		      &size);
      
      if ( ret != MP3_OK )
	{
	  NSLog(@"ret = %d", ret);
	  fclose(fp);
	  return;
	}
      
      if ( audioOpen == NO )
	{
	  int fmt;
	  
	  audioOpen = YES;
	  fmt = FMT_S16_NE;
	  
	  if(![[Output output] openAudioFormat:fmt
			       rate:mp.fr.sampling_frequency
			       numChannels:mp.fr.stereo ? 2 : 1] ) {
	    fclose(fp);
	    NSRunAlertPanel(@"%@", @"Couldn't open audio!", @"OK", nil, 
			    getPackageName(), nil);      
	    return;
	  }
	  [Input updateVolume];
	}

      while ( ret == MP3_OK )
	{
	  /*
	  while([[Output output] bufferFree] < size && stop == NO ) {
	    NSLog(@"size: %d", size);
	    mysleep(10000);
	  }
	  */
	
	  [[Output output] writeAudioData:outputBuffer length:size];
	  ret = decodeMP3(&mp, NULL, 0, outputBuffer, (BufferSize*2),&size);
	}
    }

  if ( stop == NO )
    [[Output output] wait];

  [[Output output] closeAudio];
  playing = NO;
  free(buffer);
  free(outputBuffer);
  [self donePlaying];

  [pool release];
}

- (void)playFile:(NSString *)filename
{
  stop = NO;
  playing = YES;
  [NSApplication detachDrawingThread:@selector(decode_loop:)
			    toTarget:self
			  withObject:[filename retain]];
}

- (void)stop
{
  stop = YES;
}

- (void)seek:(int) time
{
}

- (void)pause:(BOOL)p
{
  [[Output output] pause:p];
}

- (int)getTime
{
  return playing ? [[Output output] outputTime] : -1;
}

- (void)about
{
  /*
  static NibObject *aboutBox = nil;

  if (aboutBox == nil) {
    aboutBox = [[NibObject alloc] 
	 initWithNibName:@"About" 
			  bundle:[NSBundle bundleForClass:[self class]]];
  }
  [aboutBox show];
  */
}

- (BOOL)hasAbout
{
  return NO;
}

- (void)configure
{
  /*
  static Configure *configure = nil;
  
  if ( configure == nil )
    configure = [[Configure alloc] init];
  
  [configure show];
  */
}

- (BOOL)hasConfigure
{
  return NO;
}

- (void)fileInfoBox:(NSString *)filename
{
  /*
  static XFileInfo *fileInfoBox = nil;
  if ( fileInfoBox ==  nil )
    fileInfoBox = [[XFileInfo alloc] init];
  
  [fileInfoBox setFileName:filename];
  [fileInfoBox show];
  */
}

- (BOOL)enabledByDefault
{
  return YES;
}

#define	LIMIT_DB_RATIO	3

- (void)setEq:(BOOL)on preamp:(float)preamp bands:(float *)b
{
}

@end

