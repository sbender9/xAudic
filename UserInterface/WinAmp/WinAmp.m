#import "WinAmp.h"
#import <AppKit/AppKit.h>
#import <MXA/Common.h>
#import <MXA/Control.h>
#import "Skin.h"
#import <MXA/PlaylistEntry.h>

#import "MainView.h"
#import "EqView.h"
#import "PlaylistView.h"
#import "MainWindow.h"
#import "Button.h"
#import "SkinBrowser.h"
#import "Configure.h"

static WinAmp *_winAmp = nil;

@implementation WinAmp

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  _winAmp = self;

  [WinAmpConfigure initConfiguration];

  return [super initWithDescription:[NSString stringWithFormat:@"WinAmp UI %@",
					      getVersion()]];
}

+ (WinAmp *)instance
{
  return _winAmp;
}

- (void)addMenuItems
{
  NSMenuItem *item;

  [self addOptionMenuItem:[NSMenuItem separatorItem]];

  item = [[NSMenuItem alloc] initWithTitle:@"SkinBrowser" 
			     action:@selector(showSkinBrowser:)
			     keyEquivalent:@"S"];
  [item setTarget:self];
  [self addOptionMenuItem:item];


  [self addWindowMenuItem:[NSMenuItem separatorItem]];
  item = [[NSMenuItem alloc] initWithTitle:@"Main Window" 
			     action:@selector(hideShowMain:)
			     keyEquivalent:@"M"];
  [item setTarget:self];
  [self addWindowMenuItem:item];

  item = [[NSMenuItem alloc] initWithTitle:@"Playlist Editor" 
			     action:@selector(hideShowPlaylist:)
			     keyEquivalent:@"E"];
  [item setTarget:self];
  [self addWindowMenuItem:item];

  item = [[NSMenuItem alloc] initWithTitle:@"Graphical EQ" 
			     action:@selector(hideShowEq:)
			     keyEquivalent:@"G"];
  [item setTarget:self];
  [self addWindowMenuItem:item];
}

- (void)run
{
  NSRect rect;
  MainView *mainView;
  EqView *eqView;
  PlaylistView *plView;
  NSSize main_size, eq_size, pl_size;

  if ( nibLoaded == NO )
    {
      [NSBundle loadNibNamed:@"WinAmp" owner:self];    
      nibLoaded = YES;
    }

  [self addMenuItems];

  [Skin loadSkin:[config stringValueForKey:skin_file_name]];

  main_size = [MainView calcSize];
  eq_size = [EqView calcSize];
  rect = NSMakeRect(0, eq_size.height, main_size.width, 
		    main_size.height);

  mainWindow = [[MainWindow alloc] initWithContentRect:rect 
					     styleMask:NSBorderlessWindowMask
					       backing:NSBackingStoreBuffered
						 defer:FALSE
						  name:@"WinAmp.Main"];
  [mainWindow setReleasedWhenClosed:YES];
  mainView = [[[MainView alloc] initWithFrame:rect] autorelease];
  [mainWindow setContentView:mainView];

  if ( [config boolValueForKey:player_visible] )
    [mainWindow makeKeyAndOrderFront:self];

  rect = NSMakeRect(0, 0, eq_size.width, eq_size.height);
  eqWindow = [[MainWindow alloc] initWithContentRect:rect 
					 styleMask:NSBorderlessWindowMask
					   backing:NSBackingStoreBuffered
					     defer:FALSE
					      name:@"WinAmp.EQ"];
  [eqWindow setReleasedWhenClosed:YES];
  eqView = [[[EqView alloc] initWithFrame:rect] autorelease];
  [eqWindow setContentView:eqView];
  if ( [config boolValueForKey:equalizer_visible] )
    [eqWindow orderFront:self];

  pl_size = [config sizeValueForKey:playlist_size];
  rect = NSMakeRect(main_size.width, 0, pl_size.width, pl_size.height);
  playlistWindow = [[MainWindow alloc] 
		     initWithContentRect:rect 
			       styleMask:NSBorderlessWindowMask
				 backing:NSBackingStoreBuffered
				   defer:FALSE
				    name:@"WinAmp.Playlist"];
  [playlistWindow setReleasedWhenClosed:YES];
  plView = [[[PlaylistView alloc] initWithFrame:rect] autorelease];
  [playlistWindow setContentView:plView];
  if ( [config boolValueForKey:playlist_shaded] )
    [plView updateShaded:YES updatePos:NO];
  if ( [config boolValueForKey:playlist_visible] )
    [playlistWindow orderFront:self];

  timer = [NSTimer scheduledTimerWithTimeInterval:1.0
		   target:self 
		   selector:@selector(timeTimer:)
		   userInfo:nil
		   repeats:YES];
  [timer retain];
  [super run];
}

