#import "Scene.h"
#import "OculusRiftDevice.h"

@implementation Scene
{
	
    SCNNode *headRotationNode, *headPositionNode;
    float hrx, hry, hrz;  // head rotation angles in radians
	
	NSMutableDictionary *keyDownHandlers, *keyUpHandlers, *mouseDownHandlers, *mouseUpHandlers;
    BOOL isMovingForward, isMovingBackward, isMovingLeft, isMovingRight, isMovingUp, isMovingDown;
	BOOL isTurningLeft, isTurningRight, isTurningUp, isTurningDown;
	BOOL canFly;
}

@synthesize eye;
@synthesize roomSize;
@synthesize avatarHeight;
@synthesize avatarSpeed, turnSpeed;  // movement speeds
@synthesize stepM, runM, tiltM, turnM;  // seconds (frames?) of movement per single keypress
@synthesize canFly;
@synthesize headPosition;

#pragma mark -


Vector3f leftV		= Vector3f(-1, 0, 0);
Vector3f rightV		= Vector3f( 1, 0, 0);
Vector3f upV		= Vector3f( 0,-1, 0);
Vector3f downV		= Vector3f( 0, 1, 0);
Vector3f forwardV	= Vector3f( 0, 0,-1);
Vector3f backwardV	= Vector3f( 0, 0, 1);

- (Vector3f)vector3fFromSCNVector3:(SCNVector3)v { return Vector3f(v.x, v.y, v.z); }
- (SCNVector3)scnvector3FromVector3f:(Vector3f)v { return SCNVector3Make(v.x, v.y, v.z); }

- (Vector4f)vector4fFromSCNVector4:(SCNVector4)v { return Vector4f(v.x, v.y, v.z, v.w); }
- (SCNVector4)scnvector4FromVector4f:(Vector4f)v { return SCNVector4Make(v.x, v.y, v.z, v.w); }

#pragma mark - Singleton

static Scene *currentLeftScene = nil;
+ (id)currentLeftScene
{
	@synchronized(self)
	{
        if (currentLeftScene == nil)
            currentLeftScene = [[self alloc] init];
    }
	return currentLeftScene;
}
static Scene *currentRightScene = nil;
+ (id)currentRightScene
{
	@synchronized(self)
	{
        if (currentRightScene == nil)
            currentRightScene = [[self alloc] init];
    }
	return currentRightScene;
}
+ (void)setCurrentSceneLeft:(Scene*)leftScene
					  right:(Scene*)rightScene
{
	@synchronized(self)
	{
		currentLeftScene = leftScene;
		currentRightScene = rightScene;
		[leftScene resetEventHandlers];
		[rightScene resetEventHandlers];
		[leftScene addEventHandlers];
		[rightScene addEventHandlers];
    }
}

static SCNRenderer *currentLeftRenderer = nil;
+ (id)currentLeftRenderer
{
	@synchronized(self)
	{
        if (currentLeftRenderer == nil)
            currentLeftRenderer = [[self alloc] init];
    }
	return currentLeftRenderer;
}
static SCNRenderer *currentRightRenderer = nil;
+ (id)currentRightRenderer
{
	@synchronized(self)
	{
        if (currentRightRenderer == nil)
            currentRightRenderer = [[self alloc] init];
    }
	return currentRightRenderer;
}
+ (void)setCurrentRendererLeft:(SCNRenderer*)leftRenderer
						 right:(SCNRenderer*)rightRenderer
{
	@synchronized(self)
	{
		currentLeftRenderer = leftRenderer;
		currentRightRenderer = rightRenderer;
	}
}

#pragma mark - Left or Right

- (BOOL)isLeft  { return [eye isEqual: @"left"]; }
- (BOOL)isRight { return [eye isEqual: @"right"]; }

- (NSString*)eye
{
	return eye;
}
- (void)setEye:(NSString*)theEye
{
	eye = theEye;
}

#pragma mark - Initialization

- (id)init
{
    if (!(self = [super init])) return nil;
    
    // create nodes for eye cameras and head sensors
    headPositionNode = [SCNNode node];
    headPositionNode.position = SCNVector3Make(0, 0, 0);
    headRotationNode = [SCNNode node];
    [headPositionNode addChildNode:headRotationNode];
    [self.rootNode    addChildNode:headPositionNode];
	
	// default settings
    roomSize = 1000;
	avatarHeight = 100;
	avatarSpeed = avatarHeight;
	turnSpeed = 0.25;
	tiltM = 2.0;
	turnM = 5.0; // TODO: turnSpeed * turnM = 45 degrees? 90?
	stepM = 2.0;
	runM  = 5.0;
	canFly = YES;
	
	[self resetEventHandlers];  // initialize handler storage
	[self stopMoving];  // set all isMovings to NO
	[self stopTurning];
	
    return self;
}

