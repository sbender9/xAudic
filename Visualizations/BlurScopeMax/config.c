#include <gtk/gtk.h>

#include <xmms/configfile.h>
#include "blur_scope.h"


//GtkWidget *configure_win=NULL;
static GtkWidget *option_effect;
static GtkWidget *option_effect_menu;
static GtkWidget *option_bgeffect;
static GtkWidget *option_bgeffect_menu;

static GtkWidget *option_blur;
static GtkWidget *option_blur_menu;
static GtkObject *option_fade_adj;
static GtkWidget *option_fade;
static GtkWidget *option_shape;
static GtkWidget *option_shape_menu;
static GtkWidget *option_doublesize;
static GtkWidget *option_stereo;
static GtkWidget *option_bgstereo;
static GtkWidget *option_color;
static GtkWidget *option_colormap;
static GtkWidget *option_colorcycle;
static GtkWidget *option_preset;
static GtkWidget *btn_about;
static GtkWidget *btn_okay;
static GtkWidget *btn_cancel;

static GtkWidget *vbox;
static GtkWidget *bbox;
static GtkWidget *option_vbox;
static GtkWidget *color_frame;
static GtkWidget *option_frame;
static GtkWidget *preset_frame;

static GtkWidget *draw_frame;
static GtkWidget *blur_frame;
static GtkWidget *shape_frame;
static GtkWidget *draw_vbox;
static GtkWidget *blur_vbox;
static GtkWidget *shape_vbox;
static GtkWidget *color_vbox;
static GtkWidget *preset_vbox;
static GtkWidget *preset_hbox;
static GtkWidget *preset_bbox;

static GtkWidget *name_entry;
static GtkWidget *name_label;
static GtkWidget *save_label;
static GtkWidget *add_label;
static GtkWidget *btn_savepreset;
static GtkWidget *btn_addpreset;
static GtkWidget *btn_deletepreset;

static GtkWidget *effect_label;
static GtkWidget *bgeffect_label;
static GtkWidget *fade_label;
static GtkWidget *blur_label;
static GtkWidget *shape_label;
static GtkWidget *colormap_label;
static GtkWidget *preset_label;

static GtkWidget *general_hbox;
static GtkWidget *general_vbox;

static GtkWidget *generaltab_label;
static GtkWidget *colortab_label;
static GtkWidget *presettab_label;

static GtkWidget *notebook;

BlurScopeConfig origcfg;


/* This creates a widget that lets you pick one item from a hardcoded list */
static GtkWidget *gtkhelp_oneof(
	GtkSignalFunc callback,	/* called whenever an item is selected */
	char *(*namefunc)(int),	/* called to generate names of items */
	char *initial,		/* initial value to show */
	...)			/* NULL-terminated list of hardcoded items */
{
	GtkWidget *blist, *menu, *item;
	va_list	ap;
	gint	  i, init;
	char	*value;
	
	/* Create an empty menu widget */
	menu = gtk_menu_new();
	
	/* If there is a namefunc, then call it to get the first value */
	va_start(ap, initial);
	i = 0;
	value = namefunc ? (*namefunc)(i) : NULL;
	if (!value)
	{
		namefunc = NULL;
		value = va_arg(ap, char *);
	}
	
	/* For each arg... */
	for (i = init = 0; value; )
	{
		/* Create a menu item with the given label, and add it to
		 * the menu.
		 */
		item = gtk_menu_item_new_with_label(value);
		gtk_object_set_data(GTK_OBJECT(item), "cmd", (gpointer)value);
		gtk_widget_show(item);
		gtk_menu_append(GTK_MENU(menu), item);
		
		/* Arrange for the callback to be called when this item is
		 * selected.
		 */
		gtk_signal_connect(GTK_OBJECT(item), "activate", callback, value);
		
		/* if this is the initial value, remember that. */
		if (!strcmp(value, initial))
			init = i;
		
		/* get the next value, from either the function or args */
		i++;
		value = namefunc ? (*namefunc)(i) : NULL;
		if (!value)
		{
			namefunc = NULL;
			value = va_arg(ap, char *);
		}
	}
	va_end(ap);
	
	/* Stick the menu in a visible widget.  I'm not really sure why this
	 * step is necessary, but without it the picker never shows up.
	 */
	blist = gtk_option_menu_new();
	//gtk_widget_set_usize(blist, 120, -1);
	gtk_option_menu_remove_menu(GTK_OPTION_MENU(blist));
	gtk_option_menu_set_menu(GTK_OPTION_MENU(blist), menu);
	gtk_object_set_data(GTK_OBJECT(blist), "menu", (gpointer)menu);
	gtk_widget_show(blist);
	
	/* Set the initial value */
	if (init >= 0)
		gtk_option_menu_set_history(GTK_OPTION_MENU(blist), init);
	
	/* return the menu */
	return blist;
}
/* Return the name of the active item in an options menu */
static char *gtkhelp_get(GtkWidget *blist)
{
	GtkWidget *menu, *item;
	char	*value;
	
	/* Get the option menu's internal real menu */
	menu = (GtkWidget *)gtk_object_get_data(GTK_OBJECT(blist), "menu");
	
	/* Get the menu's active item */
	item = gtk_menu_get_active(GTK_MENU(menu));
	
	/* Get the item's label, and return it */
	value = (char *)gtk_object_get_data(GTK_OBJECT(item), "cmd");
	
	return value;
}



