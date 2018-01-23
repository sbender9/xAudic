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
#include <Carbon/Carbon.h>
#include <CoreAudio/AudioHardware.h>

#import <MXA/Common.h>
#import <MXA/Plugins.h>
#import <MXA/NibObject.h>
#include <pthread.h>
#import "CAConfig.h"

int GetAudioDevices (Ptr *devices, short *devicesAvailable);
void Convert16BitIntegerTo32Float(const void *in16BitDataPtr, 
				  Ptr out32BitDataPtr, 
				  UInt32 totalBytes);
OSStatus outputIOProc (AudioDeviceID inDevice, 
		       const AudioTimeStamp *inNow, 
		       const AudioBufferList *inInputData, 
                       const AudioTimeStamp *inInputTime, 
		       AudioBufferList *outOutputData, 
		       const AudioTimeStamp *inOutputTime, 
                       void *_self);

typedef struct _BufferEntry
{
  void *buffer;
  int len;
} BufferEntry;


#define USE_PTHREADS
//#define DEBUG_STACK
//#define DEBUG_LOCKS

@interface BufferStack : NSObject
{
  BufferEntry **stack;
  int size;
  int stack_length;
  int buffer_size;
  BOOL stopped;
  BOOL waitingForFinish;

#ifdef USE_PTHREADS
  pthread_mutex_t mutex;
  pthread_cond_t condition;
#else
  NSConditionLock *clock;
#endif

}

- initWithSize:(int)ssize bufferSize:(int)bsize;

- (void)push:(const void *)buffer length:(int)len;
- (void *)pop;
- (void)stop;
- (void)waitTillDone;
- (void)cancelWrite;
- (void)flush;
- (int)length;
@end

#define NUM_BUFFERS 400

@interface CoreAudioPlugin : Output
{
  AudioStreamBasicDescription outDeviceFormat;
  AudioDeviceID deviceID;
  UInt32 outputBufferSize;
  AudioTimeStamp firstTimeStamp;
  int outputTimeOffset;
  int pausedTime;

  BOOL started;
  BOOL isPaused;

  BufferStack *bufferStack;

  int bytes_written;
  int bytes_output;
  int bps, ebps;
  int sample_rate;
}
@end

@implementation CoreAudioPlugin

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- (void)stop
{
  [bufferStack stop];
}

- (void)pause:(BOOL) paused
{
  if ( paused == YES && isPaused == NO )
    {
      pausedTime = [self outputTime];
      isPaused = YES;
      AudioDeviceStop(deviceID, outputIOProc);
      AudioDeviceRemoveIOProc(deviceID, outputIOProc);
    }
  else if ( paused == NO && isPaused == YES )
    {
      isPaused = NO;
      outputTimeOffset = pausedTime;
      AudioDeviceAddIOProc(deviceID, 
			   outputIOProc, 
			   (void *)self);
      AudioDeviceStart(deviceID, outputIOProc);
    }
}

- (void)flush:(int)time
{
  if ( isPaused )
    pausedTime = time;
  else
    outputTimeOffset = time;
  bytes_written = (time / 10) * (bps / 100);		
  bytes_output = 0;
  firstTimeStamp.mFlags = 0;
  AudioDeviceStop(deviceID, outputIOProc);
  [bufferStack flush];
  AudioDeviceStart(deviceID, outputIOProc);
}

- (void)cancelWrite
{
  [bufferStack cancelWrite];
}

- (void)wait
{
  [bufferStack waitTillDone];
}

- (int)writtenTime
{
  return (int)(((float)bytes_written*1000.0)/(float)(bps));
}

- (int)outputTime
{
  AudioTimeStamp time;
  
  if ( isPaused  == NO )
    {
      int res = 0;

      AudioDeviceGetCurrentTime(deviceID, &time);

      if ( time.mFlags & kAudioTimeStampSampleTimeValid 
	   && firstTimeStamp.mFlags & kAudioTimeStampSampleTimeValid )
	res =  outputTimeOffset 
	  + (time.mSampleTime-firstTimeStamp.mSampleTime) /
	  ((float)sample_rate/1000.0);

      return res;
    }
  else
    {
      return pausedTime;
    }

}