- (SCNNode*) loadNode:(NSString*)nodename
			  fromDae:(NSString*)filename
{
	// TODO: error handling
	NSURL *fileURL = [[NSBundle mainBundle] URLForResource:filename withExtension:@"dae"];
	if (!fileURL)
	{
		NSLog(@"no DAE file named %@", filename);
		return nil;
	}
	
	SCNScene *scene = [SCNScene sceneWithURL:fileURL options:nil error:nil];
	if (!scene)
	{
		NSLog(@"no scene in file %@.dae at %@", filename, fileURL);
		return nil;
	}
	
	SCNNode *node = [scene.rootNode childNodeWithName:nodename recursively:YES];
	if (!node)
		NSLog(@"no node named %@ in file %@.dae\n%@", nodename, filename, scene);
	return node;
}

#pragma mark - Range tests

- (BOOL)isInXZRange:(float)distance x:(float)x z:(float)z { return [self isInXYZRange:distance x:x y:0 z:z]; }
- (BOOL)isInXYZRange:(float)distance x:(float)x y:(float)y z:(float)z
{
	Vector3f avatarXYZ = Vector3f(self.headPosition.x, self.headPosition.y, self.headPosition.z);
	Vector3f xyz = Vector3f(x, y, z);
	float myDistance = avatarXYZ.Distance(xyz);
	return myDistance <= distance;
}

- (BOOL)isInXZRange:(float)distance node:(SCNNode*)node { return [self isInXZRange:distance x:node.position.x z:node.position.z]; }
- (BOOL)isInXYZRange:(float)distance node:(SCNNode*)node
{
	Vector3f avatarV = [self vector3fFromSCNVector3:self.headPosition];
	Vector3f nodeV = [self vector3fFromSCNVector3:node.position];
	float myDistance = avatarV.Distance(nodeV);
	return myDistance <= distance;
}

#pragma mark - Avatar head position and rotation

// position is public, node is private
- (SCNVector3) headPosition { return headPositionNode.position; }
- (Vector3f) headPositionVector3f { return [self vector3fFromSCNVector3:headPositionNode.position]; }

- (void)setHeadPosition:(SCNVector3)position { headPositionNode.position = position; }
- (void)setHeadPositionVector3f:(Vector3f)position { headPositionNode.position = [self scnvector3FromVector3f:position]; }

- (Vector4f) headRotationVector4f { return [self vector4fFromSCNVector4:headRotationNode.rotation]; }

- (void)linkNodeToHeadPosition:(SCNNode*)node { [headPositionNode addChildNode:node]; }
- (void)linkNodeToHeadRotation:(SCNNode*)node { [headRotationNode addChildNode:node]; }

- (void)setHeadRotationX:(float)x Y:(float)y Z:(float)z
{
    hrx = x;
    hry = y;
    hrz = z;
	[self updateHeadRotation];
}
- (void)addHeadRotationX:(float)x Y:(float)y Z:(float)z
{
    hrx += x;
    hry += y;
    hrz += z;
	[self updateHeadRotation];
	
	/*NSLog(@"head rotation + %.1fx %.1fy %.1fz = %.1fx %.1fy %.1fz",
		  RadToDegree(x), RadToDegree(y), RadToDegree(z),
		  RadToDegree(hrx), RadToDegree(hry), RadToDegree(hrz));*/
}
- (void)updateHeadRotation
{
    CATransform3D transform    =      CATransform3DMakeRotation(hrx, 0, 1, 0);
    transform                  = CATransform3DRotate(transform, hry, 1, 0, 0);
    headRotationNode.transform = CATransform3DRotate(transform, hrz, 0, 0, 1);
}

#pragma mark - Avatar movement

- (void)tick:(const CVTimeStamp *)timeStamp
{
	CGFloat dt = timeStamp->hostTime / CVGetHostClockFrequency();
	if ([self isMoving])  [self move:dt];
	if ([self isTurning]) [self turn:dt];
}

- (BOOL)isMoving { return isMovingForward || isMovingBackward || isMovingLeft || isMovingRight || isMovingUp || isMovingDown; }
- (void)stopMoving
{
	isMovingForward  = NO;
	isMovingBackward = NO;
	isMovingRight    = NO;
	isMovingLeft     = NO;
	isMovingUp		 = NO;
	isMovingDown	 = NO;
}

