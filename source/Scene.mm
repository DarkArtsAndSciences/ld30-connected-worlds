#import "Scene.h"

@implementation Scene
{
	
    SCNNode *headRotationNode, *headPositionNode;
    float hrx, hry, hrz;  // head rotation angles in radians
	
	NSMutableDictionary *keyDownHandlers, *keyUpHandlers, *mouseDownHandlers, *mouseUpHandlers;
    BOOL isMovingForward, isMovingBackward, isMovingLeft, isMovingRight;
}

@synthesize eye;
@synthesize roomSize;
@synthesize avatarHeight;
@synthesize avatarSpeed;
@synthesize turnSpeed;
@synthesize headPosition;

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
	
	// default sizes
    roomSize = 1000;
	avatarHeight = 100;
	avatarSpeed = 1;
	turnSpeed = 0.025;
	
	[self resetEventHandlers];  // initialize handler storage
	[self stopMoving];  // set all isMovings to NO
	
    return self;
}

// Register event handlers with the main window.
// Defaults are StepWASD and LeftMouseDownMoveForward.
- (void) addEventHandlers
{
	// default event handlers
	[self addEventHandlersForStepWASD];
	[self addEventHandlersForStepArrows];
	[self addEventHandlersForLeftMouseDownMoveForward];
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

#pragma mark - Avatar head position and rotation

- (Vector3f)vector3fFromSCNVector3:(SCNVector3)v { return Vector3f(v.x, v.y, v.z); }
- (SCNVector3)scnvector3FromVector3f:(Vector3f)v { return SCNVector3Make(v.x, v.y, v.z); }

- (Vector4f)vector4fFromSCNVector4:(SCNVector4)v { return Vector4f(v.x, v.y, v.z, v.w); }
- (SCNVector4)scnvector4FromVector4f:(Vector4f)v { return SCNVector4Make(v.x, v.y, v.z, v.w); }

// position is public, node is private
- (SCNVector3) headPosition { return headPositionNode.position; }
- (Vector3f) headPositionVector3f { return [self vector3fFromSCNVector3:headPositionNode.position]; }

- (void)setHeadPosition:(SCNVector3)position { headPositionNode.position = position; }
- (void)setHeadPositionVector3f:(Vector3f)position { headPositionNode.position = [self scnvector3FromVector3f:position]; }

- (Vector4f) headRotationVector4f { return [self vector4fFromSCNVector4:headRotationNode.rotation]; }

- (void)setHeadRotationX:(float)x Y:(float)y Z:(float)z
{
	//NSLog(@"set hr %.2fx %.2fy %.2fz", x, y, z);
	
    hrx = x;
    hry = y;
    hrz = z;
    
    CATransform3D transform    =      CATransform3DMakeRotation(x, 0, 1, 0);
    transform                  = CATransform3DRotate(transform, y, 1, 0, 0);
    headRotationNode.transform = CATransform3DRotate(transform, z, 0, 0, 1);
}
- (void)addHeadRotationX:(float)x Y:(float)y Z:(float)z
{
	//NSLog(@"add hr %.2fx %.2fy %.2fz", x, y, z);
	
    hrx = x;
    hry = y;
    hrz = z;
    
    CATransform3D transform    = headRotationNode.transform;
	transform				   = CATransform3DRotate(transform, x, 0, 1, 0);
    transform                  = CATransform3DRotate(transform, y, 1, 0, 0);
    headRotationNode.transform = CATransform3DRotate(transform, z, 0, 0, 1);
}
- (void)turnDirection:(Vector3f)direction distance:(float)distance
{
    Vector3f t = direction * distance;
	//NSLog(@"turn %.2f %.2f %.2f", t.x, t.y, t.z);
	[self addHeadRotationX:t.x Y:t.y Z:t.z];
}

- (void)turnUp	  { [self turnDirection:Vector3f(0,-1,0) distance:turnSpeed]; }
- (void)turnDown  { [self turnDirection:Vector3f(0, 1,0) distance:turnSpeed]; }
- (void)turnLeft  { [self turnDirection:Vector3f( 1,0,0) distance:turnSpeed]; }
- (void)turnRight { [self turnDirection:Vector3f(-1,0,0) distance:turnSpeed]; }

- (void)linkNodeToHeadPosition:(SCNNode*)node { [headPositionNode addChildNode:node]; }
- (void)linkNodeToHeadRotation:(SCNNode*)node { [headRotationNode addChildNode:node]; }


#pragma mark - Avatar movement
// TODO: add diagonal 2D movement (add and normalize vectors)
// MAYBE: add XY WASD movement (locked to world, not direction facing)

- (BOOL)isMoving { return isMovingForward || isMovingBackward || isMovingLeft || isMovingRight; }
- (void)stopMoving
{
	isMovingForward  = NO;
	isMovingBackward = NO;
	isMovingRight    = NO;
	isMovingLeft     = NO;
}

- (void)startMovingForward  { isMovingForward  = YES; }
- (void)startMovingBackward { isMovingBackward = YES; }
- (void)startMovingLeft     { isMovingLeft     = YES; }
- (void)startMovingRight    { isMovingRight	   = YES; }

- (void)stopMovingForward   { isMovingForward  = NO; }
- (void)stopMovingBackward  { isMovingBackward = NO; }
- (void)stopMovingLeft      { isMovingLeft     = NO; }
- (void)stopMovingRight     { isMovingRight    = NO; }

- (void)tick:(const CVTimeStamp *)timeStamp
{
	// TODO: convert timestamp to dt, distance *= dt
	
	BOOL canFly = YES;  // TODO: setter
	if (canFly)
	{
		if (isMovingForward)
			[self flyForward];
		else if (isMovingBackward)
			[self flyBackward];
		else if (isMovingLeft)
			[self flyLeft];
		else if (isMovingRight)
			[self flyRight];
	}
	else
	{
		if (isMovingForward)
			[self moveForward];
		else if (isMovingBackward)
			[self moveBackward];
		else if (isMovingLeft)
			[self moveLeft];
		else if (isMovingRight)
			[self moveRight];
	}
}

- (void)flyForward		{ [self move3Direction: Vector3f( 0, 0,-1) distance:avatarSpeed]; }
- (void)flyBackward		{ [self move3Direction: Vector3f( 0, 0, 1) distance:avatarSpeed]; }
- (void)flyLeft			{ [self move3Direction: Vector3f(-1, 0, 0) distance:avatarSpeed]; }
- (void)flyRight		{ [self move3Direction: Vector3f( 1, 0, 0) distance:avatarSpeed]; }
// TODO: and step? or store a multiplier somewhere?

- (void)moveForward		{ [self move2Direction: Vector3f( 0, 0,-1) distance:avatarSpeed]; }
- (void)moveBackward	{ [self move2Direction: Vector3f( 0, 0, 1) distance:avatarSpeed*0.75]; }
- (void)moveLeft		{ [self move2Direction: Vector3f(-1, 0, 0) distance:avatarSpeed*0.5]; }
- (void)moveRight		{ [self move2Direction: Vector3f( 1, 0, 0) distance:avatarSpeed*0.5]; }

- (void)stepForward		{ [self move2Direction: Vector3f( 0, 0,-1) distance:avatarSpeed*4]; }
- (void)stepBackward	{ [self move2Direction: Vector3f( 0, 0, 1) distance:avatarSpeed*3]; }
- (void)stepLeft		{ [self move2Direction: Vector3f(-1, 0, 0) distance:avatarSpeed*2]; }
- (void)stepRight		{ [self move2Direction: Vector3f( 1, 0, 0) distance:avatarSpeed*2]; }

- (void)runForward		{ [self move2Direction: Vector3f( 0, 0,-1) distance:avatarSpeed*10]; }
- (void)runBackward		{ [self move2Direction: Vector3f( 0, 0, 1) distance:avatarSpeed*7.5]; }
- (void)runLeft			{ [self move2Direction: Vector3f(-1, 0, 0) distance:avatarSpeed*5]; }
- (void)runRight		{ [self move2Direction: Vector3f( 1, 0, 0) distance:avatarSpeed*5]; }

- (BOOL)move2Direction:(Vector3f)direction
              distance:(float)distance
{
    return [self move2Direction:direction distance:distance facing:hrx];
}
- (BOOL)move2Direction:(Vector3f)direction  // in avatar space
              distance:(float)distance
                facing:(float)facing  // x rotation (yaw) in world space
{
    //NSLog(@"head position: %.2fx %.2fy %.2fz, moving %.2f radians * %.2f meters", self.headPosition.x, self.headPosition.y, self.headPosition.z, hrx, distance);
    
    Vector3f position = Vector3f(headPositionNode.position.x,
                                 headPositionNode.position.y,
                                 headPositionNode.position.z);
    
    Matrix4f rotate = Matrix4f::RotationY(facing);
    position += rotate.Transform(direction) * distance;

    headPositionNode.position = SCNVector3Make(position.x, position.y, position.z);
    
    //NSLog(@" new position: %.2fx %.2fy %.2fz", self.headPosition.x, self.headPosition.y, self.headPosition.z);
    // TODO: error handling, return NO if move failed
    return YES;
}

- (BOOL)move3Direction:(Vector3f)direction
              distance:(float)distance
{
    return [self move3Direction:direction distance:distance facing:hrx tilt:hry];
}
- (BOOL)move3Direction:(Vector3f)direction  // in avatar space
              distance:(float)distance
                facing:(float)facing  // x rotation (look left or right) in world space
				  tilt:(float)tilt  // y rotation (look up or down) in world space
{
    //NSLog(@"head position: %.2fx %.2fy %.2fz, moving %.2f radians * %.2f meters", self.headPosition.x, self.headPosition.y, self.headPosition.z, hrx, distance);
    
    Vector3f position = Vector3f(headPositionNode.position.x,
                                 headPositionNode.position.y,
                                 headPositionNode.position.z);
	
	// TODO: rotate direction by headRotation for non-world-locked?
	
    Matrix4f rotateY = Matrix4f::RotationY(facing);
    Matrix4f rotateX = Matrix4f::RotationX(tilt);
	Matrix4f rotate = rotateY * rotateX;
    position += rotate.Transform(direction) * distance;
	
    headPositionNode.position = SCNVector3Make(position.x, position.y, position.z);
    
    //NSLog(@" new position: %.2fx %.2fy %.2fz", self.headPosition.x, self.headPosition.y, self.headPosition.z);
    // TODO: error handling, return NO if move failed
    return YES;
}

- (BOOL)isInXZRange:(float)distance x:(float)x z:(float)z
{
	Vector2f avatarXZ = Vector2f(self.headPosition.x, self.headPosition.z);  // ignore y
	return avatarXZ.Distance(Vector2f(x, z)) <= distance;
}

- (BOOL)isInXYZRange:(float)distance x:(float)x y:(float)y z:(float)z
{
	Vector3f avatarXYZ = Vector3f(self.headPosition.x, self.headPosition.y, self.headPosition.z);
	Vector3f xyz = Vector3f(x, y, z);
	float myDistance = avatarXYZ.Distance(xyz);
	return myDistance <= distance;
}

- (BOOL)isInXYZRange:(float)distance node:(SCNNode*)node
{
	Vector3f avatarV = [self vector3fFromSCNVector3:self.headPosition];
	Vector3f nodeV = [self vector3fFromSCNVector3:node.position];
	float myDistance = avatarV.Distance(nodeV);
	BOOL isInRange = myDistance <= distance;
	return isInRange;
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

#pragma mark - Event handlers

- (void)resetEventHandlers
{
	keyDownHandlers = [NSMutableDictionary dictionary];
	keyUpHandlers = [NSMutableDictionary dictionary];
	mouseDownHandlers = [NSMutableDictionary dictionary];
	mouseUpHandlers = [NSMutableDictionary dictionary];
}

- (void)addEventHandlerForType:(NSEventType)eventType
						  name:(NSString*)eventName
					   handler:(SEL)eventHandler
{
	NSMutableDictionary *handlers = [self getHandlersForEventType:eventType];
	[handlers setObject:[NSValue valueWithPointer:eventHandler] forKey:eventName];
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

#pragma mark - Standard control schemes

// TODO: this is getting messy, is it possible to pass parameters to handlers?

- (void)addEventHandlersForStepWASD
{
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(stepLeft)]		forKey: @"0"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runLeft)]		forKey:@"+0"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(stepBackward)]	forKey: @"1"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runBackward)]	forKey:@"+1"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(stepRight)]		forKey: @"2"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runRight)]		forKey:@"+2"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(stepForward)]	forKey: @"13"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runForward)]		forKey:@"+13"];
}

