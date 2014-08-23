#import "DefaultScene.h"

@implementation DefaultScene
{
	NSColor *lightColor, *glowColor;
	SCNMaterial *basicMaterial, *floorMaterial;
	
	SCNFloor *theFloor;
	SCNNode *floorNode;
}

#pragma mark - Initialization

- (id)init
{
    if (!(self = [super init])) return nil;
	
	NSLog(@"init default scene");
	
	self.roomSize = 1000; // max and min scene coordinates are +- roomSize/2, center is 0,0,0
	self.avatarHeight = 100;  // distance from ground to eye camera
	
	// starting position: feet on the floor (y=0) in the center of the room
    self.headPosition = SCNVector3Make(0.0, self.avatarHeight, 0.0);
	
	// create colors
	lightColor = [NSColor colorWithDeviceHue:0.18 saturation:0.25 brightness:0.75 alpha:1];
	glowColor = [NSColor colorWithDeviceHue:0.00 saturation:1.00 brightness:0.10 alpha:1];

	//create materials
	basicMaterial = [SCNMaterial material];
	basicMaterial.diffuse.contents = [NSColor grayColor];
	floorMaterial = [SCNMaterial material];
	floorMaterial.diffuse.contents = [NSColor greenColor];
	
	// create directional light
	SCNLight *directLight = [SCNLight light];
	directLight.type = SCNLightTypeDirectional;
	directLight.color = lightColor;
	directLight.castsShadow = YES;
	SCNNode *directNode = [SCNNode node];
	directNode.light = directLight;
	//directNode.rotation = SCNVector4Make(0, 0, 0, M_PI_2);
	directNode.transform = CATransform3DRotate(directNode.transform, -M_PI_2,     1, 0, 0);
	directNode.transform = CATransform3DRotate(directNode.transform,  M_PI_2*0.2, 0, 1, 0);
	[self.rootNode addChildNode:directNode];
    
	// avatar lights
    SCNLight *avatarSpotlight = [super makeAvatarSpotlight];
    avatarSpotlight.color = lightColor;
    //avatarSpotlight.gobo.contents = [NSImage imageNamed:@"AvatarLightGobo"];
	SCNLight *avatarOmniLight = [super makeAvatarOmnilight];
	avatarOmniLight.color = glowColor;
	avatarOmniLight.castsShadow = YES;
	avatarOmniLight.shadowRadius = 0.5;
	
	// create floor
	theFloor = [SCNFloor floor];
	theFloor.materials = @[basicMaterial];
	theFloor.reflectivity = 0.2;
	theFloor.reflectionFalloffStart = 0;
	theFloor.reflectionFalloffEnd = self.avatarHeight/2;
	floorNode = [SCNNode nodeWithGeometry:theFloor];
	[self.rootNode addChildNode:floorNode];
	
	// create spheres
	for (int i=0; i<10; i++)
	{
		float size = arc4random() % int(self.avatarHeight/2);
		SCNSphere *aSphere = [SCNSphere sphereWithRadius:size];
		aSphere.materials = @[basicMaterial];
		SCNNode *sphereNode = [SCNNode nodeWithGeometry:aSphere];
		float x = (arc4random() % int(self.roomSize)) - self.roomSize/2;
		float z = (arc4random() % int(self.roomSize)) - self.roomSize/2;
		sphereNode.position = SCNVector3Make(x, size, z);
		[self.rootNode addChildNode:sphereNode];
	}
	
	return self;
}

#pragma mark - Event handlers

- (void) addEventHandlers
{
	// enable standard control schemes
	[self addEventHandlersForHoldWASD];
	[self addEventHandlersForHoldArrows];
	[self addEventHandlersForLeftMouseDownMoveForward];
	[self addEventHandlersForRightMouseDownMoveBackward];
	
	// add custom controls
	[self addEventHandlerForType:NSKeyDown name:@"49" handler:@selector(onInteract)];  // space
}

// event handler for active interactions with objects
- (void)onInteract
{
	// if the avatar is close enough
	float x = 0;  // TODO: object location, or upgrade isInXZRange to take a node
	float z = 0;
	if ([self isInXZRange:self.avatarHeight x:x z:z])
	{
		// interact with the object
	}
}

// event handler for passive interactions with objects
- (void)tick:(const CVTimeStamp *)timeStamp
{
	[super tick:timeStamp];
	
	// if in range of any objects
		// perform any passive interactions
}

@end
