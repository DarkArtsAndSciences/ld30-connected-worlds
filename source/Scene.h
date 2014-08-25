#import <SceneKit/SceneKit.h>
#import "OVR.h"
using namespace OVR;

#import "MainWindow.h"

@interface Scene : SCNScene

@property NSString* eye;  // "left" or "right"
@property CGFloat roomSize, avatarHeight, avatarSpeed, turnSpeed;
@property SCNVector3 headPosition;

+ (id)currentLeftScene;
+ (id)currentRightScene;
+ (void)setCurrentSceneLeft:(Scene*)leftScene
					  right:(Scene*)rightScene;

- (BOOL)isLeft;
- (BOOL)isRight;
//- (NSString*)getEye;
- (void)setEye:(NSString*)theEye;

- (void)setHeadRotationX:(float)x Y:(float)y Z:(float)z;
- (void)linkNodeToHeadPosition:(SCNNode*)node;
- (void)linkNodeToHeadRotation:(SCNNode*)node;

- (void)tick:(const CVTimeStamp *)timeStamp;

- (BOOL)isInXZRange:(float)distance x:(float)x z:(float)z;
- (BOOL)isInXYZRange:(float)distance x:(float)x y:(float)y z:(float)z;
- (BOOL)isInXYZRange:(float)distance node:(SCNNode*)node;

- (SCNNode*)makeAvatarSpotlight;
- (SCNNode*)makeAvatarOmnilight;
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

- (void)resetEventHandlers;
- (void)addEventHandlerForType:(NSEventType)eventType
						  name:(NSString*)eventName
					   handler:(SEL)eventHandler;
- (void)removeEventHandlerForType:(NSEventType)eventType
							 name:(NSString*)eventName;
//- (NSMutableDictionary*)getHandlersForEventType:(NSEventType)eventType;

- (void)addEventHandlersForStepWASD;
- (void)addEventHandlersForHoldWASD;
- (void)addEventHandlersForStepTurnArrows;
- (void)addEventHandlersForStepArrows;
- (void)addEventHandlersForHoldArrows;
- (void)addEventHandlersForLeftMouseDownMoveForward;
- (void)addEventHandlersForLeftMouseDownMoveBackward;
- (void)addEventHandlersForRightMouseDownMoveForward;
- (void)addEventHandlersForRightMouseDownMoveBackward;

- (NSMutableDictionary*)getHandlersForEventType:(NSEventType)eventType;

@end
