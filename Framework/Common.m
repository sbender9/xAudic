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

#import "Common.h"
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <AppKit/NSApplication.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <sys/stat.h>

NSString *getPackageName()
{
  static NSString *name = nil;
  if ( name == nil )
    {
      NSDictionary *dict = [[NSBundle bundleForClass:[[NSApp delegate] class]] infoDictionary];
      name = [dict objectForKey:@"CFBundleName"];
    }
  return name;
}

NSString *getVersion()
{
  static NSString *version = nil;
  if ( version == nil )
    {
      NSDictionary *dict = [[NSBundle bundleForClass:[[NSApp delegate] class]] infoDictionary];
      version = [dict objectForKey:@"CFBundleShortVersionString"];
    }
  return version;
}

char *read_ini_string(const char *filename,const char *section,const char *key)
{
  FILE *file;
  char *buffer,*ret_buffer=NULL;
  int found_section=0,found_key=0,off=0,len=0;
  struct stat statbuf;
	
  if(!filename)
    return	NULL;
  
  if(file=fopen(filename,"r"))
    {
      stat(filename,&statbuf);
      buffer=(char *)malloc(statbuf.st_size);
      fread(buffer,1,statbuf.st_size,file);
      while(!found_key&&off<statbuf.st_size)
	{
	  while((buffer[off]=='\r'||buffer[off]=='\n'||buffer[off]==' '||buffer[off]=='\t')&&off<statbuf.st_size) off++;
	  if(off>=statbuf.st_size) break;
	  if(buffer[off]=='[')
	    {
	      off++;
	      if(off>=statbuf.st_size) break;
	      if(off<statbuf.st_size-strlen(section))
		{
		  if(!strncasecmp(section,&buffer[off],strlen(section)))
		    {
		      off+=strlen(section);
		      if(off>=statbuf.st_size) break;
		      if(buffer[off]==']')
			found_section=1;
		      else
			found_section=0;
		      off++;
		      if(off>=statbuf.st_size) break;
		    }
		  else
		    found_section=0;
		}
	      else
		found_section=0;
	      
	    }
	  else if(found_section)
	    {
	      if(off<statbuf.st_size-strlen(key))
		{
		  if(!strncasecmp(key,&buffer[off],strlen(key)))
		    {
		      off+=strlen(key);
		      while((buffer[off]==' '||buffer[off]=='\t')&&off<statbuf.st_size) off++;
		      if(off>=statbuf.st_size) break;
		      if(buffer[off]=='=')
			{
			  off++;
			  while((buffer[off]==' '||buffer[off]=='\t')&&off<statbuf.st_size) off++;
			  if(off>=statbuf.st_size) break;
			  len=0;
			  while(buffer[off+len]!='\r'&&buffer[off+len]!='\n'&&buffer[off+len]!=';'&&off+len<statbuf.st_size) len++;
			  ret_buffer=(char *)malloc(len+1);
			  strncpy(ret_buffer,&buffer[off],len);
			  ret_buffer[len]='\0';
			  off+=len;
			  found_key=1;
			}
		    }
		}
	    }
	  while(buffer[off]!='\r'&&buffer[off]!='\n'&&off<statbuf.st_size) off++;
	}
      free(buffer);
      fclose(file);
    }
  return ret_buffer;
}