/* Name helper functions */

static char *presetlist(int i) {
	if (i==MAXPRESETS) return NULL;
	else  return presets[i].name;
	
}



static char *effectlist(int i) {
	static char *names[] =
	{
		"Random","Horizontal Line", "Horizontal Dot",
		"Horizontal Solid", "Vertical Line",
		"Vertical Dot", "Vertical Solid",
		"Lightning", "Ring", "Warp","Ring Wave",
		NULL
	};
	return names[i];
}


static char *blurlist(int i) {
	static char *names[] =
	{
		"Random","Horizontal Smoke", "Vertical Smoke",
		"Circular Smoke", "Spiral Left", "Spiral Right", "Suck", "Original Blur",
		"None",
		NULL
	};
	return names[i];
}

static char *shapelist(int i) {
	static char *names[] =
	{
		"Horizontal Rectangle", "Square",
		"Vertical Rectangle","320x200", "512x384",
		NULL
	};
	return names[i];
}


static char *fadelist(int i) {
	static char *names[] =
	{
		"0", "1",
		"2",
		NULL
	};
	return names[i];
}

static char *colormaplist(int i) {
	static char *names[] =
	{
		"Random", "Normal", "Inverse","Milky", "Layers", "Color Layers", "Rainbow", "Standoff", "Stripes",
		"Color Stripes", "Color Bands",
		NULL
	};
	return names[i];
}


static GtkWidget *newmenu(GtkSignalFunc callback,	/* called whenever an item is selected */
	char *(*namefunc)(int),	/* called to generate names of items */
	char *initial,		/* initial value to show */
	...)			/* NULL-terminated list of hardcoded items */
{
	GtkWidget *blist, *menu, *item;
	va_list	ap;
	gint	  i, init;
	char	*value;
	
	/* Create an empty menu widget */
	menu = gtk_menu_new();
	
	/* If there is a namefunc, then call it to get the first value */
	va_start(ap, initial);
	i = 0;
	value = namefunc ? (*namefunc)(i) : NULL;
	if (!value)
	{
		namefunc = NULL;
		value = va_arg(ap, char *);
	}
	
	/* For each arg... */
	for (i = init = 0; value; )
	{
		/* Create a menu item with the given label, and add it to
		 * the menu.
		 */
		item = gtk_menu_item_new_with_label(value);
		gtk_object_set_data(GTK_OBJECT(item), "cmd", (gpointer)value);
		gtk_widget_show(item);
		gtk_menu_append(GTK_MENU(menu), item);
		
		/* Arrange for the callback to be called when this item is
		 * selected.
		 */
		gtk_signal_connect(GTK_OBJECT(item), "activate", callback, value);
		
		/* if this is the initial value, remember that. */
		if (!strcmp(value, initial))
			init = i;
		
		/* get the next value, from either the function or args */
		i++;
		value = namefunc ? (*namefunc)(i) : NULL;
		if (!value)
		{
			namefunc = NULL;
			value = va_arg(ap, char *);
		}
	}
	va_end(ap);
	return menu;
}



static void set_preset(int presetindex) {
	gdouble color[3];
	char *temp;
	int found;
	int i;
	
	gtk_color_selection_get_color(GTK_COLOR_SELECTION(option_color), color);
	
	temp = gtkhelp_get(option_effect);
	
	for (i=0; i<11; i++) {
		if (!strcmp(temp,effectlist(i))){
			presets[presetindex].effect=i;}
	}
	temp = gtkhelp_get(option_bgeffect);	
	for (i=0; i<11; i++) {
		if (!strcmp(temp,effectlist(i))){
			presets[presetindex].bgeffect=i;}
	}
	temp = gtkhelp_get(option_blur);
	for (i=0; i<9; i++) {
		if (!strcmp(temp,blurlist(i))){
			presets[presetindex].blur=i;}
	}
	temp = gtkhelp_get(option_fade);
	for (i=0; i<3; i++) {
		if (!strcmp(temp,fadelist(i))){
			presets[presetindex].fade=i;}
	}
	temp = gtkhelp_get(option_shape);
	for (i=0; i<5; i++) {
		if (!strcmp(temp,shapelist(i))){
			presets[presetindex].shape=i;}
	}
	temp = gtkhelp_get(option_colormap);
	for (i=0; i<11; i++) {	
		if (!strcmp(temp,colormaplist(i))){
			presets[presetindex].colormap=i; }
	}
	presets[presetindex].color = ((guint32)(255.0*color[0])<<16) |
		((guint32)(255.0*color[1])<<8) |
		((guint32)(255.0*color[2])); 
	presets[presetindex].doublesize = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_doublesize));
	presets[presetindex].stereo = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_stereo));
	presets[presetindex].bgstereo = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_bgstereo));
	presets[presetindex].colorcycle = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_colorcycle));
	temp=gtk_entry_get_text(GTK_ENTRY(name_entry));
	
	
	presets[presetindex].name=malloc(50);
	presets[presetindex].name = strcpy(presets[presetindex].name, temp);
	
}



