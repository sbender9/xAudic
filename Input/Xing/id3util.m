#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSDictionary.h>
#include "id3.h"
#include "id3util.h"
#include <MXA/id3funcs.h>

NSString *get_artist(ID3Tag *tag)
{

  NSString *val;
  
  val = id3_get_field_text(tag, ID3FID_LEADARTIST);
  if ( val == nil ) {
    val = id3_get_field_text(tag, ID3FID_BAND);
    if ( val == nil ) {
      val = id3_get_field_text(tag, ID3FID_CONDUCTOR);
      if ( val == nil )
	val = id3_get_field_text(tag, ID3FID_COMPOSER);
    }
  }
  return val;
}

#define do(type) \
  val = id3_get_field_text(tag, type); \
  if ( val ) \
    [res appendString:val]

NSDictionary *x_get_song_info(NSString *filename, NSString *id3_format)
{
  NSMutableString *res = [NSMutableString string];
  NSString *ret = res;
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];

  ID3Tag *tag = id3_create_tag(filename);
  unsigned int i = 0;
  NSString *val;

  if ( tag != 0 ) {
    val = get_artist(tag);
    if ( val )
      [dict setObject:val forKey:@"artistName"];
    val = id3_get_field_text(tag, ID3FID_ALBUM);
    if ( val )
      [dict setObject:val forKey:@"albumName"];
    val = id3_get_field_text(tag, ID3FID_TITLE);
    if ( val )
      [dict setObject:val forKey:@"songName"];
    
    while ( i < [id3_format length] ) {
      char c = [id3_format characterAtIndex:i++];
      if ( c == '%') {
	char c2 = [id3_format characterAtIndex:i++];
	/*
	if ( c2 >= '0' && c2 <= '9' ) {
	*/
	  switch (c2) {
	  case '%':
	    [res appendString:@"%"] ;
	    break ;
	  
	  case 'W':
	  case ID3_ARTIST:
	    val = get_artist(tag);
	    if ( val )
	      [res appendString:val];
	    break;

	  case 'V':
	  case ID3_TITLE:
	    do(ID3FID_TITLE);
	    break ;
	    
	  case ID3_ALBUM:
	    do(ID3FID_ALBUM);
	    break;
	    
	  case ID3_YEAR:
	    do(ID3FID_YEAR);
	    break;
	    
	  case ID3_COMMENT:
	    do(ID3FID_COMMENT);
	    break;
	    
	  case ID3_GENRE:
	    do(ID3FID_CONTENTTYPE);
	    break ;
	    
	  case FILE_NAME:
	    [res appendString:[filename lastPathComponent]];
	    break ;
	    
	  case FILE_PATH:
	    [res appendString:[filename stringByDeletingLastPathComponent]];
	    break ;
	    
	  case FILE_EXT:
	    [res appendString:[filename pathExtension]];
	    break ;
	  }
	  /*
	} else {
	  ID3_FrameID fid;
	  
	  fid = (ID3_FrameID)(c2-64);
	  do(fid);
	}
	  */
	
      } else
	[res appendFormat:@"%c", c];
    }
  }

  if ( [res length] == 0 ) {
    NSString *ext;
    
    ret = [filename lastPathComponent];
    ext = [ret pathExtension];
    if([ext isEqualToString:@"mpg"] || [ext isEqualToString:@"mp2"] || 
       [ext isEqualToString:@"mp3"] || [ext isEqualToString:@"mpeg"]) {
      ret = [ret stringByDeletingPathExtension];
    }
  }

  [dict setObject:ret forKey:@"title"];

  return dict;
}


/*
%A = Origal Album,
%B = Publisher
%C = Encoded By
%D = Encoder Settings
%E = Original Filename
%F = Language
%G = Part In Set
%H = Date
%I = Time
%J = Recording Dates
%K = Media Type
%L = File Type
%M = Net Radio Station
%N = Net Radio Owner
%O = Lyricist
%P = Original Artist
%Q = Original Lyricist
%R = Subtitle
%S = Mix Artist
%T = User Text
%U = Content Group
%V = Title
%W = Lead Artist
%X = Band
%Y = Album
%Z = Year
%a = Conductor
%b = Composer
%c = Copyright
%d = Content Type
%e = Track Num
%f = Comment
%g = WWW Audio File
%h = WWW Artist
%i = WWW Audio Source
%j = WWW Commercial Info
%k = WWW Copyright
%l = WWW Publisher
%m = WWW Payment
%n = WWW Radiopage
%o = WWW User
%p = Involved People
%q = Unsynced Lyrics
%t = Unique File Id
%u = Play Counter
%v = Popular Imeter
%7 = File name
%8 = Path
%9 = File extension
*/
