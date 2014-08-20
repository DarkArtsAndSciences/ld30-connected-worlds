#import <SceneKit/SceneKit.h>

@interface Scene : SCNScene

@property SCNVector3 headPosition;
@property CATransform3D headRotation;

- (void)linkNodeToHeadPosition:(SCNNode*)node;
- (void)linkNodeToHeadRotation:(SCNNode*)node;

@end