- (void)startMovingForward  { isMovingForward  = YES; }
- (void)startMovingBackward { isMovingBackward = YES; }
- (void)startMovingLeft     { isMovingLeft     = YES; }
- (void)startMovingRight    { isMovingRight	   = YES; }

- (void)stopMovingForward   { isMovingForward  = NO; }
- (void)stopMovingBackward  { isMovingBackward = NO; }
- (void)stopMovingLeft      { isMovingLeft     = NO; }
- (void)stopMovingRight     { isMovingRight    = NO; }

- (BOOL)isTurning { return isTurningUp || isTurningDown || isTurningLeft || isTurningRight; }
- (void)stopTurning
{
	isTurningUp		= NO;
	isTurningDown	= NO;
	isTurningRight	= NO;
	isTurningLeft	= NO;
}

- (void)startTurningForward  { isTurningUp		= YES; }
- (void)startTurningBackward { isTurningDown	= YES; }
- (void)startTurningLeft     { isTurningLeft	= YES; }
- (void)startTurningRight    { isTurningRight	= YES; }

- (void)stopTurningForward   { isTurningUp		= NO; }
- (void)stopTurningBackward  { isTurningDown	= NO; }
- (void)stopTurningLeft      { isTurningLeft	= NO; }
- (void)stopTurningRight     { isTurningRight	= NO; }

- (BOOL)move:(float)dt
{
	Vector3f direction;
	if (isMovingForward)
	{
		direction = forwardV;
	}
	else if (isMovingBackward)
	{
		direction = backwardV;
		dt *= canFly ? 1 : 0.75;
	}
	else if (isMovingLeft)
	{
		direction = leftV;
		dt *= canFly ? 1 : 0.5;
	}
	else if (isMovingRight)
	{
		direction = rightV;
		dt *= canFly ? 1 : 0.5;
	}
	
	return [self moveDirection:direction forTime:dt];
}

- (BOOL)moveDirection:(Vector3f)direction forTime:(float)dt
{
	if (canFly)
		return [self move3Direction:direction distance:dt * avatarSpeed];
	else
		return [self move2Direction:direction distance:dt * avatarSpeed];
}

- (BOOL)move2Direction:(Vector3f)direction distance:(float)distance
{ return [self move2Direction:direction distance:distance facing:hrx]; }
- (BOOL)move2Direction:(Vector3f)direction distance:(float)distance facing:(float)facing
{ return [self move3Direction:direction distance:distance facing:facing tilt:0]; }
- (BOOL)move3Direction:(Vector3f)direction distance:(float)distance
{ return [self move3Direction:direction distance:distance facing:hrx tilt:hry]; }
 
- (BOOL)move3Direction:(Vector3f)direction  // in avatar space
              distance:(float)distance
                facing:(float)facing  // x rotation (look left or right) in world space
				  tilt:(float)tilt  // y rotation (look up or down) in world space
{
    //NSLog(@"head position: %.2fx %.2fy %.2fz, moving %.2f radians * %.2f meters", self.headPosition.x, self.headPosition.y, self.headPosition.z, hrx, distance);
	
	// TODO: rotate direction by headRotation for non-world-locked?
	
	Matrix4f rotate = Matrix4f::RotationY(facing) * Matrix4f::RotationX(tilt);
	Vector3f move = rotate.Transform(direction) * distance;
	headPositionNode.transform = CATransform3DTranslate(headPositionNode.transform, move.x, move.y, move.z);
    
    //NSLog(@" new position: %.2fx %.2fy %.2fz", self.headPosition.x, self.headPosition.y, self.headPosition.z);
    // TODO: error handling, return NO if move failed
    return YES;
}

- (BOOL)turn:(float)dt
{
	Vector3f direction;
	if (isTurningUp)
	{
		direction = upV;
	}
	else if (isTurningDown)
	{
		direction = downV;
	}
	else if (isTurningLeft)
	{
		direction = leftV;
	}
	else if (isTurningRight)
	{
		direction = rightV;
	}
	return [self turnDirection:direction forTime:dt];
}
- (BOOL)turnDirection:(Vector3f)direction
{
	return [self turnDirection:direction forTime:turnM];
}
- (BOOL)turnDirection:(Vector3f)direction forTime:(float)dt
{
    Vector3f t = -direction * turnSpeed * dt;
	[self addHeadRotationX:t.x Y:t.y Z:t.z];
	return YES;  // TODO: NO if couldn't turn
}

