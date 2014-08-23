#import "HolodeckScene.h"

@implementation HolodeckScene
{
	SCNMaterial *goldMaterial, *glowMaterial, *silverMaterial;
	
	SCNSphere *ball;
	SCNNode *ballNode;
	float ballRadius;
	
	SCNText *message;
	SCNNode *messageNode;
}

#pragma mark - Initialization

- (id)init
{
    if (!(self = [super init])) return nil;
	
	self.roomSize = 1200; // max and min scene coordinates are +- roomSize/2, center is 0,0,0
	self.avatarHeight = 250;  // distance from ground to eye camera
	
	// starting position: standing on the floor in the center of the room
    self.headPosition = SCNVector3Make(0.0, self.avatarHeight - self.roomSize/2, 0.0);
    
	// avatar spotlights autofollow and autopoint where the avatar is facing
    SCNLight *avatarLight = [super makeAvatarSpotlight];
    avatarLight.color = [NSColor colorWithDeviceRed:1.0 green:0.98 blue:0.5 alpha:1.0];
    //avatarLight.color = [NSColor redColor];  // seeing red
    avatarLight.gobo.contents = [NSImage imageNamed:@"EyeLight"];
    
    [self setupHolodeck];  // walls
    [self setupObjects];   // room content
	
	return self;
}

// Create six textured walls enclosing the room.
- (void)setupHolodeck
{
    // create wall material
    NSImage *holodeckTexture = [NSImage imageNamed:@"Holodeck"];
    SCNMaterial *material = [SCNMaterial material];
    material.diffuse.minificationFilter  = SCNLinearFiltering;
    material.diffuse.magnificationFilter = SCNLinearFiltering;
    material.diffuse.mipFilter           = SCNLinearFiltering;
    material.diffuse.contents   = [NSColor darkGrayColor];
    material.specular.contents  = holodeckTexture;  // lines are shiny yellow when lit
    material.emission.contents  = holodeckTexture;  // lines glow
    material.emission.intensity = 0.05;
    material.shininess = 0.75;
    
    // create walls
	// TODO: move this into a superclass convience function, minus holodeck material
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:0.0 y:-super.roomSize/2 z:0.0 Rangle:-M_PI_2 x:1.0 y:0.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:0.0 y: super.roomSize/2 z:0.0 Rangle: M_PI_2 x:1.0 y:0.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:-super.roomSize/2 y:0.0 z:0.0 Rangle: M_PI_2 x:0.0 y:1.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx: super.roomSize/2 y:0.0 z:0.0 Rangle:-M_PI_2 x:0.0 y:1.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:0.0 y:0.0 z:-super.roomSize/2 Rangle:    0.0 x:0.0 y:0.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:0.0 y:0.0 z: super.roomSize/2 Rangle:  -M_PI x:0.0 y:1.0 z:0.0]];
}

