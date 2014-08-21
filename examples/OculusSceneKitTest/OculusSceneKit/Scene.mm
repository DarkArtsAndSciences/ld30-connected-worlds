#import "Scene.h"

@implementation Scene
{
    SCNNode *headRotationNode, *headPositionNode;
    float hrx, hry, hrz;  // head rotation angles in radians
    BOOL isMoving;
}

@synthesize roomSize;
@synthesize avatarHeight;
@synthesize avatarSpeed;
@synthesize headPosition;

- (id)init
{
    if (!(self = [super init])) return nil;
    
    // create nodes for eye cameras and head sensors
    headPositionNode = [SCNNode node];
    headRotationNode = [SCNNode node];
    [headPositionNode addChildNode:headRotationNode];
    [self.rootNode    addChildNode:headPositionNode];
	NSLog(@"Scene init: root node is %@", self.rootNode);
	
	// default sizes
    roomSize = 100;
	avatarHeight = 10;
	avatarSpeed = 1;
	
    isMoving = NO;
	
    return self;
}

static Scene *currentScene = nil;
+ (id)currentScene
{
	@synchronized(self)
	{
        if (currentScene == nil)
            currentScene = [[self alloc] init];
    }
	return currentScene;
}
+ (void)setCurrentScene:(Scene*)scene
{
	//NSLog(@"current scene: %@", scene);
	@synchronized(self)
	{
		currentScene = scene;
    }
}

#pragma mark -
#pragma mark In-scene head position and rotation

- (SCNVector3) headPosition { return headPositionNode.position; }  // position is public, node is private
- (void)setHeadPosition:(SCNVector3) position { headPositionNode.position = position; }

- (void)setHeadRotationX:(float)x Y:(float)y Z:(float)z
{
    hrx = x;
    hry = y;
    hrz = z;
    
    CATransform3D transform    =      CATransform3DMakeRotation(x, 0, 1, 0);
    transform                  = CATransform3DRotate(transform, y, 1, 0, 0);
    headRotationNode.transform = CATransform3DRotate(transform, z, 0, 0, 1);
}

- (void)linkNodeToHeadPosition:(SCNNode*)node { [headPositionNode addChildNode:node]; }
- (void)linkNodeToHeadRotation:(SCNNode*)node { [headRotationNode addChildNode:node]; }


#pragma mark -
#pragma mark Avatar movement

- (void)startMoving { isMoving = YES; }
- (void)stopMoving { isMoving = NO; }

- (void)tick:(const CVTimeStamp *)timeStamp
{
    if (isMoving)
        [self moveForward];
}

- (void)moveForward { [self move2Direction: Vector3f(0,0,-1)]; }
- (void)moveBackward { [self move2Direction: Vector3f(0,0,1)]; }
- (BOOL)move2Direction:(Vector3f)direction
{
    return [self move2Direction:direction distance:avatarSpeed facing:hrx];
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
} // TODO: 2D turning, 3D movement (flying instead of walking)


#pragma mark -
#pragma mark Convenience functions for creating lights and objects

// Make a spotlight that automatically points wherever the user looks.
- (SCNLight*)makeAvatarSpotlight
{
	SCNLight *avatarLight = [SCNLight light];
    avatarLight.type = SCNLightTypeSpot;
    avatarLight.castsShadow = YES;
    
    SCNNode *avatarLightNode = [SCNNode node];
    avatarLightNode.light = avatarLight;
    
	[self linkNodeToHeadRotation:avatarLightNode];
    
    return avatarLight; // caller can set light color, etc.
}
// Make an omnilight that automatically follows the user.
- (SCNLight*)makeAvatarOmnilight
{
	SCNLight *avatarLight = [SCNLight light];
    avatarLight.type = SCNLightTypeOmni;
    
    SCNNode *avatarLightNode = [SCNNode node];
    avatarLightNode.light = avatarLight;
    
	[self linkNodeToHeadPosition:avatarLightNode];
    
    return avatarLight; // caller can set light color, etc.
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
