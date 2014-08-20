//#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import "GLProgram.h"
#import "OculusRiftDevice.h"
#import "Scene.h"

@interface OculusRiftSceneKitView : NSOpenGLView <SCNSceneRendererDelegate>

@property(readwrite, retain, nonatomic) Scene *scene;
@property(readonly, retain) OculusRiftDevice *oculusRiftDevice;
@property(readwrite, nonatomic) CGFloat interpupillaryDistance;

- (CVReturn)renderTime:(const CVTimeStamp *)timeStamp;

@end
