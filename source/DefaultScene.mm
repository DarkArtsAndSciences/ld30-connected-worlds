#import "DefaultScene.h"

@implementation DefaultScene
{
	// setEye
	int eyeM;  // -1 for left, 1 for right. Not used?
	
	// initGlobals
	NSString *logoFontName, *hudFontName;
	NSColor *connectColor, *_leftDisconnectColor, *_rightDisconnectColor;
	SCNMaterial *basicMaterial, *connectMaterial, *disconnectMaterial;
	CAKeyframeAnimation *disconnectColorAnimation, *disconnectContentsAnimation, *disconnectMaterialAnimation;
	
	// initGame
	int level;
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
	SCNNode *messageNode;
}

#pragma mark - Initialization

// Called right after init, which can't be overridded with this variable, so all setup is done here.
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
	// text
	logoFontName = @"Zoetrope (BRK)";
	hudFontName = @"Zoetrope (BRK)";
	messageNode = [SCNNode node];
	
	// colors
	connectColor		  = [NSColor colorWithRed:0.5 green:0 blue:0 alpha:1];
	_leftDisconnectColor  = [NSColor colorWithRed:0 green:0.5 blue:0 alpha:1];
	_rightDisconnectColor = [NSColor colorWithRed:0 green:0 blue:0.5 alpha:1];

	// materials
	basicMaterial = [SCNMaterial material];
	basicMaterial.diffuse.contents = [NSColor grayColor];
	basicMaterial.doubleSided = YES;
	
	connectMaterial = [SCNMaterial material];
	basicMaterial.diffuse.contents = connectColor;
	connectMaterial.doubleSided = YES;
	
	disconnectMaterial = [SCNMaterial material];
	basicMaterial.diffuse.contents = [NSColor grayColor];
	disconnectMaterial.specular.contents = [self disconnectColor];
	disconnectMaterial.shininess = 0.1;
	disconnectMaterial.doubleSided = YES;
	
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
	
	mySize = 1.0;
	mySpeed = 0.01;
	myInfluence = 10.0;
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
	NSLog(@"loading screen");
	
	[self clearLevel];
	
	// lights
	[self addDirectionalLight];
	
	// logo
    SCNText *logoText1 = [SCNText textWithString:@"Or Else They Will" extrusionDepth:10];
    SCNText *logoText2 = [SCNText textWithString:@"Disconnect You" extrusionDepth:10];
    logoText1.materials = logoText2.materials = @[disconnectMaterial];
    logoText1.chamferRadius = logoText2.chamferRadius = 10;
	logoText1.font = logoText2.font = [NSFont fontWithName:logoFontName size:72];
	
    SCNNode *logoNode1 = [SCNNode nodeWithGeometry:logoText1];
    SCNNode *logoNode2 = [SCNNode nodeWithGeometry:logoText2];
	logoNode1.transform = CATransform3DTranslate(logoNode1.transform, -logoText1.textSize.width/2, 0, 0); // x centered
	logoNode2.transform = CATransform3DTranslate(logoNode2.transform, -logoText2.textSize.width/2, 0, 0);
	logoNode1.transform = CATransform3DTranslate(logoNode1.transform, 0, -logoText1.textSize.height/2, 0); // y centered
	logoNode2.transform = CATransform3DTranslate(logoNode2.transform, 0, -logoText2.textSize.height/2, 0);
	logoNode1.transform = CATransform3DTranslate(logoNode1.transform, 0,  100, 0); // y separation
	logoNode2.transform = CATransform3DTranslate(logoNode2.transform, 0, -100, 0);
	logoNode1.transform = CATransform3DTranslate(logoNode1.transform, 0, 0, -500);  // location
	logoNode2.transform = CATransform3DTranslate(logoNode2.transform, 0, 0, -500);
    [levelNode addChildNode:logoNode1];
    [levelNode addChildNode:logoNode2];
	
	SCNSphere *logoSphere = [SCNSphere sphereWithRadius:50];
	logoSphere.materials = @[connectMaterial];
	logoSphereNode = [SCNNode nodeWithGeometry:logoSphere];
	logoSphereNode.position = SCNVector3Make(0, 0, -500);
	[levelNode addChildNode:logoSphereNode];
	
	// TODO: giant fake sun at -1,-1,-1, distant constellations (for orientation reference)
}

