#import "OVR.h"
using namespace OVR;

@interface OculusRiftDevice : NSObject

@property (assign, readonly) ovrHmd hmd;
@property (assign, readonly) bool   isDebugHmd;

- (void)getHeadRotationX:(float*)x Y:(float*)y Z:(float*)z;
- (void)shutdown;

@end
