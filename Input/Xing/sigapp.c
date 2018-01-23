/*____________________________________________________________________________
        
        FreeAmp - The Free MP3 Player

        MP3 Decoder originally Copyright (C) 1995-1997 Xing Technology
        Corp.  http://www.xingtech.com

        Portions Copyright (C) 1998-1999 EMusic.com

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 2 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software
        Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
        
        $Id: sigapp.c,v 1.1.1.1 2001/05/21 18:46:55 sbender Exp $
____________________________________________________________________________*/

#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <math.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#ifdef WIN32
#include <io.h>
#endif
#include <fcntl.h>              /* file open flags */
#include <sys/types.h>          /* someone wants for port */
#include <sys/stat.h>           /* forward slash for portability */
#include "mhead.h"              /* mpeg header structure, decode protos */
#include "port.h"

#include "musicbrainz/mb_c.h"

float     equalizer[32] = {
   1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
   1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
   1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
   1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
};
int       enableEQ = 0;
float     EQ_gain_adjust = 1.0;

/*********  bitstream buffer */
#define BS_BUFBYTES 60000U
static unsigned char *bs_buffer = NULL;
static unsigned char *bs_bufptr;
static int bs_trigger;
static int bs_bufbytes;
static int handle = -1;

/********************** */

/********  pcm buffer ********/
#define PCM_BUFBYTES  60000U
static char *pcm_buffer;
static unsigned int pcm_bufbytes;
static unsigned int pcm_trigger = (PCM_BUFBYTES - 2500 * sizeof(short));
static int handout = -1;

/*------------------------------------------*/
static int bs_fill();
int       ff_decode(char *filename,

                    char *fileout,
                    int reduction_code,
                    int convert_code,
                    int decode8_flag, int freq_limit, int integer_decode);
int       cvt_to_wave_test();
int       write_pcm_header_wave(int handout,
                                int samprate, int channels, int bits, int type);
int       write_pcm_tailer_wave(int handout, unsigned int pcm_bytes);

