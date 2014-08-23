#import "OculusRiftDevice.h"

@implementation OculusRiftDevice

@synthesize hmd;  // ovrHmd_Create(0) or ovrHmd_CreateDebug(ovrHmd_DK2)
@synthesize isDebugHmd;

- (id)init
{
    if (!(self = [super init])) return nil;
    
    // initialize the SDK
    ovr_Initialize();
    
    // initialize the HMD
    hmd = ovrHmd_Create(0);
    if ((isDebugHmd = (hmd == nil)))
    {
        NSLog(@"WARNING: no HMD detected, faking it");
        hmd = ovrHmd_CreateDebug(ovrHmd_DK2);
    }
    NSLog(@"using HMD: %s %s", hmd->ProductName, hmd->SerialNumber);
    
    [self configureSensor];
    
    return self;
}

+ (id)getDevice
{
	static OculusRiftDevice *device = nil;
	@synchronized(self)
	{
        if (device == nil)
            device = [[self alloc] init];
    }
	return device;
}

- (void)configureSensor
{
    // default: request all DK2 capabilities, but don't require them at startup
    // FUTURE: on new hardware, add its capabilities here
    unsigned int request = ovrTrackingCap_Orientation
    | ovrTrackingCap_MagYawCorrection
    | ovrTrackingCap_Position;
    unsigned int require = 0;
    [self configureSensorWithRequest:request andRequire:require];
}
- (void)configureSensorWithRequest:(unsigned int)request
                        andRequire:(unsigned int)require
{
    if (!ovrHmd_ConfigureTracking(hmd, request, require))
        NSLog(@"ERROR: no HMD with required caps %d", require);
    // TODO: error handling?
}

- (ovrTrackingState)getTrackingState
{
    return ovrHmd_GetTrackingState(hmd, ovr_GetTimeInSeconds());
}

- (void)getHeadRotationX:(float*)x Y:(float*)y Z:(float*)z
{
    // check for sensor data
    ovrTrackingState ts = [self getTrackingState];
    bool isTrackingHeadPose = ts.StatusFlags & (ovrStatus_OrientationTracked | ovrStatus_PositionTracked);
    if (!isTrackingHeadPose)
    {
        // TODO: popup warning for HMD out of camera range / unplugged
        //return CATransform3DMakeRotation(0, 0, 0, 0);
        *x = *y = *z = 0;  // TODO: what's the actual starting value?
        return;
    }
    
    // fill x,y,z with converted sensor data
    Posef pose = ts.HeadPose.ThePose;
    pose.Rotation.GetEulerAngles<Axis_Y, Axis_X, Axis_Z>(x, y, z);
}

- (void)shutdown
{
    if (hmd)
        ovrHmd_Destroy(hmd);
    
    ovr_Shutdown();
}

@end
