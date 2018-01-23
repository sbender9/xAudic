
#define BS_BUFBYTES 60000U
#define PCM_BUFBYTES 60000U

#define FRAMES_FLAG     0x0001
#define BYTES_FLAG      0x0002
#define TOC_FLAG        0x0004
#define VBR_SCALE_FLAG  0x0008

#define FRAMES_AND_BYTES (FRAMES_FLAG | BYTES_FLAG)

// structure to receive extracted header
// toc may be NULL
typedef struct 
{
    int h_id;       // from MPEG header, 0=MPEG2, 1=MPEG1
    int samprate;   // determined from MPEG header
    int flags;      // from Xing header data
    int frames;     // total bit stream frames from Xing header data
    int bytes;      // total bit stream bytes from Xing header data
    int vbr_scale;  // encoded vbr scale from Xing header data
    unsigned char *toc;  // pointer to unsigned char toc_buffer[100]
                         // may be NULL if toc not desired
}   XHEADDATA;

int GetXingHeader(XHEADDATA *X,  unsigned char *buf);