#pragma mark - Standard control schemes

// Register event handlers with the main window.
// Defaults are HoldWASD for movement and (in debug mode) HoldTurnArrows.
- (void) addEventHandlers
{
	[self addEventHandlersForHoldWASD];
	
	if ([[OculusRiftDevice getDevice] isDebugHmd])  // TODO: check for turn sensor
		[self addEventHandlersForHoldTurnArrows];
}

- (void)addEventHandlersForStepWASD
{
	[keyDownHandlers setObject:@"stepLeft"				forKey: @"0"];
	[keyDownHandlers setObject:@"runLeft"				forKey:@"+0"];
	[keyDownHandlers setObject:@"stepBackward"			forKey: @"1"];
	[keyDownHandlers setObject:@"runBackward"			forKey:@"+1"];
	[keyDownHandlers setObject:@"stepRight"				forKey: @"2"];
	[keyDownHandlers setObject:@"runRight"				forKey:@"+2"];
	[keyDownHandlers setObject:@"stepForward"			forKey: @"13"];
	[keyDownHandlers setObject:@"runForward"			forKey:@"+13"];
}

- (void)addEventHandlersForHoldWASD
{
	[keyDownHandlers setObject:@"startMovingLeft"		forKey: @"0"];
	[keyUpHandlers   setObject:@"stopMovingLeft"		forKey: @"0"];
	[keyDownHandlers setObject:@"startMovingBackward"	forKey: @"1"];
	[keyUpHandlers   setObject:@"stopMovingBackward"	forKey: @"1"];
	[keyDownHandlers setObject:@"startMovingRight"		forKey: @"2"];
	[keyUpHandlers   setObject:@"stopMovingRight"		forKey: @"2"];
	[keyDownHandlers setObject:@"startMovingForward"	forKey:@"13"];
	[keyUpHandlers   setObject:@"stopMovingForward"		forKey:@"13"];
}

- (void)addEventHandlersForStepTurnArrows
{
	[keyDownHandlers setObject:@"tiltLeft"				forKey: @"123"];
	[keyDownHandlers setObject:@"turnLeft"				forKey:@"+123"];
	[keyDownHandlers setObject:@"tiltRight"				forKey: @"124"];
	[keyDownHandlers setObject:@"turnRight"				forKey:@"+124"];
	[keyDownHandlers setObject:@"tiltDown"				forKey: @"125"];
	[keyDownHandlers setObject:@"turnDown"				forKey:@"+125"];
	[keyDownHandlers setObject:@"tiltUp"				forKey: @"126"];
	[keyDownHandlers setObject:@"turnUp"				forKey:@"+126"];
}

- (void)addEventHandlersForStepMoveArrows
{
	[keyDownHandlers setObject:@"turnLeft"				forKey: @"123"];
	[keyDownHandlers setObject:@"runLeft"				forKey:@"+123"];
	[keyDownHandlers setObject:@"stepRight"				forKey: @"124"];
	[keyDownHandlers setObject:@"runRight"				forKey:@"+124"];
	[keyDownHandlers setObject:@"stepBackward"			forKey: @"125"];
	[keyDownHandlers setObject:@"runBackward"			forKey:@"+125"];
	[keyDownHandlers setObject:@"stepForward"			forKey: @"126"];
	[keyDownHandlers setObject:@"runForward"			forKey:@"+126"];
}

- (void)addEventHandlersForHoldTurnArrows
{
	[keyDownHandlers setObject:@"startTurningLeft"		forKey:@"123"];
	[keyUpHandlers   setObject:@"stopTurningLeft"		forKey:@"123"];
	[keyDownHandlers setObject:@"startTurningRight"		forKey:@"124"];
	[keyUpHandlers   setObject:@"stopTurningRight"		forKey:@"124"];
	[keyDownHandlers setObject:@"startTurningDown"		forKey:@"125"];
	[keyUpHandlers   setObject:@"stopTurningDown"		forKey:@"125"];
	[keyDownHandlers setObject:@"startTurningUp"		forKey:@"126"];
	[keyUpHandlers   setObject:@"stopTurningUp"			forKey:@"126"];
}