static void change_options() {
	gdouble color[3];
	char *temp;
	int found;
	int i;
	
	gtk_color_selection_get_color(GTK_COLOR_SELECTION(option_color), color);
	
	
	
	
	temp = gtkhelp_get(option_effect);
	
	for (i=0; i<11; i++) {
		if (!strcmp(temp,effectlist(i))){
			bscope_cfg.effect=i;}
	}
	
	temp = gtkhelp_get(option_bgeffect);	
	for (i=0; i<11; i++) {
		if (!strcmp(temp,effectlist(i))){
			bscope_cfg.bgeffect=i;}
	}
	
	
	temp = gtkhelp_get(option_blur);
	
	for (i=0; i<9; i++) {
		if (!strcmp(temp,blurlist(i))){
			bscope_cfg.blur=i;}
	}
	
	
	temp = gtkhelp_get(option_fade);
	for (i=0; i<3; i++) {
		if (!strcmp(temp,fadelist(i))){
			bscope_cfg.fade=i;}
	}
	
	temp = gtkhelp_get(option_shape);
	for (i=0; i<5; i++) {
		if (!strcmp(temp,shapelist(i))){
			bscope_cfg.shape=i;}
	}
	
	temp = gtkhelp_get(option_colormap);
	for (i=0; i<11; i++) {	
		if (!strcmp(temp,colormaplist(i))){
			bscope_cfg.colormap=i;
			
		}
	}
	/*
	while ((colormaplist(i)!=NULL) || !(found)) {
		if (!strcmp(temp,colormaplist(i))){
			bscope_cfg.colormap=i;
			found = 1;
		}
		i++;
	}
*/
	
	bscope_cfg.color = ((guint32)(255.0*color[0])<<16) |
		((guint32)(255.0*color[1])<<8) |
		((guint32)(255.0*color[2])); 
	
	bscope_cfg.doublesize = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_doublesize));
	bscope_cfg.colorcycle = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_colorcycle));
}



void set_options(){
	gdouble color[3];
	color[0]=((gdouble)(bscope_cfg.color /0x10000))/256;
	color[1]=((gdouble)((bscope_cfg.color %0x10000)/0x100))/256;
	color[2]=((gdouble)(bscope_cfg.color %0x100))/256;
	
	
	gtk_color_selection_set_color(GTK_COLOR_SELECTION(option_color), color);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_effect), bscope_cfg.effect);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_bgeffect), bscope_cfg.bgeffect);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_blur), bscope_cfg.blur);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_shape), bscope_cfg.shape);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_fade), bscope_cfg.fade);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_colormap), bscope_cfg.colormap);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_preset), currentpreset);
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option_doublesize), bscope_cfg.doublesize);
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option_stereo), bscope_cfg.stereo);
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option_bgstereo), bscope_cfg.bgstereo);
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option_colorcycle), bscope_cfg.colorcycle);
	
	gtk_entry_set_text (GTK_ENTRY (name_entry),presets[currentpreset].name);
	
	
}


static void save_presets()
{
	
	ConfigFile *cfg;	
	gchar *filename;
	BlurScopeConfig old;
	int i;
	char *szPreset;
	
	filename = g_strconcat(g_get_home_dir(), "/.xmms/bsmaxpresets", NULL);
	cfg = xmms_cfg_open_file(filename);
	old=bscope_cfg;
	if (!cfg)
		cfg = xmms_cfg_new();
	
	xmms_cfg_write_int(cfg, "BlurScope", "numpresets", numpresets);
	xmms_cfg_write_int(cfg, "BlurScope", "currentpreset", currentpreset);
	
	szPreset=malloc(3);
	for (i=0; i<numpresets;i++) {
		sprintf(szPreset, "%u", i);
		xmms_cfg_write_string(cfg, szPreset, "name", presets[i].name);
		xmms_cfg_write_int(cfg, szPreset, "color", presets[i].color);
		xmms_cfg_write_int(cfg, szPreset, "effect", presets[i].effect);
		xmms_cfg_write_int(cfg, szPreset, "bgeffect", presets[i].bgeffect);
		xmms_cfg_write_int(cfg, szPreset, "blur", presets[i].blur);
		xmms_cfg_write_int(cfg, szPreset, "fade", presets[i].fade);
		xmms_cfg_write_int(cfg, szPreset, "shape", presets[i].shape);
		xmms_cfg_write_int(cfg, szPreset, "doublesize", presets[i].doublesize);
		xmms_cfg_write_int(cfg, szPreset, "colormap", presets[i].colormap);
		xmms_cfg_write_int(cfg, szPreset, "stereo", presets[i].stereo);
		xmms_cfg_write_int(cfg, szPreset, "bgstereo", presets[i].bgstereo);
		xmms_cfg_write_int(cfg, szPreset, "colorcycle", presets[i].colorcycle);		
		printf("Here!\n");
		
	}
	xmms_cfg_write_file(cfg, filename);
	free(szPreset);
	
	xmms_cfg_free(cfg);
	
	g_free(filename);
	
	
	
}


