# LD48-30 Design Document

## Title

Autogenerated Code Name: Connected Bird

Working Title: Or Else They Will Disconnect You


## Autogenerated Description

I built a (random generator for this theme)[http://orteil.dashnet.org/randomgen/?gen=d7eFTPbP] and it gave me this:

	"Connected Bird: This game involves defending your hemispheres from something that wants to integrate it. There are no lands in this game.  Where is the sphere of influence? What is the best way to attach a dying black hole and an earth, then what if you weren't supplemental to something fun?"


## Design

This game involves keeping your Spheres from their natural state: synced between left and right eye worlds. You are *disconnecting* them, not connecting them, so the game gets physically harder to see/play as your field of view gets filled with objects that don't render correctly.

...except that's the wrong thing to do. Every time you disconnect a Sphere, you're also disconnecting your own body, which you can't see (unless there are mirrors). This expands your Sphere of Influence -- how close you have to be to something to disconnect it. (Maybe your SoI is *exactly* how far apart your body is?)

You are effectively a dying star about to become a black hole. If your SoI expands beyond a critical point, you won't be able to maintain physical integrity, and you will collapse to a point.

This is probably fatal.

Meanwhile, something is reintegrating the disconnected Spheres -- that is, something is *helping/healing* you, although the game misleads you into thinking it's a threat you should defend against. Letting it "kill" you is the good ending, disconnecting everything without overSoIing completes levels, overSoIing is the bad ending.

The game refers to SoIing a Sphere as "connecting" to it so the title can be Connecting instead of Disconnecting. Also, misdirection.

A higher level could have:
- more Spheres
- closer Spheres
- lower critical point
- higher SoI expansion rate
- slower Sphere reconnection
- slower/self reconnection
- no self reconnection (maybe whoever's helping you has a limit)


### Graphics and audio

There is no ground plane; you're a bird flying in the air, or maybe a "bird" flying in space (with distant constellations as visual landmarks), surrounded by spherical objects of various sizes.

- Literal bird, Spheres are eggs. Flapping sound during flight, sfxr glow on disconnect, cracking/hatching on reconnect (maybe I think I'm keeping my "eggs" warm and unbroken)
- Katamari, roll around and pickup random objects (except you don't take them with you, they just split in half when you SoI them).
- Spaceship, planets/moons/suns/etc. Engines, rocks being crushed.
- Star or space monster, enemy spaceships. End boss is a moon-sized military deathship. Slow pulse + fire crackle / space dragon wings + growl + fire / pew pew pew. BOOM.


### Controls

- passive interaction with any Sphere inside your SoI
- move forward: click/w, or maybe always flying in the direction you're facing? (need pausing, and a way to stay inside level bounds...didn't TW have something for this, something like adding your distance from the center as negative velocity if out of bounds?)
- pause/play: space is easiest to hit without looking, or maybe time only advances if a key is down or the Rift isn't still? (that is, autodetect someone taking it off and setting it down?).
- interact: space, maybe Rift-tap if that's as easy to do as it looks

I could collapse all that into "hold space to unpause/autofly in the direction you're facing". I'll need a keyboard interface for look up/down/left/right, for testing if not for non-Rift players.


### Technical issues

- I only have 2D movement implemented, but adding 3D should just be another rotation angle.
- Disconnected objects look really bad without chromatic unaberration.
- Can I make mirrors? I tried a reflective ground plane but it didn't look right. Maybe I can clone the player and fake the rest of the reflected scene. (Clone? The player doesn't have a body object in the first place, just a float for SoI.)
- Can't use real images of Earth for the jam, unless I want to draw it myself. Or, hand-drawn non-photorealistic virtual reality might look cool without taking much time.

### Secondary Features

- The Spheres are linked to some internet API, maybe there's more or less of them depending on time of day or your local weather or something, or maybe individual Spheres glow/change color in response to real-world events.
- Storyline for what/why you're doing this.