- (void)addEventHandlersForHoldWASD
{
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingLeft)]	 forKey: @"0"];
	[keyUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingLeft)]		 forKey: @"0"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingBackward)] forKey: @"1"];
	[keyUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingBackward)]  forKey: @"1"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingRight)]	 forKey: @"2"];
	[keyUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingRight)]	 forKey: @"2"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingForward)]  forKey:@"13"];
	[keyUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingForward)]   forKey:@"13"];
}

// TODO: WASD, hold turn arrows, shift for "run" step turn
// MAYBE: on trackpad swipe
- (void)addEventHandlersForStepTurnArrows
{
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(turnLeft)]		forKey: @"123"];
	//[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runLeft)]		forKey:@"+123"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(turnRight)]		forKey: @"124"];
	//[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runRight)]		forKey:@"+124"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(turnDown)]	forKey: @"125"];
	//[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runBackward)]	forKey:@"+125"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(turnUp)]	forKey: @"126"];
	//[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runForward)]		forKey:@"+126"];
}

- (void)addEventHandlersForStepArrows  // move
{
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(turnLeft)]		forKey: @"123"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runLeft)]		forKey:@"+123"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(stepRight)]		forKey: @"124"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runRight)]		forKey:@"+124"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(stepBackward)]	forKey: @"125"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runBackward)]	forKey:@"+125"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(stepForward)]	forKey: @"126"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(runForward)]		forKey:@"+126"];
}

