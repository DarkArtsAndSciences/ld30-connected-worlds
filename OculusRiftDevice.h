#include "OVR.h"
using namespace OVR;

@interface OculusRiftDevice : NSObject

@property (assign, readonly) ovrHmd hmd;
@property (assign, readonly) bool   isDebugHmd;

- (CATransform3D)getHeadTransform;
- (void)shutdown;

@end
