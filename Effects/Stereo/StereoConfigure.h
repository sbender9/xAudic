#import <MXA/NibObject.h>

@interface StereoConfigure : NibObject
{
  id intensitySlider;
  id intensityText;
}

- (void)intensityChanged:sender;

@end
