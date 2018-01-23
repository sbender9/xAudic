/* (PD) 2001 The Bitzi Corporation
 * Please see file COPYING or http://bitzi.com/publicdomain 
 * for more info.
 *
 * $Id: sigmp3.h,v 1.1.1.1 2001/05/21 18:46:55 sbender Exp $
 */
#ifndef MP3_H
#define MP3_H

typedef struct _mp3_info
{
    int            bitrate;
    int            samplerate;
    int            stereo;
    int            duration;
    int            frames;
    int            mpegVer;
    int            avgBitrate;

    // Private information -- do not use
    unsigned int   skipSize;
    unsigned char  spanningHeader[3];
    unsigned int   spanningSize;
    unsigned int   goodBytes, badBytes;
} mp3_info;

#define MP3_HEADER_SIZE 4

void mp3_init(mp3_info *info);
void mp3_final(mp3_info *info);
void mp3_update(mp3_info      *info,
                unsigned char *buffer, 
                unsigned       len);

#endif