int
ff_decode(char *filename, char ascii_sig[37],
          int reduction_code, int convert_code, int decode8_flag,
          int freq_limit, int integer)
{
   int       framebytes;
   int       u;
   MPEG_HEAD head;
   MPEG      m;
   IN_OUT    x;
   int       in_bytes, out_bytes;
   DEC_INFO  decinfo;
   int       bitrate, ret = 0;
   char      sig[17];
   trm_t     trm = 0;
   unsigned int skip;

/*------------------------------------------*/
/*   typedef struct
   {
      int       (*decode_init) (MPEG_HEAD * h, int framebytes_arg,
                                int reduction_code, int transform_code,
                                int convert_code, int freq_limit);
      void      (*decode_info) (DEC_INFO * info);
                IN_OUT(*decode) (unsigned char *bs, short *pcm);
   }
   AUDIO;
   static AUDIO audio;
   static AUDIO audio_table[2][2] =
   {
      {
         {audio_decode_init, audio_decode_info, audio_decode},
         {audio_decode8_init, audio_decode8_info, audio_decode8},
      },
      {
         {i_audio_decode_init, i_audio_decode_info, i_audio_decode},
         {audio_decode8_init, audio_decode8_info, audio_decode8},
      }
   };
*/
/*-----------------------*/
/*-----select decoder --------------*/
/*   if (decode8_flag && (convert_code >= 4))
      audio = audio_table[integer & 1][1];
   else
      audio = audio_table[integer & 1][0]; */
/*-----------------------*/

   in_bytes = out_bytes = 0;
/*-----------------------*/
   handout = -1;
   pcm_buffer = NULL;
   pcm_bufbytes = 0;
/*-----------------------*/
   bs_buffer = NULL;
   handle = -1;
   bs_bufbytes = 0;
   bs_bufptr = bs_buffer;
   bs_trigger = 2500;
/*--- test for valid cvt_to_wave compile ---*/
   if (cvt_to_wave_test() != 0)
   {
      printf("\n INVALID CVT_TO_WAVE COMPILE");
      goto abort;
   }
/*------ open mpeg file --------*/
   handle = open(filename, O_RDONLY | O_BINARY);
   if (handle < 0)
   {
      printf("\n CANNOT_OPEN_INPUT_FILE\n");
      goto abort;
   }
/*--- allocate bs buffer ----*/
   bs_buffer = malloc(BS_BUFBYTES);
   if (bs_buffer == NULL)
   {
      printf("\n CANNOT_ALLOCATE_BUFFER\n");
      goto abort;
   }
/*--- fill bs buffer ----*/
   if (!bs_fill())
      goto abort;
/*---- parse mpeg header  -------*/
   framebytes = head_info3(bs_buffer, bs_bufbytes, &head, &bitrate, &skip);
   if (framebytes == 0)
   {
      printf("\n BAD OR UNSUPPORTED MPEG FILE\n");
      goto abort;
   }
   bs_bufptr += skip;
   bs_bufbytes -= skip;

/*---- allocate pcm buffer --------*/
   pcm_buffer = malloc(PCM_BUFBYTES);
   if (pcm_buffer == NULL)
   {
      printf("\n CANNOT ALLOCATE PCM BUFFER\n");
      goto abort;
   }

/*---- init decoder -------*/
   mpeg_init(&m, 1);
   if (!audio_decode_init(&m, &head, framebytes,
                          reduction_code, 0, convert_code, freq_limit))
   {
      printf("\n DECODER INIT FAIL \n");
      goto abort;
   }
/*---- get info -------*/
   audio_decode_info(&m, &decinfo);

   trm = trm_New();
   trm_SetPCMDataInfo(trm, decinfo.samprate, decinfo.channels, decinfo.bits);
   cvt_to_wave_init(decinfo.bits);

   for (u = 0;;)
   {
      if (!bs_fill())
         break;
      if (bs_bufbytes < framebytes)
         break;                 /* end of file */
      x = audio_decode(&m, bs_bufptr, (short *) (pcm_buffer + pcm_bufbytes));
      if (x.in_bytes <= 0)
      {
         printf("\n BAD SYNC IN MPEG FILE\n");
         goto abort;
      }
      bs_bufptr += x.in_bytes;
      bs_bufbytes -= x.in_bytes;
      pcm_bufbytes += x.out_bytes;
      u++;
      if (pcm_bufbytes > pcm_trigger)
      {
         pcm_bufbytes = cvt_to_wave(pcm_buffer, pcm_bufbytes);
         ret = trm_GenerateSignature(trm, pcm_buffer, pcm_bufbytes, sig, NULL);
         if (ret)
         {
            pcm_bufbytes = 0;
            break;
         }

         out_bytes += pcm_bufbytes;
         pcm_bufbytes = 0;
      }
      in_bytes += x.in_bytes;
   }

   if (pcm_bufbytes > 0)
   {
      pcm_bufbytes = cvt_to_wave(pcm_buffer, pcm_bufbytes);

      ret = trm_GenerateSignature(trm, pcm_buffer, pcm_bufbytes, sig, NULL);
      if (!ret)
         trm_GenerateSignatureNow(trm, sig, NULL);

      out_bytes += pcm_bufbytes;
      pcm_bufbytes = 0;
   }

   trm_ConvertSigToASCII(trm, sig, ascii_sig);

   ret = 1;

 abort:
   mpeg_cleanup(&m);
   close(handle);
   free(bs_buffer);
   free(pcm_buffer);
   trm_Delete(trm);
   return ret;
}

/*-------------------------------------------------------------*/
static int
bs_fill()
{
   unsigned int nread;

   if (bs_bufbytes < 0)
      bs_bufbytes = 0;          // signed var could be negative

   if (bs_bufbytes < bs_trigger)
   {
      memmove(bs_buffer, bs_bufptr, bs_bufbytes);
      nread = read(handle, bs_buffer + bs_bufbytes, BS_BUFBYTES - bs_bufbytes);
      if ((nread + 1) == 0)
      {
/*-- test for -1 = error --*/
         bs_trigger = 0;
         printf("\n FILE_READ_ERROR\n");
         return 0;
      }
      bs_bufbytes += nread;
      bs_bufptr = bs_buffer;
   }

   return 1;
}
