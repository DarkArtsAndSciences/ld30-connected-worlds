#import "DefaultScene.h"
#import "OculusRiftDevice.h"

@implementation DefaultScene
{
	// setEye
	int eyeM;  // -1 for left, 1 for right
	
	// initGlobals
	NSSound *disconnectSFX, *reconnectSFX, *loseSFX, *winSFX;
	
	NSString *fontName;
	NSFont *logoFont, *messageFont;
	SCNNode *centerNode, *messageNode;
	
	NSColor *connectColor, *_leftDisconnectColor, *_rightDisconnectColor;
	SCNMaterial *basicMaterial, *starMaterial, *connectMaterial, *disconnectMaterial;
	NSArray *basicMaterials, *starMaterials, *connectMaterials, *disconnectMaterials;
	CAKeyframeAnimation *disconnectColorAnimation, *disconnectContentsAnimation, *disconnectMaterialAnimation;
	
	SCNMaterial *info1Material, *info2Material, *info3Material;
	
	// initGame
	int level, range, numSpheres, connectedSpheres;
	NSString *levelName;
	float mySize, mySpeed, myInfluence;  // player state
	
	// clearLevel
	SCNNode *levelNode;
	
	// setupLoadingScene
	SCNNode *logoSphereNode;
	
	// nextLevel
	float maxInfluence;
	NSMutableArray *spheres;
	
	// addDirectionalLight
	SCNNode *directLightNode;
	
	// addDisconnectedLights
	SCNNode *spotLightNode, *spotLightCenterNode, *omniLightNode;
	
	// addMessage
	SCNText *messageText;
}

#pragma mark - Initialization

// Called right after init, which can't be overridden with this variable, so all setup is done here.
- (void)setEye:(NSString*)theEye
{
	[super setEye:theEye];
	eyeM = [self isLeft] ? -1 : 1;
	
	[self initGlobals];
	[self initGame];
	[self setupLoadingScene];
}

-(void)initGlobals
{
	// audio
	disconnectSFX = [NSSound soundNamed:@"disconnect.wav"];
	reconnectSFX = [NSSound soundNamed:@"reconnect.wav"];
	loseSFX = [NSSound soundNamed:@"lose.wav"];
	winSFX = [NSSound soundNamed:@"win.wav"];
	
	// text
	fontName = @"Zoetrope (BRK)";
	logoFont = [NSFont fontWithName:fontName size:72];
	messageFont = [NSFont fontWithName:fontName size:20];
	
	centerNode = [SCNNode node];
	messageNode = [SCNNode node];
	messageNode.position = SCNVector3Make(0, 50, -100);
	messageNode.transform = CATransform3DRotate(messageNode.transform, 0.25, 1, 0, 0);
	[self linkNodeToHeadRotation:messageNode];
	[messageNode addChildNode:centerNode];
	
	// colors
	connectColor		  = [NSColor colorWithRed:0.5 green:0 blue:0 alpha:1];
	_leftDisconnectColor  = [NSColor colorWithRed:0 green:0.5 blue:0 alpha:1];
	_rightDisconnectColor = [NSColor colorWithRed:0 green:0 blue:0.5 alpha:1];

	// materials
	basicMaterial = [SCNMaterial material];
	basicMaterial.diffuse.contents = [NSColor grayColor];
	basicMaterial.doubleSided = YES;
	basicMaterials = @[basicMaterial];
	
	// TODO: animate twinkling
	starMaterial = [SCNMaterial material];
	starMaterial.diffuse.contents = [NSColor whiteColor];
	starMaterial.emission.contents = [NSColor whiteColor];
	starMaterial.doubleSided = YES;
	starMaterials = @[starMaterial];
	
	connectMaterial = [SCNMaterial material];
	connectMaterial.diffuse.contents = connectColor;
	connectMaterial.doubleSided = YES;
	connectMaterials = @[connectMaterial];
	
	disconnectMaterial = [SCNMaterial material];
	disconnectMaterial.diffuse.contents = [NSColor grayColor];
	disconnectMaterial.specular.contents = [self disconnectColor];
	disconnectMaterial.shininess = 0.1;
	disconnectMaterial.doubleSided = YES;
	disconnectMaterials = @[disconnectMaterial];
	
	info1Material = [SCNMaterial material];
	info1Material.diffuse.contents = [NSImage imageNamed:@"controls"];  // TODO: for this mode
    info1Material.diffuse.minificationFilter  = SCNLinearFiltering;
    info1Material.diffuse.magnificationFilter = SCNLinearFiltering;
    info1Material.diffuse.mipFilter           = SCNLinearFiltering;
	
	info2Material = [SCNMaterial material];
	info2Material.diffuse.contents = [NSImage imageNamed:@"ideagen"];
    info2Material.diffuse.minificationFilter  = SCNLinearFiltering;
    info2Material.diffuse.magnificationFilter = SCNLinearFiltering;
    info2Material.diffuse.mipFilter           = SCNLinearFiltering;
	
	info3Material = [SCNMaterial material];
	info3Material.diffuse.contents = [NSImage imageNamed:@"story"];
    info3Material.diffuse.minificationFilter  = SCNLinearFiltering;
    info3Material.diffuse.magnificationFilter = SCNLinearFiltering;
    info3Material.diffuse.mipFilter           = SCNLinearFiltering;
	
	//infoMaterial.emission.contents = [NSImage imageNamed:@"ideagen"];  // glowing letters
	
	// animations
	// TODO: these should be faster with more influence
	disconnectColorAnimation = [CAKeyframeAnimation animationWithKeyPath:@"color"];
	disconnectColorAnimation.duration = 3;
	disconnectColorAnimation.repeatCount = 1;
	disconnectColorAnimation.values = [NSArray arrayWithObjects: connectColor, [self disconnectColor], nil];
	
	disconnectContentsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"color"];
	disconnectContentsAnimation.duration = 3;
	disconnectContentsAnimation.repeatCount = 1;
	disconnectContentsAnimation.values = [NSArray arrayWithObjects: connectColor, [self disconnectColor], nil];
	
	disconnectMaterialAnimation = [CAKeyframeAnimation animationWithKeyPath:@"material"];
	disconnectMaterialAnimation.duration = 3;
	disconnectMaterialAnimation.repeatCount = 1;
	disconnectMaterialAnimation.values = [NSArray arrayWithObjects: connectMaterial, disconnectMaterial, nil];
	
	// removable subscene for levels
	levelNode = [SCNNode node];
}
- (NSColor*)disconnectColor
{
	if ([self isLeft])
		return _leftDisconnectColor;
	else
		return _rightDisconnectColor;
}

