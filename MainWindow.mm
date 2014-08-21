#import "MainWindow.h"

@implementation MainWindow

@synthesize scene;

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(NSUInteger)aStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect
							styleMask:aStyle & NSBorderlessWindowMask
							  backing:NSBackingStoreBuffered
								defer:flag];
    
    if (self) {
		// get the screen size
		// FUTURE: This assumes the HMD is the main screen, because the v0.4.1 Mac drivers don't support anything else.
		NSRect screenRect = [[NSScreen mainScreen] frame];
		NSRect windowRect = NSMakeRect(0.0, 0.0, screenRect.size.width, screenRect.size.height);
		[self setFrame:windowRect display:YES];          // window size and autoredraw subviews
		
		// configure window
		//[self setStyleMask:NSBorderlessWindowMask];      // no window chrome
		//[self setBackingType:NSBackingStoreBuffered];    // buffered
		[self setLevel:NSMainMenuWindowLevel+1];         // above the menu bar
		[self setHidesOnDeactivate:NO];                  // do NOT autohide when not front app
		[self setMovable:NO];                            // not movable
		//[self toggleFullScreen:nil];                   // optional: use own Space (10.7+)
		
		//[self setAcceptsMouseMovedEvents:YES];
		//[self setIgnoresMouseEvents:NO];
		
		[self makeKeyAndOrderFront:self];                // show the window
    }
    
    return self;
}

- (BOOL)canBecomeKeyWindow { return YES; }  // allow borderless window to receive key events

- (void)keyDown:(NSEvent *)theEvent
{
    //NSLog(@"key down: %d", [theEvent keyCode]);
	if ([theEvent keyCode] == 13)  // w
	{
		//NSLog(@"start move forward %@", [Scene currentScene]);
		[[Scene currentScene] startMoving];
		//[[Scene currentScene] moveForward];
	}
}

- (void)keyUp:(NSEvent *)theEvent
{
    //NSLog(@"key up: %d", [theEvent keyCode]);
	if ([theEvent keyCode] == 13)  // w
	{
		//NSLog(@"stop move forward");
		[[Scene currentScene] stopMoving];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
    //NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    //NSLog(@"mouse down: #%ld %.fx,%.fy", (long)theEvent.buttonNumber, point.x, point.y);
    [[Scene currentScene] startMoving];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    //NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSPoint point = [theEvent locationInWindow];
    NSLog(@"mouse dragged: #%ld %.fx,%.fy", (long)theEvent.buttonNumber, point.x, point.y);
}

- (void)mouseUp:(NSEvent *)theEvent
{
    //NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    //NSLog(@"mouse up: #%ld %.fx,%.fy", (long)theEvent.buttonNumber, point.x, point.y);
    [[Scene currentScene] stopMoving];
}

@end