static void configure_ok(GtkWidget *w, gpointer data)
{
	ConfigFile *cfg;	
	gchar *filename;
	BlurScopeConfig old;
	int i;
	char *szPreset;
	
	filename = g_strconcat(g_get_home_dir(), "/.xmms/config", NULL);
	cfg = xmms_cfg_open_file(filename);
	old=bscope_cfg;
	if (!cfg)
		cfg = xmms_cfg_new();
	change_options();
	xmms_cfg_write_int(cfg, "BlurScope", "color", bscope_cfg.color);
	xmms_cfg_write_int(cfg, "BlurScope", "effect", bscope_cfg.effect);
	xmms_cfg_write_int(cfg, "BlurScope", "bgeffect", bscope_cfg.bgeffect);
	xmms_cfg_write_int(cfg, "BlurScope", "blur", bscope_cfg.blur);
	xmms_cfg_write_int(cfg, "BlurScope", "fade", bscope_cfg.fade);
	xmms_cfg_write_int(cfg, "BlurScope", "shape", bscope_cfg.shape);
	xmms_cfg_write_int(cfg, "BlurScope", "doublesize", bscope_cfg.doublesize);
	xmms_cfg_write_int(cfg, "BlurScope", "colormap", bscope_cfg.colormap);
	xmms_cfg_write_int(cfg, "BlurScope", "stereo", bscope_cfg.stereo);
	xmms_cfg_write_int(cfg, "BlurScope", "bgstereo", bscope_cfg.bgstereo);
	xmms_cfg_write_int(cfg, "BlurScope", "colorcycle", bscope_cfg.colorcycle);
	
	
	
	xmms_cfg_write_file(cfg, filename);
	
	xmms_cfg_free(cfg);
	
	g_free(filename);
	
	
	save_presets();
	
	
	if (bscope_cfg.colormap != 0)
		generate_cmap(bscope_cfg.colormap, 0, bscope_cfg.colormap);
	
	if ((old.shape != bscope_cfg.shape) || (old.doublesize != bscope_cfg.doublesize))
		bscope_changesize();
	
	
	gtk_widget_destroy(configure_win);
	
}





static void doublesize_cb(GtkWidget *w, gpointer data)
{
	
	change_options();
	bscope_changesize();
	if (bscope_cfg.doublesize) {
		gtk_widget_show(option_stereo);
		gtk_widget_show(option_bgstereo);
	} else {
		gtk_widget_hide(option_stereo);
		gtk_widget_hide(option_bgstereo);
	}
	
}

static void stereo_cb(GtkWidget *w, gpointer data)
{
	
	bscope_cfg.stereo = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_stereo));
	bscope_cfg.bgstereo = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_bgstereo));
	
}


static void colorcycle_cb(GtkWidget *w, gpointer data)
{
	
	bscope_cfg.colorcycle = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(option_colorcycle));
	
}



static void preset_cb(GtkWidget *w, gpointer data)
{
	/* fetch options which don't affect the colormap or renderer */
	BlurScopeConfig old;
	char *temp;
	int i;
	
	
	old=bscope_cfg;
	
	
	temp = gtkhelp_get(option_preset);
	for (i=0; i<numpresets; i++) {
		if (!strcmp(temp,presetlist(i))){
			bscope_cfg = presets[i];
			currentpreset=i;
		}
	}
	
	
	//set options to current values
	
	set_options();	
	
	//Run the change size function to resize the window and recalculate the blur map
	
	bscope_changesize();
	bscope_prepareblurmap();
	
	generate_cmap(bscope_cfg.colormap,0,bscope_cfg.colormap);
	
}

static void savepreset_cb(GtkWidget *w, gpointer data)
{
	GtkWidget *menu;
	set_preset(currentpreset);
	menu=newmenu(GTK_SIGNAL_FUNC(preset_cb), presetlist,
			presetlist(currentpreset), NULL);
	gtk_option_menu_remove_menu(GTK_OPTION_MENU(option_preset));
	gtk_option_menu_set_menu(GTK_OPTION_MENU(option_preset), menu);
	gtk_object_set_data(GTK_OBJECT(option_preset), "menu", (gpointer)menu);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_preset), currentpreset);
	
	
	
}

static void deletepreset_cb(GtkWidget *w, gpointer data)
{
	GtkWidget *menu;
	int i;
	
	for (i=currentpreset; i<numpresets; i++) {
		presets[i]= presets[i+1];
	}
	numpresets--;
	
	if (currentpreset>=numpresets) currentpreset--;
	
	
	
	
	if (numpresets>0) {
		menu=newmenu(GTK_SIGNAL_FUNC(preset_cb), presetlist,
				presetlist(currentpreset), NULL);		
		set_options();
	} else {menu=newmenu(GTK_SIGNAL_FUNC(preset_cb), NULL,
				NULL, NULL);
	}
	gtk_option_menu_remove_menu(GTK_OPTION_MENU(option_preset));
	gtk_option_menu_set_menu(GTK_OPTION_MENU(option_preset), menu);
	gtk_object_set_data(GTK_OBJECT(option_preset), "menu", (gpointer)menu);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_preset), currentpreset);
	
	if (numpresets==0) {
		gtk_widget_hide(btn_deletepreset);
		gtk_widget_hide(btn_savepreset);
	}
	
	
	
	
}




