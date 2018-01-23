#ifndef BLUR_SCOPE_H
#define BLUR_SCOPE_H
#define MAXPRESETS 10

#import <MXA/Visualization.h>

@interface BlurScopeMax : Visualization
@end

extern NSLock *res_lock;
extern gboolean blurscope_have_mutex;

#define BUMP_LOCK() \
	{ if (blurscope_have_mutex) [res_lock lock]; }
#define BUMP_UNLOCK() \
	{ if (blurscope_have_mutex) [res_lock unlock]; }

extern void blurscope_configure(void);
extern void blurscope_read_config(void);
extern void blurscope_changesize(void);
extern void blurscope_prepareblurmap(void);
extern void set_options(void);

typedef struct
{
	gchar *name;
	guint32 color;
	guint effect;
	guint bgeffect;
	guint blur;
	guint fade;
	guint BPL;
	guint shape;
	guint doublesize;
	guint colormap;
	guint stereo;
	guint bgstereo;
	guint colorcycle;
	
} BlurScopeConfig;

extern BlurScopeConfig presets[MAXPRESETS];
extern int numpresets;
extern int currentpreset;

extern BlurScopeConfig bscope_cfg;

extern void generate_cmap(guint, guint, guint);

#endif

