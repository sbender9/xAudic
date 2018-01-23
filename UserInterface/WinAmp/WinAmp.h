
#import <MXA/UserInterface.h>


@class NSWindow;
@class NSMenu;
@class MainWindow;
@class MainView;
@class EqView;
@class PlaylistView;
@class NSTimer;

@interface WinAmp : UserInterface
{
  MainWindow *mainWindow, *eqWindow, *playlistWindow;
  id eqMenu, sortMenu;
  id skinBrowser;
  NSTimer *timer;
  BOOL nibLoaded;
}

+ (WinAmp *)instance;

- (MainWindow *)mainWindow;
- (MainWindow *)eqWindow;
- (MainWindow *)playlistWindow;
- (MainView *)mainView;
- (EqView *)eqView;
- (PlaylistView *)playlistView;

- (void)windowCameToFront;

- (NSMenu *)eqMenu;
- (NSMenu *)sortMenu;

- (void)hideShowPlaylist:sender;
- (void)hideShowEq:sender;
- (void)hideShowMain:sender;

- (void)showSkinBrowser:sender;

@end
