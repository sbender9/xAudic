#import <MXA/NibObject.h>
#import "id3.h"

@class NSMutableArray;

@interface XFileInfo : NibObject
{
  id tableView;
  NSString *filename;
  NSMutableArray *values;
}

- (void)removeId3:sender;
- (void)setFileName:(NSString *)_filename;

@end
