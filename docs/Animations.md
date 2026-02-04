---
title: Hero animations
description: How to animate a widget to fly between two screens.
shortTitle: Hero
---

:::secondary What you'll learn
* The _hero_ refers to the widget that flies between screens.
* Create a hero animation using Flutter's Hero widget.
* Fly the hero from one screen to another.
* Animate the transformation of a hero's shape from circular to
    rectangular while flying it from one screen to another.
* The Hero widget in Flutter implements a style of animation
    commonly known as _shared element transitions_ or
    _shared element animations._
:::

You've probably seen hero animations many times. For example, a screen displays
a list of thumbnails representing items for sale.  Selecting an item flies it to
a new screen, containing more details and a "Buy" button. Flying an image from
one screen to another is called a _hero animation_ in Flutter, though the same
motion is sometimes referred to as a _shared element transition_.

You might want to watch this one-minute video introducing the Hero widget:

<YouTubeEmbed id="Be9UH1kXFDw" title="Hero | Flutter widget of the week"></YouTubeEmbed>

This guide demonstrates how to build standard hero animations, and hero
animations that transform the image from a circular shape to a square shape
during flight.

:::secondary Examples
This guide provides examples of each hero animation style at
the following links.

* [Standard hero animation code][]
* [Radial hero animation code][]
::

:::secondary New to Flutter?
This page assumes you know how to create a layout
using Flutter's widgets. For more information, see
[Building Layouts in Flutter][].
:::

:::tip Terminology
  A [_Route_][] describes a page or screen in a Flutter app.
:::

You can create this animation in Flutter with Hero widgets.
As the hero animates from the source to the destination route,
the destination route (minus the hero) fades into view.
Typically, heroes are small parts of the UI, like images,
that both routes have in common. From the user's perspective
the hero "flies" between the routes. This guide shows how
to create the following hero animations:

**Standard hero animations**<br>

A _standard hero animation_ flies the hero from one route to a new route,
usually landing at a different location and with a different size.

The following video (recorded at slow speed) shows a typical example.
Tapping the flippers in the center of the route flies them to the
upper left corner of a new, blue route, at a smaller size.
Tapping the flippers in the blue route (or using the device's
back-to-previous-route gesture) flies the flippers back to
the original route.

<YouTubeEmbed id="CEcFnqRDfgw" title="Standard hero animation in Flutter"></YouTubeEmbed>

**Radial hero animations**<br>

In _radial hero animation_, as the hero flies between routes
its shape appears to change from circular to rectangular.

The following video (recorded at slow speed),
shows an example of a radial hero animation. At the start, a
row of three circular images appears at the bottom of the route.
Tapping any of the circular images flies that image to a new route
that displays it with a square shape.
Tapping the square image flies the hero back to
the original route, displayed with a circular shape.

<YouTubeEmbed id="LWKENpwDKiM" title="Radial hero animation in Flutter"></YouTubeEmbed>

