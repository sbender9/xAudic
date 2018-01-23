/*  x11amp - graphically mp3 player..
 *  Copyright (C) 1998-1999  Mikael Alm, Olle Hallnas, Thomas Nilsson and 4Front Technologies
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
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
#import <MXA/Common.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSPanel.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#import <MXA/Plugins.h>
#import "Configure.h"
#import "xing.h"
#import "http.h"

struct hostent *gethostbyname2(const char *name, int af);

#define usleep mysleep

BOOL xhttp_check_for_data(void);

#define min(x,y) (x)<(y)?(x):(y)
#define min3(x,y,z) min(x,y)<(z)?min(x,y):(z)

int http_bitrate;
static char *icy_name=NULL;
static unsigned char *buffer = 0;
static int bufferSize = 0, bufferUsed = 0, bytesRead = 0;
static int prebufferSize = 0;

static BOOL going,eof=NO, prebuffering = NO;
static int sock = -1;

static NSLock *buffer_lock, *running_lock;

static void xparse_url(NSString *_url,NSString **user,NSString **pass,NSString **host,int *port,NSString **filename)
{
  char *h,*p,*pt,*f;
  char *url = strdup([_url cString]);

  if([_url hasPrefix:@"http://"])
    url+=7;
  if(h=strchr(url,'@'))
    {
      *h='\0';
      if(p=strchr(url,':'))
	{
	  *p='\0';
	  p++;
	  *pass=[NSString stringWithCString:p];
	}
      else
	*pass=nil;
      *user=[NSString stringWithCString:url];
      h++;
      url=h;
    }
  else
    h=url;
  if(pt=strchr(url,':'))
    {
      *pt='\0';
      pt++;
      if(f=strchr(pt,'/'))
	{
	  *f='\0';
	  f++;
	}
      else
	f=NULL;
      *port=atoi(pt);
    }
  else
    {
      *port=80;
      if(f=strchr(h,'/'))
	{
	  *f='\0';
	  f++;
	}
      else
	f=NULL;
    }
  *host=[NSString stringWithCString:h];
  if(f)
    *filename=[NSString stringWithCString:f];
  else
    *filename=NULL;
}

void http_close(void)
{
  going=NO;

  [running_lock lock];
  [running_lock unlock];

  if(icy_name)
    free(icy_name);
  icy_name=NULL;
}

int http_read(void *data, int length)
{
  int total_bytes = 0, left = length, bytes;

  while ( (prebuffering || bufferUsed < length) && going ) {
    if ( !prebuffering && ![[Output output] bufferPlaying] ) {
      prebuffering = YES;
      NSLog(@"Set prebuffering");
    }
    usleep(10000);
  }

  if ( !going ) {
    return -1;
  }

  while ( total_bytes < length && going ) {
    bytes = left < bufferUsed-bytesRead ? left : bufferUsed-bytesRead;
    if ( bytes ) {
      memcpy(((unsigned char *)data)+total_bytes, 
	     buffer + bytesRead, bytes);
      bytesRead += bytes;
      total_bytes += bytes;
      left -= bytes;
    } else
      usleep(1000);

    if ( bufferUsed == bufferSize ) {
      memcpy(buffer, buffer+bytesRead, bufferSize-bytesRead);
      bufferUsed = bufferUsed-bytesRead;
      bytesRead = 0;
    }
  }
  return total_bytes;
}

int xhttp_read_line(char *buf,int size)
{
  int i=0;
	
  while(going&&i<size-1)
    {
      if(xhttp_check_for_data())
	{
	  if(read(sock,buf+i,1)<=0)
	    return -1;
	  if(buf[i]=='\n')
	    break;
	  if(buf[i]!='\r')
	    i++;
	}
    }
  if(!going)
    return -1;
  buf[i]='\0';
  return i;	
}

BOOL xhttp_check_for_data(void)
{
  fd_set set;
  struct timeval tv;
  int ret;
  
  tv.tv_sec=0;
  tv.tv_usec=10000;
  FD_ZERO(&set);
  FD_SET(sock,&set);
  ret=select(sock+1,&set,NULL,NULL,&tv);
  if(ret>0)
    return YES;
  return NO;
}

@interface XHttpDecoder : NSObject
@end

@implementation XHttpDecoder
- (void)read_loop:(NSString *)url
{
  char line[1024], *status;
  NSString *user = nil,*pass = nil,*host = nil,*filename = nil;
  NSString *chost;
  int cnt;
  int port,cport;
  struct hostent *hp;
  struct sockaddr_in address;
  NSString *temp;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSTimeInterval timeOut = [Configure httpTimeout];
  NSDate *startTime;


  [running_lock lock];

  bufferSize = [Configure httpBufferSize] * 1024;
  prebufferSize = (bufferSize*[Configure httpPreBuffer])/100;
  bufferUsed = 0;
  bytesRead = 0;
  prebuffering = NO;
  
  buffer = malloc(bufferSize);

  xparse_url(url,&user,&pass,&host,&port,&filename);
 
  if(!filename || ![filename length]) 
    filename = @"";

  chost = [Configure useProxy] ? [Configure proxyHost] : host;
  cport = [Configure useProxy] ? [Configure proxyPort] : port;
	
  sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
//  fcntl(sock,F_SETFL,O_NONBLOCK);
  fcntl(sock,F_SETFL,fcntl(sock, F_GETFL)|O_NONBLOCK);
  address.sin_family=AF_INET;
  
  [Input setInfoText:[NSString stringWithFormat:@"LOOKING UP %@", chost]];
	
  if(!(hp=gethostbyname2([chost cString], AF_INET))) {
    eof = YES;
  }
  
  if(!eof && going) {
    memcpy(&address.sin_addr.s_addr,*(hp->h_addr_list),sizeof(address.sin_addr.s_addr));
    address.sin_port=htons(cport);
      
    [xip setInfoText:[NSString stringWithFormat:@"CONNECTING TO %@:%d",
		       chost,cport]];

    if(connect(sock,(struct sockaddr *)&address,
	       sizeof(struct sockaddr_in))==-1)    {
      if(errno!=EINPROGRESS) {
	[xip setInfoText:nil];
	eof=YES;
      } else {
	struct timeval tv;
	fd_set fdSet; 
	int ret, error, err_len;
	startTime = [NSDate date];

	while ( going && !eof ) {
	  tv.tv_sec = 0;
	  tv.tv_usec = 0;
	  FD_ZERO(&fdSet); 
	  FD_SET(sock, &fdSet);
	  ret = select(sock + 1, NULL, &fdSet, NULL, &tv);
//	  printf("select returned: %d\n", ret);
	  if ( ret > 0 ) {
	    err_len = sizeof(error);
	    getsockopt(sock,SOL_SOCKET,SO_ERROR,&error,&err_len);
	    if ( error )
	      eof = YES;
	    break;
	  } else if ( ret < 0 )
	    eof = YES;
	  else
	    mysleep(1000);

	  if ( [[NSDate date] timeIntervalSinceDate:startTime] 
	       > (timeOut*10) ) {
	    eof = YES;
	    break;
	  }
	}
      }
    }
    
    if ( eof ) {
      NSRunAlertPanel(getPackageName(), 
		      @"HTTP: Could not connect to remote host",
		      @"OK", nil, nil);
    }

    if(!eof && going) {
      NSString *file;
      BOOL found = NO;
      int retryCount = 0;

      if ( [Configure useProxy] )
	file = url;
      else
	file = [@"/" stringByAppendingString:filename];

      temp = [NSString stringWithFormat:@"GET %@ HTTP/1.0\r\nHost: %@\r\nUser-Agent: %@/%@\r\n\r\n",file,host,getPackageName(),getVersion()];
      while ( retryCount++ < 3 && !eof && !found ) {
	write(sock, [temp cString], [temp length]);
	[xip setInfoText:[NSString stringWithFormat:@"%@: WAITING FOR REPLY",
			  retryCount-1 ? @"RETRY" : @"CONNECTED" ]];
	startTime = [NSDate date];
	while ( going && !eof ) {
	  if ( xhttp_check_for_data() ) {
	    if ( xhttp_read_line(line,1024) > 0 ) {
	      startTime = [NSDate date];
	      status = strchr(line,' ');
	      if ( status ) {
		if(status[1]=='2') {
		  found = YES;
		  break;
		} else {
		  eof = YES;
		  [xip setInfoText:nil];
		  break;
		}
	      }
	    } else {
	      eof = YES;
	      [xip setInfoText:nil];
	    }
	  } else
	    usleep(1000);

	  if ( [[NSDate date] timeIntervalSinceDate:startTime] 
	       > timeOut )
	    break;
	}
      }

      if ( eof ) {
	NSRunAlertPanel(getPackageName(), 
			@"Invalid response from HTTP server",
			@"OK", nil, nil);
      } else if ( !found ) {
	NSRunAlertPanel(getPackageName(), 
			@"HTTP timed out waiting for response",
			@"OK", nil, nil);
	eof = YES;
      }


      if ( eof == NO ) {
	found = NO;
	startTime = [NSDate date];
	while( going && !eof )  {
	  if ( xhttp_check_for_data() ) {
	    if ( (cnt = xhttp_read_line(line,1024))!=-1 ) {
	      startTime = [NSDate date];
	      if( !cnt ) {
		found = YES;
		break;
	      }
	      if( !strncmp(line,"icy-name:",9) )
		icy_name=strdup(line+9);
	      else if (!strncmp(line, "x-audiocast-name:", 17))
		icy_name=strdup(line+17);
	      else if (!strncmp(line, "icy-br:", 7))
		http_bitrate = atoi(line+7);
	      else if (!strncmp(line, "x-audiocast-bitrate:", 20))
		http_bitrate = atoi(line+20);
	    } else {
	      eof=YES;
	      [xip setInfoText:nil];
	      break;
	    }
	  } 
	  if ( [[NSDate date] timeIntervalSinceDate:startTime] 
	       > timeOut ) {
	    break;
	  }
	}
	
	if ( !found ) {
	  NSRunAlertPanel(getPackageName(),
			  @"HTTP timed out waiting for response",
			  @"OK", nil, nil);
	  eof = YES;
	}
	
	if ( !eof ) {
	  int bytes;
	  
	  [xip setInfoText:@"CONNECTED: GOT REPLY"];    
	  
	  
	  startTime = [[NSDate date] retain];
	  while ( going && !eof ) {
	    NSAutoreleasePool *spool = [[NSAutoreleasePool alloc] init];
	    if ( bufferSize-bufferUsed > 0  ) {
	      [buffer_lock lock];
	      if ( xhttp_check_for_data() ) {
		int nbytes = bufferSize-bufferUsed;
		[startTime release];
		startTime = [[NSDate date] retain];
		if ( nbytes > 1024 )
		  nbytes = 1024;
		bytes = recv(sock, buffer+bufferUsed, nbytes, 0);
		if ( bytes < 0 ) {
		  NSLog(@"error reading from HTTP stream");
		  eof = YES;
		}
		bufferUsed += bytes;
	      }
	      
	      if( prebuffering ) {
		if ( bufferUsed > prebufferSize ) {
		  NSLog(@"done prebuffer: %d", bufferUsed);
		  prebuffering = NO;
		  [xip unlockInfoText];
		} else {
		  [xip lockInfoText:[NSString stringWithFormat:@"PRE-BUFFERING: %dKB/%dKB",bufferUsed/1024,prebufferSize/1024]];	  
		}
	      }
	      [buffer_lock unlock];
	  } else
	    mysleep(1000);
	    
	    if ( [[NSDate date] timeIntervalSinceDate:startTime]
		 > timeOut ) {
	      NSRunAlertPanel(getPackageName(),
			      @"HTTP timed out waiting for data",
			      @"OK", nil, nil);
	      eof = YES;
	    }
	    
	    [spool release];
	  }
	}
      }
    }
  }

  going = 0;
  if ( sock != -1 ) {
    close(sock);
    sock = -1;
  }
  free(buffer);
  buffer = 0;
  [url release];
  [running_lock unlock];
  [pool release];
//  printf("exiting http thread\n");
}
@end

void http_open(NSString *url)
{
  static XHttpDecoder *decoder = nil;

  buffer = 0;
  bufferSize = 0;
  bufferUsed = 0;
  bytesRead = 0;
  prebufferSize = 0;
  
  if ( decoder == nil )
    decoder = [[XHttpDecoder alloc] init];

  if ( running_lock == nil ) {
    running_lock = [[NSLock alloc] init];
    buffer_lock = [[NSLock alloc] init];
  }

  going = 1;
  [NSApplication detachDrawingThread:@selector(read_loop:)
			    toTarget:decoder
			  withObject:[url retain]];

}

NSString *http_get_title(NSString *url)
{
  if(icy_name)
    return [NSString stringWithCString:icy_name];
  return url;
}
