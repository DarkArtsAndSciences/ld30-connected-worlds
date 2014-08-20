#import "SLSAppDelegate.h"

@implementation SLSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // TODO: if debug HMD, use windowed mode
    [self setupFullscreenMode];
}

- (void)setupFullscreenMode
{
    // used by default if an HMD is detected at startup
    // TODO: and can be called to switch modes during runtime (HMD connected or at user request)
    
    // MacOSX 10.6+ automatically optimizes performance of screen-sized windows
    // OS error dialogs will be still be displayed (readable on mirrored screens, unreadable on the HMD, but it's better than hiding them)
    // https://developer.apple.com/library/mac/documentation/graphicsimaging/conceptual/opengl-macprogguide/opengl_fullscreen/opengl_cgl.html
    
    NSLog(@"setup fullscreen mode");
    
    // get the screen size
    // FUTURE: This assumes the HMD is the main screen, because the v0.4.1 Mac drivers don't support anything else.
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSRect windowRect = NSMakeRect(0.0, 0.0, screenRect.size.width, screenRect.size.height);
    
    // configure window
    [_window setStyleMask:NSBorderlessWindowMask];      // no window chrome
    [_window setBackingType:NSBackingStoreBuffered];    // buffered
    [_window setLevel:NSMainMenuWindowLevel+1];         // above the menu bar
    [_window setHidesOnDeactivate:NO];                  // do NOT autohide when not front app
    [_window setMovable:NO];                            // not movable
    [_window setFrame:windowRect display:YES];          // window size and autoredraw subviews
    [_window setContentView:self.oculusView];           // connect the view renderer
    [_window makeKeyAndOrderFront:self];                // show the window
    
    //[_window toggleFullScreen:nil];                   // optional: use own Space (10.7+)
}

- (void)setupWindowedMode
{
    // TODO: settings for standard window, used by default if no HMD detected
    NSLog(@"setup windowed mode");
}

- (IBAction)increaseIPD:(id)sender;
{
    self.oculusView.interpupillaryDistance = self.oculusView.interpupillaryDistance + 2.0;
}

- (IBAction)decreaseIPD:(id)sender;
{
    self.oculusView.interpupillaryDistance = self.oculusView.interpupillaryDistance - 2.0;
}

/* TODO: move these into Scene and connect to WASD instead of menu
- (IBAction)increaseDistance:(id)sender;
{
    SCNVector3 currentLocation = scene.headLocation;
    currentLocation.z = currentLocation.z - 50.0;
    scene.headLocation = currentLocation;
}

- (IBAction)decreaseDistance:(id)sender;
{
    SCNVector3 currentLocation = scene.headLocation;
    currentLocation.z = currentLocation.z + 50.0;
    scene.headLocation = currentLocation;
}*/

@end
