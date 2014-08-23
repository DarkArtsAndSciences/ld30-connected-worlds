#import <SceneKit/SceneKit.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import "GLProgram.h"

#import "OculusRiftDevice.h"
#import "Scene.h"
#import "MainWindow.h"

@interface OculusRiftSceneKitView : NSOpenGLView <SCNSceneRendererDelegate>

- (void)setScenesForLeft:(SCNScene *)leftSCNScene
				   right:(SCNScene *)rightSCNScene;
- (CVReturn)renderTime:(const CVTimeStamp *)timeStamp;

@end
