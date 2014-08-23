#import "MainWindow.h"
#import "Scene.h"
#import "OculusRiftDevice.h"

@implementation MainWindow

#pragma mark - Initialization

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(NSUInteger)aStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)flag
{	
	// if debug HMD, use windowed mode
	BOOL isFullscreen = ![[OculusRiftDevice getDevice] isDebugHmd];
	if (isFullscreen)
	{
		NSLog(@"HMD detected, using fullscreen mode");
		aStyle = aStyle & NSBorderlessWindowMask; // no window chrome
		bufferingType = NSBackingStoreBuffered;   // buffered
	}
    self = [super initWithContentRect:contentRect
							styleMask:aStyle
							  backing:bufferingType
								defer:flag];
    if (!self) return nil;
	
	if (isFullscreen)
	{
		// FUTURE: This assumes the HMD is the main screen, because the v0.4.1 Mac drivers don't support anything else.
		NSRect screenRect = [[NSScreen mainScreen] frame];
		NSRect windowRect = NSMakeRect(0.0, 0.0, screenRect.size.width, screenRect.size.height);
		[self setFrame:windowRect display:YES];		// window size and autoredraw subviews
		[self setLevel:NSMainMenuWindowLevel+1];	// above the menu bar
		[self setMovable:NO];						// not movable
		[self setHidesOnDeactivate:NO];				// do NOT autohide when not front app
		//[self toggleFullScreen:nil];				// use own Space (10.7+)
	}
	[self makeKeyAndOrderFront:self];				// show the window
	
    return self;
}

#pragma mark - Event handlers

- (void)eventHandler:(NSEvent*)theEvent
{
	NSEventType eventType = [theEvent type];
	NSDictionary *handlers = [[Scene currentScene] getHandlersForEventType:eventType];
	NSMutableString *keyCodeString = [NSMutableString string];
	
	unsigned long modifierFlags = [theEvent modifierFlags];
	if (modifierFlags & NSCommandKeyMask)	[keyCodeString appendString:@"#"];
	if (modifierFlags & NSControlKeyMask)	[keyCodeString appendString:@"^"];
	if (modifierFlags & NSAlternateKeyMask)	[keyCodeString appendString:@"="];
	if (modifierFlags & NSShiftKeyMask)		[keyCodeString appendString:@"+"];
	
	if ((eventType == NSKeyDown) || (eventType == NSKeyUp))
		[keyCodeString appendString:[[NSNumber numberWithInt:[theEvent keyCode]] stringValue]];
	
	else if ((eventType == NSLeftMouseDown) || (eventType == NSLeftMouseUp))
		[keyCodeString appendString:@"left"];
	else if ((eventType == NSRightMouseDown) || (eventType == NSRightMouseUp))
		[keyCodeString appendString:@"right"];
	else if (eventType == NSMouseMoved)
		[keyCodeString appendString:@"drag"];
	
	BOOL debug = [[OculusRiftDevice getDevice] isDebugHmd];
	if (debug) NSLog(@"handling event for type %lu-%@", (unsigned long)eventType, keyCodeString);
	
	SEL handler = (SEL)[[handlers objectForKey:keyCodeString] pointerValue];
	if (handler)
		[[Scene currentScene] performSelector:handler];
	else
		if (debug) NSLog(@"no handler for key %lu-%@", (unsigned long)eventType, keyCodeString);
}

- (void)keyDown:(NSEvent *)theEvent        { [self eventHandler:theEvent]; }
- (void)keyUp:(NSEvent *)theEvent          { [self eventHandler:theEvent]; }
- (void)mouseUp:(NSEvent *)theEvent        { [self eventHandler:theEvent]; }
- (void)mouseDown:(NSEvent *)theEvent      { [self eventHandler:theEvent]; }
- (void)mouseDragged:(NSEvent *)theEvent   { [self eventHandler:theEvent]; }
- (void)rightMouseDown:(NSEvent *)theEvent { [self eventHandler:theEvent]; }
- (void)rightMouseUp:(NSEvent *)theEvent   { [self eventHandler:theEvent]; }

- (BOOL)canBecomeKeyWindow { return YES; }  // allow borderless window to receive key events

@end
