#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[_window setContentView:self.oculusView]; // connect the view renderer
}

@end