- (BOOL)bufferPlaying
{
  return [bufferStack length] > 0;
}

void  OSType2Str (OSType theType, Str255 prompt)
{
    BlockMove ( "'", &prompt[0], 1 );

    BlockMove ( &theType, &prompt[1], 4 );
    BlockMove ("'", &prompt[5], 1 );
    prompt[6] = 0;
} 

/*
OSStatus deviceListenerProc(AudioDeviceID inDevice,
			    UInt32 inLine,
			    Boolean isInput,
			    AudioDevicePropertyID inPropertyID,
			    void *_self)
{
    OSStatus err = noErr;
    UInt32 outSize;
    CoreAudioPlugin *self = (CoreAudioPlugin *)_self;
    Str255 str;

    OSType2Str(inPropertyID, str);
    NSLog(@"deviceListenerProc: %s", str);

    if ( isInput )
      return noErr;

    switch(inPropertyID)
      {
      case kAudioDevicePropertyBufferSize:
	break;

      case kAudioDevicePropertyDeviceIsRunning:
	break;

      case kAudioDevicePropertyVolumeScalar:
	{
	  float value;
	  outSize = sizeof(float);
	  err = AudioDeviceGetProperty(inDevice, 
				       inLine, 
				       isInput,
				       kAudioDevicePropertyVolumeScalar, 
				       &outSize, 
				       &value);
	  NSLog(@"volume changed to: %f", value);
	}
	break;

      case kAudioDevicePropertyMute:
	{
	  UInt32 muted;
	  outSize = sizeof(UInt32);
	  err = AudioDeviceGetProperty(inDevice,
				       inLine,
				       isInput,
				       kAudioDevicePropertyMute,
				       &outSize,
				       &muted);
	  NSLog(@"muted: %d", muted);
	}
	break;
	
      case kAudioDevicePropertyDeviceIsAlive:
	break;
      }
        
    return err;
}
*/

OSStatus outputIOProc (AudioDeviceID inDevice, 
		       const AudioTimeStamp *inNow, 
		       const AudioBufferList *inInputData, 
                       const AudioTimeStamp *inInputTime, 
		       AudioBufferList *outOutputData, 
		       const AudioTimeStamp *inOutputTime, 
                       void *_self)
{
  CoreAudioPlugin *self = (CoreAudioPlugin *)_self;
  void *buffer = [self->bufferStack pop];

  
  if ( (self->firstTimeStamp.mFlags & kAudioTimeStampSampleTimeValid) == 0 )
    {
      self->firstTimeStamp = *inOutputTime;
    }

  if ( buffer != NULL )
    {
      BlockMoveData(buffer, 
		    outOutputData->mBuffers[0].mData, 
		    self->outputBufferSize);
      free(buffer);
      self->bytes_output += self->outputBufferSize;
    }
  else
    {
      memset(outOutputData->mBuffers[0].mData, 0, self->outputBufferSize);
    }
  
  return noErr;
}


- (void)closeAudio
{
  if ( isPaused == NO )
    {
      OSErr err = AudioDeviceStop(deviceID, outputIOProc);
      err = AudioDeviceRemoveIOProc(deviceID, outputIOProc);
    }
  [bufferStack release];
  bufferStack = nil;
}

- (void)writeAudioData:(const void *)ptr length:(int)length
{
  [bufferStack push:ptr length:length];
  bytes_written += length;
  if ( started == NO )
    {
      AudioDeviceStart(deviceID, outputIOProc);
      started = YES;
    }
}