Before moving to the sections specific to
[standard](#standard-hero-animations)
or [radial](#radial-hero-animations) hero animations,
read [basic structure of a hero animation](#basic-structure)
to learn how to structure hero animation code,
and [behind the scenes](#behind-the-scenes) to understand
how Flutter performs a hero animation.

<a id="basic-structure"></a>

## Basic structure of a hero animation

:::secondary What's the point?
* Use two hero widgets in different routes but with matching tags to
    implement the animation.
* The Navigator manages a stack containing the app's routes.
* Pushing a route on or popping a route from the Navigator's stack
    triggers the animation.
* The Flutter framework calculates a rectangle tween,
    [`RectTween`][] that defines the hero's boundary
    as it flies from the source to the destination route.
    During its flight, the hero is moved to
    an application overlay, so that it appears on top of both routes.
:::

:::tip Terminology
If the concept of tweens or tweening is new to you,
check out the [Animations in Flutter tutorial][].
:::

Hero animations are implemented using two [`Hero`][]
widgets: one describing the widget in the source route,
and another describing the widget in the destination route.
From the user's point of view, the hero appears to be shared, and
only the programmer needs to understand this implementation detail.
Hero animation code has the following structure:

1. Define a starting Hero widget, referred to as the _source
   hero_. The hero specifies its graphical representation
   (typically an image), and an identifying tag, and is in
   the currently displayed widget tree as defined by the source route.
1. Define an ending Hero widget, referred to as the _destination hero_.
   This hero also specifies its graphical representation,
   and the same tag as the source hero.
   It's **essential that both hero widgets are created with
   the same tag**, typically an object that represents the
   underlying data. For best results, the heroes should have
   virtually identical widget trees.
1. Create a route that contains the destination hero.
   The destination route defines the widget tree that exists
   at the end of the animation.
1. Trigger the animation by pushing the destination route on the
   Navigator's stack. The Navigator push and pop operations trigger
   a hero animation for each pair of heroes with matching tags in
   the source and destination routes.

Flutter calculates the tween that animates the Hero's bounds from
the starting point to the endpoint (interpolating size and position),
and performs the animation in an overlay.

The next section describes Flutter's process in greater detail.

## Behind the scenes

The following describes how Flutter performs the
transition from one route to another.

![Before the transition the source hero appears in the source route](/assets/images/docs/ui/animations/hero-transition-0.png)

Before transition, the source hero waits in the source
route's widget tree. The destination route does not yet exist,
and the overlay is empty.

---

![The transition begins](/assets/images/docs/ui/animations/hero-transition-1.png)

Pushing a route to the `Navigator` triggers the animation.
At `t=0.0`, Flutter does the following:

* Calculates the destination hero's path, offscreen,
  using the curved motion as described in the Material
  motion spec. Flutter now knows where the hero ends up.

* Places the destination hero in the overlay,
  at the same location and size as the _source_ hero.
  Adding a hero to the overlay changes its Z-order so that it
  appears on top of all routes.

* Moves the source hero offscreen.

---

![The hero flies in the overlay to its final position and size](/assets/images/docs/ui/animations/hero-transition-2.png)

As the hero flies, its rectangular bounds are animated using
[Tween&lt;Rect&gt;][], specified in Hero's
[`createRectTween`][] property.
By default, Flutter uses an instance of
[`MaterialRectArcTween`][], which animates the
rectangle's opposing corners along a curved path.
(See [Radial hero animations][] for an example
that uses a different Tween animation.)

---

![When the transition is complete, the hero is moved from the overlay to the destination route](/assets/images/docs/ui/animations/hero-transition-3.png)

When the flight completes:

* Flutter moves the hero widget from the overlay to
  the destination route. The overlay is now empty.

* The destination hero appears in its final position
  in the destination route.

* The source hero is restored to its route.

---

Popping the route performs the same process,
animating the hero back to its size
and location in the source route.

### Essential classes

The examples in this guide use the following classes to
implement hero animations:

[`Hero`][]
: The widget that flies from the source to the destination route.
  Define one Hero for the source route and another for the
  destination route, and assign each the same tag.
  Flutter animates pairs of heroes with matching tags.

[`InkWell`][]
: Specifies what happens when tapping the hero.
  The `InkWell`'s `onTap()` method builds the
  new route and pushes it to the `Navigator`'s stack.

[`Navigator`][]
: The `Navigator` manages a stack of routes. Pushing a route on or
  popping a route from the `Navigator`'s stack triggers the animation.

[`Route`][]
: Specifies a screen or page. Most apps,
  beyond the most basic, have multiple routes.

## Standard hero animations

:::secondary What's the point?
* Specify a route using `MaterialPageRoute`, `CupertinoPageRoute`,
    or build a custom route using `PageRouteBuilder`.
    The examples in this section use MaterialPageRoute.
* Change the size of the image at the end of the transition by
    wrapping the destination's image in a `SizedBox`.
* Change the location of the image by placing the destination's
    image in a layout widget. These examples use `Container`.
:::

<a id="standard-hero-animation-code"></a>

:::secondary Standard hero animation code
Each of the following examples demonstrates flying an image from one
route to another. This guide describes the first example.

[hero_animation][]
: Encapsulates the hero code in a custom `PhotoHero` widget.
  Animates the hero's motion along a curved path,
  as described in the Material motion spec.

[basic_hero_animation][]
: Uses the hero widget directly.
  This more basic example, provided for your reference, isn't
  described in this guide.
:::

### What's going on?

Flying an image from one route to another is easy to implement
using Flutter's hero widget. When using `MaterialPageRoute`
to specify the new route, the image flies along a curved path,
as described by the [Material Design motion spec][].

[Create a new Flutter app][] and
update it using the files from the [hero_animation][].

To run the example:

* Tap on the home route's photo to fly the image to a new route
  showing the same photo at a different location and scale.
* Return to the previous route by tapping the image, or by using the
  device's back-to-the-previous-route gesture.
* You can slow the transition further using the `timeDilation`
  property.

### PhotoHero class

The custom PhotoHero class maintains the hero,
and its size, image, and behavior when tapped.
The PhotoHero builds the following widget tree:

<DashImage figure image="ui/animations/photohero-class.png" alt="PhotoHero class widget tree" />

Here's the code:

```dart
class PhotoHero extends StatelessWidget {
  const PhotoHero({
    super.key,
    required this.photo,
    this.onTap,
    required this.width,
  });

  final String photo;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Hero(
        tag: photo,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Image.asset(
              photo,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
```

Key information:

* The starting route is implicitly pushed by `MaterialApp` when
  `HeroAnimation` is provided as the app's home property.
* An `InkWell` wraps the image, making it trivial to add a tap
  gesture to the both the source and destination heroes.
* Defining the Material widget with a transparent color
  enables the image to "pop out" of the background as it
  flies to its destination.
* The `SizedBox` specifies the hero's size at the start and
  end of the animation.
* Setting the Image's `fit` property to `BoxFit.contain`,
  ensures that the image is as large as possible during the
  transition without changing its aspect ratio.

### HeroAnimation class

The `HeroAnimation` class creates the source and destination
PhotoHeroes, and sets up the transition.

Here's the code:

```dart
class HeroAnimation extends StatelessWidget {
  const HeroAnimation({super.key});

  Widget build(BuildContext context) {
    [!timeDilation = 5.0; // 1.0 means normal animation speed.!]

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Hero Animation'),
      ),
      body: Center(
        [!child: PhotoHero(!]
          photo: 'images/flippers-alpha.png',
          width: 300.0,
          [!onTap: ()!] {
            [!Navigator.of(context).push(MaterialPageRoute<void>(!]
              [!builder: (context)!] {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Flippers Page'),
                  ),
                  body: Container(
                    // Set background to blue to emphasize that it's a new route.
                    color: Colors.lightBlueAccent,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.topLeft,
                    [!child: PhotoHero(!]
                      photo: 'images/flippers-alpha.png',
                      width: 100.0,
                      [!onTap: ()!] {
                        [!Navigator.of(context).pop();!]
                      },
                    ),
                  ),
                );
              }
            ));
          },
        ),
      ),
    );
  }
}
```

Key information:

* When the user taps the `InkWell` containing the source hero,
  the code creates the destination route using `MaterialPageRoute`.
  Pushing the destination route to the `Navigator`'s stack triggers
  the animation.
* The `Container` positions the `PhotoHero` in the destination
  route's top-left corner, below the `AppBar`.
* The `onTap()` method for the destination `PhotoHero`
  pops the `Navigator`'s stack, triggering the animation
  that flies the `Hero` back to the original route.
* Use the `timeDilation` property to slow the transition
  while debugging.

---

## Radial hero animations

:::secondary What's the point?
* A _radial transformation_ animates a circular shape into a square
    shape.
* A radial _hero_ animation performs a radial transformation while
    flying the hero from the source route to the destination route.
* MaterialRectCenter&shy;Arc&shy;Tween defines the tween animation.
* Build the destination route using `PageRouteBuilder`.
:::

Flying a hero from one route to another as it transforms
from a circular shape to a rectangular shape is a slick
effect that you can implement using Hero widgets.
To accomplish this, the code animates the intersection of
two clip shapes: a circle and a square.
Throughout the animation, the circle clip (and the image)
scales from `minRadius` to `maxRadius`, while the square
clip maintains constant size. At the same time,
the image flies from its position in the source route to its
position in the destination route. For visual examples
of this transition, see [Radial transformation][]
in the Material motion spec.

This animation might seem complex (and it is), but you can **customize the
provided example to your needs.** The heavy lifting is done for you.

<a id="radial-hero-animation-code"></a>

:::secondary Radial hero animation code
Each of the following examples demonstrates a radial hero animation.
This guide describes the first example.

[radial_hero_animation][]
: A radial hero animation as described in the Material motion spec.

[basic_radial_hero_animation][]
: The simplest example of a radial hero animation. The destination
  route has no Scaffold, Card, Column, or Text.
  This basic example, provided for your reference, isn't
  described in this guide.

[radial_hero_animation_animate<wbr>_rectclip][]
: Extends radial_hero_animation by also animating the size of the
  rectangular clip. This more advanced example,
  provided for your reference, isn't described in this guide.
:::

:::tip Pro tip
The radial hero animation involves intersecting a round shape with
a square shape. This can be hard to see, even when slowing
the animation with `timeDilation`, so you might consider enabling
the [`debugPaintSizeEnabled`][] flag during development.
:::

### What's going on?

The following diagram shows the clipped image at the beginning
(`t = 0.0`), and the end (`t = 1.0`) of the animation.

![Radial transformation from beginning to end](/assets/images/docs/ui/animations/radial-hero-animation.png)

The blue gradient (representing the image), indicates where the clip
shapes intersect. At the beginning of the transition,
the result of the intersection is a circular clip ([`ClipOval`][]).
During the transformation, the `ClipOval` scales from `minRadius`
to `maxRadius` while the [ClipRect][] maintains a constant size.
At the end of the transition the intersection of the circular and
rectangular clips yield a rectangle that's the same size as the hero
widget. In other words, at the end of the transition the image is no
longer clipped.

[Create a new Flutter app][] and
update it using the files from the
[radial_hero_animation][] GitHub directory.

To run the example:

* Tap on one of the three circular thumbnails to animate the image
  to a larger square positioned in the middle of a new route that
  obscures the original route.
* Return to the previous route by tapping the image, or by using the
  device's back-to-the-previous-route gesture.
* You can slow the transition further using the `timeDilation`
  property.

### Photo class

The `Photo` class builds the widget tree that holds the image:

```dart
class Photo extends StatelessWidget {
  const Photo({super.key, required this.photo, this.color, this.onTap});

  final String photo;
  final Color? color;
  final VoidCallback onTap;

  Widget build(BuildContext context) {
    return [!Material(!]
      // Slightly opaque color appears where the image has transparency.
      [!color: Theme.of(context).primaryColor.withValues(alpha: 0.25),!]
      child: [!InkWell(!]
        onTap: [!onTap,!]
        child: [!Image.asset(!]
          photo,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
```

Key information:

* The `InkWell` captures the tap gesture.
  The calling function passes the `onTap()` function to the
  `Photo`'s constructor.
* During flight, the `InkWell` draws its splash on its first
  Material ancestor.
* The Material widget has a slightly opaque color, so the
  transparent portions of the image are rendered with color.
  This ensures that the circle-to-square transition is easy to see,
  even for images with transparency.
* The `Photo` class does not include the `Hero` in its widget tree.
  For the animation to work, the hero
  wraps the `RadialExpansion` widget.

### RadialExpansion class

The `RadialExpansion` widget, the core of the demo, builds the
widget tree that clips the image during the transition.
The clipped shape results from the intersection of a circular clip
(that grows during flight),
with a rectangular clip (that remains a constant size throughout).

To do this, it builds the following widget tree:

<DashImage figure image="ui/animations/radial-expansion-class.png" alt="RadialExpansion widget tree" />

Here's the code:

```dart
class RadialExpansion extends StatelessWidget {
  const RadialExpansion({
    super.key,
    required this.maxRadius,
    this.child,
  }) : [!clipRectSize = 2.0 * (maxRadius / math.sqrt2);!]

  final double maxRadius;
  final double clipRectSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return [!ClipOval(!]
      child: [!Center(!]
        child: [!SizedBox(!]
          width: clipRectSize,
          height: clipRectSize,
          child: [!ClipRect(!]
            child: [!child,!] // Photo
          ),
        ),
      ),
    );
  }
}
```

Key information:

* The hero wraps the `RadialExpansion` widget.
* As the hero flies, its size changes and,
  because it constrains its child's size,
  the `RadialExpansion` widget changes size to match.
* The `RadialExpansion` animation is created by two overlapping clips.
* The example defines the tweening interpolation using
  [`MaterialRectCenterArcTween`][].
  The default flight path for a hero animation
  interpolates the tweens using the corners of the heroes.
  This approach affects the hero's aspect ratio during
  the radial transformation, so the new flight path uses
  `MaterialRectCenterArcTween` to interpolate the tweens using the
  center point of each hero.

  Here's the code:

  ```dart
  static RectTween _createRectTween(Rect? begin, Rect? end) {
    return MaterialRectCenterArcTween(begin: begin, end: end);
  }
  ```

  The hero's flight path still follows an arc,
  but the image's aspect ratio remains constant.

[Animations in Flutter tutorial]: /ui/animations/tutorial
[basic_hero_animation]: {{site.repo.this}}/tree/{{site.branch}}/examples/_animation/basic_hero_animation/
[basic_radial_hero_animation]: {{site.repo.this}}/tree/{{site.branch}}/examples/_animation/basic_radial_hero_animation
[Building Layouts in Flutter]: /ui/layout
[`ClipOval`]: {{site.api}}/flutter/widgets/ClipOval-class.html
[ClipRect]: {{site.api}}/flutter/widgets/ClipRect-class.html
[Create a new Flutter app]: /reference/create-new-app
[`createRectTween`]: {{site.api}}/flutter/widgets/CreateRectTween.html
[`debugPaintSizeEnabled`]: /tools/devtools/inspector#debugging-layout-issues-visually
[`Hero`]: {{site.api}}/flutter/widgets/Hero-class.html
[hero_animation]: {{site.repo.this}}/tree/{{site.branch}}/examples/_animation/hero_animation/
[`InkWell`]: {{site.api}}/flutter/material/InkWell-class.html
[Material Design motion spec]: {{site.material2}}/design/motion/understanding-motion.html#principles
[`MaterialRectArcTween`]: {{site.api}}/flutter/material/MaterialRectArcTween-class.html
[`MaterialRectCenterArcTween`]: {{site.api}}/flutter/material/MaterialRectCenterArcTween-class.html
[`Navigator`]: {{site.api}}/flutter/widgets/Navigator-class.html
[Radial hero animation code]: #radial-hero-animation-code
[radial_hero_animation]: {{site.repo.this}}/tree/{{site.branch}}/examples/_animation/radial_hero_animation
[radial_hero_animation_animate<wbr>_rectclip]: {{site.repo.this}}/tree/{{site.branch}}/examples/_animation/radial_hero_animation_animate_rectclip
[Radial hero animations]: #radial-hero-animations
[Radial transformation]: https://web.archive.org/web/20180223140424/https://material.io/guidelines/motion/transforming-material.html
[`RectTween`]: {{site.api}}/flutter/animation/RectTween-class.html
[_Route_]: /cookbook/navigation/navigation-basics
[`Route`]: {{site.api}}/flutter/widgets/Route-class.html
[Standard hero animation code]: #standard-hero-animation-code
[Tween&lt;Rect&gt;]: {{site.api}}/flutter/animation/Tween-class.html




---
title: Implicit animations
description: Where to find more information on using implicit animations in Flutter.
---

With Flutter's [animation library][],
you can add motion and create visual effects
for the widgets in your UI.
One part of the library is an assortment of widgets
that manage animations for you.
These widgets are collectively referred to as _implicit animations_,
or _implicitly animated widgets_, deriving their name from the
[`ImplicitlyAnimatedWidget`][] class that they implement.
The following set of resources provide many ways to learn
about implicit animations in Flutter.

[animation library]: {{site.api}}/flutter/animation/animation-library.html

## Documentation

[Animations in Flutter codelab][]
: Learn about implicit and explicit animations 
  and get hands-on experience adding implicit animations
  to a complete Flutter app.

[`AnimatedContainer` sample][]
: A step-by-step recipe for using the
  [`AnimatedContainer`][] implicitly animated widget.

[`ImplicitlyAnimatedWidget`][] API page
: All implicit animations extend the `ImplicitlyAnimatedWidget` class.

[Animations in Flutter codelab]: {{site.codelabs}}/advanced-flutter-animations
[`AnimatedContainer` sample]: /cookbook/animation/animated-container
[`AnimatedContainer`]: {{site.api}}/flutter/widgets/AnimatedContainer-class.html
[`ImplicitlyAnimatedWidget`]: {{site.api}}/flutter/widgets/ImplicitlyAnimatedWidget-class.html

## Flutter in Focus videos

Flutter in Focus videos feature 5-10 minute tutorials
with real code that cover techniques
that every Flutter dev needs to know from top to bottom.
The following videos cover topics
that are relevant to implicit animations.

<YouTubeEmbed id="IVTjpW3W33s" title="Flutter implicit animation basics"></YouTubeEmbed>

<YouTubeEmbed id="6KiPEqzJIKQ" title="Create custom implicit animations with TweenAnimationBuilder"></YouTubeEmbed>

## The Boring Show

Watch the Boring Show to follow Google Engineers build apps
from scratch in Flutter. The following episode covers
using implicit animations in a news aggregator app.

<YouTubeEmbed id="8ehlWchLVlQ" title="Adding implicit animations to a news application"></YouTubeEmbed>

## Widget of the Week videos

A weekly series of short animated videos each showing
the important features of one particular widget.
In about 60 seconds, you'll see real code for each
widget with a demo about how it works.
The following Widget of the Week videos cover
implicitly animated widgets:

<div class="card-grid wide">
  <div class="card wrapped-card outlined-card">
    <div class="card-content">
      <YouTubeEmbed id="QZAvjqOqiLY" title="AnimatedOpacity - Flutter widget of the week"></YouTubeEmbed>
    </div>
  </div>
  <div class="card wrapped-card outlined-card">
    <div class="card-content">
      <YouTubeEmbed id="PY2m0fhGNz4" title="AnimatedPadding - Flutter widget of the week"></YouTubeEmbed>
    </div>
  </div>
  <div class="card wrapped-card outlined-card">
    <div class="card-content">
      <YouTubeEmbed id="hC3s2YdtWt8" title="AnimatedPositioned - Flutter widget of the week"></YouTubeEmbed>
    </div>
  </div>
  <div class="card wrapped-card outlined-card">
    <div class="card-content">
      <YouTubeEmbed id="2W7POjFb88g" title="AnimatedSwitcher - Flutter widget of the week"></YouTubeEmbed>
    </div>
  </div>
</div>


---
title: Introduction to animations
shortTitle: Animations
description: How to perform animations in Flutter.
---

Well-designed animations make a UI feel more intuitive,
contribute to the slick look and feel of a polished app,
and improve the user experience.
Flutter's animation support makes it easy to implement a variety of
animation types. Many widgets, especially [Material widgets][],
come with the standard motion effects defined in their design spec,
but it's also possible to customize these effects.

## Choosing an approach

There are different approaches you can take when creating
animations in Flutter. Which approach is right for you?
To help you decide, check out the video,
[How to choose which Flutter Animation Widget is right for you?][]
(Also published as a [_companion article_][article1].)

<YouTubeEmbed id="GXIJJkq_H8g" title="How to choose which Flutter animation widget is right for your use case"></YouTubeEmbed>

(To dive deeper into the decision process,
watch the [Animations in Flutter done right][] video,
presented at Flutter Europe.)

As shown in the video, the following
decision tree helps you decide what approach
to use when implementing a Flutter animation:

<img src='/assets/images/docs/ui/animations/animation-decision-tree.png' alt="The animation decision tree">

## Animation deep dive

For a deeper understanding of just how animations work in Flutter, watch
[Animation deep dive][].
(Also published as a [_companion article_][article6].)

<YouTubeEmbed id="PbcILiN8rbo" title="Take a deep dive into Flutter animation"></YouTubeEmbed>

## Implicit and explicit animations

### Pre-packaged implicit animations

If a pre-packaged implicit animation (the easiest animation
to implement) suits your needs, watch
[Animation basics with implicit animations][].
(Also published as a [_companion article_][article2].)

<YouTubeEmbed id="IVTjpW3W33s" title="Flutter implicit animation basics"></YouTubeEmbed>

### Custom implicit animations

To create a custom implicit animation, watch
[Creating your own custom implicit animations with TweenAnimationBuilder][].
(Also published as a [_companion article_][article3].)

<YouTubeEmbed id="6KiPEqzJIKQ" title="Create custom implicit animations with TweenAnimationBuilder"></YouTubeEmbed>

### Built-in explicit animations

To create an explicit animation (where you control the animation,
rather than letting the framework control it), perhaps
you can use one of the built-in explicit animations classes.
For more information, watch
[Making your first directional animations with
built-in explicit animations][].
(Also published as a [_companion article_][article4].)

<YouTubeEmbed id="CunyH6unILQ" title="Making your first directional animations with built-in explicit animations"></YouTubeEmbed>

### Explicit animations

If you need to build an explicit animation from scratch, watch
[Creating custom explicit animations with
AnimatedBuilder and AnimatedWidget][].
(Also published as a [_companion article_][article5].)

<YouTubeEmbed id="fneC7t4R_B0" title="Creating custom explicit animations with AnimatedBuilder and AnimatedWidget"></YouTubeEmbed>

## Animation types

Generally, animations are either tween- or physics-based.
The following sections explain what these terms mean,
and point you to resources where you can learn more.

### Tween animation

Short for _in-betweening_. In a tween animation, the beginning
and ending points are defined, as well as a timeline, and a curve
that defines the timing and speed of the transition.
The framework calculates how to transition from the beginning point
to the end point.

* See the [Animations tutorial][], which uses tweens in the examples.

* Also see the API documentation for [`Tween`][], [`CurveTween`][], and
  [`TweenSequence`][].

### Physics-based animation

In physics-based animation, motion is modeled to resemble real-world
behavior. When you toss a ball, for example, where and when it lands
depends on how fast it was tossed and how far it was from the ground.
Similarly, dropping a ball attached to a spring falls
(and bounces) differently than dropping a ball attached to a string.

* [Animate a widget using a physics simulation][]<br>
  A recipe in the animations section of the Flutter cookbook.

* Also see the API documentation for
  [`AnimationController.animateWith`][] and
  [`SpringSimulation`][].

## Common animation patterns

Most UX or motion designers find that certain
animation patterns are used repeatedly when designing a UI.
This section lists some of the commonly
used animation patterns, and tells you where to learn more.

### Animated list or grid

This pattern involves animating the addition or removal of
elements from a list or grid.

* [`AnimatedList` example][]<br>
  This demo, from the [Sample app catalog][], shows how to
  animate adding an element to a list, or removing a selected element.
  The internal Dart list is synced as the user modifies the list using
  the plus (+) and minus (-) buttons.

### Shared element transition

In this pattern, the user selects an element&mdash;often an
image&mdash;from the page, and the UI animates the selected element
to a new page with more detail. In Flutter, you can easily implement
shared element transitions between routes (pages)
using the `Hero` widget.

* [Hero animations][]
  How to create two styles of Hero animations:
  * The hero flies from one page to another while changing position
    and size.
  * The hero's boundary changes shape, from a circle to a square,
    as its flies from one page to another.

* Also see the API documentation for the
  [`Hero`][], [`Navigator`][], and [`PageRoute`][] classes.

### Staggered animation

Animations that are broken into smaller motions,
where some of the motion is delayed.
The smaller animations might be sequential,
or might partially or completely overlap.

* [Staggered Animations][]

<a id="concepts"></a>

## Essential animation concepts and classes

The animation system in Flutter is based on typed
[`Animation`][] objects. Widgets can either incorporate
these animations in their build functions directly by
reading their current value and listening to their state
changes or they can use the animations as the basis of
more elaborate animations that they pass along to
other widgets.

<a id="animation-class"></a>

### Animation<wbr>\<double>

In Flutter, an `Animation` object knows nothing about what
is onscreen. An `Animation` is an abstract class that
understands its current value and its state (completed or dismissed).
One of the more commonly used animation types is `Animation<double>`.

An `Animation` object sequentially generates
interpolated numbers between two values over a certain duration.
The output of an `Animation` object might be linear,
a curve, a step function, or any other mapping you can create.
Depending on how the `Animation` object is controlled,
it could run in reverse, or even switch directions in the
middle.

Animations can also interpolate types other than double, such as
`Animation<Color>` or `Animation<Size>`.

An `Animation` object has state. Its current value is
always available in the `.value` member.

An `Animation` object knows nothing about rendering or
`build()` functions.

### CurvedAnimation

A [`CurvedAnimation`][] defines the animation's progress
as a non-linear curve.

<?code-excerpt "animation/animate5/lib/main.dart (CurvedAnimation)"?>
```dart
animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
```

`CurvedAnimation` and `AnimationController` (described in the next sections)
are both of type `Animation<double>`, so you can pass them interchangeably.
The `CurvedAnimation` wraps the object it's modifying&mdash;you
don't subclass `AnimationController` to implement a curve.

You can use [`Curves`][] with `CurvedAnimation`. The `Curves` class defines
many commonly used curves, or you can create your own. For example:

<?code-excerpt "animation/animate5/lib/main.dart (ShakeCurve)" plaster="none"?>
```dart
import 'dart:math';

class ShakeCurve extends Curve {
  @override
  double transform(double t) => sin(t * pi * 2);
}
```

If you want to apply an animation curve to a `Tween`, consider using
[`CurveTween`][].

### AnimationController

[`AnimationController`][] is a special `Animation`
object that generates a new value whenever the hardware
is ready for a new frame. By default,
an `AnimationController` linearly produces the numbers
from 0.0 to 1.0 during a given duration.
For example, this code creates an `Animation` object,
but does not start it running:

<?code-excerpt "animation/animate5/lib/main.dart (animation-controller)"?>
```dart
controller = AnimationController(
  duration: const Duration(seconds: 2),
  vsync: this,
);
```

`AnimationController` derives from `Animation<double>`, so it can be used
wherever an `Animation` object is needed. However, the `AnimationController`
has additional methods to control the animation. For example, you start
an animation with the `.forward()` method. The generation of numbers is
tied to the screen refresh, so typically 60 numbers are generated per
second. After each number is generated, each `Animation` object calls the
attached `Listener` objects. To create a custom display list for each
child, see [`RepaintBoundary`][].

When creating an `AnimationController`, you pass it a `vsync` argument.
The presence of `vsync` prevents offscreen animations from consuming
unnecessary resources.
You can use your stateful object as the vsync by adding
`SingleTickerProviderStateMixin` to the class definition.
You can see an example of this in [animate1][] on GitHub.

{% comment %}
The `vsync` object ties the ticking of the animation controller to
the visibility of the widget, so that when the animating widget goes
off-screen, the ticking stops, and when the widget is restored, it
starts again (without stopping the clock, so it's as if it had
been ticking the whole time, but without using the CPU.)
To use your custom State object as the `vsync`, include the
`TickerProviderStateMixin` when defining the custom State class.
{% endcomment %}

:::note
In some cases, a position might exceed the `AnimationController`'s
0.0-1.0 range. For example, the `fling()` function
allows you to provide velocity, force, and position
(using the Force object). The position can be anything and
so can be outside of the 0.0 to 1.0 range.

A `CurvedAnimation` can also exceed the 0.0 to 1.0 range,
even if the `AnimationController` doesn't.
Depending on the curve selected, the output of
the `CurvedAnimation` can have a wider range than the input.
For example, elastic curves such as `Curves.elasticIn`
significantly overshoots or undershoots the default range.
:::

### Tween

By default, the `AnimationController` object ranges from 0.0 to 1.0.
If you need a different range or a different data type, you can use a
[`Tween`][] to configure an animation to interpolate to a
different range or data type. For example, the
following `Tween` goes from -200.0 to 0.0:

<?code-excerpt "animation/animate5/lib/main.dart (tween)"?>
```dart
tween = Tween<double>(begin: -200, end: 0);
```

A `Tween` is a stateless object that takes only `begin` and `end`.
The sole job of a `Tween` is to define a mapping from an
input range to an output range. The input range is commonly
0.0 to 1.0, but that's not a requirement.

A `Tween` inherits from `Animatable<T>`, not from `Animation<T>`.
An `Animatable`, like `Animation`, doesn't have to output double.
For example, `ColorTween` specifies a progression between two colors.

<?code-excerpt "animation/animate5/lib/main.dart (colorTween)"?>
```dart
colorTween = ColorTween(begin: Colors.transparent, end: Colors.black54);
```

A `Tween` object doesn't store any state. Instead, it provides the
[`evaluate(Animation<double> animation)`][] method that uses the
`transform` function to map the current value of the animation
(between 0.0 and 1.0), to the actual animation value.

The current value of the `Animation` object can be found in the
`.value` method. The evaluate function also performs some housekeeping,
such as ensuring that begin and end are returned when the
animation values are 0.0 and 1.0, respectively.

#### Tween.animate

To use a `Tween` object, call `animate()` on the `Tween`,
passing in the controller object. For example,
the following code generates the
integer values from 0 to 255 over the course of 500 ms.

<?code-excerpt "animation/animate5/lib/main.dart (IntTween)"?>
```dart
AnimationController controller = AnimationController(
  duration: const Duration(milliseconds: 500),
  vsync: this,
);
Animation<int> alpha = IntTween(begin: 0, end: 255).animate(controller);
```

:::note
The `animate()` method returns an [`Animation`][],
not an [`Animatable`][].
:::

The following example shows a controller, a curve, and a `Tween`:

<?code-excerpt "animation/animate5/lib/main.dart (IntTween-curve)"?>
```dart
AnimationController controller = AnimationController(
  duration: const Duration(milliseconds: 500),
  vsync: this,
);
final Animation<double> curve = CurvedAnimation(
  parent: controller,
  curve: Curves.easeOut,
);
Animation<int> alpha = IntTween(begin: 0, end: 255).animate(curve);
```

### Animation notifications

An [`Animation`][] object can have `Listener`s and `StatusListener`s,
defined with `addListener()` and `addStatusListener()`.
A `Listener` is called whenever the value of the animation changes.
The most common behavior of a `Listener` is to call `setState()`
to cause a rebuild. A `StatusListener` is called when an animation begins,
ends, moves forward, or moves reverse, as defined by `AnimationStatus`.

## Codelabs, tutorials, and articles

The following resources are a good place to start learning
the Flutter animation framework. Each of these documents
shows how to write animation code.

* [Animations in Flutter codelab][]<br>
  Learn about implicit and explicit animations
  while building a multiple-choice quiz game.

* [Animations tutorial][]<br>
  Explains the fundamental classes in the Flutter animation package
  (controllers, `Animatable`, curves, listeners, builders),
  as it guides you through a progression of tween animations using
  different aspects of the animation APIs. This tutorial shows
  how to create your own custom explicit animations.

* [Zero to One with Flutter, part 1][] and [part 2][]<br>
  Medium articles showing how to create an animated chart using tweening.

* [Casual games toolkit][]<br>
  A toolkit with game templates that contain examples of how to use Flutter
  animations.

## Other resources

Learn more about Flutter animations at the following links:

* There are several [animations packages][] available on pub.dev that contain
  pre-built animations for commonly used patterns, including:
  `Container` transforms, shared axis transitions,
  fade through transitions, and fade transitions.

* [Animation samples][] from the [Sample app catalog][].

* [Animation recipes][] from the Flutter cookbook.

* [Animation videos][] from the Flutter YouTube channel.

* [Animations: overview][]<br>
  A look at some of the major classes in the
  animations library, and Flutter's animation architecture.

* [Animation and motion widgets][]<br>
  A catalog of some of the animation widgets
  provided in the Flutter APIs.

* The [animation library][] in the [Flutter API documentation][]<br>
  The animation API for the Flutter framework. This link
  takes you to a technical overview page for the library.

[animate1]: {{site.repo.this}}/tree/main/examples/animation/animate1
[Animate a widget using a physics simulation]: /cookbook/animation/physics-simulation
[`Animatable`]: {{site.api}}/flutter/animation/Animatable-class.html
[`AnimatedList` example]: {{site.github}}/flutter/samples/blob/main/animations
[`Animation`]: {{site.api}}/flutter/animation/Animation-class.html
[Animation and motion widgets]: /ui/widgets/animation
[Animation basics with implicit animations]: {{site.yt.watch}}?v=IVTjpW3W33s&list=PLjxrf2q8roU2v6UqYlt_KPaXlnjbYySua&index=1
[Animation deep dive]: {{site.yt.watch}}?v=PbcILiN8rbo&list=PLjxrf2q8roU2v6UqYlt_KPaXlnjbYySua&index=5
[animation library]: {{site.api}}/flutter/animation/animation-library.html
[Animation recipes]: /cookbook/animation
[Animation samples]: {{site.repo.samples}}/tree/main/animations#animation-samples
[Animation videos]: {{site.social.youtube}}/search?query=animation
[Animations in Flutter done right]: {{site.yt.watch}}?v=wnARLByOtKA&t=3s
[Animations: overview]: /ui/animations/overview
[animations packages]: {{site.pub}}/packages?q=topic%3Aanimation
[Animations tutorial]: /ui/animations/tutorial
[`AnimationController`]: {{site.api}}/flutter/animation/AnimationController-class.html
[`AnimationController.animateWith`]: {{site.api}}/flutter/animation/AnimationController/animateWith.html
[article1]: {{site.flutter-blog}}/how-to-choose-which-flutter-animation-widget-is-right-for-you-79ecfb7e72b5
[article2]: {{site.flutter-blog}}/flutter-animation-basics-with-implicit-animations-95db481c5916
[article3]: {{site.flutter-blog}}/custom-implicit-animations-in-flutter-with-tweenanimationbuilder-c76540b47185
[article4]: {{site.flutter-blog}}/directional-animations-with-built-in-explicit-animations-3e7c5e6fbbd7
[article5]: {{site.flutter-blog}}/when-should-i-useanimatedbuilder-or-animatedwidget-57ecae0959e8
[article6]: {{site.flutter-blog}}/animation-deep-dive-39d3ffea111f
[Casual games toolkit]: /resources/games-toolkit/
[Creating your own custom implicit animations with TweenAnimationBuilder]: {{site.yt.watch}}?v=6KiPEqzJIKQ&feature=youtu.be
[Creating custom explicit animations with AnimatedBuilder and AnimatedWidget]: {{site.yt.watch}}?v=fneC7t4R_B0&list=PLjxrf2q8roU2v6UqYlt_KPaXlnjbYySua&index=4
[`Curves`]: {{site.api}}/flutter/animation/Curves-class.html
[`CurvedAnimation`]: {{site.api}}/flutter/animation/CurvedAnimation-class.html
[`CurveTween`]: {{site.api}}/flutter/animation/CurveTween-class.html
[`evaluate(Animation<double> animation)`]: {{site.api}}/flutter/animation/Animation/value.html
[Flutter API documentation]: {{site.api}}
[`Hero`]: {{site.api}}/flutter/widgets/Hero-class.html
[Hero animations]: /ui/animations/hero-animations
[How to choose which Flutter Animation Widget is right for you?]: {{site.yt.watch}}?v=GXIJJkq_H8g
[Animations in Flutter codelab]: {{site.codelabs}}/advanced-flutter-animations
[Making your first directional animations with built-in explicit animations]: {{site.yt.watch}}?v=CunyH6unILQ&list=PLjxrf2q8roU2v6UqYlt_KPaXlnjbYySua&index=3
[Material widgets]: /ui/widgets/material
[`Navigator`]: {{site.api}}/flutter/widgets/Navigator-class.html
[`PageRoute`]: {{site.api}}/flutter/widgets/PageRoute-class.html
[part 2]: {{site.medium}}/dartlang/zero-to-one-with-flutter-part-two-5aa2f06655cb
[`RepaintBoundary`]: {{site.api}}/flutter/widgets/RepaintBoundary-class.html
[Sample app catalog]: {{site.github}}/flutter/samples
[`SpringSimulation`]: {{site.api}}/flutter/physics/SpringSimulation-class.html
[Staggered Animations]: /ui/animations/staggered-animations
[`Tween`]: {{site.api}}/flutter/animation/Tween-class.html
[`TweenSequence`]: {{site.api}}/flutter/animation/TweenSequence-class.html
[Zero to One with Flutter, part 1]: {{site.medium}}/dartlang/zero-to-one-with-flutter-43b13fd7b354

---
title: Animations API overview
shortTitle: API overview
description: An overview of animation concepts.
---

The animation system in Flutter is based on typed
[`Animation`][] objects. Widgets can either
incorporate these animations in their build
functions directly by reading their current value and listening to their
state changes or they can use the animations as the basis of more elaborate
animations that they pass along to other widgets.

## Animation

The primary building block of the animation system is the
[`Animation`][] class. An animation represents a value
of a specific type that can change over the lifetime of
the animation. Most widgets that perform an animation
receive an `Animation` object as a parameter,
from which they read the current value of the animation
and to which they listen for changes to that value.

### `addListener`

Whenever the animation's value changes,
the animation notifies all the listeners added with
[`addListener`][]. Typically, a [`State`][]
object that listens to an animation calls
[`setState`][] on itself in its listener callback
to notify the widget system that it needs to
rebuild with the new value of the animation.

This pattern is so common that there are two widgets
that help widgets rebuild when animations change value:
[`AnimatedWidget`][] and [`AnimatedBuilder`][].
The first, `AnimatedWidget`, is most useful for
stateless animated widgets. To use `AnimatedWidget`,
simply subclass it and implement the [`build`][] function.
The second, `AnimatedBuilder`, is useful for more complex widgets
that wish to include an animation as part of a larger build function.
To use `AnimatedBuilder`, simply construct the widget
and pass it a `builder` function.

### `addStatusListener`

Animations also provide an [`AnimationStatus`][],
which indicates how the animation will evolve over time.
Whenever the animation's status changes,
the animation notifies all the listeners added with
[`addStatusListener`][]. Typically, animations start
out in the `dismissed` status, which means they're
at the beginning of their range. For example,
animations that progress from 0.0 to 1.0
will be `dismissed` when their value is 0.0.
An animation might then run `forward` (from 0.0 to 1.0)
or perhaps in `reverse` (from 1.0 to 0.0).
Eventually, if the animation reaches the end of its range
(1.0), the animation reaches the `completed` status.

## Animation&shy;Controller

To create an animation, first create an [`AnimationController`][].
As well as being an animation itself, an `AnimationController`
lets you control the animation. For example,
you can tell the controller to play the animation
[`forward`][] or [`stop`][] the animation.
You can also [`fling`][] animations,
which uses a physical simulation, such as a spring,
to drive the animation.

Once you've created an animation controller,
you can start building other animations based on it.
For example, you can create a [`ReverseAnimation`][]
that mirrors the original animation but runs in the
opposite direction (from 1.0 to 0.0).
Similarly, you can create a [`CurvedAnimation`][]
whose value is adjusted by a [`Curve`][].

## Tweens

To animate beyond the 0.0 to 1.0 interval, you can use a
[`Tween<T>`][], which interpolates between its
[`begin`][] and [`end`][] values. Many types have specific
`Tween` subclasses that provide type-specific interpolation.
For example, [`ColorTween`][] interpolates between colors and
[`RectTween`][] interpolates between rects.
You can define your own interpolations by creating
your own subclass of `Tween` and overriding its
[`lerp`][] function.

By itself, a tween just defines how to interpolate
between two values. To get a concrete value for the
current frame of an animation, you also need an
animation to determine the current state.
There are two ways to combine a tween
with an animation to get a concrete value:

1. You can [`evaluate`][] the tween at the current
   value of an animation. This approach is most useful
   for widgets that are already listening to the animation and hence
   rebuilding whenever the animation changes value.

2. You can [`animate`][] the tween based on the animation.
   Rather than returning a single value, the animate function
   returns a new `Animation` that incorporates the tween.
   This approach is most useful when you want to give the
   newly created animation to another widget,
   which can then read the current value that incorporates
   the tween as well as listen for changes to the value.

## Architecture

Animations are actually built from a number of core building blocks.

### Scheduler

The [`SchedulerBinding`][] is a singleton class
that exposes the Flutter scheduling primitives.

For this discussion, the key primitive is the frame callbacks.
Each time a frame needs to be shown on the screen,
Flutter's engine triggers a "begin frame" callback that
the scheduler multiplexes to all the listeners registered using
[`scheduleFrameCallback()`][]. All these callbacks are
given the official time stamp of the frame, in
the form of a `Duration` from some arbitrary epoch. Since all the
callbacks have the same time, any animations triggered from these
callbacks will appear to be exactly synchronised even
if they take a few milliseconds to be executed.

### Tickers

The [`Ticker`][] class hooks into the scheduler's
[`scheduleFrameCallback()`][]
mechanism to invoke a callback every tick.

A `Ticker` can be started and stopped. When started,
it returns a `Future` that will resolve when it is stopped.

Each tick, the `Ticker` provides the callback with the
duration since the first tick after it was started.

Because tickers always give their elapsed time relative to the first
tick after they were started; tickers are all synchronised. If you
start three tickers at different times between two ticks, they will all
nonetheless be synchronised with the same starting time, and will
subsequently tick in lockstep. Like people at a bus-stop,
all the tickers wait for a regularly occurring event
(the tick) to begin moving (counting time).

### Simulations

The [`Simulation`][] abstract class maps a
relative time value (an elapsed time) to a
double value, and has a notion of completion.

In principle simulations are stateless but in practice
some simulations (for example,
[`BouncingScrollSimulation`][] and
[`ClampingScrollSimulation`][])
change state irreversibly when queried.

There are [various concrete implementations][]
of the `Simulation` class for different effects.

### Animatables

The [`Animatable`][] abstract class maps a
double to a value of a particular type.

`Animatable` classes are stateless and immutable.

#### Tweens

The [`Tween<T>`][] abstract class maps a double
value nominally in the range 0.0-1.0 to a typed value
(for example, a `Color`, or another double).
It is an `Animatable`.

It has a notion of an output type (`T`),
a `begin` value and an `end` value of that type,
and a way to interpolate (`lerp`) between the begin
and end values for a given input value (the double nominally in
the range 0.0-1.0).

`Tween` classes are stateless and immutable.

#### Composing animatables

Passing an `Animatable<double>` (the parent) to an `Animatable`'s
`chain()` method creates a new `Animatable` subclass that applies the
parent's mapping then the child's mapping.

### Curves

The [`Curve`][] abstract class maps doubles
nominally in the range 0.0-1.0 to doubles
nominally in the range 0.0-1.0.

`Curve` classes are stateless and immutable.

### Animations

The [`Animation`][] abstract class provides a
value of a given type, a concept of animation
direction and animation status, and a listener interface to
register callbacks that get invoked when the value or status change.

Some subclasses of `Animation` have values that never change
([`kAlwaysCompleteAnimation`][], [`kAlwaysDismissedAnimation`][],
[`AlwaysStoppedAnimation`][]); registering callbacks on
these has no effect as the callbacks are never called.

The `Animation<double>` variant is special because it can be used to
represent a double nominally in the range 0.0-1.0, which is the input
expected by `Curve` and `Tween` classes, as well as some further
subclasses of `Animation`.

Some `Animation` subclasses are stateless,
merely forwarding listeners to their parents.
Some are very stateful.

#### Composable animations

Most `Animation` subclasses take an explicit "parent"
`Animation<double>`. They are driven by that parent.

The `CurvedAnimation` subclass takes an `Animation<double>` class (the
parent) and a couple of `Curve` classes (the forward and reverse
curves) as input, and uses the value of the parent as input to the
curves to determine its output. `CurvedAnimation` is immutable and
stateless.

The `ReverseAnimation` subclass takes an
`Animation<double>` class as its parent and reverses
all the values of the animation. It assumes the parent
is using a value nominally in the range 0.0-1.0 and returns
a value in the range 1.0-0.0. The status and direction of the parent
animation are also reversed. `ReverseAnimation` is immutable and
stateless.

The `ProxyAnimation` subclass takes an `Animation<double>` class as
its parent and merely forwards the current state of that parent.
However, the parent is mutable.

The `TrainHoppingAnimation` subclass takes two parents,
and switches between them when their values cross.

#### Animation controllers

The [`AnimationController`][] is a stateful
`Animation<double>` that uses a `Ticker` to give itself life.
It can be started and stopped. At each tick, it takes the time
elapsed since it was started and passes it to a `Simulation` to obtain
a value. That is then the value it reports. If the `Simulation`
reports that at that time it has ended, then the controller stops
itself.

The animation controller can be given a lower and upper bound to
animate between, and a duration.

In the simple case (using `forward()` or `reverse()`), the animation controller simply does a linear
interpolation from the lower bound to the upper bound (or vice versa,
for the reverse direction) over the given duration.

When using `repeat()`, the animation controller uses a linear
interpolation between the given bounds over the given duration, but
does not stop.

When using `animateTo()`, the animation controller does a linear
interpolation over the given duration from the current value to the
given target. If no duration is given to the method, the default
duration of the controller and the range described by the controller's
lower bound and upper bound is used to determine the velocity of the
animation.

When using `fling()`, a `Force` is used to create a specific
simulation which is then used to drive the controller.

When using `animateWith()`, the given simulation is used to drive the
controller.

These methods all return the future that the `Ticker` provides and
which will resolve when the controller next stops or changes
simulation.

#### Attaching animatables to animations

Passing an `Animation<double>` (the new parent) to an `Animatable`'s
`animate()` method creates a new `Animation` subclass that acts like
the `Animatable` but is driven from the given parent.


[`addListener`]: {{site.api}}/flutter/animation/Animation/addListener.html
[`addStatusListener`]: {{site.api}}/flutter/animation/Animation/addStatusListener.html
[`AlwaysStoppedAnimation`]: {{site.api}}/flutter/animation/AlwaysStoppedAnimation-class.html
[`Animatable`]: {{site.api}}/flutter/animation/Animatable-class.html
[`animate`]: {{site.api}}/flutter/animation/Animatable/animate.html
[`AnimatedBuilder`]: {{site.api}}/flutter/widgets/AnimatedBuilder-class.html
[`AnimationController`]: {{site.api}}/flutter/animation/AnimationController-class.html
[`AnimatedWidget`]: {{site.api}}/flutter/widgets/AnimatedWidget-class.html
[`Animation`]: {{site.api}}/flutter/animation/Animation-class.html
[`AnimationStatus`]: {{site.api}}/flutter/animation/AnimationStatus.html
[`begin`]: {{site.api}}/flutter/animation/Tween/begin.html
[`BouncingScrollSimulation`]: {{site.api}}/flutter/widgets/BouncingScrollSimulation-class.html
[`build`]: {{site.api}}/flutter/widgets/AnimatedWidget/build.html
[`ClampingScrollSimulation`]: {{site.api}}/flutter/widgets/ClampingScrollSimulation-class.html
[`ColorTween`]: {{site.api}}/flutter/animation/ColorTween-class.html
[`Curve`]: {{site.api}}/flutter/animation/Curves-class.html
[`CurvedAnimation`]: {{site.api}}/flutter/animation/CurvedAnimation-class.html
[`end`]: {{site.api}}/flutter/animation/Tween/end.html
[`evaluate`]: {{site.api}}/flutter/animation/Animatable/evaluate.html
[`fling`]: {{site.api}}/flutter/animation/AnimationController/fling.html
[`forward`]: {{site.api}}/flutter/animation/AnimationController/forward.html
[`kAlwaysCompleteAnimation`]: {{site.api}}/flutter/animation/kAlwaysCompleteAnimation-constant.html
[`kAlwaysDismissedAnimation`]: {{site.api}}/flutter/animation/kAlwaysDismissedAnimation-constant.html
[`lerp`]: {{site.api}}/flutter/animation/Tween/lerp.html
[`RectTween`]: {{site.api}}/flutter/animation/RectTween-class.html
[`ReverseAnimation`]: {{site.api}}/flutter/animation/ReverseAnimation-class.html
[`scheduleFrameCallback()`]: {{site.api}}/flutter/scheduler/SchedulerBinding/scheduleFrameCallback.html
[`SchedulerBinding`]: {{site.api}}/flutter/scheduler/SchedulerBinding-mixin.html
[`setState`]: {{site.api}}/flutter/widgets/State/setState.html
[`Simulation`]: {{site.api}}/flutter/physics/Simulation-class.html
[`State`]: {{site.api}}/flutter/widgets/State-class.html
[`stop`]: {{site.api}}/flutter/animation/AnimationController/stop.html
[`Ticker`]: {{site.api}}/flutter/scheduler/Ticker-class.html
[`Tween<T>`]: {{site.api}}/flutter/animation/Tween-class.html
[various concrete implementations]: {{site.api}}/flutter/physics/physics-library.html


---
title: Staggered animations
description: How to write a staggered animation in Flutter.
shortTitle: Staggered
---

:::secondary What you'll learn
* A staggered animation consists of sequential or overlapping
    animations.
* To create a staggered animation, use multiple `Animation` objects.
* One `AnimationController` controls all of the `Animation`s.
* Each `Animation` object specifies the animation during an `Interval`.
* For each property being animated, create a `Tween`.
:::

:::tip Terminology
If the concept of tweens or tweening is new to you, see the
[Animations in Flutter tutorial][].
:::

Staggered animations are a straightforward concept: visual changes
happen as a series of operations, rather than all at once.
The animation might be purely sequential, with one change occurring after
the next, or it might partially or completely overlap. It might also
have gaps, where no changes occur.

This guide shows how to build a staggered animation in Flutter.

:::secondary Examples
This guide explains the basic_staggered_animation example.
You can also refer to a more complex example,
staggered_pic_selection.

[basic_staggered_animation][]
: Shows a series of sequential and overlapping animations
  of a single widget. Tapping the screen begins an animation
  that changes opacity, size, shape, color, and padding.

[staggered_pic_selection][]
: Shows deleting an image from a list of images displayed
  in one of three sizes. This example uses two
  [animation controllers][]: one for image selection/deselection,
  and one for image deletion. The selection/deselection
  animation is staggered. (To see this effect,
  you might need to increase the `timeDilation` value.)
  Select one of the largest images&mdash;it shrinks as it
  displays a checkmark inside a blue circle.
  Next, select one of the smallest images&mdash;the
  large image expands as the checkmark disappears.
  Before the large image has finished expanding,
  the small image shrinks to display its checkmark.
  This staggered behavior is similar to what you might
  see in Google Photos.
:::

The following video demonstrates the animation performed by
basic_staggered_animation:

<YouTubeEmbed id="0fFvnZemmh8" title="Staggered animation example"></YouTubeEmbed>

In the video, you see the following animation of a single widget,
which begins as a bordered blue square with slightly rounded corners.
The square runs through changes in the following order:

1. Fades in
1. Widens
1. Becomes taller while moving upwards
1. Transforms into a bordered circle
1. Changes color to orange

After running forward, the animation runs in reverse.

:::secondary New to Flutter?
This page assumes you know how to create a layout using Flutter's
widgets.  For more information, see [Building Layouts in Flutter][].
:::

## Basic structure of a staggered animation

:::secondary What's the point?
* All of the animations are driven by the same
    [`AnimationController`][].
* Regardless of how long the animation lasts in real time,
    the controller's values must be between 0.0 and 1.0, inclusive.
* Each animation has an [`Interval`][]
    between 0.0 and 1.0, inclusive.
* For each property that animates in an interval, create a
    [`Tween`][]. The `Tween` specifies the start and end
    values for that property.
* The `Tween` produces an [`Animation`][]
    object that is managed by the controller.
:::

{% comment %}
The app is essentially animating a `Container` whose
decoration and size are animated. The `Container`
is within another `Container` whose padding moves the
inner container around and an `Opacity` widget that's
used to fade everything in and out.
{% endcomment %}

The following diagram shows the `Interval`s used in the
[basic_staggered_animation][] example.
You might notice the following characteristics:

* The opacity changes during the first 10% of the timeline.
* A tiny gap occurs between the change in opacity,
  and the change in width.
* Nothing animates during the last 25% of the timeline.
* Increasing the padding makes the widget appear to rise upward.
* Increasing the border radius to 0.5,
  transforms the square with rounded corners into a circle.
* The padding and height changes occur during
  the same exact interval, but they don't have to.

![Diagram showing the interval specified for each motion](/assets/images/docs/ui/animations/StaggeredAnimationIntervals.png)

To set up the animation:

* Create an `AnimationController` that manages all of the
  `Animations`.
* Create a `Tween` for each property being animated.
  * The `Tween` defines a range of values.
  * The `Tween`'s `animate` method requires the
    `parent` controller, and produces an `Animation`
    for that property.
* Specify the interval on the `Animation`'s `curve` property.

When the controlling animation's value changes,
the new animation's value changes, triggering the UI to update.

The following code creates a tween for the `width` property.
It builds a [`CurvedAnimation`][],
specifying an eased curve. See [`Curves`][] for
other available pre-defined animation curves.

```dart
width = Tween<double>(
  begin: 50.0,
  end: 150.0,
).animate(
  CurvedAnimation(
    parent: controller,
    curve: const Interval(
      0.125,
      0.250,
      curve: Curves.ease,
    ),
  ),
),
```

The `begin` and `end` values don't have to be doubles.
The following code builds the tween for the `borderRadius` property
(which controls the roundness of the square's corners),
using `BorderRadius.circular()`.

```dart
borderRadius = BorderRadiusTween(
  begin: BorderRadius.circular(4),
  end: BorderRadius.circular(75),
).animate(
  CurvedAnimation(
    parent: controller,
    curve: const Interval(
      0.375,
      0.500,
      curve: Curves.ease,
    ),
  ),
),
```

### Complete staggered animation

Like all interactive widgets, the complete animation consists
of a widget pair: a stateless and a stateful widget.

The stateless widget specifies the `Tween`s,
defines the `Animation` objects, and provides a `build()` function
responsible for building the animating portion of the widget tree.

The stateful widget creates the controller, plays the animation,
and builds the non-animating portion of the widget tree.
The animation begins when a tap is detected anywhere in the screen.

[Full code for basic_staggered_animation's main.dart][]

### Stateless widget: StaggerAnimation

In the stateless widget, `StaggerAnimation`,
the `build()` function instantiates an
[`AnimatedBuilder`][]&mdash;a general purpose widget for building
animations. The `AnimatedBuilder`
builds a widget and configures it using the `Tweens`' current values.
The example creates a function named `_buildAnimation()` (which performs
the actual UI updates), and assigns it to its `builder` property.
AnimatedBuilder listens to notifications from the animation controller,
marking the widget tree dirty as values change.
For each tick of the animation, the values are updated,
resulting in a call to `_buildAnimation()`.

```dart
[!class StaggerAnimation extends StatelessWidget!] {
  StaggerAnimation({super.key, required this.controller}) :

    // Each animation defined here transforms its value during the subset
    // of the controller's duration defined by the animation's interval.
    // For example the opacity animation transforms its value during
    // the first 10% of the controller's duration.

    [!opacity = Tween<double>!](
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.0,
          0.100,
          curve: Curves.ease,
        ),
      ),
    ),

    // ... Other tween definitions ...
    );

  [!final AnimationController controller;!]
  [!final Animation<double> opacity;!]
  [!final Animation<double> width;!]
  [!final Animation<double> height;!]
  [!final Animation<EdgeInsets> padding;!]
  [!final Animation<BorderRadius?> borderRadius;!]
  [!final Animation<Color?> color;!]

  // This function is called each time the controller "ticks" a new frame.
  // When it runs, all of the animation's values will have been
  // updated to reflect the controller's current value.
  [!Widget _buildAnimation(BuildContext context, Widget? child)!] {
    return Container(
      padding: padding.value,
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: opacity.value,
        child: Container(
          width: width.value,
          height: height.value,
          decoration: BoxDecoration(
            color: color.value,
            border: Border.all(
              color: Colors.indigo[300]!,
              width: 3,
            ),
            borderRadius: borderRadius.value,
          ),
        ),
      ),
    );
  }

  @override
  [!Widget build(BuildContext context)!] {
    return [!AnimatedBuilder!](
      [!builder: _buildAnimation!],
      animation: controller,
    );
  }
}
```

### Stateful widget: StaggerDemo

The stateful widget, `StaggerDemo`, creates the `AnimationController`
(the one who rules them all), specifying a 2000 ms duration. It plays
the animation, and builds the non-animating portion of the widget tree.
The animation begins when a tap is detected in the screen.
The animation runs forward, then backward.

```dart
[!class StaggerDemo extends StatefulWidget!] {
  @override
  State<StaggerDemo> createState() => _StaggerDemoState();
}

class _StaggerDemoState extends State<StaggerDemo>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  // ...Boilerplate...

  [!Future<void> _playAnimation() async!] {
    try {
      [!await _controller.forward().orCancel;!]
      [!await _controller.reverse().orCancel;!]
    } on TickerCanceled {
      // The animation got canceled, probably because it was disposed of.
    }
  }

  @override
  [!Widget build(BuildContext context)!] {
    timeDilation = 10.0; // 1.0 is normal animation speed.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staggered Animation'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _playAnimation();
        },
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            child: StaggerAnimation(controller:_controller.view),
          ),
        ),
      ),
    );
  }
}
```

[`Animation`]: {{site.api}}/flutter/animation/Animation-class.html
[animation controllers]: {{site.api}}/flutter/animation/AnimationController-class.html
[`AnimationController`]: {{site.api}}/flutter/animation/AnimationController-class.html
[`AnimatedBuilder`]: {{site.api}}/flutter/widgets/AnimatedBuilder-class.html
[Animations in Flutter tutorial]: /ui/animations/tutorial
[basic_staggered_animation]: {{site.repo.this}}/tree/{{site.branch}}/examples/_animation/basic_staggered_animation
[Building Layouts in Flutter]: /ui/layout
[staggered_pic_selection]: {{site.repo.this}}/tree/{{site.branch}}/examples/_animation/staggered_pic_selection
[`CurvedAnimation`]: {{site.api}}/flutter/animation/CurvedAnimation-class.html
[`Curves`]: {{site.api}}/flutter/animation/Curves-class.html
[Full code for basic_staggered_animation's main.dart]: {{site.repo.this}}/tree/{{site.branch}}/examples/_animation/basic_staggered_animation/lib/main.dart
[`Interval`]: {{site.api}}/flutter/animation/Interval-class.html
[`Tween`]: {{site.api}}/flutter/animation/Tween-class.html


---
title: Animations tutorial
shortTitle: Tutorial
description: A tutorial showing how to build explicit animations in Flutter.
---

<?code-excerpt path-base="animation"?>

:::secondary What you'll learn
* How to use the fundamental classes from the
  animation library to add animation to a widget.
* When to use `AnimatedWidget` vs. `AnimatedBuilder`.
:::

This tutorial shows you how to build explicit animations in Flutter.
The examples build on each other, introducing you to different aspects of the
animation library. The tutorial is built on essential concepts, classes,
and methods in the animation library that you can learn about in
[Introduction to animations][].

The Flutter SDK also provides built-in explicit animations,
such as [`FadeTransition`][], [`SizeTransition`][],
and [`SlideTransition`][]. These simple animations are
triggered by setting a beginning and ending point.
They are simpler to implement
than custom explicit animations, which are described here.

The following sections walks you through several animation examples.
Each section provides a link to the source code for that example.

## Rendering animations

:::secondary What's the point?
* How to add basic animation to a widget using `addListener()` and
  `setState()`.
* Every time the Animation generates a new number, the `addListener()`
  function calls `setState()`.
* How to define an `AnimationController` with the required
  `vsync` parameter.
* Understanding the "`..`" syntax in "`..addListener`",
  also known as Dart's _cascade notation_.
* To make a class private, start its name with an underscore (`_`).
:::

So far you've learned how to generate a sequence of numbers over time.
Nothing has been rendered to the screen. To render with an
`Animation` object, store the `Animation` object as a
member of your widget, then use its value to decide how to draw.

Consider the following app that draws the Flutter logo without animation:

<?code-excerpt "animate0/lib/main.dart"?>
```dart
import 'package:flutter/material.dart';

void main() => runApp(const LogoApp());

class LogoApp extends StatefulWidget {
  const LogoApp({super.key});

  @override
  State<LogoApp> createState() => _LogoAppState();
}

class _LogoAppState extends State<LogoApp> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 300,
        width: 300,
        child: const FlutterLogo(),
      ),
    );
  }
}
```

**App source:** [animate0][]

The following shows the same code modified to animate the
logo to grow from nothing to full size.
When defining an `AnimationController`, you must pass in a
`vsync` object. The `vsync` parameter is described in the
[`AnimationController` section][].

The changes from the non-animated example are highlighted:

```dart diff
- class _LogoAppState extends State<LogoApp> {
+ class _LogoAppState extends State<LogoApp> with SingleTickerProviderStateMixin {
+   late Animation<double> animation;
+   late AnimationController controller;
+
+   @override
+   void initState() {
+     super.initState();
+     controller =
+         AnimationController(duration: const Duration(seconds: 2), vsync: this);
+     animation = Tween<double>(begin: 0, end: 300).animate(controller)
+       ..addListener(() {
+         setState(() {
+           // The state that has changed here is the animation object's value.
+         });
+       });
+     controller.forward();
+   }
+
    @override
    Widget build(BuildContext context) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
-         height: 300,
-         width: 300,
+         height: animation.value,
+         width: animation.value,
          child: const FlutterLogo(),
        ),
      );
    }
+
+   @override
+   void dispose() {
+     controller.dispose();
+     super.dispose();
+   }
  }
```

**App source:** [animate1][]

The `addListener()` function calls `setState()`,
so every time the `Animation` generates a new number,
the current frame is marked dirty, which forces
`build()` to be called again. In `build()`,
the container changes size because its height and
width now use `animation.value` instead of a hardcoded value.
Dispose of the controller when the `State` object is
discarded to prevent memory leaks.

With these few changes,
you've created your first animation in Flutter!

:::tip Dart language trick
You might not be familiar with Dart's cascade notation&mdash;the two
dots in `..addListener()`. This syntax means that the `addListener()`
method is called with the return value from `animate()`.
Consider the following example:

<?code-excerpt "animate1/lib/main.dart (add-listener)"?>
```dart highlightLines=2
animation = Tween<double>(begin: 0, end: 300).animate(controller)
  ..addListener(() {
    // ···
  });
```

This code is equivalent to:

<?code-excerpt "animate1/lib/main.dart (add-listener)" replace="/animation.*/$&;/g; /  \./animation/g;"?>
```dart highlightLines=2
animation = Tween<double>(begin: 0, end: 300).animate(controller);
animation.addListener(() {
    // ···
  });
```

To learn more about cascades,
check out [Cascade notation][]
in the [Dart language documentation][].
:::

## Simplifying with AnimatedWidget

:::secondary What's the point?
* How to use the [`AnimatedWidget`][] helper class
  (instead of `addListener()`
  and `setState()`) to create a widget that animates.
* Use `AnimatedWidget` to create a widget that performs
  a reusable animation.
  To separate the transition from the widget, use an
  `AnimatedBuilder`, as shown in the
  [Refactoring with AnimatedBuilder][] section.
* Examples of `AnimatedWidget`s in the Flutter API:
  `AnimatedBuilder`, `AnimatedModalBarrier`,
  `DecoratedBoxTransition`, `FadeTransition`,
  `PositionedTransition`, `RelativePositionedTransition`,
  `RotationTransition`, `ScaleTransition`,
  `SizeTransition`, `SlideTransition`.
:::

The `AnimatedWidget` base class allows you to separate out
the core widget code from the animation code.
`AnimatedWidget` doesn't need to maintain a `State`
object to hold the animation. Add the following `AnimatedLogo` class:

<?code-excerpt path-base="animation/animate2"?>
<?code-excerpt "lib/main.dart (AnimatedLogo)"?>
```dart
class AnimatedLogo extends AnimatedWidget {
  const AnimatedLogo({super.key, required Animation<double> animation})
    : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: animation.value,
        width: animation.value,
        child: const FlutterLogo(),
      ),
    );
  }
}
```
<?code-excerpt path-base="animation"?>

`AnimatedLogo` uses the current value of the `animation`
when drawing itself.

The `LogoApp` still manages the `AnimationController` and the `Tween`,
and it passes the `Animation` object to `AnimatedLogo`:

```dart diff
  void main() => runApp(const LogoApp());

+ class AnimatedLogo extends AnimatedWidget {
+   const AnimatedLogo({super.key, required Animation<double> animation})
+       : super(listenable: animation);
+
+   @override
+   Widget build(BuildContext context) {
+     final animation = listenable as Animation<double>;
+     return Center(
+       child: Container(
+         margin: const EdgeInsets.symmetric(vertical: 10),
+         height: animation.value,
+         width: animation.value,
+         child: const FlutterLogo(),
+       ),
+     );
+   }
+ }
+
  class LogoApp extends StatefulWidget {
    // ...

    @override
    void initState() {
      super.initState();
      controller =
          AnimationController(duration: const Duration(seconds: 2), vsync: this);
-     animation = Tween<double>(begin: 0, end: 300).animate(controller)
-       ..addListener(() {
-         setState(() {
-           // The state that has changed here is the animation object's value.
-         });
-       });
+     animation = Tween<double>(begin: 0, end: 300).animate(controller);
      controller.forward();
    }

    @override
-   Widget build(BuildContext context) {
-     return Center(
-       child: Container(
-         margin: const EdgeInsets.symmetric(vertical: 10),
-         height: animation.value,
-         width: animation.value,
-         child: const FlutterLogo(),
-       ),
-     );
-   }
+   Widget build(BuildContext context) => AnimatedLogo(animation: animation);

    // ...
  }
```

**App source:** [animate2][]

<a id="monitoring"></a>

## Monitoring the progress of the animation

:::secondary What's the point?
* Use `addStatusListener()` for notifications of changes
  to the animation's state, such as starting, stopping,
  or reversing direction.
* Run an animation in an infinite loop by reversing direction when
  the animation has either completed or returned to its starting state.
:::

It's often helpful to know when an animation changes state,
such as finishing, moving forward, or reversing.
You can get notifications for this with `addStatusListener()`.
The following code modifies the previous example so that
it listens for a state change and prints an update.
The highlighted line shows the change:

<?code-excerpt "animate3/lib/main.dart (print-state)" plaster="none" replace="/\/\/ (\.\..*)/$1;/g; /\n  }/$&\n  \/\/ .../g"?>
```dart highlightLines=13
class _LogoAppState extends State<LogoApp> with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    animation = Tween<double>(begin: 0, end: 300).animate(controller)
      ..addStatusListener((status) => print('$status'));
    controller.forward();
  }
  // ...
}
```

Running this code produces this output:

```console
AnimationStatus.forward
AnimationStatus.completed
```

Next, use `addStatusListener()` to reverse the animation
at the beginning or the end. This creates a "breathing" effect:

```dart diff
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
-   animation = Tween<double>(begin: 0, end: 300).animate(controller);
+   animation = Tween<double>(begin: 0, end: 300).animate(controller)
+     ..addStatusListener((status) {
+       if (status == AnimationStatus.completed) {
+         controller.reverse();
+       } else if (status == AnimationStatus.dismissed) {
+         controller.forward();
+       }
+     })
+     ..addStatusListener((status) => print('$status'));
    controller.forward();
  }
```

**App source:** [animate3][]

## Refactoring with AnimatedBuilder

:::secondary What's the point?
* An [`AnimatedBuilder`][] understands how to render the transition.
* An `AnimatedBuilder` doesn't know how to render the widget,
  nor does it manage the `Animation` object.
* Use `AnimatedBuilder` to describe an animation as
  part of a build method for another widget.
  If you simply want to define a widget with a reusable
  animation, use an `AnimatedWidget`, as shown in
  the [Simplifying with AnimatedWidget][] section.
* Examples of `AnimatedBuilders` in the Flutter API: `BottomSheet`,
  `ExpansionTile`, `PopupMenu`, `ProgressIndicator`,
  `RefreshIndicator`, `Scaffold`, `SnackBar`, `TabBar`,
  `TextField`.
:::

One problem with the code in the [animate3][] example,
is that changing the animation required changing the widget
that renders the logo. A better solution
is to separate responsibilities into different classes:

* Render the logo
* Define the `Animation` object
* Render the transition

You can accomplish this separation with the help of the
`AnimatedBuilder` class. An `AnimatedBuilder` is a
separate class in the render tree. Like `AnimatedWidget`,
`AnimatedBuilder` automatically listens to notifications
from the `Animation` object, and marks the widget tree
dirty as necessary, so you don't need to call `addListener()`.

The widget tree for the [animate4][]
example looks like this:

<DashImage figure image="ui/AnimatedBuilder-WidgetTree.png" alt="AnimatedBuilder widget tree" />

Starting from the bottom of the widget tree, the code for rendering
the logo is straightforward:

<?code-excerpt "animate4/lib/main.dart (logo-widget)"?>
```dart
class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  // Leave out the height and width so it fills the animating parent.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: const FlutterLogo(),
    );
  }
}
```

The middle three blocks in the diagram are all created in the
`build()` method in `GrowTransition`, shown below.
The `GrowTransition` widget itself is stateless and holds
the set of final variables necessary to define the transition animation.
The build() function creates and returns the `AnimatedBuilder`,
which takes the (`Anonymous` builder) method and the
`LogoWidget` object as parameters. The work of rendering the
transition actually happens in the (`Anonymous` builder)
method, which creates a `Container` of the appropriate size
to force the `LogoWidget` to shrink to fit.

One tricky point in the code below is that the child looks
like it's specified twice. What's happening is that the
outer reference of child is passed to `AnimatedBuilder`,
which passes it to the anonymous closure, which then uses
that object as its child. The net result is that the
`AnimatedBuilder` is inserted in between the two widgets
in the render tree.

<?code-excerpt "animate4/lib/main.dart (grow-transition)"?>
```dart
class GrowTransition extends StatelessWidget {
  const GrowTransition({
    required this.child,
    required this.animation,
    super.key,
  });

  final Widget child;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return SizedBox(
            height: animation.value,
            width: animation.value,
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}
```

Finally, the code to initialize the animation looks very
similar to the [animate2][] example. The `initState()`
method creates an `AnimationController` and a `Tween`,
then binds them with `animate()`. The magic happens in
the `build()` method, which returns a `GrowTransition`
object with a `LogoWidget` as a child, and an animation object to
drive the transition. These are the three elements listed
in the bullet points above.

```dart diff
  void main() => runApp(const LogoApp());

+ class LogoWidget extends StatelessWidget {
+   const LogoWidget({super.key});
+
+   // Leave out the height and width so it fills the animating parent.
+   @override
+   Widget build(BuildContext context) {
+     return Container(
+       margin: const EdgeInsets.symmetric(vertical: 10),
+       child: const FlutterLogo(),
+     );
+   }
+ }
+
+ class GrowTransition extends StatelessWidget {
+   const GrowTransition({
+     required this.child,
+     required this.animation,
+     super.key,
+   });
+
+   final Widget child;
+   final Animation<double> animation;
+
+   @override
+   Widget build(BuildContext context) {
+     return Center(
+       child: AnimatedBuilder(
+         animation: animation,
+         builder: (context, child) {
+           return SizedBox(
+             height: animation.value,
+             width: animation.value,
+             child: child,
+           );
+         },
+         child: child,
+       ),
+     );
+   }
+ }

  class LogoApp extends StatefulWidget {
    // ...

    @override
-   Widget build(BuildContext context) => AnimatedLogo(animation: animation);
+   Widget build(BuildContext context) {
+     return GrowTransition(
+       animation: animation,
+       child: const LogoWidget(),
+     );
+   }

    // ...
  }
```

**App source:** [animate4][]

## Simultaneous animations

:::secondary What's the point?
* The [`Curves`][] class defines an array of
  commonly used curves that you can
  use with a [`CurvedAnimation`][].
:::

In this section, you'll build on the example from
[monitoring the progress of the animation][]
([animate3][]), which used `AnimatedWidget`
to animate in and out continuously. Consider the case
where you want to animate in and out while the
opacity animates from transparent to opaque.

:::note
This example shows how to use multiple tweens on the same animation
controller, where each tween manages a different effect in
the animation. It is for illustrative purposes only.
If you were tweening opacity and size in production code,
you'd probably use [`FadeTransition`][] and [`SizeTransition`][]
instead.
:::

Each tween manages an aspect of the animation. For example:

<?code-excerpt "animate5/lib/main.dart (tweens)" plaster="none"?>
```dart
controller = AnimationController(
  duration: const Duration(seconds: 2),
  vsync: this,
);
sizeAnimation = Tween<double>(begin: 0, end: 300).animate(controller);
opacityAnimation = Tween<double>(begin: 0.1, end: 1).animate(controller);
```

You can get the size with `sizeAnimation.value` and the opacity
with `opacityAnimation.value`, but the constructor for `AnimatedWidget`
only takes a single `Animation` object. To solve this problem,
the example creates its own `Tween` objects and explicitly calculates the
values.

Change `AnimatedLogo` to encapsulate its own `Tween` objects,
and its `build()` method calls `Tween.evaluate()`
on the parent's animation object to calculate
the required size and opacity values.
The following code shows the changes with highlights:

<?code-excerpt "animate5/lib/main.dart (diff)" replace="/(static final|child: Opacity|opacity:|_sizeTween\.|CurvedAnimation).*/[!$&!]/g"?>
```dart
class AnimatedLogo extends AnimatedWidget {
  const AnimatedLogo({super.key, required Animation<double> animation})
    : super(listenable: animation);

  // Make the Tweens static because they don't change.
  [!static final _opacityTween = Tween<double>(begin: 0.1, end: 1);!]
  [!static final _sizeTween = Tween<double>(begin: 0, end: 300);!]

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Center(
      [!child: Opacity(!]
        [!opacity: _opacityTween.evaluate(animation),!]
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          height: [!_sizeTween.evaluate(animation),!]
          width: [!_sizeTween.evaluate(animation),!]
          child: const FlutterLogo(),
        ),
      ),
    );
  }
}

class LogoApp extends StatefulWidget {
  const LogoApp({super.key});

  @override
  State<LogoApp> createState() => _LogoAppState();
}

class _LogoAppState extends State<LogoApp> with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    animation = [!CurvedAnimation(parent: controller, curve: Curves.easeIn)!]
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
      });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) => AnimatedLogo(animation: animation);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

**App source:** [animate5][] object knows the current state of an animation
  (for example, whether it's started, stopped,
  or moving forward or in reverse),
  but doesn't know anything about what appears onscreen.
* An [`AnimationController`][] manages the `Animation`.
* A [`CurvedAnimation`][] defines progression as a non-linear curve.
* A [`Tween`][] interpolates between a beginning and ending value
  for a property being animated.

## Next steps

This tutorial gives you a foundation for creating animations in
Flutter using `Tweens`, but there are many other classes to explore.
You might investigate the specialized `Tween` classes,
animations specific to your design system type, `ReverseAnimation`,
shared element transitions (also known as Hero animations),
physics simulations and `fling()` methods.

[animate0]: {{site.repo.this}}/tree/main/examples/animation/animate0
[animate1]: {{site.repo.this}}/tree/main/examples/animation/animate1
[animate2]: {{site.repo.this}}/tree/main/examples/animation/animate2
[animate3]: {{site.repo.this}}/tree/main/examples/animation/animate3
[animate4]: {{site.repo.this}}/tree/main/examples/animation/animate4
[animate5]: {{site.repo.this}}/tree/main/examples/animation/animate5
[`AnimatedWidget`]: {{site.api}}/flutter/widgets/AnimatedWidget-class.html
[`AnimatedBuilder`]: {{site.api}}/flutter/widgets/AnimatedBuilder-class.html
[Introduction to animations]: /ui/animations
[`AnimationController`]: {{site.api}}/flutter/animation/AnimationController-class.html
[`AnimationController` section]: /ui/animations/index#animationcontroller
[`Curves`]: {{site.api}}/flutter/animation/Curves-class.html
[`CurvedAnimation`]: {{site.api}}/flutter/animation/CurvedAnimation-class.html
[Cascade notation]: {{site.dart-site}}/language/operators#cascade-notation
[Dart language documentation]: {{site.dart-site}}/language
[`FadeTransition`]: {{site.api}}/flutter/widgets/FadeTransition-class.html
[Monitoring the progress of the animation]: #monitoring
[Refactoring with AnimatedBuilder]: #refactoring-with-animatedbuilder
[`SlideTransition`]: {{site.api}}/flutter/widgets/SlideTransition-class.html
[Simplifying with AnimatedWidget]: #simplifying-with-animatedwidget
[`SizeTransition`]: {{site.api}}/flutter/widgets/SizeTransition-class.html
[`Tween`]: {{site.api}}/flutter/animation/Tween-class.html