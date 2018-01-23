/*  
 *  xAudic - an audio player for MacOS X
 *  Copyright (C) 1999  Scott P. Bender (sbender@harmony-ds.com)
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

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSPathUtilities.h>

#include "id3.h"

/** 
    I know this sucks, but I can't get exceptions to work properly 
    in a bundle
**/

extern NSString *id3_frames[];
extern int num_id3frames;

NSString *id3_get_field_text(ID3Tag *tag, ID3_FrameID frameId)
{
  char buf[1024];
  ID3Frame *frame = ID3Tag_FindFrameWithID(tag, frameId);
  if ( frame != 0 ) 
    {
      ID3Field *field = ID3Frame_GetField(frame, ID3FN_TEXT);
      if ( field != 0 )
	{
	  NSString *res;
	  //ID3Field_GetASCII(field, buf, 1024);
	  ID3Field_GetASCIIItem(field, buf, 1024, 0);
	  res =  [NSString stringWithCString:buf];
	  return res;
	}
    }
  return nil;
}

ID3Tag *id3_create_tag(NSString *filename)
{
  ID3Tag *tag =  ID3Tag_New();
  if ( tag != NULL )
    {
      ID3Tag_Link(tag, [filename fileSystemRepresentation]);
      return tag;
    }
  return 0;
}

void id3_delete_tag(ID3Tag *tag)
{
  ID3Tag_Delete(tag);
}


NSDictionary *id3_get_tag_dictionary(NSString *filename)
{
  NSMutableDictionary *vals = nil;
  ID3Tag *tag;
  NSString *val;
  ID3Frame *frame;
  char buf[1024];
  ID3TagIterator *it;
      
  tag = ID3Tag_New();
  ID3Tag_Link(tag, [filename fileSystemRepresentation]);

  vals = [NSMutableDictionary dictionary];

  it = ID3Tag_CreateIterator(tag);
  while ((frame = ID3TagIterator_GetNext(it)) != 0 )
    {
      const char *desc;
      ID3Field *field = ID3Frame_GetField(frame, ID3FN_TEXT);

      *buf = 0;
      if ( field != 0 )
	{
	  ID3Field_GetASCII(field, buf, 1024);
	  val = [NSString stringWithCString:buf];
	}
      else
	{
	  val = @"(Not Textual)";
	}


      {
	NSString *key;
	NSMutableArray *values;
	desc = ID3Frame_GetDescription(frame);
	key = [NSString stringWithCString:desc];

	values = [vals objectForKey:key];
	if ( values == nil )
	  {
	    values = [NSMutableArray array];
	    [vals setObject:values forKey:key];
	  }
	[values addObject:val];
      }
    }
  return vals;
}


NSString *id3_frames[] = {
  @"None",
  @"Origal Album",
  @"Publisher",
  @"Encoded By",
  @"Encoder Settings",
  @"Original Filename",
  @"Language",
  @"Part In Set",
  @"Date",
  @"Time",
  @"Recording Dates",
  @"Media Type",
  @"File Type",
  @"Net Radio Station",
  @"Net Radio Owner",
  @"Lyricist",
  @"Original Artist",
  @"Original Lyricist",
  @"Subtitle",
  @"Mix Artist",
  @"User Text",
  @"Content Group",
  @"Title",
  @"Lead Artist",
  @"Band",
  @"Album",
  @"Year",
  @"Conductor",
  @"Composer",
  @"Copyright",
  @"Content Type",
  @"Track Num",
  @"Comment",
  @"WWW Audio File",
  @"WWW Artist",
  @"WWW Audio Source",
  @"WWW Commercial Info",
  @"WWW Copyright",
  @"WWW Publisher",
  @"WWW Payment",
  @"WWW Radiopage",
  @"WWW User",
  @"Involved People",
  @"Unsynced Lyrics",
  @"Picture",
  @"General Object",
  @"Unique File Id",
  @"Play Counter",
  @"Popular Imeter",
  @"Group Ingreg",
  @"Gryptoreg"
};

int num_id3frames = sizeof(id3_frames) / sizeof(*id3_frames);
