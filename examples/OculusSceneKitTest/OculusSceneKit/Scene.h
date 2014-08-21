#import <SceneKit/SceneKit.h>
#import "OVR.h"
using namespace OVR;

@interface Scene : SCNScene

@property SCNVector3 headPosition;

- (void)setHeadRotationX:(float)x Y:(float)y Z:(float)z;
- (void)linkNodeToHeadPosition:(SCNNode*)node;
- (void)linkNodeToHeadRotation:(SCNNode*)node;

- (void)tick:(const CVTimeStamp *)timeStamp;
- (void)startMoving;
- (void)stopMoving;

@end