- (void)addEventHandlersForHoldArrows
{
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingLeft)]	 forKey:@"123"];
	[keyUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingLeft)]		 forKey:@"123"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingRight)]	 forKey:@"124"];
	[keyUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingRight)]	 forKey:@"124"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingBackward)] forKey:@"125"];
	[keyUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingBackward)]  forKey:@"125"];
	[keyDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingForward)]  forKey:@"126"];
	[keyUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingForward)]   forKey:@"126"];
}

- (void)addEventHandlersForLeftMouseDownMoveForward
{
	[mouseDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingForward)] forKey:@"left"];
	[mouseUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingForward)]  forKey:@"left"];
}
- (void)addEventHandlersForLeftMouseDownMoveBackward
{
	[mouseDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingForward)] forKey:@"left"];
	[mouseUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingForward)]  forKey:@"left"];
}
- (void)addEventHandlersForRightMouseDownMoveForward
{
	[mouseDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingForward)] forKey:@"right"];
	[mouseUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingForward)]  forKey:@"right"];
}
- (void)addEventHandlersForRightMouseDownMoveBackward
{
	[mouseDownHandlers setObject:[NSValue valueWithPointer:@selector(startMovingBackward)] forKey:@"right"];
	[mouseUpHandlers   setObject:[NSValue valueWithPointer:@selector(stopMovingBackward)]  forKey:@"right"];
}
//- (void)addEventHandlersForBothMouseDownMove  // TODO: both buttons at once
// TODO: QE turning
// TODO: defaults for space, return, esc?
// MAYBE: jump

@end