- (void)addEventHandlersForHoldMoveArrows
{
	[keyDownHandlers setObject:@"startMovingLeft"		forKey:@"123"];
	[keyUpHandlers   setObject:@"stopMovingLeft"		forKey:@"123"];
	[keyDownHandlers setObject:@"startMovingRight"		forKey:@"124"];
	[keyUpHandlers   setObject:@"stopMovingRight"		forKey:@"124"];
	[keyDownHandlers setObject:@"startMovingBackward"	forKey:@"125"];
	[keyUpHandlers   setObject:@"stopMovingBackward"	forKey:@"125"];
	[keyDownHandlers setObject:@"startMovingForward"	forKey:@"126"];
	[keyUpHandlers   setObject:@"stopMovingForward"		forKey:@"126"];
}

- (void)addEventHandlersForLeftMouseDownMoveForward
{
	[mouseDownHandlers setObject:@"startMovingForward"	forKey:@"left"];
	[mouseUpHandlers   setObject:@"stopMovingForward"	forKey:@"left"];
}
- (void)addEventHandlersForLeftMouseDownMoveBackward
{
	[mouseDownHandlers setObject:@"startMovingForward"	forKey:@"left"];
	[mouseUpHandlers   setObject:@"stopMovingForward"	forKey:@"left"];
}
- (void)addEventHandlersForRightMouseDownMoveForward
{
	[mouseDownHandlers setObject:@"startMovingForward"	forKey:@"right"];
	[mouseUpHandlers   setObject:@"stopMovingForward"	forKey:@"right"];
}
- (void)addEventHandlersForRightMouseDownMoveBackward
{
	[mouseDownHandlers setObject:@"startMovingBackward"	forKey:@"right"];
	[mouseUpHandlers   setObject:@"stopMovingBackward"	forKey:@"right"];
}

//- (void)addEventHandlersForBothMouseDownMove  // TODO: both buttons at once
// TODO: QE turning
// TODO: defaults for space, return, esc?

#pragma mark - Event handlers

- (void)doEvent:(NSString*)event
{
	((void (^)())@{
				   @"startMovingForward"	: ^{ isMovingForward = YES; },
				   @"startMovingBackward"	: ^{ isMovingBackward = YES; },
				   @"startMovingLeft"		: ^{ isMovingLeft = YES; },
				   @"startMovingRight"		: ^{ isMovingRight = YES; },
				   @"startMovingUp"			: ^{ isMovingUp = YES; },
				   @"startMovingDown"		: ^{ isMovingDown = YES; },
				   
				   @"stopMovingForward" 	: ^{ isMovingForward = NO; },
				   @"stopMovingBackward"	: ^{ isMovingBackward = NO; },
				   @"stopMovingLeft"		: ^{ isMovingLeft = NO; },
				   @"stopMovingRight"		: ^{ isMovingRight = NO; },
				   @"stopMovingUp"			: ^{ isMovingUp = NO; },
				   @"stopMovingDown"		: ^{ isMovingDown = NO; },
				   
				   @"startTurningLeft"		: ^{ isTurningLeft	= YES; },
				   @"startTurningRight"		: ^{ isTurningRight = YES; },
				   @"startTurningUp"		: ^{ isTurningUp	= YES; },
				   @"startTurningDown"		: ^{ isTurningDown	= YES; },
				   
				   @"stopTurningLeft"		: ^{ isTurningLeft	= NO; },
				   @"stopTurningRight"		: ^{ isTurningRight = NO; },
				   @"stopTurningUp"			: ^{ isTurningUp	= NO; },
				   @"stopTurningDown"		: ^{ isTurningDown	= NO; },
				   
				   @"stepForward"	 : ^{ [self moveDirection:forwardV	forTime:stepM]; },
				   @"stepBackward"	 : ^{ [self moveDirection:backwardV forTime:stepM]; },
				   @"stepLeft"		 : ^{ [self moveDirection:leftV		forTime:stepM]; },
				   @"stepRight"		 : ^{ [self moveDirection:rightV	forTime:stepM]; },
				   
				   @"runForward"	 : ^{ [self moveDirection:forwardV	forTime:runM];  },
				   @"runBackward"	 : ^{ [self moveDirection:backwardV forTime:runM];  },
				   @"runLeft"		 : ^{ [self moveDirection:leftV		forTime:runM];  },
				   @"runRight"		 : ^{ [self moveDirection:rightV	forTime:runM];  },
				   
				   @"turnLeft"		 : ^{ [self turnDirection:leftV		forTime:turnM]; },
				   @"turnRight"		 : ^{ [self turnDirection:rightV	forTime:turnM]; },
				   @"turnUp"		 : ^{ [self turnDirection:upV		forTime:turnM]; },
				   @"turnDown"		 : ^{ [self turnDirection:downV		forTime:turnM]; },
				   
				   @"tiltLeft"		 : ^{ [self turnDirection:leftV		forTime:tiltM]; },
				   @"tiltRight"		 : ^{ [self turnDirection:rightV	forTime:tiltM]; },
				   @"tiltUp"		 : ^{ [self turnDirection:upV		forTime:tiltM]; },
				   @"tiltDown"		 : ^{ [self turnDirection:downV		forTime:tiltM]; },
				   
				   }[event]			?: ^{ NSLog(@"override doEvent in your Scene subclass to handle %@ events", event); }
	 )();
}

