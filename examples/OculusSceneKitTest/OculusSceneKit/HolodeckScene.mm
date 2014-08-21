#import "HolodeckScene.h"

@implementation HolodeckScene
{
    CGFloat podiumRadius, podiumHeight, podiumGap;
    SCNVector3 podiumPosition;
}

- (id)init
{
    if (!(self = [super init])) return nil;
	
	super.roomSize = 1200;
	super.avatarHeight = 250;
	
    [self initHolodeck];
	
	return self;
}

- (void)initHolodeck
{
    podiumHeight = super.roomSize /   5;
    podiumRadius = super.roomSize /  25;
    podiumGap    = super.roomSize / 100;
    podiumPosition = SCNVector3Make(0.0, -super.roomSize/2, -super.roomSize/4);
    
    super.avatarSpeed  = 1;
    self.headPosition = SCNVector3Make(0.0, super.avatarHeight - super.roomSize/2, 0.0);
    SCNLight *avatarLight = [super makeAvatarSpotlight];
    avatarLight.color = [NSColor colorWithDeviceRed:1.0 green:0.98 blue:0.5 alpha:1.0];
    //avatarLight.color = [NSColor redColor];  // seeing red
    //avatarLight.gobo.contents = [NSImage imageNamed:@"Holodeck"];  // TODO: better image
    
    [self setupHolodeck];
    [self setupObjects];
}

- (void)setupHolodeck
{
    // create wall material
    NSImage *holodeckTexture = [NSImage imageNamed:@"Holodeck"];
    
    SCNMaterial *material = [SCNMaterial material];
    
    material.diffuse.minificationFilter  = SCNLinearFiltering;
    material.diffuse.magnificationFilter = SCNLinearFiltering;
    material.diffuse.mipFilter           = SCNLinearFiltering;
    
    material.diffuse.contents   = [NSColor blackColor];
    material.specular.contents  = holodeckTexture;  // lines are shiny yellow when lit
    material.emission.contents  = holodeckTexture;  // lines glow
    material.emission.intensity = 0.1;
    
    material.shininess = 0.75;
    
    // create walls
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:0.0 y:-super.roomSize/2 z:0.0 Rangle:-M_PI_2 x:1.0 y:0.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:0.0 y: super.roomSize/2 z:0.0 Rangle: M_PI_2 x:1.0 y:0.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:-super.roomSize/2 y:0.0 z:0.0 Rangle: M_PI_2 x:0.0 y:1.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx: super.roomSize/2 y:0.0 z:0.0 Rangle:-M_PI_2 x:0.0 y:1.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:0.0 y:0.0 z:-super.roomSize/2 Rangle:    0.0 x:0.0 y:0.0 z:0.0]];
    [self.rootNode addChildNode:[super makeWallWithMaterial:material Width:super.roomSize height:super.roomSize Tx:0.0 y:0.0 z: super.roomSize/2 Rangle:  -M_PI x:0.0 y:1.0 z:0.0]];
}

