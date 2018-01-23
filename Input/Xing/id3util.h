
#ifdef __cplusplus
extern "C" {
#endif


enum id3_format_codes { ID3_ARTIST = '1', ID3_TITLE, ID3_ALBUM, ID3_YEAR,
			ID3_COMMENT, ID3_GENRE, FILE_NAME, FILE_PATH,
			FILE_EXT } ;


NSDictionary *x_get_song_info(NSString *filename, NSString *id3_format);


#ifdef __cplusplus
}
#endif