- (BOOL)openAudioFormat:(AFormat )fmt rate:(int)rate numChannels:(int)nch
{
  OSErr err;
  UInt32 outSize;
  UInt32 isAlive;

  outSize = sizeof(outDeviceFormat);
  AudioDeviceGetProperty(deviceID,
			 0, 
			 false, 
			 kAudioDevicePropertyStreamFormat, 
			 &outSize, 
			 &outDeviceFormat);

  outSize = sizeof(UInt32);
  AudioDeviceGetProperty(deviceID,
			 0,
			 false, 
			 kAudioDevicePropertyDeviceIsAlive,
			 &outSize,
			 &isAlive);

  if ( isAlive == 0 )
    {
      NSLog(@"audio device is not alive");
    }

  if ( fmt != FMT_S16_NE )
    {
      NSLog(@"format not supported");
      return NO;
    }

  /*
    AudioStreamBasicDescription format;
    memset(&format, 0, sizeof(format));
    outDeviceFormat.mChannelsPerFrame = nch;
    outDeviceFormat.mSampleRate = rate;
    outDeviceFormat.mFormatFlags = 0;
    outDeviceFormat.mFormatFlags &= kLinearPCMFormatFlagIsSignedInteger;
    outDeviceFormat.mFormatFlags &= kLinearPCMFormatFlagIsBigEndian;
    
    outSize = sizeof(format);
    err = AudioDeviceGetProperty(deviceID, 0, false, 
    kAudioDevicePropertyStreamFormatMatch,
    &outSize,
    &format);

    NSLog(@"mBitsPerChannel: %d", format.mBitsPerChannel);

    err = AudioDeviceSetProperty(deviceID, 
				   0, 
				   0,
				   false, 
				   kAudioDevicePropertyStreamFormat, 
				   sizeof(outDeviceFormat), 
				   &format);

      if ( err != noErr )
	{
	  NSLog(@"Can't set format");
	  return NO;
	}
  */

  outputBufferSize = 16384;
  //outputBufferSize = 4096;
  //outputBufferSize = 32768;
  err = AudioDeviceSetProperty(deviceID, 
			       0, 
			       0,
			       false,
			       kAudioDevicePropertyBufferSize,
			       sizeof(UInt32),
			       &outputBufferSize);
  
  if ( err != noErr )
    {
      NSLog(@"Can't set bufferSize");
      return NO;
    }

  ebps=(rate * nch)*2;
  bps = ebps;
  bytes_written = 0;
  bytes_output = 0;
  sample_rate = rate;
  firstTimeStamp.mFlags = 0;
  outputTimeOffset = 0;
  bufferStack = [[BufferStack alloc] initWithSize:NUM_BUFFERS
				       bufferSize:outputBufferSize];
  started = NO;
  isPaused = NO;

  err = AudioDeviceAddIOProc(deviceID, 
			     outputIOProc, 
			     (void *)self);

  return YES;
}

- init
{
  UInt32 outSize;
  OSErr err;

  deviceID = nil;

  outSize = sizeof(deviceID);
  err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
				 &outSize, 
				 &deviceID);
  
  if ( err != noErr )
    {
      NSLog(@"unable to get default audio device");
      return nil;
    }

  /*
  AudioDeviceAddPropertyListener(deviceID, 
				 1,
				 false,
				 kAudioDevicePropertyVolumeScalar,
				 deviceListenerProc, 
				 self);

  AudioDeviceAddPropertyListener(deviceID, 
				 2,
				 false,
				 kAudioDevicePropertyVolumeScalar,
				 deviceListenerProc, 
				 self);

  AudioDeviceAddPropertyListener(deviceID, 
				 1,
				 false,
				 kAudioDevicePropertyMute,
				 deviceListenerProc, 
				 self);
  */

  return [super initWithDescription:[NSString stringWithFormat:@"CoreAudio Driver %@", getVersion()]];
}

- (void)getVolumeLeft:(int *)l right:(int *)r
{
  Float32 left, right;
  UInt32 size;
  OSErr err;

  size = sizeof(left);
  err = AudioDeviceGetProperty(deviceID, 
			       1, 
			       false, 
			       kAudioDevicePropertyVolumeScalar, 
			       &size,
			       &left);

  err = AudioDeviceGetProperty(deviceID, 
			       2, 
			       false, 
			       kAudioDevicePropertyVolumeScalar, 
			       &size,
			       &right);

  *l = left * 100.0;
  *r = right * 100.0;
}