- (void)setupObjects
{
    SCNNode *objectsNode = [SCNNode node];
    [self.rootNode addChildNode:objectsNode];
    
    // Materials
    NSColor *goldColor             = [NSColor yellowColor];
    SCNMaterial *goldMaterial      = [SCNMaterial material];
    goldMaterial.diffuse.contents  = goldColor;
    goldMaterial.specular.contents = goldColor;
    
    NSColor *glowColor             = [NSColor colorWithDeviceRed:1.0 green:0.98 blue:0.6 alpha:1.0];
    SCNMaterial *glowMaterial      = [SCNMaterial material];
    glowMaterial.emission.contents = glowColor;
    glowMaterial.emission.intensity = 0.75;
    
    NSColor *silverColor             = [NSColor colorWithDeviceRed:0.98 green:0.98 blue:1.00 alpha:1.0];
    SCNMaterial *silverMaterial      = [SCNMaterial material];
    silverMaterial.diffuse.contents  = silverColor;
    silverMaterial.specular.contents = silverColor;
    
    // Silver cubes in corners
    float b = super.roomSize/2 - super.roomSize/10;
    SCNVector3 cubePositions[] =
    {
        SCNVector3Make( b,  b,  b),
        SCNVector3Make(-b,  b,  b),
        SCNVector3Make( b, -b,  b),
        SCNVector3Make(-b, -b,  b),
        SCNVector3Make( b,  b, -b),
        SCNVector3Make(-b,  b, -b),
        SCNVector3Make( b, -b, -b),
        SCNVector3Make(-b, -b, -b)
    };
    for (int i=0; i < sizeof(cubePositions) / sizeof(cubePositions[0]); i++)
        [objectsNode addChildNode:[self makeCubeWithSize:super.roomSize/10 chamfer:podiumGap materials:@[silverMaterial] position:cubePositions[i]]];
    
    // Silver podium base
    SCNCylinder *cylinder = [SCNCylinder cylinderWithRadius:podiumRadius height:1];
    cylinder.materials = @[silverMaterial];
    SCNNode *cylinderNode = [SCNNode nodeWithGeometry:cylinder];
    cylinderNode.position = SCNVector3Make(podiumPosition.x, podiumPosition.y, podiumRadius + podiumPosition.z);
    [objectsNode addChildNode:cylinderNode];
    
    SCNCylinder *cylinder2 = [SCNCylinder cylinderWithRadius:podiumRadius*0.75 height:podiumHeight*0.25];
    cylinder.materials = @[silverMaterial];
    SCNNode *cylinder2Node = [SCNNode nodeWithGeometry:cylinder2];
    cylinder2Node.position = SCNVector3Make(0.0, cylinder2.height/2, 0.0);
    [cylinderNode addChildNode:cylinder2Node];
    
    SCNCylinder *cylinder3 = [SCNCylinder cylinderWithRadius:podiumRadius*0.5 height:podiumHeight];
    cylinder.materials = @[silverMaterial];
    SCNNode *cylinder3Node = [SCNNode nodeWithGeometry:cylinder3];
    cylinder3Node.position = SCNVector3Make(0.0, cylinder3.height/2, 0.0);
    [cylinderNode addChildNode:cylinder3Node];
    
    // Large gold ball on podium
    int ballRadius = podiumRadius * 0.4;
    SCNSphere *ball = [SCNSphere sphereWithRadius:ballRadius];
    SCNNode *ballNode = [SCNNode nodeWithGeometry:ball];
    ballNode.position = SCNVector3Make(0, podiumHeight + podiumGap + ballRadius, 0);
    ball.materials = @[goldMaterial];
    [cylinderNode addChildNode:ballNode];
    
    // Silver ring around ball
    int ringRadius = podiumRadius * 0.8;
    SCNTorus *ring = [SCNTorus torusWithRingRadius:ringRadius pipeRadius:ringRadius/8];
    ring.materials = @[silverMaterial];
    SCNNode *ringNode = [SCNNode nodeWithGeometry:ring];
    [ballNode addChildNode:ringNode];
    
    // Glowing ball in ring (makes ring rotation visible)
    SCNSphere *ringStone = [SCNSphere sphereWithRadius:ringRadius/4];
    ringStone.materials = @[glowMaterial];
    SCNNode *ringStoneNode = [SCNNode nodeWithGeometry:ringStone];
    ringStoneNode.position = SCNVector3Make(ringRadius, 0, 0);
    [ringNode addChildNode:ringStoneNode];
    
	SCNLight *ballLight = [SCNLight light];
    SCNNode *ballLightNode = [SCNNode node];
    ballLight.type = SCNLightTypeOmni;
    ballLight.color = glowColor;
    ballLightNode.light = ballLight;
	[ringStoneNode addChildNode:ballLightNode];
    
    // rotate the ring around the ball
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 20;
    animation.repeatCount = HUGE_VALF;
    animation.values = [NSArray arrayWithObjects:
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 4 * M_PI_2, 0.f, 1.f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 3 * M_PI_2, 0.f, 1.f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 2 * M_PI_2, 0.f, 1.f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 1 * M_PI_2, 0.f, 1.f, 0.f)],
                        [NSValue valueWithCATransform3D:CATransform3DRotate(ringNode.transform, 0 * M_PI_2, 0.f, 1.f, 0.f)],
                        nil];
    [ringNode addAnimation:animation forKey:@"transform"];
    
    // Spinning golden question mark
    SCNText *questionMark = [SCNText textWithString:@"?" extrusionDepth:4];
    questionMark.materials = @[goldMaterial];
    questionMark.chamferRadius = 5;
    SCNNode *questionMarkNode = [SCNNode nodeWithGeometry:questionMark];
    questionMarkNode.position = SCNVector3Make(-10, podiumGap, 0);
    [ringStoneNode addChildNode:questionMarkNode];
    
    CAKeyframeAnimation *questionMarkAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    questionMarkAnimation.duration = 5;
    questionMarkAnimation.repeatCount = HUGE_VALF;
    questionMarkAnimation.values = [NSArray arrayWithObjects:
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 0 * M_PI_2, 0.f, 1.f, 0.f)],
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 1 * M_PI_2, 0.f, 1.f, 0.f)],
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 2 * M_PI_2, 0.f, 1.f, 0.f)],
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 3 * M_PI_2, 0.f, 1.f, 0.f)],
									[NSValue valueWithCATransform3D:CATransform3DRotate(ringStoneNode.transform, 4 * M_PI_2, 0.f, 1.f, 0.f)],
									nil];
    [ringStoneNode addAnimation:questionMarkAnimation forKey:@"transform"];
}

@end