- (void)initGame
{
	level = 0;
	levelName = @"init";
	
	mySpeed = 1;
	mySize = 100.0;
	myInfluence = 150.0;
	range = 1000;
	connectedSpheres = 0;
}

- (void)clearLevel
{
	if (spheres) spheres = [NSMutableArray array];
	
	if (levelNode) [levelNode removeFromParentNode];
	levelNode = [SCNNode node];
	[self.rootNode addChildNode:levelNode];
	
	[self setHeadPosition:SCNVector3Make(0,0,0)];
}

- (void)setupLoadingScene
{
	[self clearLevel];
	mySpeed = 10;
	
	// lights
	SCNLight *ambientLight = [SCNLight light];
	ambientLight.type = SCNLightTypeAmbient;
	ambientLight.color = [NSColor grayColor];
	SCNNode *ambientLightNode = [SCNNode node];
	ambientLightNode.light = ambientLight;
	[levelNode addChildNode:ambientLightNode];
	
	[self addDirectionalLight];
	[self addDisconnectedLights];
	
	// instructions
	int width = 664;
	int height = 343;
	SCNPlane *wall1 = [SCNPlane planeWithWidth:width height:height];
	wall1.materials = @[info1Material];
	SCNNode *wall1Node = [SCNNode nodeWithGeometry:wall1];
	wall1Node.position = SCNVector3Make(0, 0, -250);
	[levelNode addChildNode:wall1Node];
	
	SCNPlane *wall2 = [SCNPlane planeWithWidth:width height:height];
	wall2.materials = @[info2Material];
	SCNNode *wall2Node = [SCNNode nodeWithGeometry:wall2];
	wall2Node.position = SCNVector3Make(0, 0, -500);
	[levelNode addChildNode:wall2Node];
	
	SCNPlane *wall3 = [SCNPlane planeWithWidth:width height:height];
	wall3.materials = @[info3Material];
	SCNNode *wall3Node = [SCNNode nodeWithGeometry:wall3];
	wall3Node.position = SCNVector3Make(0, 0, -750);
	[levelNode addChildNode:wall3Node];
	
	// logo
    SCNText *logoText1 = [SCNText textWithString:@"Or Else They Will" extrusionDepth:10];
    SCNText *logoText2 = [SCNText textWithString:@"Disconnect You" extrusionDepth:10];
    logoText1.materials = logoText2.materials = disconnectMaterials;
    logoText1.chamferRadius = logoText2.chamferRadius = 10;
	logoText1.font = logoText2.font = logoFont;
	
    SCNNode *logoNode1 = [SCNNode nodeWithGeometry:logoText1];
    SCNNode *logoNode2 = [SCNNode nodeWithGeometry:logoText2];
	logoNode1.transform = CATransform3DTranslate(logoNode1.transform, -logoText1.textSize.width/2, 0, 0); // x centered
	logoNode2.transform = CATransform3DTranslate(logoNode2.transform, -logoText2.textSize.width/2, 0, 0);
	logoNode1.transform = CATransform3DTranslate(logoNode1.transform, 0, -logoText1.textSize.height/2, 0); // y centered
	logoNode2.transform = CATransform3DTranslate(logoNode2.transform, 0, -logoText2.textSize.height/2, 0);
	logoNode1.transform = CATransform3DTranslate(logoNode1.transform, 0,  100, 0); // y separation
	logoNode2.transform = CATransform3DTranslate(logoNode2.transform, 0, -100, 0);
	logoNode1.transform = CATransform3DTranslate(logoNode1.transform, 0, 0, -1000);  // location
	logoNode2.transform = CATransform3DTranslate(logoNode2.transform, 0, 0, -1000);
    [levelNode addChildNode:logoNode1];
    [levelNode addChildNode:logoNode2];
	
	SCNSphere *logoSphere = [SCNSphere sphereWithRadius:50];
	logoSphere.materials = connectMaterials;
	logoSphereNode = [SCNNode nodeWithGeometry:logoSphere];
	logoSphereNode.position = SCNVector3Make(0, 0, -1000);
	[levelNode addChildNode:logoSphereNode];
	
	// TODO: giant fake sun at -1,-1,-1, distant constellations (for orientation reference)
	srandom(1234);
	for (int i=0; i<1000; i++)
	{
		float size = 1 + (random() % 100)/50.0;
		SCNSphere *star = [SCNSphere sphereWithRadius:size*size];
		star.materials = starMaterials;
		// TODO: tint material per star?
		
		SCNNode *starNode = [SCNNode nodeWithGeometry:star];
		starNode.position = [self getRandomLocationOutsideRange];
		
		[self.rootNode addChildNode:starNode];
	}
}