- (void)nextLevel
{
	level += 1;
	mySpeed = 0.01 * level;
	myInfluence = 10 * level;
	maxInfluence = 1000.0/(float)level;
	int range = 1000 * level;
	NSLog(@"\nWelcome to level %d, size %d.\nYour speed is now %.2f.\nYour influence has been reset to %.f. Please keep it below %.f.", level, range, mySpeed, myInfluence, maxInfluence);
	[self addMessage:[NSString stringWithFormat:@"Level %d", level]];
	
	[self clearLevel];
	
	// lights
	[self addDirectionalLight];
	[self addDisconnectedLights];
	
	// spheres
	srandom(1234);  // both eyes use the same seed
	spheres = [NSMutableArray array];
	for (int i=0; i<10*level*level; i++)
	{
		float size = arc4random_uniform(100);
		float x = arc4random_uniform(range) - range/2.0;
		float y = arc4random_uniform(range) - range/2.0;
		float z = arc4random_uniform(range) - range/2.0;
		//NSLog(@"sphere: %.f %.f %.f", x, y, z);
		
		SCNSphere *sphere = [SCNSphere sphereWithRadius:size];
		sphere.materials = @[connectMaterial];
		
		SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
		sphereNode.position = SCNVector3Make(x, y, z);
		
		[levelNode addChildNode:sphereNode];
		[spheres addObject:sphereNode];
	}
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
	CATransform3D spotTranslate = CATransform3DMakeTranslation(0, 50, 0);
	
	spotLightCenterNode = [super makeAvatarSpotlight];
	spotLightCenterNode.light.castsShadow = NO;
	spotLightCenterNode.light.color = connectColor;
	[spotLightCenterNode.light setAttribute:@0 forKey: SCNLightSpotInnerAngleKey];
	[spotLightCenterNode.light setAttribute:@10 forKey: SCNLightSpotOuterAngleKey];
	spotLightCenterNode.transform = CATransform3DConcat(spotLightCenterNode.transform, spotTranslate);
	
    spotLightNode = [super makeAvatarSpotlight];
    spotLightNode.light.color = connectColor;
	[spotLightNode.light setAttribute:@30 forKey: SCNLightSpotInnerAngleKey];
	[spotLightNode.light setAttribute:@90 forKey: SCNLightSpotOuterAngleKey];
	spotLightNode.transform = CATransform3DConcat(spotLightNode.transform, spotTranslate);
	//spotLightNode.transform = CATransform3DRotate(spotLightNode.transform, M_PI_2*0.01, 1, 0, 0);
	
	
	CAKeyframeAnimation *spotAnimation = [CAKeyframeAnimation animationWithKeyPath:SCNLightSpotOuterAngleKey];
	spotAnimation.duration = 0.5;
	spotAnimation.repeatCount = HUGE_VALF;
	spotAnimation.values = [NSArray arrayWithObjects:
							[NSNumber numberWithFloat:45.0],
							[NSNumber numberWithFloat:90.0],
							nil];
	//[spotLightNode.light addAnimation:spotAnimation forKey:SCNLightSpotOuterAngleKey];
	
	// two lights, one per scene, distance apart = influence
	omniLightNode = [super makeAvatarOmnilight];
	omniLightNode.light.color = [self disconnectColor]; // TODO: start as connect, animate after intro/first disconnect
    [omniLightNode.light setAttribute:@50 forKey:SCNLightAttenuationStartKey];
    [omniLightNode.light setAttribute:@1000 forKey:SCNLightAttenuationEndKey];
	float x = 500;
	omniLightNode.transform = CATransform3DTranslate(omniLightNode.transform, x, 0, 0);
}

// Messages in front of player
- (void)addMessage:(NSString*)string
{
	[messageNode removeFromParentNode];
	
	messageText = [SCNText textWithString:string extrusionDepth:1];
	messageText.name = string;
	messageText.materials = @[basicMaterial];
	messageText.font = [NSFont fontWithName:hudFontName size:36];
	messageText.chamferRadius = 1;
	
	messageNode = [SCNNode nodeWithGeometry:messageText];
	[self linkNodeToHeadRotation:messageNode];
	
	float x = -messageText.textSize.width/2;
	float y = -messageText.textSize.height/2;
	messageNode.transform = CATransform3DTranslate(messageNode.transform, x, y+0.5, -1);
	messageNode.transform = CATransform3DRotate(messageNode.transform, 0.5, 1, 0, 0);
}

#pragma mark - Event handlers

- (void)addEventHandlers
{
	// enable standard control schemes
	[self addEventHandlersForHoldWASD];
	[self addEventHandlersForHoldArrows];
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
			[self nextLevel];
		}
	}
	else
	{
		// for each sphere
		float newInfluence = 0;
		for (int i=0; i<spheres.count; i++)
		{
			SCNNode *sphere = [spheres objectAtIndex:i];
			
			// if it's inside your influence
			if ([self isInXYZRange:myInfluence node:sphere])
			{
				sphere.geometry.materials = @[disconnectMaterial];
				// TODO: timestamp
				// TODO: animate fade out
				
				// disconnect yourself
				newInfluence += 1;
			}
			else
			{
				// reconnect spheres outside the influence
				// TODO: if enough time since disconnect timestamp
				//if (arc4random_uniform(20) == 0)  // if you're lucky
				//sphere.geometry.materials = @[connectMaterial];
			}
		}
		
		// TODO: passive healing
		// if (random chance)
		//		myInfluence -= 1;
		//		healLimit -= 1;
		
		myInfluence += newInfluence;
		NSLog(@"\nWarning: your influence has increased to %.f/%.f", myInfluence, maxInfluence);
		// TODO: update lights for new influence
		
		unsigned long connected = 0;
		for (int i=0; i<spheres.count; i++)
		{
			SCNNode *sphere = [spheres objectAtIndex:i];
			if ([sphere.geometry.materials isEqual: @[connectMaterial]])
				connected += 1;
		}
		//NSLog(@"spheres connected: %lu/%lu", connected, (unsigned long)spheres.count);
		
		if ((connected == 0) and (level < 10))  // TODO: max level variable
			[self nextLevel];
		else if (myInfluence > maxInfluence)
			[self badEnding];
		else if (myInfluence < 0)
			[self goodEnding];
	}
}

- (void)badEnding
{
	NSLog(@"bad ending");
	[self addMessage:[NSString stringWithFormat:@"You split into two.\nNeither survives."]];
}

- (void)goodEnding
{
	NSLog(@"good ending");
	[self addMessage:[NSString stringWithFormat:@"Slowly, the pain stops.\nYou are one."]];
}

@end
