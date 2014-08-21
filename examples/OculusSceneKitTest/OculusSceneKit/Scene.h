#import <SceneKit/SceneKit.h>
#import "OVR.h"
using namespace OVR;

@interface Scene : SCNScene

@property CGFloat roomSize, avatarHeight, avatarSpeed;
@property SCNVector3 headPosition;

+ (id)currentScene;
+ (void)setCurrentScene:(Scene*)scene;

- (void)setHeadRotationX:(float)x Y:(float)y Z:(float)z;
- (void)linkNodeToHeadPosition:(SCNNode*)node;
- (void)linkNodeToHeadRotation:(SCNNode*)node;

- (void)tick:(const CVTimeStamp *)timeStamp;
- (void)startMoving;
- (void)stopMoving;
- (void)moveForward;

- (SCNLight*)makeAvatarSpotlight;
- (SCNLight*)makeAvatarOmnilight;
- (SCNNode*)makeWallWithMaterial:(SCNMaterial*)material
						  Width:(float)width
						 height:(float)height
							 Tx:(float)tx
							  y:(float)ty
							  z:(float)tz
						 Rangle:(float)rangle
							  x:(float)rx
							  y:(float)ry
							  z:(float)rz;
- (SCNNode*)makeCubeWithSize:(float)size
                     chamfer:(float)chamfer
                   materials:(NSArray*)materials
                    position:(SCNVector3)position;

@end