- (void)setAvatarSpeed:(CGFloat)avatarSpeed
{
	self.avatarSpeed = avatarSpeed;
}
- (CGFloat)avatarSpeed
{
	if (connectedSpheres > 0)
		return mySpeed * connectedSpheres;
	else
		return mySpeed;
}

- (void)nextLevel
{
	level += 1;
	mySpeed = 2 + level*0.1;
	myInfluence = 100 + (10 * level);
	maxInfluence = 1000.0/(float)level;
	range = mySize * 10 * level;
	numSpheres = 10 * level * level;
	connectedSpheres = 0;
	NSLog(@"\nWelcome to level %d, size %d, %d spheres.\nYour speed is now %.2f.\nYour influence has been reset to %.f. Please keep it below %.f.", level, range, numSpheres, mySpeed, myInfluence, maxInfluence);
	
	[self clearLevel];
	[self addMessage:[NSString stringWithFormat:@"Level %d", level]];
	
	// lights
	SCNLight *ambientLight = [SCNLight light];
	ambientLight.type = SCNLightTypeAmbient;
	ambientLight.color = [NSColor grayColor];
	SCNNode *ambientLightNode = [SCNNode node];
	ambientLightNode.light = ambientLight;
	[levelNode addChildNode:ambientLightNode];
	[self addDirectionalLight];
	[self addDisconnectedLights];
	
	// spheres
	// both eyes use the same random seed
	// use random() to make scenes match, arc4random() to mismatch
	srandom(1234);
	spheres = [NSMutableArray array];
	for (int i=0; i<numSpheres; i++)
	{
		float size = 10 + random() % 100;
		SCNSphere *sphere = [SCNSphere sphereWithRadius:size];
		sphere.materials = connectMaterials;
		
		SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
		sphereNode.position = [self getRandomLocationInRangeOutsideInfluence];
		
		[levelNode addChildNode:sphereNode];
		[spheres addObject:sphereNode];
	}
}