- (void)stop
{
  [timer invalidate];
  [timer release];
  timer = nil;

  [mainWindow close];
  [eqWindow close];
  [playlistWindow close];
  [super stop];
}

- (NSWindow *)mainWindow
{
  return mainWindow;
}

- (NSWindow *)eqWindow
{
  return eqWindow;
}

- (NSWindow *)playlistWindow
{
  return playlistWindow;
}

- (MainView *)mainView
{
  return [mainWindow contentView];
}

- (EqView *)eqView
{
  return [eqWindow contentView];
}

- (PlaylistView *)playlistView
{
  return [playlistWindow contentView];
}

- (NSMenu *)eqMenu
{
  return eqMenu;
}

- (NSMenu *)sortMenu
{
  return sortMenu;
}

- (void)lockInfoText:(NSString *)string
{
  [[mainWindow contentView] lockInfoText:string];
}

- (void)unlockInfoText
{
  [[mainWindow contentView] unlockInfoText];
}

- (void)windowCameToFront
{
  if ( [mainWindow isVisible] )
    [mainWindow orderFront:self];
  if ( [eqWindow isVisible] )
    [eqWindow orderFront:self];
  if ( [playlistWindow isVisible] )
    [playlistWindow orderFront:self];
}

- (void)hideShowPlaylist:sender
{
  if ( [config boolValueForKey:playlist_visible] == NO )
    [playlistWindow orderFront:self];
  else
    [playlistWindow orderOut:self];
  [config setBoolValue:![config boolValueForKey:playlist_visible] 
	         forKey:playlist_visible];
  [[[mainWindow contentView] playlistButton] 
    toggle:[config boolValueForKey:playlist_visible]];
}

- (void)hideShowEq:sender
{
  if ( [config boolValueForKey:equalizer_visible] == NO )
    [eqWindow orderFront:self];
  else
    [eqWindow orderOut:self];
  [config setBoolValue:![config boolValueForKey:equalizer_visible] 
	        forKey:equalizer_visible];
  [[[mainWindow contentView] eqButton] 
    toggle:[config boolValueForKey:equalizer_visible]];
}

- (void)hideShowMain:sender
{
  if ( [config boolValueForKey:player_visible] == NO )
    [mainWindow orderFront:self];
  else
    [mainWindow orderOut:self];
  [config setBoolValue:![config boolValueForKey:player_visible] 
	        forKey:player_visible];
}

- (void)addAndPlayFile:(NSString *)file
{
  [Control addAndPlayFile:file];
}

- (void)timeTimer:nothing
{
  int time, length, t;
  char stime_prefix;	
  PlaylistView *pl = [self playlistView];
  MainView *mv = [self mainView];
  int minusn;

  if ( [Input isPlaying] ) {
    time = [Input getTime];
    if ( time != -1 ) {
      length = [Control getPlayingSongLength];
      [pl setTime:time length:length];

      if ( [config timer_mode] == TIMER_REMAINING ) {
	if ( length != -1 ) {
	  minusn = 11;
	  t = length - time;
	  stime_prefix = '-';
	} else {
	  minusn = 10;
	  t = time;
	  stime_prefix = ' ';
	}
      } else {
	minusn = 10;
	t=time;
	stime_prefix = ' ';
      }
      t/=1000;
      [mv setNumbers:minusn :t/600 :(t/60)%10 :(t/10)%6 :t%10];
      
      [mv setSNumbers:[NSString stringWithFormat:@"%c%2.2d", stime_prefix, t/60]
	             :[NSString stringWithFormat:@"%2.2d",t%60]];

      time /= 1000;
      length /= 1000;
      if ( length > 0 )	{
	if (time > length) {
	  [mv setPosbar:100];
	  [mv setSposbar:100];
	} else {
	  [mv setPosbar:(time*100)/length];
	  [mv setSposbar:(time*100)/length];
	}
      } else {
	[mv setPosbar:0];
	[mv setSposbar:0];
      }
    }
  }
}

- (unsigned char (*)[24][3])getVisualizationColors
{
  return &currentSkin->vis_color;
}

- (void)showSkinBrowser:sender
{
  static SkinBrowser *browser = nil;
  
  if ( browser == nil )
    browser = [[SkinBrowser alloc] init];
  
  [browser show];
}

- (BOOL)enabledByDefault
{
  return YES;
}

- (BOOL)hasConfigure
{
  return YES;
}

- (void)configure
{
  static WinAmpConfigure *configure = nil;
  
  if ( configure == nil )
    configure = [[WinAmpConfigure alloc] init];
  
  [configure show];
 
}

@end