- (void)setVolumeLeft:(int )l right:(int)r
{
  Float32 left, right;
  UInt32 size;
  OSErr err;

  left = l / 100.0;
  right = r / 100.0;

  size = sizeof(left);
  
  err = AudioDeviceSetProperty(deviceID, 
			       0,
			       1, 
			       false, 
			       kAudioDevicePropertyVolumeScalar, 
			       size,
			       &left);

  err = AudioDeviceSetProperty(deviceID, 
			       0,
			       2, 
			       false, 
			       kAudioDevicePropertyVolumeScalar, 
			       size,
			       &right);
}

- (void)about
{
  static NibObject *aboutBox = nil;

  if (aboutBox == nil) {
    aboutBox = [[NibObject alloc] 
	 initWithNibName:@"About" 
		  bundle:[NSBundle bundleForClass:[self class]]];
  }
  [aboutBox show];
}

- (BOOL)hasAbout
{
  return YES;
}

/*
- (void)configure
{
  static CAConfig *config = nil;

  if (config == nil) 
    config = [[CAConfig alloc] init];

  [config show];
}
*/

- (BOOL)hasConfigure
{
  return FALSE;
}

- (BOOL)enabledByDefault
{
  return YES;
}

@end


int GetAudioDevices (Ptr *devices, short *devicesAvailable)
{
    OSStatus	err = noErr;
    UInt32 		outSize;
    Boolean		outWritable;
    
    // find out how many audio devices there are, if any
    err = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &outSize, &outWritable);	
    
    if ( err != noErr )
      {
	return 0;
      }
   
    // calculate the number of device available
    *devicesAvailable = outSize / sizeof(AudioDeviceID);						
    if ( *devicesAvailable < 1 )
      {
	NSLog(@"No devices");
	return 0;
      }
    
    // make space for the devices we are about to get
    *devices = malloc(outSize);						
    // get an array of AudioDeviceIDs
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &outSize, (void *) *devices);	

    if (err != noErr )
      return 0;

    return 1;
}


@implementation BufferStack

- initWithSize:(int)ssize bufferSize:(int)bsize
{
  size = ssize;
  buffer_size = bsize;
  stack = malloc(sizeof(BufferEntry *)*size);
  stack_length = 0;

#ifdef USE_PTHREADS
  {
    int rc;

    rc = pthread_mutex_init(&mutex, NULL);
    if (rc) 
      {
	fprintf(stderr, "ao_macosx_open: pthread_mutex_init returned %d\n", rc);
      }
    
    rc = pthread_cond_init(&condition, NULL);
    if (rc) 
      {
	fprintf(stderr, "ao_macosx_open: pthread_mutex_init returned %d\n", rc);
      }
  }
#else
  clock = [[NSConditionLock alloc] init];
#endif

  return [super init];
}

- (void)dealloc
{
  int i;
  for ( i = 0; i < stack_length; i++ )
    {
      free(stack[i]->buffer);
    }
  free(stack);
  [super dealloc];
}

- (void)lock:(NSString *)from
{
#ifdef DEBUG_LOCKS
  NSLog(@"lock: %@", from);
#endif
#ifdef USE_PTHREADS
  pthread_mutex_lock(&mutex);
#else
  [clock lock];
#endif
}

- (void)poplock
{
#ifdef DEBUG_LOCKS
  NSLog(@"lock: pop");
#endif
#ifdef USE_PTHREADS
  pthread_mutex_lock(&mutex);
#else
  [clock lock];
#endif
}

- (void)unlock:(NSString *)from
{
#ifdef DEBUG_LOCKS
  NSLog(@"unlock: %@", from);
#endif
#ifdef USE_PTHREADS
  pthread_mutex_unlock(&mutex);
#else
  [clock unlock];
#endif
}

- (void)popunlock
{
#ifdef DEBUG_LOCKS
  NSLog(@"unlock: pop");
#endif
#ifdef USE_PTHREADS
  pthread_mutex_unlock(&mutex);
#else
  [clock unlockWithCondition:1];
#endif
}

- (void)signal
{
#ifdef USE_PTHREADS
#ifdef DEBUG_LOCKS
  NSLog(@"signal");
#endif
  pthread_cond_signal(&condition);
#endif
}

