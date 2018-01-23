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

#import "xing.h"
#import <string.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSPanel.h>
#import <MXA/Common.h>
#import <MXA/Visualization.h>
#import "mhead.h"
#import <stdlib.h>
#import "id3util.h"
#import "Configure.h"
#import <MXA/MXAConfig.h>
#import "FileInfo.h"
#import "http.h"
#import "dxhead.h"

xing *xip = nil;

static BOOL find_header(unsigned char *buf, int n, int *found_pos);

@implementation xing

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  decoding_lock = [[NSLock alloc] init];
  xip = self;
  return [super initWithDescription:[NSString stringWithFormat:@"Xing MPEG Decoder %@", getVersion()]];
}

- (BOOL)isOurFile:(NSString *)filename
{
  NSString *ext;

  if ( [filename hasPrefix:@"http://"] ) { 
    /* We assume all http:// are mpeg -- why do we do that? */
    return TRUE;
  }
  
  ext = [filename pathExtension];
  if(ext) {
    if([ext isEqualToString:@"mpg"] || [ext isEqualToString:@"mp2"] || 
       [ext isEqualToString:@"mp3"] || [ext isEqualToString:@"mpeg"]) {
      return YES;
    }
  }

  return NO;
}

- (BOOL)readHeadInfo:(NSString *)fileName 
		head:(MPEG_HEAD *)the_head
		info:(DEC_INFO *)the_info
	  framebytes:(int *)the_framebytes
	     bitrate:(int *)abitrate
	  xingHeader:(XHEADDATA *)xingHead
       hasXingHeader:(BOOL *)_hasXingHeader
{
  FILE *tfp = fopen([fileName fileSystemRepresentation], "r");
  unsigned char *buf = 0;

  if ( tfp != NULL ) {
    //WAVE_HEAD whead;
    int read, pos;
    int freq_limit = 24000;
    int offset;
    int iLastSRIndex = -1, iLastOption = -1;
    int iLastId = -1, iLastMode = -1;

    //int maxDecodeRetries = 32;
    int maxFrame = 1441;
    int checkFrames = 3;
    int initFrameSize = maxFrame * checkFrames;

    buf = malloc(initFrameSize);

    read = fread(buf, 1, initFrameSize, tfp);

    if ( read == -1 )
      goto error;

    offset = 0;
    *the_framebytes = head_info3(buf+offset, 
				 read-offset, 
				 the_head, 
				 abitrate, 
				 &pos);
	    
    if (*the_framebytes > 0 )
      {
	offset += *the_framebytes + pos + the_head->pad;
	iLastSRIndex = the_head->sr_index;
	iLastOption = the_head->option;
	iLastId = the_head->id;
	iLastMode = the_head->mode;
	
	xingHead->toc = malloc(sizeof(char)*100);
	if (!GetXingHeader(xingHead, (unsigned char *)buf))
	  {
	    free(xingHead->toc);
	    xingHead->toc = 0;
	    *_hasXingHeader = NO;
	  }
	else
	  *_hasXingHeader = YES;
	
	if (!audio_decode_init(&mpeg, the_head,*the_framebytes,
			       0,0,4,freq_limit))
	  {
	    goto error;
	  }
	audio_decode_info(&mpeg, the_info);
	
	free(buf);
	fclose(tfp);
	return YES;
      }
  }
  
error:
  if ( buf != 0 )
    free(buf);
  if ( tfp != 0 )
    fclose(tfp);
  return NO;
}

