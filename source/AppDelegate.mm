#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// load base scene with event handlers
	Scene *leftScene = [self getDefaultScene];
	Scene *rightScene = [self getDefaultScene];
	[leftScene setEye:@"left"];
	[rightScene setEye:@"right"];
	
	// connect the scene to the view
	[self.oculusView setScenesForLeft:leftScene right:rightScene];
	
	// connect the view to the window
	[_window setContentView:self.oculusView];
}

- (Scene*)getDefaultScene
{
	// get the class name of the default scene
	NSString *defaultSceneName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Default scene"];
	NSAssert(defaultSceneName != nil, @"No default scene name in Info.plist.");
	
    // create the default scene
	Class defaultSceneClass = NSClassFromString(defaultSceneName);
	NSAssert(defaultSceneClass != nil, @"No class for default scene named %@ in Info.plist.", defaultSceneName);
	return [defaultSceneClass scene];
}

- (SCNScene*)loadSceneAtURL:(NSURL*)url {
    NSDictionary *options = @{SCNSceneSourceCreateNormalsIfAbsentKey : @YES};
    
    // Load and set the scene.
    NSError * __autoreleasing error;
    SCNScene *scene = [SCNScene sceneWithURL:url options:options error:&error];
    if (scene) {
        return scene;
    }
    else {
        NSLog(@"Problem loading scene from %@\n%@", url, [error localizedDescription]);
		return nil;
    }
}

- (void)loadDAEFile
{
	// load file
	NSURL *url;
	//url = [NSURL URLWithString:@"file:///Path/to/file.dae"];
	//url = [NSURL URLWithString:@"http://www.path.to/file.dae"];
	//url = [[NSBundle mainBundle] URLForResource:@"avatar" withExtension:@"dae"];
	NSLog(@"Loading DAE file: %@", url);
	
	SCNSceneSource *sceneSource = [[SCNSceneSource alloc]initWithURL:url options:nil];
	NSArray *nodes = [sceneSource identifiersOfEntriesWithClass:[SCNNode class]];
	if ((!nodes) || (nodes.count == 0))
	{
		NSLog(@"  No nodes in DAE file");
	}
	else
	{
		Scene *leftScene  = [Scene currentLeftScene];
		Scene *rightScene = [Scene currentRightScene];
		
		//NSLog(@"DAE file contains: %@", nodes);
		SCNNode *subroot = [SCNNode node];
		for (int i=0; i < nodes.count; i++)
		{
			SCNNode *node = [sceneSource entryWithIdentifier:nodes[i] withClass:[SCNNode class]];
			SCNMaterial *material = [SCNMaterial material];
			material.diffuse.contents = [NSColor blueColor];
			node.geometry.materials = @[material];
			[subroot addChildNode:node];
			NSLog(@"  added node #%d: %@", i, nodes[i]);
		}
		//NSLog(@"using node %@", node);
		float scale = 200; // TODO: calculate this based on size of scene?
		SCNVector3 p = [[Scene currentLeftScene] headPosition];
		subroot.position = SCNVector3Make(p.x,p.y-scale,p.z);
		subroot.transform = CATransform3DScale(subroot.transform, scale, scale, scale);
		[leftScene.rootNode addChildNode:subroot];
		[rightScene.rootNode addChildNode:subroot];
	}
}

@end
