
#import "id3.h"

#ifdef __cplusplus
extern "C" {
#endif

  NSString *id3_get_field_text(ID3Tag *tag, ID3_FrameID frameId);
  ID3Tag *id3_create_tag(NSString *filename);
  void id3_delete_tag(ID3Tag *tag);
  NSDictionary *id3_get_tag_dictionary(NSString *filename);

#ifdef __cplusplus
}
#endif