- (void)wait
{
#ifdef DEBUG_LOCKS
  NSLog(@"wait");
#endif
#ifdef USE_PTHREADS
  pthread_cond_wait(&condition, &mutex);
#else
  [clock lockWhenCondition:1];
#endif
#ifdef DEBUG_LOCKS
  NSLog(@"back from wait");
#endif
}

- (void)stop
{
  stopped = YES;
  [self lock:@"stop"];
  [self signal];
  [self unlock:@"stop"];
}

- (void)flush
{
  int i;

  [self lock:@"flush"];

  for ( i = 0; i < stack_length; i++ )
    {
      free(stack[i]->buffer);
      stack[i]->len = 0;
    }

  stack_length = 0;
  [self unlock:@"flush"];
}

- (void)cancelWrite
{
  [self lock:@"cancelWrite"];
  stopped = YES;
  [self signal];
  stopped = NO;
  [self unlock:@"cancelWrite"];
}

- (void *)pop
{
  void *res = 0;
  [self poplock];
  if ( stack_length > 0 
       && (stack[0]->len == buffer_size || waitingForFinish))
    {
      res = stack[0]->buffer;
      if (stack[0]->len < buffer_size)
	memset(res+stack[0]->len, 0, buffer_size-stack[0]->len);
      memmove(stack, stack+1, (size-1)*sizeof(BufferEntry *));
      stack_length--;
#ifdef DEBUG_STACK
      NSLog(@"popped some data");
#endif
    }
#ifdef DEBUG_STACK
  else
    {
      NSLog(@"popped nothing");
    }
#endif
  [self signal];
  [self popunlock];
  return res;
}

- (BOOL)isFull
{
  return stack_length < size ? NO : YES;
}

- (void)push:(const void *)buffer length:(int)len
{
#ifdef DEBUG_STACK
  NSLog(@"push: %d", len);
#endif
  
  while ( len > 0 )
    {
      int copy;
      void *dst;
      BufferEntry *entry;

      [self lock:@"push"];

      if ( [self isFull] == YES )
	{
	  [self wait];

	  if ( stopped )
	    {
	      [self unlock:@"push"];
	      return;
	    }
	}

      if ( stack_length > 0 && stack[stack_length-1]->len != buffer_size)
	{
	  int in_buffer, left;
	  entry = stack[stack_length-1];
	  in_buffer = entry->len;
	  left = buffer_size - in_buffer;
	  dst = entry->buffer + in_buffer;
	  copy = (len*2) < left ? len : left/2;
	}
      else
	{
	  stack[stack_length] = malloc(sizeof(BufferEntry));
	  entry = stack[stack_length];
	  entry->buffer = malloc(buffer_size);
	  entry->len = 0;
	  stack_length++;
	  dst = entry->buffer;
	  copy = (len*2) < buffer_size ? len : (buffer_size/2);
	}
      
      entry->len += (copy*2);

      Convert16BitIntegerTo32Float(buffer, 
				   dst,
				   copy);

      buffer += copy;
      len -= copy;
      [self unlock:@"push"];
    }
}

- (void)waitTillDone
{
  waitingForFinish = YES;
  while ( stack_length > 0 )
    {
      [self lock:@"waitTillDone"];
      [self wait];
      [self unlock:@"waitTillDone"];
    }
  waitingForFinish = NO;
}

- (int)length
{
  return stack_length;
}

@end

void Convert16BitIntegerTo32Float(const void *in16BitDataPtr, 
				  Ptr out32BitDataPtr, 
				  UInt32 totalBytes)
{
  UInt32 samples = totalBytes / 2 /*each 16 bit sample is 2 bytes*/;
  UInt32 count;
  SInt16 *inDataPtr = (SInt16 *) in16BitDataPtr;
  Float32 *outDataPtr = (Float32 *) out32BitDataPtr;
    
  for (count = 0; count < samples; count++)
    {
      *outDataPtr = (Float32) *inDataPtr;
      if (*outDataPtr > 0)
	*outDataPtr /= 32767.0;
      else
	*outDataPtr /= 32768.0;
      
      outDataPtr++;
      inDataPtr++;
    }
}