static void addpreset_cb(GtkWidget *w, gpointer data)
{
	GtkWidget *menu;
	
	
	if (numpresets==0) {
		gtk_widget_show(btn_savepreset);
		gtk_widget_show(btn_deletepreset);		
	}
	
	numpresets++;
	currentpreset=numpresets-1;
	set_preset(numpresets-1);
	menu=newmenu(GTK_SIGNAL_FUNC(preset_cb), presetlist,
			presetlist(currentpreset), NULL);
	gtk_option_menu_remove_menu(GTK_OPTION_MENU(option_preset));
	gtk_option_menu_set_menu(GTK_OPTION_MENU(option_preset), menu);
	gtk_object_set_data(GTK_OBJECT(option_preset), "menu", (gpointer)menu);
	gtk_option_menu_set_history(GTK_OPTION_MENU(option_preset), currentpreset);
	if (numpresets==MAXPRESETS) {
		gtk_widget_hide(btn_addpreset);
	}
	
	
	
	gtk_box_pack_start(GTK_BOX(preset_vbox), option_preset, FALSE, FALSE, 0);
	gtk_widget_show (option_preset);
	
	
}



static void other_cb(GtkWidget *w, gpointer data)
{
	/* fetch options which don't affect the colormap or renderer */
	BlurScopeConfig old;
	old=bscope_cfg;
	change_options();
	//Run the change size function to resize the window and recalculate the blur map
	if (old.shape != bscope_cfg.shape) {
		bscope_changesize();
		bscope_prepareblurmap();
	}
	if (old.blur != bscope_cfg.blur)
		bscope_prepareblurmap();
	
	generate_cmap(bscope_cfg.colormap,0 ,bscope_cfg.colormap);
	
}


static void configure_cancel(GtkWidget *w, gpointer data)
{
	bscope_cfg.color = (guint32)data;
	bscope_cfg=origcfg;
	bscope_changesize();
	generate_cmap(bscope_cfg.colormap, 0, bscope_cfg.colormap);
	gtk_widget_destroy(configure_win);
}

static void configure_apply(GtkWidget *w, gpointer data)
{
	
	
	BlurScopeConfig old;
	old=bscope_cfg;
	change_options();
	if (old.shape != bscope_cfg.shape)
		bscope_changesize();
	generate_cmap(bscope_cfg.colormap, 0, bscope_cfg.colormap);
}

static void color_changed(GtkWidget *w, gpointer data)
{
	gdouble color[3]; 
	gtk_color_selection_get_color(GTK_COLOR_SELECTION(option_color), color);
	bscope_cfg.color = ((guint32)(255.0*color[0])<<16) |
		((guint32)(255.0*color[1])<<8) |
		((guint32)(255.0*color[2]));
	generate_cmap(bscope_cfg.colormap, 0, bscope_cfg.colormap);
}

static void blurscope_toggle_cb(GtkWidget *w, gint *data) {
	*data = GTK_TOGGLE_BUTTON(w)->active;
}