- (BOOL)canDecode:(NSString *)fileName 
{
  FILE *tfp = fopen([fileName fileSystemRepresentation], "r");
  unsigned char *buf = 0;
  MPEG_HEAD the_head;
  int the_framebytes;
  int abitrate;

  if ( tfp != NULL ) {
    //WAVE_HEAD whead;
    int read, pos;
    int offset, frame;
    int iLastSRIndex = -1, iLastOption = -1;
    int iLastId = -1, iLastMode = -1;

    //int maxDecodeRetries = 32;
    int maxFrame = 1441;
    int checkFrames = 3;
    int initFrameSize = maxFrame * checkFrames;

    buf = malloc(initFrameSize);

    read = fread(buf, 1, initFrameSize, tfp);

    if ( read == -1 )
      goto error;

    offset = 0;
    for ( frame = 0; frame < checkFrames; frame++ )
      {
	the_framebytes = head_info3(buf+offset, 
				    read-offset, 
				    &the_head, 
				    &abitrate, 
				    &pos);
	    
	if (the_framebytes > 0 && frame == 0)
	  {
	    offset += the_framebytes + pos + the_head.pad;
	    iLastSRIndex = the_head.sr_index;
	    iLastOption = the_head.option;
	    iLastId = the_head.id;
	    iLastMode = the_head.mode;
	    continue;
	  }
	
	if (the_framebytes > 0 && the_framebytes < maxFrame && 
	    (the_head.option == 1 || the_head.option == 2) &&
	    iLastSRIndex == the_head.sr_index &&
	    iLastOption == the_head.option && 
	    iLastId == the_head.id && 
	    iLastMode == the_head.mode)
	  {
	    offset += the_framebytes + pos + the_head.pad;
	    iLastSRIndex = the_head.sr_index;
	    iLastOption = the_head.option;
	    iLastId = the_head.id;
	    iLastMode = the_head.mode;
	    
	    if (frame < checkFrames - 1)
	      continue;
	    
	    free(buf);
	    fclose(tfp);
	    return YES;
	  }
	else
	  {
	    // see if we can find a frame starting somewhere
	    int hpos;
	    int trycount = 0;
	    int maxTries = 3;
	    BOOL found;
	    do {
	      found = find_header(buf+offset, read-offset, &hpos);
	      if ( found == NO ) 
		{
		  read = fread(buf, 1, initFrameSize, tfp);
		  offset = 0;
		}
	      else
		offset = hpos;
	    } while ( found == NO && read > 0 && trycount++ < maxTries );
	  }
      }
  }
  
error:
  if ( buf != 0 )
    free(buf);
  if ( tfp != 0 )
    fclose(tfp);
  return NO;
}

#define compute_tpf mcompute_tpf
static double compute_tpf(DEC_INFO *info, MPEG_HEAD *head)
{
  static int bs[4] = { 0,1152,1152,384 };
  double tpf;
  
  tpf = (double) bs[head->option];
  tpf /= (double)(info->samprate << (head->pad));
  return tpf;
}

#define compute_bpf mcompute_bpf
double compute_bpf(DEC_INFO *info, MPEG_HEAD *head, int bitrate)
{
  double bpf;
  
  switch(head->option) {
  case 3:
    bpf = bitrate / 1000;
    bpf *= 12000.0 * 4.0;
    bpf /= info->samprate << head->pad;
    break;
  case 2:
  case 1:
    bpf = bitrate / 1000;
    bpf *= 144000;
    bpf /= info->samprate << head->pad;
    break;
  default:
    bpf = 1.0;
  }
  
  return bpf;
}


- (int)computeSongLength:(NSString *)filename :(int *)length
{
  NSDictionary *attrs;
  unsigned long long end;
  int aframebytes;
  MPEG_HEAD ahead;
  DEC_INFO adecinfo;
  XHEADDATA xHead;
  BOOL hasXhead;
  int abitrate;
  double tpf;
  BOOL res;

  *length = -1;

  attrs = [[NSFileManager defaultManager] 
	    fileAttributesAtPath:filename traverseLink:YES];
  end = [attrs fileSize];

  res = [self readHeadInfo:filename head:&ahead 
				    info:&adecinfo 
			      framebytes:&aframebytes
				 bitrate:&abitrate
			      xingHeader:&xHead
			   hasXingHeader:&hasXhead];

  if ( res ) {
    tpf = compute_tpf(&adecinfo, &ahead);
    if ( hasXhead )
      *length = (int)(tpf*(double)xHead.frames*1000);
    else 
      {
	int num_frames=(int)((double)end/compute_bpf(&adecinfo, &ahead, 
						     abitrate));
	*length = (int)(num_frames*tpf*1000);
      }
    return YES;
  }

  return NO;

#if 0
//  int sampRateIndex = 4 * head.id + head.sr_index;
  double    milliseconds_per_frame = 0;
  static int l[4] = {25, 3, 2, 1};
  int layer;
  static double ms_p_f_table[3][3] =
  {
    {8.707483f, 8.0f, 12.0f},
    {26.12245f, 24.0f, 36.0f},
    {26.12245f, 24.0f, 36.0f}
  };
  int totalFrames;
  NSDictionary *attrs;
  unsigned long long end;
  int length, aframebytes;
  MPEG_HEAD ahead;
  DEC_INFO adecinfo;
  int samprate;

  if ( [filename hasPrefix:@"http://"] ) { 
    return -1;
  }
  
  attrs = [[NSFileManager defaultManager] 
	    fileAttributesAtPath:filename traverseLink:YES];
  end = [attrs fileSize];

  if ( [filename isEqualToString:playingFileName] == NO ) {
    [self readHeadInfo:filename head:&ahead info:&adecinfo 
				     framebytes:&aframebytes];
  } else {
    ahead = head;
    adecinfo = decinfo;
    aframebytes = framebytes;
  }
  
  layer = l[ahead.option];
  samprate = adecinfo.samprate;
  
  if ((ahead.sync & 1) == 0)
     samprate = samprate / 2;    // mpeg25

   milliseconds_per_frame = ms_p_f_table[layer - 1][ahead.sr_index];

   if (end > 0)
   {
       totalFrames = end / aframebytes;
       length = (float) ((double) totalFrames * 
                      (double) milliseconds_per_frame);
   }
   else
   {
       length = 0;
   }
   return length;
#endif
}