// Place some objects in the room.
- (void)setupObjects
{
    CGFloat podiumHeight = super.roomSize /   5;
    CGFloat podiumRadius = super.roomSize /  25;
    CGFloat podiumGap    = super.roomSize / 100;
	
    SCNVector3 podiumPosition = SCNVector3Make(0.0, -self.roomSize/2, -self.roomSize/4);
	
    SCNNode *objectsNode = [SCNNode node];
    [self.rootNode addChildNode:objectsNode];
    
    // Materials
	// TODO: move some standard materials into superclass convenience variables
    NSColor *goldColor = [NSColor yellowColor];
    goldMaterial = [SCNMaterial material];
    goldMaterial.diffuse.contents  = goldColor;
    goldMaterial.specular.contents = goldColor;
    
    NSColor *glowColor = [NSColor colorWithDeviceRed:1.0 green:0.98 blue:0.6 alpha:1.0];
    glowMaterial = [SCNMaterial material];
    glowMaterial.emission.contents = glowColor;
    glowMaterial.emission.intensity = 0.75;
    
    NSColor *silverColor = [NSColor colorWithDeviceRed:0.98 green:0.98 blue:1.00 alpha:1.0];
    silverMaterial = [SCNMaterial material];
    silverMaterial.diffuse.contents  = silverColor;
    silverMaterial.specular.contents = silverColor;
    
    // Silver cubes in corners
    float b = super.roomSize/2 - super.roomSize/10;
    SCNVector3 cubePositions[] =
    {
        SCNVector3Make( b,  b,  b),
        SCNVector3Make(-b,  b,  b),
        SCNVector3Make( b, -b,  b),
        SCNVector3Make(-b, -b,  b),
        SCNVector3Make( b,  b, -b),
        SCNVector3Make(-b,  b, -b),
        SCNVector3Make( b, -b, -b),
        SCNVector3Make(-b, -b, -b)
    };
    for (int i=0; i < sizeof(cubePositions) / sizeof(cubePositions[0]); i++)
        [objectsNode addChildNode:[self makeCubeWithSize:super.roomSize/10 chamfer:podiumGap materials:@[silverMaterial] position:cubePositions[i]]];
    
    // Silver podium base
    SCNCylinder *cylinder = [SCNCylinder cylinderWithRadius:podiumRadius height:1];
    cylinder.materials = @[silverMaterial];
    SCNNode *cylinderNode = [SCNNode nodeWithGeometry:cylinder];
    cylinderNode.position = SCNVector3Make(podiumPosition.x, podiumPosition.y, podiumRadius + podiumPosition.z);
    [objectsNode addChildNode:cylinderNode];
    
    SCNCylinder *cylinder2 = [SCNCylinder cylinderWithRadius:podiumRadius*0.75 height:podiumHeight*0.25];
    cylinder.materials = @[silverMaterial];
    SCNNode *cylinder2Node = [SCNNode nodeWithGeometry:cylinder2];
    cylinder2Node.position = SCNVector3Make(0.0, cylinder2.height/2, 0.0);
    [cylinderNode addChildNode:cylinder2Node];
    
    SCNCylinder *cylinder3 = [SCNCylinder cylinderWithRadius:podiumRadius*0.5 height:podiumHeight];
    cylinder.materials = @[silverMaterial];
    SCNNode *cylinder3Node = [SCNNode nodeWithGeometry:cylinder3];
    cylinder3Node.position = SCNVector3Make(0.0, cylinder3.height/2, 0.0);
    [cylinderNode addChildNode:cylinder3Node];
    
    // Large gold ball on podium
    ballRadius = podiumRadius * 0.4;
    ball = [SCNSphere sphereWithRadius:ballRadius];
    ballNode = [SCNNode nodeWithGeometry:ball];
    ballNode.position = SCNVector3Make(0, podiumHeight + podiumGap + ballRadius, 0);
    ball.materials = @[goldMaterial];
    [cylinderNode addChildNode:ballNode];
    
    // Silver ring around ball
    int ringRadius = podiumRadius * 0.8;
    SCNTorus *ring = [SCNTorus torusWithRingRadius:ringRadius pipeRadius:ringRadius/8];
    ring.materials = @[silverMaterial];
    SCNNode *ringNode = [SCNNode nodeWithGeometry:ring];
    [ballNode addChildNode:ringNode];
    
    // Glowing ball in ring (makes ring rotation visible)
    SCNSphere *ringStone = [SCNSphere sphereWithRadius:ringRadius/4];
    ringStone.materials = @[glowMaterial];
    SCNNode *ringStoneNode = [SCNNode nodeWithGeometry:ringStone];
    ringStoneNode.position = SCNVector3Make(ringRadius, 0, 0);
    [ringNode addChildNode:ringStoneNode];
    
	SCNLight *ballLight = [SCNLight light];
    SCNNode *ballLightNode = [SCNNode node];
    ballLight.type = SCNLightTypeOmni;
    ballLight.color = glowColor;
    ballLightNode.light = ballLight;
	[ringStoneNode addChildNode:ballLightNode];
    
    // rotate the ring around the ball
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 20;
    animation.repeatCount = HUGE_VALF;
    animation.values = [NSArray arrayWithObjects:
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 4 * M_PI_2, 0.f, 1.f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 3 * M_PI_2, 0.f, 1.f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 2 * M_PI_2, 0.f, 1.f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 1 * M_PI_2, 0.f, 1.f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 0 * M_PI_2, 0.f, 1.f, 0.f)],
                        nil];
    [ringNode addAnimation:animation forKey:@"transform"];
    
    // Spinning golden question mark above ball
    SCNText *questionMark = [SCNText textWithString:@"?" extrusionDepth:4];
    questionMark.materials = @[goldMaterial];
    questionMark.chamferRadius = 5;
    SCNNode *questionMarkNode = [SCNNode nodeWithGeometry:questionMark];
    questionMarkNode.position = SCNVector3Make(-10, podiumGap, 0);
    [ringStoneNode addChildNode:questionMarkNode];
    
    CAKeyframeAnimation *questionMarkAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    questionMarkAnimation.duration = 5;
    questionMarkAnimation.repeatCount = HUGE_VALF;
    questionMarkAnimation.values = [NSArray arrayWithObjects:
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 0 * M_PI_2, 0.f, 1.f, 0.f)],
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 1 * M_PI_2, 0.f, 1.f, 0.f)],
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 2 * M_PI_2, 0.f, 1.f, 0.f)],
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 3 * M_PI_2, 0.f, 1.f, 0.f)],
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 4 * M_PI_2, 0.f, 1.f, 0.f)],
									nil];
    [ringStoneNode addAnimation:questionMarkAnimation forKey:@"transform"];
	
	[self addMessage:@"Press Space to Save"];
}

- (void)addMessage:(NSString*)string
{
	// Messages above ball
	[messageNode removeFromParentNode];
	message = [SCNText textWithString:string extrusionDepth:3];
	message.name = string;
	message.materials = @[silverMaterial];
	messageNode = [SCNNode nodeWithGeometry:message];
	messageNode.position = SCNVector3Make(-message.textSize.width/2, ballRadius*1.5, 0);
	[ballNode addChildNode:messageNode];
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
	[self addEventHandlerForType:NSKeyDown name:@"49" handler:@selector(onSave)];  // space
}

// DEMO: custom event handler
- (void)onSave
{
	if ([self isInXZRange:self.avatarHeight x:0.0 z:-self.roomSize/4])
	{
		[self addMessage:@"Saved!"];
	}
}

// DEMO: custom tick event, makes ball glow if avatar is in range
- (void)tick:(const CVTimeStamp *)timeStamp
{
	[super tick:timeStamp];
	
	if ([self isInXZRange:self.avatarHeight x:0.0 z:-self.roomSize/4])
	{
		ball.materials = message.materials = @[glowMaterial];
	}
	else
	{
		ball.materials = message.materials = @[goldMaterial];
		if ([message.name isEqual: @"Saved!"])
		{
			[self addMessage:@"Save Again?"];
		}
	}
}

@end