- (void)setupBadEnding
{
	level = -1;
	[self clearLevel];
	[loseSFX play];
	[self addMessage:[NSString stringWithFormat:@"You split into two pieces\none green, one blue.\n\nNeither survives."]];
	[self addDirectionalLight];
	[self addDisconnectedLights];
}

- (void)setupGoodEnding
{
	level = -2;
	[self clearLevel];
	[winSFX play];
	[self addMessage:[NSString stringWithFormat:@"Your eyes stop hurting.\nYou are in one piece.\n\nYou have survived."]];
	[self addDirectionalLight];
	//[self addConnectedLights];
}

- (SCNVector3)getRandomLocationInRangeOutsideInfluence
{
	float x, y, z;
	x = y = z = 0.0;
	
	int tries = 0;
	int maxTries = 1000;
	while ((tries < maxTries) && [self isInXYZRange:myInfluence x:x y:y z:z])
	{
		tries++;
		x = (random() % range) - range/2.0;
		y = (random() % range) - range/2.0;
		z = (random() % range) - range/2.0;
		
		if (tries == maxTries)
			NSLog(@"can't make sphere in range %d outside influence %f after %d tries, giving up and using %.f,%.f,%.f",
				  range, myInfluence, tries, x, y, z);
	}
	return SCNVector3Make(x, y, z);
}

- (SCNVector3)getRandomLocationOutsideRange
{
	float x, y, z;
	x = y = z = 0.0;
	
	int tries = 0;
	int maxTries = 1000;
	while ((tries < maxTries) && [self isInXYZRange:range x:x y:y z:z])
	{
		tries++;
		x = (random() % range*10) - range*5;  //random() - RAND_MAX/2.0;
		y = (random() % range*10) - range*5;
		z = (random() % range*10) - range*5;
		
		if (tries == maxTries)
			NSLog(@"can't make sphere in range %d outside influence %f after %d tries, giving up and using %.f,%.f,%.f",
				  range, myInfluence, tries, x, y, z);
	}
	return SCNVector3Make(x, y, z);
}

- (void)addDirectionalLight
{
	// directional light from -1,-1,-1
	SCNLight *directLight = [SCNLight light];
	directLight.type = SCNLightTypeDirectional;
	directLight.color = [NSColor colorWithDeviceWhite:0.5 alpha:1];
	
	directLightNode = [SCNNode node];
	directLightNode.light = directLight;
	directLightNode.transform = CATransform3DRotate(directLightNode.transform, -M_PI_4, 1, 0, 0);
	directLightNode.transform = CATransform3DRotate(directLightNode.transform, -M_PI_4, 0, 1, 0);
	directLightNode.transform = CATransform3DRotate(directLightNode.transform, -M_PI_4, 0, 0, 1);
	[levelNode addChildNode:directLightNode];
}

- (void)addDisconnectedLights
{
	// create avatar lights
	// TODO: remove old lights
	
	spotLightCenterNode = [super makeAvatarSpotlight];
	spotLightCenterNode.light.castsShadow = NO;
	spotLightCenterNode.light.color = connectColor;
	[spotLightCenterNode.light setAttribute:@0 forKey: SCNLightSpotInnerAngleKey];
	[spotLightCenterNode.light setAttribute:@1 forKey: SCNLightSpotOuterAngleKey];
	
    spotLightNode = [super makeAvatarSpotlight];
    spotLightNode.light.color = connectColor;
	[spotLightNode.light setAttribute:@5 forKey: SCNLightSpotInnerAngleKey];
	[spotLightNode.light setAttribute:@15 forKey: SCNLightSpotOuterAngleKey];
	
	// two lights, one per scene, distance apart = influence
	omniLightNode = [super makeAvatarOmnilight];
	omniLightNode.light.color = [self disconnectColor]; // TODO: start as connect, animate after intro/first disconnect
    [omniLightNode.light setAttribute:@50 forKey:SCNLightAttenuationStartKey];
    [omniLightNode.light setAttribute:@1000 forKey:SCNLightAttenuationEndKey];
	omniLightNode.transform = CATransform3DTranslate(omniLightNode.transform, eyeM*myInfluence, 0, 0);
}