- (NSDictionary *)getSongInfoForFile:(NSString *)filename
{
  NSMutableDictionary *info = [NSMutableDictionary dictionary];
  NSString *title;
  int len;

  if ( [filename hasPrefix:@"http://"] ) 
    { 
      if ( playing_http && [filename isEqualToString:filename] )
	title = http_get_title(filename);
      else
	title = filename;
      [info setObject:title forKey:@"title"];
      len = -1;
    } 
  else 
    {
      NSDictionary *id3_info;
      
      if ([self computeSongLength:filename :&len])
	{
	  id3_info = x_get_song_info(filename, [Configure id3Format]);
	  [info addEntriesFromDictionary:id3_info];
	}
      else
	return nil;
    }
  [info setObject:[NSNumber numberWithInt:len] forKey:@"length"];
  return info;
}

static BOOL find_header(unsigned char *buf, int n, int *found_pos)
{
  int iCount;
  
  for(iCount = 0; iCount < n - 1 &&
	!(*buf == 0xFF && ((*(buf+1) & 0xF0) == 0xF0 || 
			   (*(buf+1) & 0xF0) == 0xE0)); 
      buf++, iCount++)
    ; // <=== Empty body!

  if (iCount != 0 && iCount < n - 1) {
    *found_pos = iCount;
    return YES;
  }
  return NO;


#if 0
  unsigned int pBuf = 0;
  BOOL found = NO;
  unsigned long head;
  unsigned char *tmp;
  
  while (pBuf+4 < n && found == NO ) {
    tmp = buf+pBuf;
    head=((unsigned long)tmp[0]<<24)|((unsigned long)tmp[1]<<16)|
      ((unsigned long)tmp[2]<<8)|(unsigned long)tmp[3];
    if ( xhead_check(head) )
      found = YES;
    else
      pBuf++;
  }

  *found_pos = pBuf;
  return found;
#endif
}

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
			
