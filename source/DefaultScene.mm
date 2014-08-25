#import "DefaultScene.h"

@implementation DefaultScene
{
	NSColor *lightColor, *glowColor;
	
	SCNMaterial *basicMaterial;
	SCNMaterial *connectedMaterial;
	SCNMaterial *leftDisconnectedMaterial;
	SCNMaterial *rightDisconnectedMaterial;
	
	NSMutableArray *spheres;
	
	float influence;
}

#pragma mark - Initialization

- (id)init
{
    if (!(self = [super init])) return nil;
	
	self.roomSize = 1000; // max and min scene coordinates are +- roomSize/2, center is 0,0,0
	self.avatarHeight = 100;  // distance from ground to eye camera
	self.avatarSpeed = 1.5;
	influence = 200;
	
	// starting position: feet on the floor (y=0) in the center of the room
    self.headPosition = SCNVector3Make(0.0, self.avatarHeight, 0.0);
	
	// create colors
	lightColor = [NSColor colorWithDeviceHue:0.18 saturation:0.25 brightness:0.75 alpha:1];
	glowColor = [NSColor colorWithDeviceHue:0.00 saturation:1.00 brightness:0.10 alpha:1];

	//create materials
	basicMaterial = [SCNMaterial material];
	basicMaterial.diffuse.contents = [NSColor grayColor];
	
	connectedMaterial = [SCNMaterial material];
	connectedMaterial.diffuse.contents = [NSColor redColor];
	
	leftDisconnectedMaterial = [SCNMaterial material];
	leftDisconnectedMaterial.diffuse.contents = [NSColor greenColor];
	
	rightDisconnectedMaterial = [SCNMaterial material];
	rightDisconnectedMaterial.diffuse.contents = [NSColor blueColor];
	
	// create directional light
	SCNLight *directLight = [SCNLight light];
	directLight.type = SCNLightTypeDirectional;
	directLight.color = lightColor;
	SCNNode *directNode = [SCNNode node];
	directNode.light = directLight;
	//directNode.rotation = SCNVector4Make(0, 0, 0, M_PI_2);
	directNode.transform = CATransform3DRotate(directNode.transform, -M_PI_2,     1, 0, 0);
	directNode.transform = CATransform3DRotate(directNode.transform,  M_PI_2*0.2, 0, 1, 0);
	[self.rootNode addChildNode:directNode];
    
	// avatar lights
    SCNLight *avatarSpotlight = [super makeAvatarSpotlight];
    avatarSpotlight.color = lightColor;
	avatarSpotlight.castsShadow = YES;
    //avatarSpotlight.gobo.contents = [NSImage imageNamed:@"AvatarLightGobo"];
	SCNLight *avatarOmniLight = [super makeAvatarOmnilight];
	avatarOmniLight.color = glowColor;
	avatarOmniLight.shadowRadius = 0.5;
	
	// create spheres
	srandom(1234);  // both eyes use the same seed
	spheres = [NSMutableArray array];
	for (int i=0; i<10; i++)
	{
		float size = random() % int(self.avatarHeight/2);
		SCNSphere *aSphere = [SCNSphere sphereWithRadius:size];
		aSphere.materials = @[connectedMaterial];
		SCNNode *sphereNode = [SCNNode nodeWithGeometry:aSphere];
		float x = (random() % int(self.roomSize)) - self.roomSize/2;
		float z = (random() % int(self.roomSize)) - self.roomSize/2;
		//NSLog(@"create sphere at %.f %.f %.f", x, size, z);
		sphereNode.position = SCNVector3Make(x, size, z);
		[self.rootNode addChildNode:sphereNode];
		[spheres addObject:sphereNode];
	}
	
	return self;
}

#pragma mark - Event handlers

- (void) addEventHandlers
{
	// enable standard control schemes
	//[self addEventHandlersForHoldWASD];
	//[self addEventHandlersForHoldArrows];
	//[self addEventHandlersForLeftMouseDownMoveForward];
	//[self addEventHandlersForRightMouseDownMoveBackward];
	
	// add custom controls
	//[self addEventHandlerForType:NSKeyDown name:@"49" handler:@selector(onInteract)];  // space
	[self addEventHandlerForType:NSKeyDown name:@"49" handler:@selector(startMovingForward)];  // space
	[self addEventHandlerForType:NSKeyUp   name:@"49" handler:@selector(stopMovingForward)];  // space
}

/*/ event handler for active interactions with objects
- (void)onInteract
{
	// if in range of any objects
	for (int i=0; i<spheres.count; i++)
	{
		SCNNode *sphere = [spheres objectAtIndex:i];
		// perform any active interactions
		if ([self isInXYZRange:influence node:sphere])
		{
			NSLog(@"interact with sphere #%d", i);
		}
	}
}*/

// event handler for passive interactions with objects
- (void)tick:(const CVTimeStamp *)timeStamp
{
	[super tick:timeStamp];
	
	// if in range of any objects
	for (int i=0; i<spheres.count; i++)
	{
		SCNNode *sphere = [spheres objectAtIndex:i];
		// perform any passive interactions
		if ([self isInXYZRange:influence node:sphere])
		{
			if ([self.eye isEqual:@"left"])
			{
				sphere.geometry.materials = @[leftDisconnectedMaterial];
				// TODO: timestamp
			}
			else
			{
				sphere.geometry.materials = @[rightDisconnectedMaterial];
			}
		}
		else
		{
			// reconnect spheres outside the influence
			// TODO: if enough time since disconnect timestamp
			//if (arc4random_uniform(20) == 0)  // if you're lucky
				//sphere.geometry.materials = @[connectedMaterial];
		}
	}
	
	if ([self checkForWin])
	{
		NSLog(@"you win");
	}
}

- (BOOL)checkForWin
{
	for (int i=0; i<spheres.count; i++)
	{
		SCNNode *sphere = [spheres objectAtIndex:i];
		if ([sphere.geometry.materials isEqual: @[connectedMaterial]])
			return NO;
	}
	return YES;
}

@end
