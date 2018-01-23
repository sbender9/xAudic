#import <MXA/NibObject.h>

@interface EchoConfigure : NibObject
{
  id delaySlider;
  id delayText;
  id feedbackSlider;
  id feedbackText;
  id volumeSlider;
  id volumeText;
}

- (void)valueChanged:sender;

+ (void)loadConfig;


@end
