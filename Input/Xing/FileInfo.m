#define _MATH_H_ // keep math.h from being include
//#include "id3_tag.h"
//extern "C" {
#import <AppKit/AppKit.h>
//}
#import "FileInfo.h"
#import <MXA/id3funcs.h>

@interface ID3Value : NSObject
{
  NSString *name;
  NSString *value;
}

- initWithName:(NSString *)aname value:(NSString *)avalue;
- (NSString *)name;
- (NSString *)value;
@end
@implementation ID3Value
- initWithName:(NSString *)aname value:(NSString *)avalue
{
  name = [aname retain];
  value = [avalue retain];
  return [super init];
}

- (void)dealloc
{
  [name release];
  [value release];
}

- (NSString *)name
{
  return name;
}

- (NSString *)value
{
  return value;
}

@end

@implementation XFileInfo

- (NSString *)nibName
{
  return @"FileInfo";
}

- (BOOL)readtag
{
  NSDictionary *dict;
  NSArray *keys;
  int i;

  [values release];
  values = nil;

  dict = id3_get_tag_dictionary(filename);

  if ( dict != nil )
    {
      keys = [dict allKeys];
      
      values = [[NSMutableArray array] retain];
      for ( i = 0; i < [keys count]; i++ )
	{
	  int j;
	  NSString *key = [keys objectAtIndex:i];
	  NSArray *v  = [dict objectForKey:key];
	  for ( j = 0; j < [v count]; j++ )
	    {
	      [values addObject:[[ID3Value alloc] initWithName:key
						  value:[v objectAtIndex:j]]];
	    }
	}
    }
  
  return values != nil;
}

- (void)alert:(NSString *)string
{
  NSRunAlertPanel(@"File Info", string, @"OK", nil, nil);
}

- (BOOL)savetag
{
  return NO;
}	

- (BOOL)removetag
{
  return NO;
}	


- (void)updateDisplay
{
  if ( [self readtag] ) {
    [window setTitleWithRepresentedFilename:filename];
    [tableView reloadData];
  } else {
  }
  
}

- (void)awakeFromNib
{
  [tableView setDataSource:self];
}

- (void)removeId3:sender
{
  if ( [self removetag] )
    [super cancel:sender];
}

- (void)setFileName:(NSString *)_filename
{
  [filename release];
  filename = [_filename retain];
}

- (void)ok:sender
{
  [super ok:sender];
}

- (id)tableView:(NSTableView *)aTableView
   objectValueForTableColumn:(NSTableColumn *)aTableColumn
   row:(int)rowIndex
{
  if ( [[aTableColumn identifier] isEqualToString:@"name"] )
    {
      return [[values objectAtIndex:rowIndex] name];
    }
  else
    return [[values objectAtIndex:rowIndex] value];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
   return [values count];
}


@end