// Messages in front of player
- (void)addMessage:(NSString*)string
{
	NSLog(@"message: %@", string);
	messageText = [SCNText textWithString:string extrusionDepth:4];
	messageText.name = string;
	messageText.materials = basicMaterials;
	messageText.font = messageFont;
	messageText.chamferRadius = 4;
	centerNode.geometry = messageText;
	
	float x = -messageText.textSize.width/2;
	float y = -messageText.textSize.height/2;
	centerNode.position = SCNVector3Make(x, y, 0);
}

#pragma mark - Event handlers

- (void)addEventHandlers
{
	// TODO: check for turn sensor
	if ([[OculusRiftDevice getDevice] isDebugHmd])
		[self addEventHandlersForStepTurnArrows];
	
	// enable standard control schemes
	[self addEventHandlersForHoldWASD];
	[self addEventHandlersForLeftMouseDownMoveForward];
	//[self addEventHandlersForRightMouseDownMoveBackward];
	
	// add custom controls
	[self addEventHandlerForType:NSKeyDown name:@"49" handler:@selector(startMovingForward)];  // space
	[self addEventHandlerForType:NSKeyUp   name:@"49" handler:@selector(stopMovingForward)];  // space
}

// event handler for passive interactions with objects
- (void)tick:(const CVTimeStamp *)timeStamp
{
	[super tick:timeStamp];
	
	if (level == 0)
	{
		// if the logo is inside your influence
		if ([self isInXYZRange:myInfluence node:logoSphereNode])
		{
			// start the game
			// TODO: after changing the material and waiting a few seconds
			//NSLog(@"close enough to sphere at %.2f, %.2f, %.2f", self.headPosition.x, self.headPosition.y, self.headPosition.z);
			[self nextLevel];
		}
		/*else
		{
			NSLog(@"too far from sphere at %.2f, %.2f, %.2f", self.headPosition.x, self.headPosition.y, self.headPosition.z);
		}*/
	}
	else if (level == -1)
	{
		// bad ending
	}
	else if (level == -2)
	{
		// good ending
	}
	else
	{
		// for each sphere
		float newInfluence = 0;
		float reconnected = 0;
		for (int i=0; i<spheres.count; i++)
		{
			SCNNode *sphere = [spheres objectAtIndex:i];
			
			// if it's connected and inside your influence
			if ([sphere.geometry.materials isEqual: connectMaterials]
				and [self isInXYZRange:myInfluence node:sphere])
			{
				NSLog(@"disconnecting sphere #%d", i);
				
				sphere.geometry.materials = disconnectMaterials;
				// TODO: timestamp
				// TODO: animate fade out
				
				// disconnect yourself
				newInfluence += 1;  // TODO: size of sphere?
			}
			// if it's disconnected and outside your influence
			else if ([sphere.geometry.materials isEqual: disconnectMaterials]
					and ![self isInXYZRange:myInfluence node:sphere])
			{
				// if you're lucky
				/*/ TODO: if enough time since disconnect timestamp
				if (random() % range == 0)
				{
					NSLog(@"reconnected sphere #%d", i);
					sphere.geometry.materials = connectMaterials;
					reconnected++;
				}*/
			}
		}
		unsigned long connected = 0;
		for (int i=0; i<spheres.count; i++)
		{
			SCNNode *sphere = [spheres objectAtIndex:i];
			if ([sphere.geometry.materials isEqual: connectMaterials])
				connected += 1;
		}
		//NSLog(@"spheres connected: %lu/%lu", connected, (unsigned long)spheres.count);
		
		// if any spheres changed
		if (newInfluence)
		{
			myInfluence += newInfluence;
			NSLog(@"\nWarning: your influence has increased to %.f/%.f", myInfluence, maxInfluence);
			
			[disconnectSFX play];
			
			// TODO: update lights for new influence
		}
		if (reconnected)
		{
			myInfluence -= reconnected / 2;  // regain half what you lost
			[reconnectSFX play];
		}
		
		/*/ if you're lucky
		if (random() % range == 0)
		{
			NSLog(@"An unexplained force heals you.");
			myInfluence -= connected;
			// TODO: heal sound
			// TODO: healLimit -= level;
		}*/
		
		if (connected == 0)
			[self nextLevel];
		
		else if (myInfluence > maxInfluence)
			[self setupBadEnding];
		
		else if (myInfluence < 0)
			[self setupGoodEnding];
	}
}

@end