void blurscope_configure (void)
{
	gdouble color[3];
	int i;
	gchar *tmp;
	if(configure_win)
		return;
	
	bscope_read_config();
	color[0]=((gdouble)(bscope_cfg.color /0x10000))/256;
	color[1]=((gdouble)((bscope_cfg.color %0x10000)/0x100))/256;
	color[2]=((gdouble)(bscope_cfg.color %0x100))/256;
	origcfg=bscope_cfg;
	
	
	configure_win = gtk_window_new(GTK_WINDOW_DIALOG);
	gtk_container_set_border_width(GTK_CONTAINER(configure_win), 10);
	gtk_window_set_title(GTK_WINDOW(configure_win), "Blur Scope MAX Configuration");
	gtk_window_set_policy(GTK_WINDOW(configure_win), FALSE, FALSE, FALSE);
	gtk_window_set_position(GTK_WINDOW(configure_win), GTK_WIN_POS_MOUSE);
	gtk_signal_connect(GTK_OBJECT(configure_win), "destroy", GTK_SIGNAL_FUNC(gtk_widget_destroyed),
		&configure_win);
	
	
	
	
	
	vbox = gtk_vbox_new(FALSE, 5);
	
	
	notebook = gtk_notebook_new ();
	
	
	
	
	
	
	
	//Color tab	
	color_frame = gtk_frame_new("Color:");
	gtk_container_set_border_width(GTK_CONTAINER(color_frame), 5);
	
	color_vbox = gtk_vbox_new(FALSE, 5);
	gtk_container_set_border_width(GTK_CONTAINER(color_vbox), 5);	
	gtk_container_add (GTK_CONTAINER (color_frame), color_vbox);
	gtk_widget_show (color_vbox);	
	
	
	option_color = gtk_color_selection_new();
	gtk_color_selection_set_color(GTK_COLOR_SELECTION(option_color), color);
	gtk_signal_connect(GTK_OBJECT(option_color), "color_changed", GTK_SIGNAL_FUNC(color_changed), NULL);
	gtk_box_pack_start (GTK_BOX (color_vbox), option_color, FALSE, FALSE, 0);
	gtk_widget_show(option_color);
	
	colormap_label = gtk_label_new ("Colormap");
	gtk_label_set_justify (GTK_LABEL (colormap_label), GTK_JUSTIFY_LEFT);
	gtk_box_pack_start (GTK_BOX (color_vbox), colormap_label, FALSE, FALSE, 0);
	gtk_widget_show(colormap_label);
	gtk_misc_set_alignment (GTK_MISC (colormap_label), 0.0500001, 0.71);
	
	
	option_colormap = gtkhelp_oneof(GTK_SIGNAL_FUNC(other_cb), colormaplist,
			colormaplist(bscope_cfg.colormap), NULL);
	
	gtk_box_pack_start(GTK_BOX(color_vbox), option_colormap, FALSE, FALSE, 0);
	gtk_widget_show(option_colormap);
	
	option_colorcycle = gtk_check_button_new_with_label("Color Cycling");
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option_colorcycle), bscope_cfg.colorcycle);
	gtk_signal_connect(GTK_OBJECT(option_colorcycle), "toggled",
		GTK_SIGNAL_FUNC(colorcycle_cb), &bscope_cfg.colorcycle);
	gtk_box_pack_start(GTK_BOX(color_vbox), option_colorcycle, TRUE, TRUE, 0);
	gtk_widget_show(option_colorcycle);
	
	
	
	//General tab
	option_frame = gtk_frame_new("Options:");
	gtk_container_set_border_width(GTK_CONTAINER(option_frame), 5);
	option_vbox = gtk_vbox_new(FALSE, 5);
	gtk_container_set_border_width(GTK_CONTAINER(option_vbox), 5);
	
	
	//Set up the frames for the General notebook tab		
	draw_frame = gtk_frame_new("Drawing Effects:");
	gtk_container_set_border_width(GTK_CONTAINER(draw_frame), 5);
	draw_vbox = gtk_vbox_new(FALSE, 5);
	gtk_container_set_border_width(GTK_CONTAINER(draw_vbox), 5);
	
	
	blur_frame = gtk_frame_new("Blur Effects:");
	gtk_container_set_border_width(GTK_CONTAINER(blur_frame), 5);
	blur_vbox = gtk_vbox_new(FALSE, 5);
	gtk_container_set_border_width(GTK_CONTAINER(blur_vbox), 5);
	
	
	shape_frame = gtk_frame_new("Window Shape:");
	gtk_container_set_border_width(GTK_CONTAINER(shape_frame), 5);
	shape_vbox = gtk_vbox_new(FALSE, 5);
	gtk_container_set_border_width(GTK_CONTAINER(shape_vbox), 5);	
	
	
	
	general_vbox = gtk_vbox_new (FALSE, 0);
	gtk_widget_show (general_vbox);
	gtk_container_add (GTK_CONTAINER (notebook), general_vbox);
	
	general_hbox = gtk_hbox_new (FALSE, 0);
	gtk_widget_show (general_hbox);
	gtk_container_add (GTK_CONTAINER (general_vbox), general_hbox);
	
	
	
	gtk_widget_show (draw_vbox);
	gtk_widget_show (draw_frame);
	gtk_container_add (GTK_CONTAINER (draw_frame), draw_vbox);
	gtk_container_add (GTK_CONTAINER (general_hbox), draw_frame);
	gtk_widget_show (blur_vbox);
	gtk_widget_show (blur_frame);	
	gtk_container_add (GTK_CONTAINER (blur_frame), blur_vbox);
	gtk_container_add (GTK_CONTAINER (general_hbox), blur_frame);
	gtk_widget_show (shape_vbox);
	gtk_widget_show (shape_frame);	
	gtk_container_add (GTK_CONTAINER (shape_frame), shape_vbox);
	gtk_container_add (GTK_CONTAINER (general_vbox), shape_frame);
	
	
	
	
	effect_label = gtk_label_new ("Effect");
	gtk_label_set_justify (GTK_LABEL (effect_label), GTK_JUSTIFY_LEFT);
	gtk_box_pack_start (GTK_BOX (draw_vbox), effect_label, FALSE, FALSE, 0);
	gtk_widget_show(effect_label);
	gtk_misc_set_alignment (GTK_MISC (effect_label), 0.0500001, 0.71);
	
	
	
	option_effect = gtkhelp_oneof(GTK_SIGNAL_FUNC(other_cb), effectlist,
			effectlist(bscope_cfg.effect) ,NULL);
	gtk_box_pack_start(GTK_BOX(draw_vbox), option_effect, FALSE, FALSE, 0);	
	
	gtk_widget_show (option_effect);	
	
	option_stereo = gtk_check_button_new_with_label("Stereo");
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option_stereo), bscope_cfg.stereo);
	gtk_signal_connect(GTK_OBJECT(option_stereo), "toggled",
		GTK_SIGNAL_FUNC(stereo_cb), &bscope_cfg.stereo);
	gtk_box_pack_start(GTK_BOX(draw_vbox), option_stereo, TRUE, TRUE, 0);
	if (bscope_cfg.doublesize) 
		gtk_widget_show(option_stereo);
	
	
	bgeffect_label = gtk_label_new ("Background Effect");
	gtk_label_set_justify (GTK_LABEL (bgeffect_label), GTK_JUSTIFY_LEFT);
	gtk_box_pack_start (GTK_BOX (draw_vbox), bgeffect_label, FALSE, FALSE, 0);
	gtk_widget_show(bgeffect_label);
	gtk_misc_set_alignment (GTK_MISC (bgeffect_label), 0.0500001, 0.71);
	
	option_bgeffect = gtkhelp_oneof(GTK_SIGNAL_FUNC(other_cb), effectlist,
			effectlist(bscope_cfg.bgeffect) ,NULL);
	gtk_box_pack_start(GTK_BOX(draw_vbox), option_bgeffect, FALSE, FALSE, 0);	
	
	
	gtk_widget_show (option_bgeffect);	
	
	option_bgstereo = gtk_check_button_new_with_label("Stereo");
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option_bgstereo), bscope_cfg.bgstereo);
	gtk_signal_connect(GTK_OBJECT(option_bgstereo), "toggled",
		GTK_SIGNAL_FUNC(stereo_cb), &bscope_cfg.bgstereo);
	gtk_box_pack_start(GTK_BOX(draw_vbox), option_bgstereo, TRUE, TRUE, 0);
	if (bscope_cfg.doublesize) 
		gtk_widget_show(option_bgstereo);
	
	
	
	
	
	blur_label = gtk_label_new ("Blur");
	gtk_label_set_justify (GTK_LABEL (blur_label), GTK_JUSTIFY_LEFT);
	gtk_box_pack_start (GTK_BOX (blur_vbox), blur_label, FALSE, FALSE, 0);
	gtk_widget_show(blur_label);	
	gtk_misc_set_alignment (GTK_MISC (blur_label), 0.0500001, 0.71);
	
	option_blur = gtkhelp_oneof(GTK_SIGNAL_FUNC(other_cb), blurlist,
			blurlist(bscope_cfg.blur), NULL);
	gtk_box_pack_start(GTK_BOX(blur_vbox), option_blur, FALSE, FALSE, 0);
	gtk_widget_show (option_blur);
	
	
	fade_label = gtk_label_new ("Fade");
	gtk_label_set_justify (GTK_LABEL (fade_label), GTK_JUSTIFY_LEFT);
	gtk_box_pack_start (GTK_BOX (blur_vbox), fade_label, FALSE, FALSE, 0);
	gtk_widget_show(fade_label);	
	gtk_misc_set_alignment (GTK_MISC (fade_label), 0.0500001, 0.71);
	
	
	option_fade = gtkhelp_oneof(GTK_SIGNAL_FUNC(other_cb), NULL,
			fadelist(bscope_cfg.fade), "0", "1", "2",NULL);
	
	gtk_box_pack_start(GTK_BOX(blur_vbox), option_fade, FALSE, FALSE, 0);
	gtk_widget_show(option_fade);
	
	shape_label = gtk_label_new ("Shape");
	gtk_label_set_justify (GTK_LABEL (shape_label), GTK_JUSTIFY_LEFT);
	gtk_box_pack_start (GTK_BOX (shape_vbox), shape_label, FALSE, FALSE, 0);
	gtk_widget_show(shape_label);	
	gtk_misc_set_alignment (GTK_MISC (shape_label), 0.03, 0.71);
	
	
	option_shape = gtkhelp_oneof(GTK_SIGNAL_FUNC(other_cb), shapelist,
			shapelist(bscope_cfg.shape),NULL);
	
	gtk_box_pack_start(GTK_BOX(shape_vbox), option_shape, FALSE, FALSE, 0);
	gtk_widget_show(option_shape);
	
	
	
	option_doublesize = gtk_check_button_new_with_label("Double Size");
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(option_doublesize), bscope_cfg.doublesize);
	gtk_signal_connect(GTK_OBJECT(option_doublesize), "toggled",
		GTK_SIGNAL_FUNC(doublesize_cb), &bscope_cfg.doublesize);
	gtk_box_pack_start(GTK_BOX(shape_vbox), option_doublesize, TRUE, TRUE, 0);
	gtk_widget_show(option_doublesize);
	
	gtk_box_pack_start (GTK_BOX (vbox), notebook, FALSE, FALSE, 0);
	gtk_widget_show (notebook);		
	
	
	gtk_container_add(GTK_CONTAINER(notebook), color_frame);
	gtk_widget_show(color_frame);
	
	//Preset tab
	
	preset_frame = gtk_frame_new("Preset:");
	gtk_container_set_border_width(GTK_CONTAINER(preset_frame), 5);
	preset_vbox = gtk_vbox_new(FALSE, 5);
	gtk_container_set_border_width(GTK_CONTAINER(preset_vbox), 5);
	
	preset_hbox = gtk_hbox_new(FALSE, 5);
	gtk_container_set_border_width(GTK_CONTAINER(preset_hbox), 5);
	
	gtk_container_add(GTK_CONTAINER(preset_frame), preset_hbox);
	gtk_box_pack_start (GTK_BOX (preset_hbox), preset_vbox, FALSE, FALSE, 0);
	gtk_container_add(GTK_CONTAINER(notebook), preset_frame);
	gtk_widget_show(preset_frame);
	gtk_widget_show(preset_vbox);
	gtk_widget_show(preset_hbox);
	
	
	preset_label = gtk_label_new ("Current Preset");
	gtk_label_set_justify (GTK_LABEL (preset_label), GTK_JUSTIFY_LEFT);
	gtk_box_pack_start (GTK_BOX (preset_vbox), preset_label, FALSE, FALSE, 0);
	gtk_widget_show(preset_label);	
	gtk_misc_set_alignment (GTK_MISC (preset_label), 0.0500001, 0.71);
	
	option_preset = gtkhelp_oneof(GTK_SIGNAL_FUNC(preset_cb), presetlist,
			presetlist(currentpreset), NULL);
	gtk_box_pack_start(GTK_BOX(preset_vbox), option_preset, FALSE, FALSE, 0);
	gtk_widget_show (option_preset);
	
	
	name_label = gtk_label_new ("New Name");
	gtk_label_set_justify (GTK_LABEL (name_label), GTK_JUSTIFY_LEFT);
	gtk_box_pack_start (GTK_BOX (preset_vbox), name_label, FALSE, FALSE, 0);
	gtk_widget_show(name_label);	
	gtk_misc_set_alignment (GTK_MISC (name_label), 0.0500001, 0.71);
	
	
	
	name_entry = gtk_entry_new_with_max_length (50);
	gtk_entry_set_text (GTK_ENTRY (name_entry),presetlist(currentpreset));
	gtk_box_pack_start (GTK_BOX (preset_vbox), name_entry, FALSE, FALSE, 0);
	gtk_widget_show (name_entry);
	
	preset_bbox = gtk_vbutton_box_new();
	gtk_button_box_set_layout(GTK_BUTTON_BOX(preset_bbox), GTK_BUTTONBOX_END);
	gtk_button_box_set_spacing(GTK_BUTTON_BOX(preset_bbox), 5);
	gtk_box_pack_start(GTK_BOX(preset_hbox), preset_bbox, FALSE, FALSE, 0);
	gtk_widget_show(preset_bbox);
	
	
	btn_savepreset = gtk_button_new_with_label("Replace Current");
	gtk_signal_connect(GTK_OBJECT(btn_savepreset), "clicked",
		GTK_SIGNAL_FUNC(savepreset_cb), NULL);
	GTK_WIDGET_SET_FLAGS(btn_savepreset, GTK_CAN_DEFAULT);
	gtk_box_pack_start(GTK_BOX(preset_bbox), btn_savepreset, TRUE, TRUE, 0);
	
	if (numpresets>0) {
		gtk_widget_show(btn_savepreset);
	}
	
	
	btn_addpreset = gtk_button_new_with_label("Add New");
	gtk_signal_connect(GTK_OBJECT(btn_addpreset), "clicked",
		GTK_SIGNAL_FUNC(addpreset_cb), NULL);
	GTK_WIDGET_SET_FLAGS(btn_addpreset, GTK_CAN_DEFAULT);
	gtk_box_pack_start(GTK_BOX(preset_bbox), btn_addpreset, TRUE, TRUE, 0);
	if (numpresets<MAXPRESETS) {
		gtk_widget_show(btn_addpreset);
	}
	
	btn_deletepreset = gtk_button_new_with_label("Delete Current");
	gtk_signal_connect(GTK_OBJECT(btn_deletepreset), "clicked",
		GTK_SIGNAL_FUNC(deletepreset_cb), NULL);
	GTK_WIDGET_SET_FLAGS(btn_deletepreset, GTK_CAN_DEFAULT);
	gtk_box_pack_start(GTK_BOX(preset_bbox), btn_deletepreset, TRUE, TRUE, 0);
	if (numpresets>0) {
		gtk_widget_show(btn_deletepreset);
	}
	
	
	
	generaltab_label = gtk_label_new ("General");
	gtk_widget_show (generaltab_label);
	gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook), 0), generaltab_label);
	colortab_label = gtk_label_new ("Color");
	gtk_widget_show (colortab_label);
	gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook), 1), colortab_label);
	presettab_label = gtk_label_new ("Presets");
	gtk_widget_show (presettab_label);
	gtk_notebook_set_tab_label (GTK_NOTEBOOK (notebook), gtk_notebook_get_nth_page (GTK_NOTEBOOK (notebook), 2), presettab_label);
	
	
	
	
	
	
	
	
	
	
	bbox = gtk_hbutton_box_new();
	gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), GTK_BUTTONBOX_END);
	gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), 5);
	gtk_box_pack_start(GTK_BOX(vbox), bbox, FALSE, FALSE, 0);
	/*	
	btn_about = gtk_button_new_with_label("About");
	gtk_signal_connect(GTK_OBJECT(btn_about), "clicked",
		GTK_SIGNAL_FUNC(configure_about), NULL);
	GTK_WIDGET_SET_FLAGS(btn_okay, GTK_CAN_DEFAULT);
	gtk_box_pack_start(GTK_BOX(bbox), btn_about, TRUE, TRUE, 0);
	gtk_widget_show(btn_about);
	*/
	
	btn_okay = gtk_button_new_with_label("Ok");
	gtk_signal_connect(GTK_OBJECT(btn_okay), "clicked",
		GTK_SIGNAL_FUNC(configure_ok), NULL);
	GTK_WIDGET_SET_FLAGS(btn_okay, GTK_CAN_DEFAULT);
	gtk_box_pack_start(GTK_BOX(bbox), btn_okay, TRUE, TRUE, 0);
	gtk_widget_show(btn_okay);
	
	
	btn_cancel = gtk_button_new_with_label("Cancel");
	gtk_signal_connect(GTK_OBJECT(btn_cancel), "clicked",
		GTK_SIGNAL_FUNC(configure_cancel),
		(gpointer)bscope_cfg.color);
	GTK_WIDGET_SET_FLAGS(btn_cancel, GTK_CAN_DEFAULT);
	gtk_box_pack_start(GTK_BOX(bbox), btn_cancel, TRUE, TRUE, 0);
	gtk_widget_show(btn_cancel);
	gtk_widget_show(bbox);
	
	
	
	gtk_container_add(GTK_CONTAINER(configure_win), vbox);
	gtk_widget_show(vbox);
	gtk_widget_show(configure_win);
	gtk_widget_grab_default(btn_okay);
	
	
}