- (void)resetEventHandlers
{
	keyDownHandlers   = [NSMutableDictionary dictionary];
	keyUpHandlers     = [NSMutableDictionary dictionary];
	mouseDownHandlers = [NSMutableDictionary dictionary];
	mouseUpHandlers   = [NSMutableDictionary dictionary];
}

- (void)addEventHandlerForType:(NSEventType)eventType
						  name:(NSString*)eventName
					   handler:(NSString*)eventHandler
{
	NSMutableDictionary *handlers = [self getHandlersForEventType:eventType];
	[handlers setObject:eventHandler forKey:eventName];
}

- (void)removeEventHandlerForType:(NSEventType)eventType
							 name:(NSString*)eventName
{
	NSMutableDictionary *handlers = [self getHandlersForEventType:eventType];
	[handlers removeObjectForKey:eventName];
}

- (NSMutableDictionary*)getHandlersForEventType:(NSEventType)eventType
{
	NSMutableDictionary *handlers;
	if (eventType == NSKeyUp)
		handlers = keyUpHandlers;
	else if (eventType == NSKeyDown)
		handlers = keyDownHandlers;
	else if ((eventType == NSLeftMouseUp) || (eventType == NSRightMouseUp))
		handlers = mouseUpHandlers;
	else if ((eventType == NSLeftMouseDown) || (eventType == NSRightMouseDown))
		handlers = mouseDownHandlers;
	else
	{
		//NSLog(@"tried to get event handlers for unrecognized event type %lu", (unsigned long)eventType);
		return nil;
	}
	return handlers;
}

#pragma mark - Convenience functions for creating lights and objects

// Make a spotlight that automatically points wherever the user looks.
- (SCNNode*)makeAvatarSpotlight
{
	SCNLight *avatarLight = [SCNLight light];
    avatarLight.type = SCNLightTypeSpot;
    avatarLight.castsShadow = YES;
    
    SCNNode *avatarLightNode = [SCNNode node];
    avatarLightNode.light = avatarLight;
    
	[self linkNodeToHeadRotation:avatarLightNode];
    
    return avatarLightNode; // caller can set light color, position, etc.
}
// Make an omnilight that automatically follows the user.
- (SCNNode*)makeAvatarOmnilight
{
	SCNLight *avatarLight = [SCNLight light];
    avatarLight.type = SCNLightTypeOmni;
    
    SCNNode *avatarLightNode = [SCNNode node];
    avatarLightNode.light = avatarLight;
    
	[self linkNodeToHeadPosition:avatarLightNode];
	
    return avatarLightNode; // caller can set light color, position etc.
}

// Make and place a wall.
- (SCNNode*)makeWallWithMaterial:(SCNMaterial*)material
						   Width:(float)width
						  height:(float)height
							  Tx:(float)tx
							   y:(float)ty
							   z:(float)tz
						  Rangle:(float)rangle
							   x:(float)rx
							   y:(float)ry
							   z:(float)rz
{
    SCNPlane *wall = [SCNPlane planeWithWidth:width height:height];
    wall.materials = @[material];
    
    CATransform3D transform = CATransform3DMakeTranslation(tx, ty, tz);
    transform = CATransform3DRotate(transform, rangle, rx, ry, rz);
    
    SCNNode *node = [SCNNode nodeWithGeometry:wall];
    node.transform = transform;
    
    return node;
}

// Make and place a cube.
- (SCNNode*)makeCubeWithSize:(float)size
                     chamfer:(float)chamfer
                   materials:(NSArray*)materials
                    position:(SCNVector3)position
{
    SCNBox *box = [SCNBox boxWithWidth:size height:size length:size chamferRadius:chamfer];
    box.materials = materials;
    
    SCNNode *node = [SCNNode nodeWithGeometry:box];
    node.position = position;
    return node;
}

@end