- (BOOL)open_file:(NSString *)fileName
{
  BOOL res = NO;

  if ( [fileName hasPrefix:@"http://"] ) { 
    http_open(fileName);
    res = TRUE;
    playing_http = YES;
  } else {
    playing_http = NO;
    fp = fopen([fileName fileSystemRepresentation], "r");
    if ( fp != NULL ) {
      res = YES;
    }
  }

  if ( res ) {
    WAVE_HEAD whead;
    int freq_limit = 24000;
    NSDictionary *info;
    unsigned int pos;
    BOOL found;
    //BOOL force8 = NO;
    int tries = 0, max_retries = 32;

    reduction_code = 0;
    convert_code = 0;

    if ( playing_http )
      BufferSize = (([Configure httpBufferSize] * 1024)
		    *[Configure httpPreBuffer])/100;
    else
      BufferSize = 60000;

    buffer = malloc(BufferSize);
    outputBuffer = malloc(64512);
    currentInputBuffer = buffer;

    if (playing_http == NO )
      {
	fseek(fp, 0, SEEK_END);
	file_length = ftell(fp);
	fseek(fp, 0, SEEK_SET);
	inputBytes = fread(buffer, 1, BufferSize, fp);
      }
    else
      inputBytes = http_read(buffer, BufferSize);      

    if ( stop )
      {
	free(buffer);
	free(outputBuffer);
	buffer = 0;
	outputBuffer = 0;
	return NO;
      }

    if ( inputBytes <= 0 )
      {
	free(buffer);
	free(outputBuffer);
	buffer = 0;
	outputBuffer = 0;
	return NO;
      }

    memcpy(&whead, buffer, sizeof(whead));
    if ((whead.riff[0]=='R') && (whead.riff[1]=='I') && (whead.riff[2]=='F')
	&&(whead.riff[3]=='F'))
      {
	/* Second test to be sure */
	if ((whead.wave[0]=='W') && (whead.wave[1]=='A') 
	    && (whead.wave[2]=='V') && (whead.wave[3]=='E'))
	  {
	    /* This is a WAVE.MP3 - update buffer (???) */
	    currentInputBuffer += 72;
	    inputBytes -= 72;
	  }
      }

    if ( playing_http == NO ) 
      {
	do {
	  framebytes = head_info3(currentInputBuffer, inputBytes , &head,
				  &bitrate, &pos);
	  if ( framebytes == 0 && pos == 0 )
	    pos = 1; // must be a messed up frame, look for another
	  currentInputBuffer += pos;
	  inputBytes -= pos;
	  [self fillBuffer];

	  if ( framebytes == 0 && pos )
	    NSLog(@"Skipped %d bytes at begining of stream", pos);

	} while ( framebytes <= 0 && tries++ < max_retries );

	xingHeader.toc = malloc(sizeof(char)*100);
	if (!GetXingHeader(&xingHeader, currentInputBuffer))
	  {
	    free(xingHeader.toc);
	    hasXingHeader = NO;
	  }
	else
	  hasXingHeader = YES;
      } 
    else 
      {
	int totalBytes = inputBytes;
	
	do {
	  do {
	    found = find_header(currentInputBuffer, inputBytes, &pos);
	    if ( found == NO ) {
	      if ( playing_http )
		inputBytes = http_read(buffer, BufferSize);
	      else
		inputBytes = fread(buffer, 1, BufferSize, fp);
	      currentInputBuffer = buffer;
	      totalBytes += inputBytes;
	    }
	  } while ( found == NO && totalBytes < BufferSize*3 && stop == NO );
	  if ( found ) {
	    currentInputBuffer += pos;
	    inputBytes -= pos;
	    framebytes = head_info3(currentInputBuffer, inputBytes , &head,
				    &bitrate, &pos);
	    if ( framebytes <= 0 ) {
	      framebytes = 0;
	      currentInputBuffer++;
	      inputBytes--;
	    }
	  }
	} while ( framebytes == 0 && tries++ < max_retries );
      }

    mpeg_init(&mpeg, 1);
    if (framebytes == 0
	|| !audio_decode_init(&mpeg, &head, framebytes, reduction_code, 0, 
			      convert_code, freq_limit)) {
      if ( playing_http )
	http_close();
      else
	fclose(fp);
      NSRunAlertPanel(getPackageName(), @"Invalid MPEG File: %@", @"OK", nil, 
		      nil, fileName);      
      return NO;
      
    }

    audio_decode_info(&mpeg, &decinfo);
    current_tpf = compute_tpf(&decinfo, &head);
    current_bpf = compute_bpf(&decinfo, &head, bitrate);

    if ( playing_http == NO && hasXingHeader )
      {
	totalFrames = (int)((double)file_length/current_bpf);
      }
    else
      totalFrames = xingHeader.frames;

    {
      int fmt;
      fmt = decinfo.bits == 16 ?  FMT_S16_NE : FMT_U8;
      
      if(![[Output output] openAudioFormat:fmt
				      rate:decinfo.samprate
			       numChannels:decinfo.channels] ) {
	fclose(fp);
	NSRunAlertPanel(getPackageName(), @"Couldn't open audio!", @"OK", nil, 
			nil);      
	return NO;
      }
      [Input updateVolume];
    }

    info = [self getSongInfoForFile:fileName];

    if ( info == nil )
      return NO;

    playingFileName = [fileName retain];
    [Input setInfoTitle:[info objectForKey:@"title"]
	         length:[[info objectForKey:@"length"] intValue]
		   rate:bitrate
	      frequency:decinfo.samprate
	    numChannels:decinfo.channels];

    if ( [config slow_cpu] )
      outputTrigger = BufferSize - 2500 * sizeof(short);
    else
      outputTrigger = 2500;
    inputTrigger =  framebytes < 2500 ? framebytes : 2500;
    outputBytes = 0;
    seekTo = -1;
    return YES;
  } else {
    NSRunAlertPanel(getPackageName(), @"Could not open File: %@", @"OK", nil, 
		    nil, fileName);      
  }

  return NO;
}


int xhead_check(unsigned long head)
{
    if( (head & 0xffe00000) != 0xffe00000)
	return FALSE;
    if(!((head>>17)&3))
	return FALSE;
    if( ((head>>12)&0xf) == 0xf)
	return FALSE;
    if( ((head>>10)&0x3) == 0x3 )
	return FALSE;
    
    if( ((head>>19)&1)==1 && ((head>>17)&3)==3 && ((head>>19)&1)==1 )
	return FALSE;

    return TRUE;
}

- (void)repositionInput:(int)pos
{
  fseek(fp, pos, SEEK_SET);
  currentInputBuffer = buffer;
  inputBytes = 0;
}

int xing_seek_point(unsigned char TOC[100], int file_bytes, float percent) 
{
  /* interpolate in TOC to get file seek point in bytes */ 
  int a, seekpoint;
	
  float fa, fb, fx;
  if (percent < 0.0f)
    percent = 0.0f;
  
  if (percent > 100.0f)
    percent = 100.0f;
  
  
  a = (int) percent;
  
  if (a > 99)
    a = 99;
  
  fa = TOC[a];
  
  if (a < 99)
    {
      fb = TOC[a + 1];
    }
  else
    {
      fb = 256.0f;
    }
  fx = fa + (fb - fa) * (percent - a);
		
  seekpoint = (int) ((1.0f / 256.0f) * fx * file_bytes);

  return seekpoint;
}


- (void)decode_loop:(NSString *)filename
{
  BOOL eof = NO;
  //int bps = (decinfo.samprate * decinfo.channels)*2;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  [decoding_lock lock];

  if ( [self open_file:filename] ) {
    while ( eof == NO && stop == NO ) {
      NSAutoreleasePool *ppool = [[NSAutoreleasePool alloc] init];
      do {

	if ( seekTo != -1 && playing_http == NO )
	  {
	    int filePos;
	    if (!hasXingHeader)
	      {
		filePos = (int)(seekTo / current_tpf)  * (framebytes+4);
	      }
	    else
	      filePos = xing_seek_point(xingHeader.toc,
					xingHeader.bytes,
					((double) seekTo * 100.0) / ((double) totalFrames *current_tpf));
	    
	    [self repositionInput:filePos];
	    [[Output output] flush:seekTo * 1000];
	    seekTo = -1;
	  }

	if ( [self fillBuffer] == NO ) {
	  eof = YES;
	  break;
	}
	if (inputBytes < framebytes)
	  break;
	
	mpg_out = audio_decode(&mpeg, currentInputBuffer, 
			       (short *)(outputBuffer+outputBytes));
	if (mpg_out.in_bytes <= 0) {
	  // stream got screwed up, look for another header
	  int totalBytes = 0, pos;
	  BOOL found = NO;
	  do {
	    found = find_header(currentInputBuffer, inputBytes, &pos);
	    if ( found == NO ) {
	      totalBytes += inputBytes;
	      inputBytes = 0;
	      if ( [self fillBuffer] == NO ) {
		eof = YES;
		break;
	      }
	    }
	  } while ( found == NO && eof == NO && stop == NO );
	  if ( found == NO ) {
	    eof = YES;
	    break;
	  } else {
	    //NSLog(@"Skipped %d bytes in stream", totalBytes+pos);
	    inputBytes -= pos;
	    currentInputBuffer += pos;
	    mpeg_init(&mpeg, 0);
	    audio_decode_init(&mpeg, &head, framebytes, reduction_code, 0, 
			      convert_code, 24000);
	    continue;
	  }	    
	}

	currentInputBuffer += mpg_out.in_bytes;
	inputBytes -= mpg_out.in_bytes;
	outputBytes += mpg_out.out_bytes;

      } while ( outputBytes < outputTrigger && eof == NO && stop == NO );

      if (stop == NO && eof == NO && outputBytes) {

	outputBytes = [Effect
			modSampleData:(short int *)outputBuffer
			       length:outputBytes
			bitsPerSample:16
			  numChannels:decinfo.channels
				 freq:decinfo.samprate];

	[Visualization addVisPcmTime:[[Output output] writtenTime]
		      format:FMT_S16_NE
		 numChannels:decinfo.channels
		      length:outputBytes
			data:(void *)outputBuffer];
      
	[[Output output] writeAudioData:outputBuffer length:outputBytes];
	outputBytes = 0;
      }
      [ppool release];
    }
    if ( playing_http )
      http_close();
    else
      fclose(fp);
  }

  if ( stop == NO )
    [[Output output] wait];

  
  [[Output output] closeAudio];
  mpeg_cleanup(&mpeg);
  [filename release];
  [playingFileName release];
  playingFileName = nil;
  framebytes = 0;
  playing = NO;
  free(buffer);
  free(outputBuffer);
  buffer = 0;
  outputBuffer = 0;
  if ( stop == NO )
    [self donePlaying:NO];
  [decoding_lock unlock];
  [pool release];
//  printf("exiting xing thread\n");
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
  [[Output output] stop];
  stop = YES;
  [decoding_lock lock];
  [decoding_lock unlock];
  [self donePlaying:YES];
}

- (void)seek:(int) time
{
  seekTo = time;

  [[Output output] cancelWrite];
  while (seekTo != -1 )
    mysleep(1000);
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
  static NibObject *aboutBox = nil;

  if (aboutBox == nil) {
    aboutBox = [[NibObject alloc] 
	 initWithNibName:@"XingAbout" 
			  bundle:[NSBundle bundleForClass:[self class]]];
  }
  [aboutBox show];
}

- (BOOL)hasAbout
{
  return YES;
}

- (void)configure
{
  static Configure *configure = nil;
  
  if ( configure == nil )
    configure = [[Configure alloc] init];
  
  [configure show];
}

- (BOOL)hasConfigure
{
  return YES;
}

- (void)fileInfoBox:(NSString *)filename
{
  static XFileInfo *fileInfoBox = nil;
  if ( fileInfoBox ==  nil )
    fileInfoBox = [[XFileInfo alloc] init];
  
  [fileInfoBox setFileName:filename];
  [fileInfoBox show];
}

- (BOOL)enabledByDefault
{
  return YES;
}

#define	LIMIT_DB_RATIO	3

- (void)setEq:(BOOL)on preamp:(float)preamp bands:(float *)b
{
  float band[10];
  int i;

  /** from freeamp **/
  
  eq_active=on;
  if(eq_active)
    {
      for(i=0;i<10;i++)
	{
	  band[i]=b[i]+preamp;
	}

#define eq_val() (float)pow(2,(double)(band[i])/10)
//#define eq_val() (float)pow(10,(double)(0-band[i]/LIMIT_DB_RATIO)/10)

      for ( i = 0; i < 10; i++ ) {
	switch (i) {
	case 0:
	case 1:
	case 2:
	case 3:
	case 4:
	case 5:
	  eq_mul[i] = eq_val();
	  break;
	case 6:
	  eq_mul[6] = eq_val();
	  eq_mul[7] = eq_mul[6];
	  break;
	case 7:
	  eq_mul[8] = eq_val();
	  eq_mul[9] = eq_mul[8];
	  eq_mul[10] = eq_mul[8];
	  eq_mul[11] = eq_mul[8];
	  break;
	case 8:
	  eq_mul[12] = eq_val();
	  eq_mul[13] = eq_mul[12];
	  eq_mul[14] = eq_mul[12];
	  eq_mul[15] = eq_mul[12];
	  eq_mul[16] = eq_mul[12];
	  eq_mul[17] = eq_mul[12];
	  eq_mul[18] = eq_mul[12];
	  eq_mul[19] = eq_mul[12];
	  break;
	case 9:
	  eq_mul[20] = eq_val();
	  eq_mul[21] = eq_mul[20];
	  eq_mul[22] = eq_mul[20];
	  eq_mul[23] = eq_mul[20];
	  eq_mul[24] = eq_mul[20];
	  eq_mul[25] = eq_mul[20];
	  eq_mul[26] = eq_mul[20];
	  eq_mul[27] = eq_mul[20];
	  eq_mul[28] = eq_mul[20];
	  eq_mul[29] = eq_mul[20];
	  eq_mul[30] = eq_mul[20];
	  eq_mul[31] = eq_mul[20];
	  break;
	  
	}
      }
    }
}

- (BOOL)eq_active
{
  return eq_active;
}

- (float *)eq
{
  return eq_mul;
}

- (BOOL)playing
{
  return playing;
}

@end


int xing_eq_active()
{
  return [xip eq_active];
}

float *xing_eq()
{
  return [xip eq];
}

void xbitrate_changed(int new_bitrate)
{
  [Input setBitrateChange:new_bitrate*1000];
}
