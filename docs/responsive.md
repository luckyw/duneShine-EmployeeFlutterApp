---
title: Best practices for adaptive design
description: >-
  Summary of some of the best practices for adaptive design.
shortTitle: Best practices
---

Recommended best practices for adaptive design include:

## Design considerations

### Break down your widgets

While designing your app, try to break down large,
complex widgets into smaller, simpler ones.

Refactoring widgets can reduce the complexity of
adopting an adaptive UI by sharing core pieces of code.
There are other benefits as well:

* On the performance side, having lots of small `const`
  widgets improves rebuild times over having large,
  complex widgets.
* Flutter can reuse `const` widget instances,
  while a larger complex widget has to be set up
  for every rebuild.
* From a code health perspective, organizing your UI
  into smaller bite sized pieces helps keep the complexity
  of each `Widget` down. A less-complex `Widget` is more readable,
  easier to refactor, and less likely to have surprising behavior.

To learn more, check out the 3 steps of
adaptive design in [General approach][].

[General approach]: /ui/adaptive-responsive/general

### Design to the strengths of each form factor

Beyond screen size, you should also spend time
considering the unique strengths and weaknesses
of different form factors. It isn't always ideal
for your multiplatform app to offer identical
functionality everywhere. Consider whether it makes
sense to focus on specific capabilities,
or even remove certain features, on some device categories.

For example, mobile devices are portable and have cameras,
but they aren't well suited for detailed creative work.
With this in mind, you might focus more on capturing content
and tagging it with location data for a mobile UI,
but focus on organizing or manipulating that content
for a tablet or desktop UI.

Another example is leveraging the web's extremely low barrier
for sharing. If you're deploying a web app,
decide which [deep links][] to support,
and design your navigation routes with those in mind.

The key takeaway here is to think about what each
platform does best and see if there are unique capabilities
you can leverage.

[deep links]: /ui/navigation/deep-linking

### Solve touch first

Building a great touch UI can often be more difficult
than a traditional desktop UI due, in part,
to the lack of input accelerators like right-click,
scroll wheel, or keyboard shortcuts.

One way to approach this challenge is to focus initially
on a great touch-oriented UI. You can still do most of
your testing using the desktop target for its iteration speed.
But, remember to switch frequently to a mobile device to
verify that everything feels right.

After you have the touch interface polished, you can tweak
the visual density for mouse users, and then layer on all
the additional inputs. Approach these other inputs as
accelerator—alternatives that make a task faster.
The important thing to consider is what a user expects
when using a particular input device,
and work to reflect that in your app.

## Implementation details

### Don't lock the orientation of your app.

An adaptive app should look good on windows of
different sizes and shapes. While locking an app
to portrait mode on phones can help narrow the scope
of a minimum viable product, it can increase the
effort required to make the app adaptive in the future.

For example, the assumption that phones will only
render your app in a full screen portrait mode is
not a guarantee. Multi window app support is becoming common,
and foldables have many use cases that work best with
multiple apps running side by side.

If you absolutely must lock your app in portrait mode (but don't),
use the `Display` API instead of something like `MediaQuery`
to get the physical dimensions of the screen.

To summarize:

  * Locked screens can be [an accessibility issue][] for some users
  * Android large format tiers require portrait and landscape
    support at the [lowest level][].
  * Android devices can [override a locked screen][]
  * Apple guidelines say [aim to support both orientations][]

[an accessibility issue]: https://www.w3.org/WAI/WCAG21/Understanding/orientation.html
[aim to support both orientations]: https://www.w3.org/WAI/WCAG21/Understanding/orientation.html
[lowest level]:  {{site.android-dev}}/docs/quality-guidelines/large-screen-app-quality#T3-8
[override a locked screen]: {{site.android-dev}}/guide/topics/large-screens/large-screen-compatibility-mode#per-app_overrides

### Avoid device orientation-based layouts

Avoid using `MediaQuery`'s orientation field
or `OrientationBuilder` near the top of your widget tree
to switch between different app layouts. This is
similar to the guidance of not checking device types
to determine screen size. The device's orientation also
doesn't necessarily inform you of how much space your
app window has.

Instead, use `MediaQuery`'s `sizeOf` or `LayoutBuilder`,
as discussed in the [General approach][] page.
Then use adaptive breakpoints like the ones that
[Material][] recommends.

[General approach]: /ui/adaptive-responsive/general#
[Material]: https://m3.material.io/foundations/layout/applying-layout/window-size-classes

### Don't gobble up all of the horizontal space

Apps that use the full width of the window to
display boxes or text fields don't play well
when these apps run on large screens.

To learn how to avoid this,
check out [Layout with GridView][].

[Layout with GridView]: /ui/adaptive-responsive/large-screens#layout-with-gridview

### Avoid checking for hardware types

Avoid writing code that checks whether the device you're
running on is a "phone" or a "tablet", or any other type
of device when making layout decisions.

What space your app is actually given to render in
isn't always tied to the full screen size of the device.
Flutter can run on many different platforms,
and your app might be running in a resizeable window on ChromeOS,
side by side with another app on tablets in a multi-window mode,
or even in a picture-in-picture on phones.
Therefore, device type and app window size aren't
really strongly connected.

Instead, use `MediaQuery` to get the size of the window
your app is currently running in.

This isn't only helpful for UI code.
To learn how abstracting out device
capabilities can help your business logic code,
check out the 2022 Google I/O talk,
[Flutter lessons for federated plugin development][].

[Flutter lessons for federated plugin development]: {{site.youtube-site}}/watch?v=GAnSNplNpCA

### Support a variety of input devices

Apps should support basic mice, trackpads,
and keyboard shortcuts. The most common user
flows should support keyboard navigation
to ensure accessibility. In particular,
your app follow accessible best practices
for keyboards on large devices.

The Material library provides widgets with
excellent default behavior for touch, mouse,
and keyboard interaction.

To learn how to add this support to custom widgets,
check out [User input & accessibility][].

[User input & accessibility]: /ui/adaptive-responsive/input

### Restore List state

To maintain the scroll position in a list
that doesn't change its layout when the
device's orientation changes,
use the [`PageStorageKey`][] class.
[`PageStorageKey`][] persists the
widget state in storage after the widget is
destroyed and restores state when recreated.

You can see an example of this in the [Wonderous app][],
where it stores the list's state in the
`SingleChildScrollView` widget.

If the `List` widget changes its layout
when the device's orientation changes,
you might have to do a bit of math ([example][])
to change the scroll position on screen rotation.

[example]: {{site.github}}/gskinnerTeam/flutter-wonderous-app/blob/34e49a08084fbbe69ed67be948ab00ef23819313/lib/ui/screens/collection/widgets/_collection_list.dart#L39
[`PageStorageKey`]: {{site.api}}/flutter/widgets/PageStorageKey-class.html
[Wonderous app]: {{site.github}}/gskinnerTeam/flutter-wonderous-app/blob/8a29d6709668980340b1b59c3d3588f123edd4d8/lib/ui/screens/wonder_events/widgets/_events_list.dart#L64

## Save app state

Apps should retain or restore [app state][]
as the device rotates, changes window size,
or folds and unfolds.
By default, an app should maintain state.

If your app loses state during device configuration,
verify that the plugins and native extensions
that your app uses support the
device type, such as a large screen.
Some native extensions might lose state when the
device changes position.

For more information on a real-world case
where this occurred, check out
[Problem: Folding/unfolding causes state loss][state-loss]
in [Developing Flutter apps for Large screens][article],
a free article on Medium.

[app state]: {{site.android-dev}}/jetpack/compose/state#store-state
[article]: {{site.flutter-blog}}/developing-flutter-apps-for-large-screens-53b7b0e17f10
[state-loss]: {{site.flutter-blog}}/developing-flutter-apps-for-large-screens-53b7b0e17f10#:~:text=Problem%3A%20Folding/Unfolding%20causes%20state%2Dloss

---
title: Capabilities & policies
description: >-
  Learn how to adapt your app to the
  capabilities and policies required
  by the platform, app store, your company,
  and so on.
---

Most real-world apps have the need to adapt to the
capabilities and policies of different devices and platforms.
This page contains advice for how to
handle these scenarios in your code.

## Design to the strengths of each device type

Consider the unique strengths and weaknesses of different devices.
Beyond their screen size and inputs, such as touch, mouse, keyboard,
what other unique capabilities can you leverage?
Flutter enables your code to _run_ on different devices,
but strong design is more than just running code.
Think about what each platform does best and
see if there are unique capabilities to leverage.

For example: Apple's App Store and Google's Play Store
have different rules that apps need to abide by.
Different host operating systems have differing
capabilities across time as well as each other.

Another example is leveraging the web's extremely
low barrier for sharing. If you're deploying a web app,
decide what deep links to support,
and design the navigation routes with those in mind.

Flutter's recommended pattern for handling different
behavior based on these unique capabilities is to create
a set of `Capability` and `Policy` classes for your app.

### Capabilities

A _capability_ defines what the code or device _can_ do.
Examples of capabilities include:

* The existence of an API
* OS-enforced restrictions
* Physical hardware requirements (like a camera)

### Policies

A _policy_ defines what the code _should_ do.

Examples of policies include:

* App store guidelines
* Design preferences
* Assets or copy that refers to the host device
* Features enabled on the server side

### How to structure policy code

The simplest mechanical way is `Platform.isAndroid`,
`Platform.isIOS`, and `kIsWeb`. These APIs mechanically
let you know where the code is running but have some
problems as the app expands where it can run, and
as host platforms add functionality.

The following guidelines explain best practices
when developing the capabilities and policies for your app:

**Avoid using `Platform.isAndroid` and similar functions
to make layout decisions or assumptions about what a device can do.**

Instead, describe what you want to branch on in a method.

Example: Your app has a link to buy something in a
website, but you don't want to show that link on iOS
devices for policy reasons.

```dart
bool shouldAllowPurchaseClick() {
  // Banned by Apple App Store guidelines.
  return !Platform.isIOS;
}

...
TextSpan(
  text: 'Buy in browser',
  style: new TextStyle(color: Colors.blue),
  recognizer: shouldAllowPurchaseClick ? TapGestureRecognizer()
    ..onTap = () { launch('<some url>') : null;
  } : null,
```

What did you get by adding an additional layer of indirection?
The code makes it more clear why the branched path exists.
This method can exist directly in the class but it's likely
that other parts of the code might need this same check.
If so, put the code in a class.

```dart title="policy.dart"

class Policy {

  bool shouldAllowPurchaseClick() {
    // Banned by Apple App Store guidelines.
    return !Platform.isIOS;
  }
}
```

With this code in a class, any widget test can mock
`Policy().shouldAllowPurchaseClick` and verify the behavior
independently of where the device runs.
It also means that later, if you decide that
buying on the web isn't the right flow for
Android users, you can change the implementation
and the tests for clickable text won't need to change.

## Capabilities

Sometimes you want your code to do something but the
API doesn't exist, or maybe you depend on a plugin feature
that isn't yet implemented on all of the platforms you support.
This is a limitation of what the device _can_ do.

Those situations are similar to the policy decisions
described above, but these are referred to as _capabilities_.
Why separate policy classes from capabilities
when the structure of the classes is similar?
The Flutter team has found with productionized apps that making
a logical distinction between what apps _can_ do and
what they _should_ do helps larger products respond to
changes in what platforms can do or require
in addition to your own preferences after
the initial code is written.

For example, consider the case where one platform adds
a new permission that requires users to interact with
a system dialog before your code calls a sensitive API.
Your team does the work for platform 1 and creates a
capability named `requirePermissionDialogFlow`.
Then, if and when platform 2 adds a similar requirement
but only for new API versions,
then the implementation of `requirePermissionDialogFlow`
can now check the API level and return true for platform 2.
You've leveraged the work you already did.

## Policies

We encourage starting with a `Policy` class initially
even if it seems like you won't make many policy based decisions.
As the complexity of the class grows or the number of inputs expands,
you might decide to break up the policy class by feature
or some other criteria.

For policy implementation, you can use compile time,
run time, or Remote Procedure Call (RPC) backed implementations.

Compile-time policy checks are good for platforms
where the preference is unlikely to change and where
accidentally changing the value might have large consequences.
For example, if a platform requires that you not
link to the Play store, or requires that you use
a specific payment provider given the content of your app.

Runtime checks can be good for determining if there
is a touch screen the user can use. Android has a feature
you can check and your web implementation could
check for max touch points.

RPC-backed policy changes are good for incremental
feature rollout or for decisions that might change later.

## Summary

Use a `Capability` class to define what the code *can* do.
You might check against the existence of an API,
OS-enforced restrictions,
and physical hardware requirements (like a camera).
A capability usually involves compile or runtime checks.

Use a `Policy` class (or classes depending on complexity)
to define what the code _should_ do to comply with
App store guidelines, design preferences,
and assets or copy that need to refer to the host device.
Policies can be a mix of compile, runtime, or RPC checks.

Test the branching code by mocking capabilities and
policies so the widget tests don't need to change
when capabilities or policies change.

Name the methods in your capabilities and policies classes
based on what they are trying to branch, rather than on device type.

---
title: General approach to adaptive apps
description: >-
  General advice on how to approach making your Flutter app adaptive.
shortTitle: General approach
---

<?code-excerpt path-base="ui/adaptive_app_demos"?>

So, just _how_ do you approach taking an app
designed for conventional mobile devices,
and make it beautiful on a wide range
of devices? What steps are required?

Google engineers, who have experience doing this
very thing for large apps, recommend the
following 3-step approach.

## Step 1: Abstract

![Step 1: Abstract info common to any UI widget](/assets/images/docs/ui/adaptive-responsive/abstract.png)

First, identify the widgets that you plan to
make dynamic. Analyze the constructors for those
widgets and abstract out the data that you can share.

Common widgets that require adaptability are:

* Dialogs, both fullscreen and modal
* Navigation UI, both rail and bottom bar
* Custom layout, such as "is the UI area taller or wider?"

For example, in a `Dialog` widget, you can share
the info that contains the _content_ of the dialog.

Or, perhaps you want to switch between a
`NavigationBar` when the app window is small,
and a `NavigationRail` when the app window is large.
These widgets would likely share a list of
navigable destinations. In this case,
you might create a `Destination` widget to hold
this info, and specify the `Destination` as having both
an icon and a text label.

Next, you will evaluate your screen size to decide
on how to display your UI.

## Step 2: Measure

![Step 2: How to measure screen size](/assets/images/docs/ui/adaptive-responsive/measure.png)

You have two ways to determine the size of your display area:
`MediaQuery` and `LayoutBuilder`.

### MediaQuery

In the past, you might have used `MediaQuery.of` to
determine the size of the device's screen.
However, devices today feature screens
with a wide variety of sizes and shapes,
and this test can be misleading.

For example, maybe your app currently occupies a
small window on a large screen. If you use the
`MediaQuery.of` method and conclude the screen to be small
(when, in fact, the app displays in a tiny window on a large screen),
and you've portrait locked your app, it causes the
app's window to lock to the center of the
screen, surrounded with black.
This is hardly an ideal UI on a large screen.

:::note
The Material Guidelines encourage you to never
_portrait lock_ your app (by disabling landscape mode).
However, if you feel you really must,
then at least define the portrait mode to work
in top-down mode as well as bottom up.
:::

Keep in mind that `MediaQuery.sizeOf` returns the
current size of the app's entire screen and
not just a single widget.

You have two ways to measure your screen space.
You can use either `MediaQuery.sizeOf` or `LayoutBuilder`,
depending on whether you want the size of the whole
app window, or more local sizing.

If you want your widget to be fullscreen,
even when the app window is small,
use `MediaQuery.sizeOf` so you can choose the
UI based on the size of the app window itself.
In the previous section, you want to base the
sizing behavior on the entire app's window,
so you would use `MediaQuery.sizeOf`.

:::secondary Why use `MediaQuery.sizeOf` instead of `MediaQuery.of`?
Previous advice recommended that you use the `of` method of
`MediaQuery` to obtain the app window's dimensions.
Why has this advice changed?
The short answer is **for performance reasons.**

`MediaQuery` contains a lot of data, but if you're
only interested in the size property, it's more
efficient to use the `sizeOf` method. Both methods
return the size of the app window in logical pixels
(also known as _density independent pixels_).
The logical pixel dimensions generally works best as its
roughly the same visual size across all devices.
The `MediaQuery` class has other specialized functions
for each of its individual properties for the same reason.
:::

Requesting the size of the app window from inside
the `build` method, as in `MediaQuery.sizeOf(context)`,
causes the given `BuildContext` to rebuild any time
the size property changes.

### LayoutBuilder

`LayoutBuilder` accomplishes a similar goal as
`MediaQuery.sizeOf`, with some distinctions.

Rather than providing the size of the app's window,
`LayoutBuilder` provides the layout constraints from
the parent `Widget`. This means that you get
sizing information based on the specific spot
in the widget tree where you added the `LayoutBuilder`.
Also, `LayoutBuilder` returns a `BoxConstraints`
object instead of a `Size` object,
so you are given the valid width
and height ranges (minimum and maximum) for the content,
rather than just a fixed size.
This can be useful for custom widgets.

For example, imagine a custom widget, where you want
the sizing to be based on the space specifically
given to that widget, and not the app window in general.
In this scenario, use `LayoutBuilder`.

## Step 3: Branch

![Step 3: Branch the code based on the desired UI](/assets/images/docs/ui/adaptive-responsive/branch.png)

At this point, you must decide what sizing breakpoints to use
when choosing what version of the UI to display.
For example, the [Material layout][] guidelines suggest using
a bottom nav bar for windows less than 600 logical pixels wide,
and a nav rail for those that are 600 pixels wide or greater.
Again, your choice shouldn't depend on the _type_ of device,
but on the device's available window size.

[Material layout]: https://m3.material.io/foundations/layout/applying-layout/window-size-classes

To work through an example that switches between a
`NavigationRail` and a `NavigationBar`, check out
the [Building an animated responsive app layout with Material 3][codelab].

[codelab]: {{site.codelabs}}/codelabs/flutter-animated-responsive-layout

The next page discusses how to ensure that your
app looks best on large screens and foldables.

---
title: Platform idioms
description: >-
  Learn how to create a responsive app
  that responds to changes in the screen size.
shortTitle: Idioms
---

<?code-excerpt path-base="ui/adaptive_app_demos"?>

The final area to consider for adaptive apps is platform standards.
Each platform has its own idioms and norms;
these nominal or de facto standards inform user expectations
of how an application should behave. Thanks, in part to the web,
users are accustomed to more customized experiences,
but reflecting these platform standards can still provide
significant benefits:

* **Reduce cognitive load**
: By matching the user's existing mental model,
  accomplishing tasks becomes intuitive,
  which requires less thinking,
  boosts productivity, and reduces frustrations.

* **Build trust**
: Users can become wary or suspicious
  when applications don't adhere to their expectations.
  Conversely, a UI that feels familiar can build user trust
  and can help improve the perception of quality.
  This often has the added benefit of better app store
  ratings—something we can all appreciate!

## Consider expected behavior on each platform

The first step is to spend some time considering what
the expected appearance, presentation,
or behavior is on this platform.
Try to forget any limitations of your current implementation,
and just envision the ideal user experience.
Work backwards from there.

Another way to think about this is to ask,
"How would a user of this platform expect to achieve this goal?"
Then, try to envision how that would work in your app
without any compromises.

This can be difficult if you aren't a regular user of the platform.
You might be unaware of the specific idioms and can easily miss
them completely. For example, a lifetime Android user is
likely unaware of platform conventions on iOS,
and the same holds true for macOS, Linux, and Windows.
These differences might be subtle to you,
but be painfully obvious to an experienced user.

### Find a platform advocate

If possible, assign someone as an advocate for each platform.
Ideally, your advocate uses the platform as their primary device,
and can offer the perspective of a highly opinionated user.
To reduce the number of people, combine roles.
Have one advocate for Windows and Android,
one for Linux and the web, and one for Mac and iOS.

The goal is to have constant, informed feedback so the app
feels great on each platform. Advocates should be encouraged
to be quite picky, calling out anything they feel differs from
typical applications on their device. A simple example is how
the default button in a dialog is typically on the left on Mac
and Linux, but is on the right on Windows.
Details like that are easy to miss if you aren't using a platform
on a regular basis.

:::secondary Important
Advocates don't need to be developers or
even full-time team members. They can be designers,
stakeholders, or external testers that are provided
with regular builds.
:::

### Stay unique

Conforming to expected behaviors doesn't mean that your app
needs to use default components or styling.
Many of the most popular multiplatform apps have very distinct
and opinionated UIs including custom buttons, context menus,
and title bars.

The more you can consolidate styling and behavior across platforms,
the easier development and testing will be.
The trick is to balance creating a unique experience with a
strong identity, while respecting the norms of each platform.

## Common idioms and norms to consider

Take a quick look at a few specific norms and idioms
you might want to consider, and how you could approach
them in Flutter.

### Scrollbar appearance and behavior

Desktop and mobile users expect scrollbars,
but they expect them to behave differently on different platforms.
Mobile users expect smaller scrollbars that only appear
while scrolling, whereas desktop users generally expect
omnipresent, larger scrollbars that they can click or drag.

Flutter comes with a built-in `Scrollbar` widget that already
has support for adaptive colors and sizes according to the
current platform. The one tweak you might want to make is to
toggle `alwaysShown` when on a desktop platform:

<?code-excerpt "lib/pages/adaptive_grid_page.dart (scrollbar-always-shown)"?>
```dart
return Scrollbar(
  thumbVisibility: DeviceType.isDesktop,
  controller: _scrollController,
  child: GridView.count(
    controller: _scrollController,
    padding: const EdgeInsets.all(Insets.extraLarge),
    childAspectRatio: 1,
    crossAxisCount: colCount,
    children: listChildren,
  ),
);
```

This subtle attention to detail can make your app feel more
comfortable on a given platform.

### Multi-select

Dealing with multi-select within a list is another area
with subtle differences across platforms:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (multi-select-shift)"?>
```dart
static bool get isSpanSelectModifierDown =>
    isKeyDown({LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight});
```

To perform a platform-aware check for control or command,
you can write something like this:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (multi-select-modifier-down)"?>
```dart
static bool get isMultiSelectModifierDown {
  bool isDown = false;
  if (Platform.isMacOS) {
    isDown = isKeyDown({
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    });
  } else {
    isDown = isKeyDown({
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
    });
  }
  return isDown;
}
```

A final consideration for keyboard users is the **Select All** action.
If you have a large list of items of selectable items,
many of your keyboard users will expect that they can use
`Control+A` to select all the items.

#### Touch devices

On touch devices, multi-selection is typically simplified,
with the expected behavior being similar to having the
`isMultiSelectModifier` down on the desktop.
You can select or deselect items using a single tap,
and will usually have a button to **Select All** or
**Clear** the current selection.

How you handle multi-selection on different devices depends
on your specific use cases, but the important thing is to
make sure that you're offering each platform the best
interaction model possible.

### Selectable text

A common expectation on the web (and to a lesser extent desktop)
is that most visible text can be selected with the mouse cursor.
When text is not selectable,
users on the web tend to have an adverse reaction.

Luckily, this is easy to support with the [`SelectableText`][] widget:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (selectable-text)"?>
```dart
return const SelectableText('Select me!');
```

To support rich text, then use `TextSpan`:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (rich-text-span)"?>
```dart
return const SelectableText.rich(
  TextSpan(
    children: [
      TextSpan(text: 'Hello'),
      TextSpan(
        text: 'Bold',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  ),
);
```

[`SelectableText`]: {{site.api}}/flutter/material/SelectableText-class.html

### Title bars

On modern desktop applications, it's common to customize
the title bar of your app window, adding a logo for
stronger branding or contextual controls to help save
vertical space in your main UI.

![Samples of title bars](/assets/images/docs/ui/adaptive-responsive/titlebar.png){:width="100%"}

This isn't supported directly in Flutter, but you can use the
[`bits_dojo`][] package to disable the native title bars,
and replace them with your own.

This package lets you add whatever widgets you want to the
`TitleBar` because it uses pure Flutter widgets under the hood.
This makes it easy to adapt the title bar as you navigate
to different sections of the app.

[`bits_dojo`]: {{site.github}}/bitsdojo/bitsdojo_window

### Context menus and tooltips

On desktop, there are several interactions that
manifest as a widget shown in an overlay,
but with differences in how they're triggered, dismissed,
and positioned:

* **Context menu**
: Typically triggered by a right-click,
  a context menu is positioned close to the mouse,
  and is dismissed by clicking anywhere,
  selecting an option from the menu, or clicking outside it.

* **Tooltip**
: Typically triggered by hovering for
  200-400ms over an interactive element,
  a tooltip is usually anchored to a widget
  (as opposed to the mouse position) and is dismissed
  when the mouse cursor leaves that widget.

* **Popup panel (also known as flyout)**
: Similar to a tooltip,
  a popup panel is usually anchored to a widget.
  The main difference is that panels are most often
  shown on a tap event, and they usually don't hide
  themselves when the cursor leaves.
  Instead, panels are typically dismissed by clicking
  outside the panel or by pressing a **Close** or **Submit** button.

To show basic tooltips in Flutter,
use the built-in [`Tooltip`][] widget:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (tooltip)"?>
```dart
return const Tooltip(
  message: 'I am a Tooltip',
  child: Text('Hover over the text to show a tooltip.'),
);
```

Flutter also provides built-in context menus when editing
or selecting text.

To show more advanced tooltips, popup panels,
or create custom context menus,
you either use one of the available packages,
or build it yourself using a `Stack` or `Overlay`.

Some available packages include:

* [`context_menus`][]
* [`anchored_popups`][]
* [`flutter_portal`][]
* [`super_tooltip`][]
* [`custom_pop_up_menu`][]

While these controls can be valuable for touch users as accelerators,
they are essential for mouse users. These users expect
to right-click things, edit content in place,
and hover for more information. Failing to meet those expectations
can lead to disappointed users, or at least,
a feeling that something isn't quite right.

[`anchored_popups`]: {{site.pub}}/packages/anchored_popups
[`context_menus`]: {{site.pub}}/packages/context_menus
[`custom_pop_up_menu`]: {{site.pub}}/packages/custom_pop_up_menu
[`flutter_portal`]: {{site.pub}}/packages/flutter_portal
[`super_tooltip`]: {{site.pub}}/packages/super_tooltip
[`Tooltip`]: {{site.api}}/flutter/material/Tooltip-class.html

### Horizontal button order

On Windows, when presenting a row of buttons,
the confirmation button is placed at the start of
the row (left side). On all other platforms,
it's the opposite. The confirmation button is
placed at the end of the row (right side).

This can be easily handled in Flutter using the
`TextDirection` property on `Row`:

<?code-excerpt "lib/widgets/ok_cancel_dialog.dart (row-text-direction)"?>
```dart
TextDirection btnDirection = DeviceType.isWindows
    ? TextDirection.rtl
    : TextDirection.ltr;
return Row(
  children: [
    const Spacer(),
    Row(
      textDirection: btnDirection,
      children: [
        DialogButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        DialogButton(
          label: 'Ok',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  ],
);
```

![Sample of embedded image](/assets/images/docs/ui/adaptive-responsive/embed_image1.png){:width="75%"}

![Sample of embedded image](/assets/images/docs/ui/adaptive-responsive/embed_image2.png){:width="90%"}

### Menu bar

Another common pattern on desktop apps is the menu bar.
On Windows and Linux, this menu lives as part of the Chrome title bar,
whereas on macOS, it's located along the top of the primary screen.

Currently, you can specify custom menu bar entries using
a prototype plugin, but it's expected that this functionality will
eventually be integrated into the main SDK.

It's worth mentioning that on Windows and Linux,
you can't combine a custom title bar with a menu bar.
When you create a custom title bar,
you're replacing the native one completely,
which means you also lose the integrated native menu bar.

If you need both a custom title bar and a menu bar,
you can achieve that by implementing it in Flutter,
similar to a custom context menu.

### Drag and drop

One of the core interactions for both touch-based and
pointer-based inputs is drag and drop. Although this
interaction is expected for both types of input,
there are important differences to think about when
it comes to scrolling lists of draggable items.

Generally speaking, touch users expect to see drag handles
to differentiate draggable areas from scrollable ones,
or alternatively, to initiate a drag by using a long
press gesture. This is because scrolling and dragging
are both sharing a single finger for input.

Mouse users have more input options. They can use a wheel
or scrollbar to scroll, which generally eliminates the need
for dedicated drag handles. If you look at the macOS
Finder or Windows Explorer, you'll see that they work
this way: you just select an item and start dragging.

In Flutter, you can implement drag and drop in many ways.
Discussing specific implementations is outside
the scope of this article, but some high level options
include the following:

* Use the [`Draggable`][] and [`DragTarget`][] APIs
  directly for a custom look and feel.

* Hook into `onPan` gesture events,
  and move an object yourself within a parent `Stack`.

* Use one of the [pre-made list packages][] on pub.dev.

[`Draggable`]: {{site.api}}/flutter/widgets/Draggable-class.html
[`DragTarget`]: {{site.api}}/flutter/widgets/DragTarget-class.html
[pre-made list packages]: {{site.pub}}/packages?q=reorderable+list


---
title: Adaptive and responsive design in Flutter
description: >-
  It's important to create an app,
  whether for mobile or web,
  that responds to size and orientation changes
  and maximizes the use of each platform.
shortTitle: Adaptive design
---

![List of supported platforms](/assets/images/docs/ui/adaptive-responsive/platforms.png)

One of Flutter's primary goals is to create a framework
that allows you to develop apps from a single codebase
that look and feel great on any platform.

This means that your app might appear on screens of
many different sizes, from a watch, to a foldable
phone with two screens, to a high definition monitor.
And your input device might be a physical or
virtual keyboard, a mouse, a touchscreen, or
any number of other devices.

Two terms that describe these design concepts
are _adaptive_ and _responsive_. Ideally,
you'd want your app to be _both_ but what,
exactly, does this mean?

## What is responsive vs adaptive?

An easy way to think about it is that responsive design
is about fitting the UI _into_ the space and
adaptive design is about the UI being _usable_ in
the space.

So, a responsive app adjusts the placement of design
elements to _fit_ the available space. And an
adaptive app selects the appropriate layout and
input devices to be usable _in_ the available space.
For example, should a tablet UI use bottom navigation or
side-panel navigation?

:::note
Often adaptive and responsive concepts are
collapsed into a single term. Most often,
_adaptive design_ is used to refer to both
adaptive and responsive.
:::

This section covers various aspects of adaptive and
responsive design:

* [General approach][]
* [SafeArea & MediaQuery][]
* [Large screens & foldables][]
* [User input & accessibility][]
* [Capabilities & policies][]
* [Best practices for adaptive apps][]
* [Additional resources][]

[Additional resources]: /ui/adaptive-responsive/more-info
[Best practices for adaptive apps]: /ui/adaptive-responsive/best-practices
[Capabilities & policies]: /ui/adaptive-responsive/capabilities
[General approach]: /ui/adaptive-responsive/general
[Large screens & foldables]: /ui/adaptive-responsive/large-screens
[SafeArea & MediaQuery]: /ui/adaptive-responsive/safearea-mediaquery
[User input & accessibility]: /ui/adaptive-responsive/input

:::note
You might also check out the Google I/O 2024 talk about
this subject.

<YouTubeEmbed id="LeKLGzpsz9I" title="How to build adaptive UI with Flutter"></YouTubeEmbed>
:::


---
title: User input & accessibility
description: >-
  A truly adaptive app also handles differences
  in how user input works and also programs
  to help folks with accessibility issues.
---

<?code-excerpt path-base="ui/adaptive_app_demos"?>

It isn't enough to just adapt how your app looks,
you also have to support a variety of user inputs.
The mouse and keyboard introduce input types beyond those
found on a touch device, like scroll wheel, right-click,
hover interactions, tab traversal, and keyboard shortcuts.

Some of these features work by default on Material
widgets. But, if you've created a custom widget,
you might need to implement them directly.

Some features that encompass a well-designed app,
also help users who work with assistive technologies.
For example, aside from being **good app design**,
some features, like tab traversal and keyboard shortcuts,
are _critical for users who work with assistive devices_.
In addition to the standard advice for
[creating accessible apps][], this page covers
info for creating apps that are both
adaptive _and_ accessible.

[creating accessible apps]: /ui/accessibility

## Scroll wheel for custom widgets

Scrolling widgets like `ScrollView` or `ListView`
support the scroll wheel by default, and because
almost every scrollable custom widget is built
using one of these, it works with those as well.

If you need to implement custom scroll behavior,
you can use the [`Listener`][] widget, which lets you
customize how your UI reacts to the scroll wheel.

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (pointer-scroll)"?>
```dart
return Listener(
  onPointerSignal: (event) {
    if (event is PointerScrollEvent) print(event.scrollDelta.dy);
  },
  child: ListView(),
);
```

[`Listener`]: {{site.api}}/flutter/widgets/Listener-class.html

## Tab traversal and focus interactions

Users with physical keyboards expect that they can use
the tab key to quickly navigate an application,
and users with motor or vision differences often rely
completely on keyboard navigation.

There are two considerations for tab interactions:
how focus moves from widget to widget, known as traversal,
and the visual highlight shown when a widget is focused.

Most built-in components, like buttons and text fields,
support traversal and highlights by default.
If you have your own widget that you want included in
traversal, you can use the [`FocusableActionDetector`][] widget
to create your own controls. The [`FocusableActionDetector`][]
widget is helpful for combining focus, mouse input,
and shortcuts together in one widget. You can create
a detector that defines actions and key bindings,
and provides callbacks for handling focus and hover highlights.

<?code-excerpt "lib/pages/focus_examples_page.dart (focusable-action-detector)"?>
```dart
class _BasicActionDetectorState extends State<BasicActionDetector> {
  bool _hasFocus = false;
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (value) => setState(() => _hasFocus = value),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<Intent>(
          onInvoke: (intent) {
            print('Enter or Space was pressed!');
            return null;
          },
        ),
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const FlutterLogo(size: 100),
          // Position focus in the negative margin for a cool effect
          if (_hasFocus)
            Positioned(
              left: -4,
              top: -4,
              bottom: -4,
              right: -4,
              child: _roundedBorder(),
            ),
        ],
      ),
    );
  }
}
```

[`Actions`]: {{site.api}}/flutter/widgets/Actions-class.html
[`Focus`]: {{site.api}}/flutter/widgets/Focus-class.html
[`FocusableActionDetector`]: {{site.api}}/flutter/widgets/FocusableActionDetector-class.html
[`MouseRegion`]: {{site.api}}/flutter/widgets/MouseRegion-class.html
[`Shortcuts`]: {{site.api}}/flutter/widgets/Shortcuts-class.html

### Controlling traversal order

To get more control over the order that
widgets are focused on when the user tabs through,
you can use [`FocusTraversalGroup`][] to define sections
of the tree that should be treated as a group when tabbing.

For example, you might to tab through all the fields in
a form before tabbing to the submit button:

<?code-excerpt "lib/pages/focus_examples_page.dart (focus-traversal-group)"?>
```dart
return Column(
  children: [
    FocusTraversalGroup(child: MyFormWithMultipleColumnsAndRows()),
    SubmitButton(),
  ],
);
```

Flutter has several built-in ways to traverse widgets and groups,
defaulting to the `ReadingOrderTraversalPolicy` class.
This class usually works well, but it's possible to modify this
using another predefined `TraversalPolicy` class or by creating
a custom policy.

[`FocusTraversalGroup`]: {{site.api}}/flutter/widgets/FocusTraversalGroup-class.html

## Keyboard accelerators

In addition to tab traversal, desktop and web users are accustomed
to having various keyboard shortcuts bound to specific actions.
Whether it's the `Delete` key for quick deletions or
`Control+N` for a new document, be sure to consider the different
accelerators your users expect. The keyboard is a powerful
input tool, so try to squeeze as much efficiency from it as you can.
Your users will appreciate it!

Keyboard accelerators can be accomplished in a few ways in Flutter,
depending on your goals.

If you have a single widget like a `TextField` or a `Button` that
already has a focus node, you can wrap it in a [`KeyboardListener`][]
or a [`Focus`][] widget and listen for keyboard events:

<?code-excerpt "lib/pages/focus_examples_page.dart (focus-keyboard-listener)"?>
```dart
  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          print(event.logicalKey);
        }
        return KeyEventResult.ignored;
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: const TextField(
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
      ),
    );
  }
}
```

To apply a set of keyboard shortcuts to a large section
of the tree, use the [`Shortcuts`][] widget:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (shortcuts)"?>
```dart
// Define a class for each type of shortcut action you want
class CreateNewItemIntent extends Intent {
  const CreateNewItemIntent();
}

Widget build(BuildContext context) {
  return Shortcuts(
    // Bind intents to key combinations
    shortcuts: const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.keyN, control: true):
          CreateNewItemIntent(),
    },
    child: Actions(
      // Bind intents to an actual method in your code
      actions: <Type, Action<Intent>>{
        CreateNewItemIntent: CallbackAction<CreateNewItemIntent>(
          onInvoke: (intent) => _createNewItem(),
        ),
      },
      // Your sub-tree must be wrapped in a focusNode, so it can take focus.
      child: Focus(autofocus: true, child: Container()),
    ),
  );
}
```

The [`Shortcuts`][] widget is useful because it only
allows shortcuts to be fired when this widget tree
or one of its children has focus and is visible.

The final option is a global listener. This listener
can be used for always-on, app-wide shortcuts or for
panels that can accept shortcuts whenever they're visible
(regardless of their focus state). Adding global listeners
is easy with [`HardwareKeyboard`][]:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (hardware-keyboard)"?>
```dart
@override
void initState() {
  super.initState();
  HardwareKeyboard.instance.addHandler(_handleKey);
}

@override
void dispose() {
  HardwareKeyboard.instance.removeHandler(_handleKey);
  super.dispose();
}
```

To check key combinations with the global listener,
you can use the `HardwareKeyboard.instance.logicalKeysPressed` set.
For example, a method like the following can check whether any
of the provided keys are being held down:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (keys-pressed)"?>
```dart
static bool isKeyDown(Set<LogicalKeyboardKey> keys) {
  return keys
      .intersection(HardwareKeyboard.instance.logicalKeysPressed)
      .isNotEmpty;
}
```

Putting these two things together,
you can fire an action when `Shift+N` is pressed:

<?code-excerpt "lib/widgets/extra_widget_excerpts.dart (handle-key)"?>
```dart
bool _handleKey(KeyEvent event) {
  bool isShiftDown = isKeyDown({
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
  });

  if (isShiftDown && event.logicalKey == LogicalKeyboardKey.keyN) {
    _createNewItem();
    return true;
  }

  return false;
}
```

One note of caution when using the static listener,
is that you often need to disable it when the user
is typing in a field or when the widget it's
associated with is hidden from view.
Unlike with `Shortcuts` or `KeyboardListener`,
this is your responsibility to manage. This can be especially
important when you're binding a Delete/Backspace accelerator for
`Delete`, but then have child `TextFields` that the user
might be typing in.

[`HardwareKeyboard`]: {{site.api}}/flutter/services/HardwareKeyboard-class.html
[`KeyboardListener`]: {{site.api}}/flutter/widgets/KeyboardListener-class.html

## Mouse enter, exit, and hover for custom widgets {:#custom-widgets}

On desktop, it's common to change the mouse cursor
to indicate the functionality about the content the
mouse is hovering over. For example, you typically see
a hand cursor when you hover over a button,
or an `I` cursor when you hover over text.

Flutter's Material buttons handle basic focus states
for standard button and text cursors.
(A notable exception is if you change the default styling
of the Material buttons to set the `overlayColor` to transparent.)

Implement a focus state for any custom buttons or
gesture detectors in your app.
If you change the default Material button styles,
test for keyboard focus states and
implement your own, if needed.

To change the cursor from within your custom widgets,
use [`MouseRegion`][]:

<?code-excerpt "lib/pages/focus_examples_page.dart (mouse-region)"?>
```dart
// Show hand cursor
return MouseRegion(
  cursor: SystemMouseCursors.click,
  // Request focus when clicked
  child: GestureDetector(
    onTap: () {
      Focus.of(context).requestFocus();
      _submit();
    },
    child: Logo(showBorder: hasFocus),
  ),
);
```

`MouseRegion` is also useful for creating custom
rollover and hover effects:

<?code-excerpt "lib/pages/focus_examples_page.dart (mouse-over)"?>
```dart
return MouseRegion(
  onEnter: (_) => setState(() => _isMouseOver = true),
  onExit: (_) => setState(() => _isMouseOver = false),
  onHover: (e) => print(e.localPosition),
  child: Container(
    height: 500,
    color: _isMouseOver ? Colors.blue : Colors.black,
  ),
);
```

For an example that changes the button style
to outline the button when it has focus,
check out the [button code for the Wonderous app][].
The app modifies the [`FocusNode.hasFocus`][]
property to check whether the button has focus
and, if so, adds an outline.

[button code for the Wonderous app]: {{site.github}}/gskinnerTeam/flutter-wonderous-app/blob/8a29d6709668980340b1b59c3d3588f123edd4d8/lib/ui/common/controls/buttons.dart#L143
[`FocusNode.hasFocus`]: {{site.api}}/flutter/widgets/FocusNode/hasFocus.html

## Visual density

You might consider enlarging the "hit area"
of a widget to accommodate a touch screen, for example.

Different input devices offer various levels of precision,
which necessitate differently-sized hit areas.
Flutter's `VisualDensity` class makes it easy to adjust the
density of your views across the entire application,
for example, by making a button larger
(and therefore easier to tap) on a touch device.

When you change the `VisualDensity` for
your `MaterialApp`, `MaterialComponents`
that support it animate their densities to match.
By default, both horizontal and vertical densities
are set to 0.0, but you can set the densities to any
negative or positive value that you want.
By switching between different
densities, you can easily adjust your UI.

![Adaptive scaffold](/assets/images/docs/ui/adaptive-responsive/adaptive_scaffold.webp){:width="100%"}

To set a custom visual density,
inject the density into your `MaterialApp` theme:

<?code-excerpt "lib/main.dart (visual-density)"?>
```dart
double densityAmt = touchMode ? 0.0 : -1.0;
VisualDensity density = VisualDensity(
  horizontal: densityAmt,
  vertical: densityAmt,
);
return MaterialApp(
  theme: ThemeData(visualDensity: density),
  home: MainAppScaffold(),
  debugShowCheckedModeBanner: false,
);
```

To use `VisualDensity` inside your own views,
you can look it up:

<?code-excerpt "lib/pages/adaptive_reflow_page.dart (visual-density-own-view)"?>
```dart
VisualDensity density = Theme.of(context).visualDensity;
```

Not only does the container react automatically to changes
in density, it also animates when it changes.
This ties together your custom components,
along with the built-in components,
for a smooth transition effect across the app.

As shown, `VisualDensity` is unit-less,
so it can mean different things to different views.
In the following example, 1 density unit equals 6 pixels,
but this is totally up to you to decide.
The fact that it is unit-less makes it quite versatile,
and it should work in most contexts.

It's worth noting that the Material generally
use a value of around 4 logical pixels for each
visual density unit. For more information about the
supported components, see the [`VisualDensity`][] API.
For more information about density principles in general,
see the [Material Design guide][].

[Material Design guide]: {{site.material2}}/design/layout/applying-density.html#usage
[`VisualDensity`]: {{site.api}}/flutter/material/VisualDensity-class.html

---
title: Large screen devices
description: >-
  Things to keep in mind when adapting apps
  to large screens.
shortTitle: Large screens
---

<?code-excerpt path-base="ui/adaptive_app_demos"?>

This page provides guidance on optimizing your
app to improve its behavior on large screens.

Flutter, like Android, defines [large screens][] as tablets,
foldables, and ChromeOS devices running Android. Flutter
_also_ defines large screen devices as web, desktop,
and iPads.

:::secondary Why do large screens matter, in particular?
Demand for large screens continues to increase.
As of January 2024,
more than [270 million active large screen][large screens]
and foldable devices run on Android and more than
[14.9 million iPad users][].

When your app supports large screens,
it also receives other benefits.
Optimizing your app to fill the screen.
For example, it:

* Improves your app's user engagement metrics.
* Increases your app's visibility in the Play Store.
  Recent [Play Store updates][] show ratings by
  device type and indicates when an app lacks
  large screen support.
* Ensures that your app meets iPadOS submission
  guidelines and is [accepted in the App Store][].
:::

[14.9 million iPad users]: https://www.statista.com/statistics/299632/tablet-shipments-apple/
[accepted in the App Store]: https://developer.apple.com/ipados/submit/
[large screens]: {{site.android-dev}}/guide/topics/large-screens/get-started-with-large-screens
[Play Store updates]: {{site.android-dev}}/2022/03/helping-users-discover-quality-apps-on.html

## Layout with GridView

Consider the following screenshots of an app.
The app displays its UI in a `ListView`.
The image on the left shows the app running
on a mobile device. The image on the right shows the
app running on a large screen device
_before the advice on this page was applied_.

![Sample of large screen](/assets/images/docs/ui/adaptive-responsive/large-screen.png){:width="90%"}

This is not optimal.

The [Android Large Screen App Quality Guidelines][guidelines]
and the [iOS equivalent][]
say that neither text nor boxes should take up the
full screen width. How to solve this in an adaptive way?

[guidelines]: https://developer.android.com/docs/quality-guidelines/large-screen-app-quality
[iOS equivalent]: https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados

A common solution uses `GridView`, as shown in the next section.

### GridView

You can use the `GridView` widget to transform
your existing `ListView` into more reasonably-sized items.

`GridView` is similar to the [`ListView`][] widget,
but instead of handling only a list of widgets arranged linearly,
`GridView` can arrange widgets in a two-dimensional array.

`GridView` also has constructors that are similar to `ListView`.
The `ListView` default constructor maps to `GridView.count`,
and `ListView.builder` is similar to `GridView.builder`.

`GridView` has some additional constructors for more custom layouts.
To learn more, visit the [`GridView`][] API page.

[`GridView`]: {{site.api}}/flutter/widgets/GridView-class.html
[`ListView`]: {{site.api}}/flutter/widgets/ListView-class.html

For example, if your original app used a `ListView.builder`,
swap that out for a `GridView.builder`.
If your app has a large number of items,
it's recommended to use this builder constructor to only
build the item widgets that are actually visible.

Most of the parameters in the constructor are the same between
the two widgets, so it's a straightforward swap.
However, you need to figure out what to set for the `gridDelegate`.

Flutter provides powerful premade `gridDelegates`
that you can use, namely:

[`SliverGridDelegateWithFixedCrossAxisCount`][]
: Lets you assign a specific number of columns to your grid.

[`SliverGridDelegateWithMaxCrossAxisExtent`][]
: Lets you define a max item width.

[`SliverGridDelegateWithFixedCrossAxisCount`]: {{site.api}}/flutter/rendering/SliverGridDelegateWithFixedCrossAxisCount-class.html
[`SliverGridDelegateWithMaxCrossAxisExtent`]:  {{site.api}}/flutter/rendering/SliverGridDelegateWithMaxCrossAxisExtent-class.html

:::secondary
Don't use the grid delegate for these classes that lets
you set the column count directly and then hardcode
the number of columns based on whether the device
is a tablet, or whatever.
The number of columns should be based on the size of
the window and not the size of the physical device.

This distinction is important because many mobile
devices support multi-window mode, which can
cause your app to be rendered in a space smaller than
the physical size of the display. Also, Flutter apps
can run on web and desktop, which might be sized in many ways.
**For this reason, use `MediaQuery` to get the app window size
rather than the physical device size.**
:::

### Other solutions

Another way to approach these situations is to
use the `maxWidth` property of `BoxConstraints`.
This involves the following:

* Wrap the `GridView`in a `ConstrainedBox` and give
  it a `BoxConstraints` with a maximum width set.
* Use a `Container` instead of a `ConstrainedBox`
  if you want other functionality like setting the
  background color.

For choosing the maximum width value,
consider using the values recommended
by Material 3 in the [Applying layout][] guide.

[Applying layout]: https://m3.material.io/foundations/layout/applying-layout/window-size-classes

## Foldables

As mentioned previously, Android and Flutter both
recommend in their design guidance **not**
to lock screen orientation,
but some apps lock screen orientation anyway.
Be aware that this can cause problems when running your
app on a foldable device.

When running on a foldable, the app might look ok
when the device is folded. But when unfolding,
you might find the app letterboxed.

As described in the [SafeArea & MediaQuery][sa-mq] page,
letterboxing means that the app's window is locked to
the center of the screen while the window is
surrounded with black.

[sa-mq]: /ui/adaptive-responsive/safearea-mediaquery

Why can this happen?

This can happen when using `MediaQuery` to figure out
the window size for your app. When the device is folded,
orientation is restricted to portrait mode.
Under the hood, `setPreferredOrientations` causes
Android to use a portrait compatibility mode and the app
is displayed in a letterboxed state.
In the letterboxed state, `MediaQuery` never receives
the larger window size that allows the UI to expand.

You can solve this in one of two ways:

* Support all orientations.
* Use the dimensions of the _physical display_.
  In fact, this is one of the _few_ situations where
  you would use the physical display dimensions and
  _not_ the window dimensions.

How to obtain the physical screen dimensions?

You can use the [`Display`][] API, introduced in
Flutter 3.13, which contains the size,
pixel ratio, and the refresh rate of the physical device.

[`Display`]: {{site.api}}/flutter/dart-ui/Display-class.html

The following sample code retrieves a `Display` object:

```dart
/// AppState object.
ui.FlutterView? _view;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _view = View.maybeOf(context);
}

void didChangeMetrics() {
  final ui.Display? display = _view?.display;
}
```

The important thing is to find the display of the
view that you care about. This creates a forward-looking
API that should handle current _and_ future multi-display
and multi-view devices.

## Adaptive input

Adding support for more screens, also means
expanding input controls.

Android guidelines describe three tiers of large format device support.

![3 tiers of large format device support](/assets/images/docs/ui/adaptive-responsive/large-screen-guidelines.png){:width="90%"}

Tier 3, the lowest level of support,
includes support for mouse and stylus input
([Material 3 guidelines][m3-guide], [Apple guidelines][]).

If your app uses Material 3 and its buttons and selectors,
then your app already has built-in support for
various additional input states.

But what if you have a custom widget?
Check out the [User input][] page for
guidance on adding
[input support for widgets][].

[Apple guidelines]: https://developer.apple.com/design/human-interface-guidelines/designing-for-ipados#Best-practices
[input support for widgets]: /ui/adaptive-responsive/input#custom-widgets
[m3-guide]: {{site.android-dev}}/docs/quality-guidelines/large-screen-app-quality
[User input]: /ui/adaptive-responsive/input

### Navigation

Navigation can create unique challenges when working with a variety of
differently-sized devices. Generally, you want to switch between
a [`BottomNavigationBar`][] and a [`NavigationRail`] depending on
available screen space.

For more information (and corresponding example code),
check out [Problem: Navigation rail][], a section in the
[Developing Flutter apps for Large screens][article] article.

[article]: {{site.flutter-blog}}/developing-flutter-apps-for-large-screens-53b7b0e17f10
[`BottomNavigationBar`]: {{site.api}}/flutter/material/BottomNavigationBar-class.html
[`NavigationRail`]: {{site.api}}/flutter/material/NavigationRail-class.html
[Problem: Navigation rail]: {{site.flutter-blog}}/developing-flutter-apps-for-large-screens-53b7b0e17f10#:~:text=Problem%3A%20Navigation%20rail1

---
title: Additional resources
description: >-
  Other resources that you might find useful
  when writing adaptive apps.
shortTitle: Learn
---

## Examples

If you'd like to see how the adaptive and responsive
concepts (as described in these pages) come together.
check out the source code for the following apps:

* [Wonderous][]
* [Flutter adaptive demo][]

[Flutter adaptive demo]: {{site.github}}/gskinnerTeam/flutter-adaptive-demo
[Wonderous]: {{site.github}}/gskinnerTeam/flutter-wonderous-app

## Learn more about basic usability principles

Of course, these pages don't constitute an
exhaustive list of the things you might consider.
The more operating systems, form factors,
and input devices you support, the more difficult
it becomes to spec out every permutation in design.

Taking time to learn basic usability principles as a
developer empowers you to make better decisions,
reduces back-and-forth iterations with
design during production, and results in
improved productivity with better outcomes.

Here are some resources that you might find useful:

* [Android large screen guidelines][]
* [Material guidelines on applying layout][]
* [Material design for large screens][]
* [Material guidelines on canonical layouts][]
* [Build high quality apps (Android)][]
* [UI design do's and don'ts (Apple)][]
* [Human interface guidelines (Apple)][]
* [Responsive design techniques (Microsoft)][]
* [Machine sizes and breakpoints (Microsoft)][]
* [How to build Adaptive UI with Flutter][],
  a Google I/O 2024 video.

[Android large screen guidelines]: {{site.android-dev}}/docs/quality-guidelines/large-screen-app-quality
[Build high quality apps (Android)]: {{site.android-dev}}/quality
[How to build Adaptive UI with Flutter]: {{site.youtube-site}}/watch?v=LeKLGzpsz9I
[Material guidelines on applying layout]: {{site.material}}/foundations/layout/applying-layout/window-size-classes
[Material guidelines on canonical layouts]: {{site.material}}/foundations/layout/canonical-layouts/overview
[Human interface guidelines (Apple)]: {{site.apple-dev}}/design/human-interface-guidelines/
[Material design for large screens]: {{site.material2}}/blog/material-design-for-large-screens
[Machine sizes and breakpoints (Microsoft)]: https://docs.microsoft.com/en-us/windows/uwp/design/layout/screen-sizes-and-breakpoints-for-responsive-desig
[Responsive design techniques (Microsoft)]: https://docs.microsoft.com/en-us/windows/uwp/design/layout/responsive-design
[UI design do's and don'ts (Apple)]: {{site.apple-dev}}/design/tips/

---
title: Automatic platform adaptations
description: Learn more about Flutter's platform adaptiveness.
---

## Adaptation philosophy

In general, two cases of platform adaptiveness exist:

1. Things that are behaviors of the OS environment
   (such as text editing and scrolling) and that
   would be 'wrong' if a different behavior took place.
2. Things that are conventionally implemented in apps using
   the OEM's SDKs (such as using parallel tabs on iOS or
   showing an [`android.app.AlertDialog`][] on Android).

This article mainly covers the automatic adaptations
provided by Flutter in case 1 on Android and iOS.

For case 2, Flutter bundles the means to produce the
appropriate effects of the platform conventions but doesn't
adapt automatically when app design choices are needed.
For a discussion, see [issue #8410][] and the
[Material/Cupertino adaptive widget problem definition][].

For an example of an app using different information
architecture structures on Android and iOS but sharing
the same content code, see the [platform_design code samples][].

:::secondary
Preliminary guides addressing case 2
are being added to the UI components section.
You can request additional guides by commenting on [issue #8427][8427].
:::

[`android.app.AlertDialog`]: {{site.android-dev}}/reference/android/app/AlertDialog.html
[issue #8410]: {{site.repo.flutter}}/issues/8410#issuecomment-468034023
[Material/Cupertino adaptive widget problem definition]: https://bit.ly/flutter-adaptive-widget-problem
[platform_design code samples]: {{site.repo.samples}}/tree/main/platform_design

## Page navigation

Flutter provides the navigation patterns seen on Android
and iOS and also automatically adapts the navigation animation
to the current platform.

### Navigation transitions

On **Android**, the default [`Navigator.push()`][] transition
is modeled after [`startActivity()`][],
which generally has one bottom-up animation variant.

On **iOS**:

* The default [`Navigator.push()`][] API produces an
  iOS Show/Push style transition that animates from
  end-to-start depending on the locale's RTL setting.
  The page behind the new route also parallax-slides
  in the same direction as in iOS.
* A separate bottom-up transition style exists when
  pushing a page route where [`PageRoute.fullscreenDialog`][]
  is true. This represents iOS's Present/Modal style
  transition and is typically used on fullscreen modal pages.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/navigation-android.webp" img-style="border-radius: 12px;" caption="Android page transition" alt="An animation of the bottom-up page transition on Android" />
  <DashImage figure image="platform-adaptations/navigation-ios.webp" img-style="border-radius: 22px;" caption="iOS push transition" alt="An animation of the end-start style push page transition on iOS" />
  <DashImage figure image="platform-adaptations/navigation-ios-modal.webp" img-style="border-radius: 22px;" caption="iOS present transition" alt="An animation of the bottom-up style present page transition on iOS" />
</div>

[`Navigator.push()`]: {{site.api}}/flutter/widgets/Navigator/push.html
[`startActivity()`]: {{site.android-dev}}/reference/kotlin/android/app/Activity#startactivity
[`PageRoute.fullscreenDialog`]: {{site.api}}/flutter/widgets/PageRoute-class.html

### Platform-specific transition details

On **Android**, Flutter uses the [`ZoomPageTransitionsBuilder`][] animation.
When the user taps on an item, the UI zooms in to a screen that features that item.
When the user taps to go back, the UI zooms out to the previous screen.

On **iOS** when the push style transition is used,
Flutter's bundled [`CupertinoNavigationBar`][]
and [`CupertinoSliverNavigationBar`][] nav bars
automatically animate each subcomponent to its corresponding
subcomponent on the next or previous page's
`CupertinoNavigationBar` or `CupertinoSliverNavigationBar`.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/android-zoom-animation.png" img-style="border-radius: 12px;" caption="Android" alt="An animation of the page transition on Android" />
  <DashImage figure image="platform-adaptations/navigation-ios-nav-bar.webp" img-style="border-radius: 22px;" caption="iOS Nav Bar" alt="An animation of the nav bar transitions during a page transition on iOS" />
</div>

[`ZoomPageTransitionsBuilder`]: {{site.api}}/flutter/material/ZoomPageTransitionsBuilder-class.html
[`CupertinoNavigationBar`]: {{site.api}}/flutter/cupertino/CupertinoNavigationBar-class.html
[`CupertinoSliverNavigationBar`]: {{site.api}}/flutter/cupertino/CupertinoSliverNavigationBar-class.html

### Back navigation

On **Android**,
the OS back button, by default, is sent to Flutter
and pops the top route of the [`WidgetsApp`][]'s Navigator.

On **iOS**,
an edge swipe gesture can be used to pop the top route.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/navigation-android-back.webp" img-style="border-radius: 12px;" caption="Android back button" alt="A page transition triggered by the Android back button" />
  <DashImage figure image="platform-adaptations/navigation-ios-back.webp" img-style="border-radius: 22px;" caption="iOS back swipe gesture" alt="A page transition triggered by an iOS back swipe gesture" />
</div>

[`WidgetsApp`]: {{site.api}}/flutter/widgets/WidgetsApp-class.html

## Scrolling

Scrolling is an important part of the platform's
look and feel, and Flutter automatically adjusts
the scrolling behavior to match the current platform.

### Physics simulation

Android and iOS both have complex scrolling physics
simulations that are difficult to describe verbally.
Generally, iOS's scrollable has more weight and
dynamic friction but Android has more static friction.
Therefore iOS gains high speed more gradually but stops
less abruptly and is more slippery at slow speeds.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/scroll-soft.webp" caption="Soft fling comparison" alt="A soft fling where the iOS scrollable slid longer at lower speed than Android" />
  <DashImage figure image="platform-adaptations/scroll-medium.webp" caption="Medium fling comparison" alt="A medium force fling where the Android scrollable reaches speed faster and stopped more abruptly after reaching a longer distance" />
  <DashImage figure image="platform-adaptations/scroll-strong.webp" caption="Strong fling comparison" alt="A strong fling where the Android scrollable reaches speed faster and covered significantly more distance" />
</div>

### Overscroll behavior

On **Android**,
scrolling past the edge of a scrollable shows an
[overscroll glow indicator][] (based on the color
of the current Material theme).

On **iOS**, scrolling past the edge of a scrollable
[overscrolls][] with increasing resistance and snaps back.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/scroll-overscroll.webp" caption="Dynamic overscroll comparison" alt="Android and iOS scrollables being flung past their edge and exhibiting platform specific overscroll behavior" />
  <DashImage figure image="platform-adaptations/scroll-static-overscroll.webp" caption="Static overscroll comparison" alt="Android and iOS scrollables being overscrolled from a resting position and exhibiting platform specific overscroll behavior" />
</div>

[overscroll glow indicator]: {{site.api}}/flutter/widgets/GlowingOverscrollIndicator-class.html
[overscrolls]: {{site.api}}/flutter/widgets/BouncingScrollPhysics-class.html

### Scrollbars

On **Material-based platforms** (such as Android and web),
scrollbars are typically visible during scrolling
and may remain visible depending on the platform and theme.

On **Cupertino-based platforms** (such as iOS),
scrollbars are more minimal and generally only appear briefly
while the user is actively scrolling, fading out when interaction stops.

This difference reflects each platform’s visual conventions
and helps maintain a native look and feel across devices.

### Momentum

On **iOS**,
repeated flings in the same direction stacks momentum
and builds more speed with each successive fling.
There is no equivalent behavior on Android.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/scroll-momentum-ios.webp" caption="iOS scroll momentum" alt="Repeated scroll flings building momentum on iOS" />
</div>

### Return to top

On **iOS**,
tapping the OS status bar scrolls the primary
scroll controller to the top position.
There is no equivalent behavior on Android.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/scroll-tap-to-top-ios.webp" img-style="border-radius: 22px;" caption="iOS status bar tap to top" alt="Tapping the status bar scrolls the primary scrollable back to the top" />
</div>

## Typography

When using the Material package,
the typography automatically defaults to the
font family appropriate for the platform.
Android uses the Roboto font.
iOS uses the San Francisco font.

When using the Cupertino package, the [default theme][]
uses the San Francisco font.

The San Francisco font license limits its usage to
software running on iOS, macOS, or tvOS only.
Therefore a fallback font is used when running on Android
if the platform is debug-overridden to iOS or the
default Cupertino theme is used.

You might choose to adapt the text styling of Material
widgets to match the default text styling on iOS.
You can see widget-specific examples in the
[UI Component section](#ui-components).

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/typography-android.png" img-style="border-radius: 12px;" caption="Roboto on Android" alt="Roboto font typography scale on Android" />
  <DashImage figure image="platform-adaptations/typography-ios.png" img-style="border-radius: 22px;" caption="San Francisco on iOS" alt="San Francisco typography scale on iOS" />
</div>

[default theme]: {{site.repo.flutter}}/blob/main/packages/flutter/lib/src/cupertino/text_theme.dart

## Iconography

When using the Material package,
certain icons automatically show different
graphics depending on the platform.
For instance, the overflow button's three dots
are horizontal on iOS and vertical on Android.
The back button is a simple chevron on iOS and
has a stem/shaft on Android.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/iconography-android.png" caption="Icons on Android" alt="Android appropriate icons" />
  <DashImage figure image="platform-adaptations/iconography-ios.png" caption="Icons on iOS" alt="iOS appropriate icons" />
</div>

The material library also provides a set of
platform-adaptive icons through [`Icons.adaptive`][].

[`Icons.adaptive`]: {{site.api}}/flutter/material/PlatformAdaptiveIcons-class.html

## Haptic feedback

The Material and Cupertino packages automatically
trigger the platform appropriate haptic feedback in
certain scenarios.

For instance,
a word selection via text field long-press triggers a 'buzz'
vibrate on Android and not on iOS.

Scrolling through picker items on iOS triggers a
'light impact' knock and no feedback on Android.

## Text editing

Both the Material and Cupertino Text Input fields
support spellcheck and adapt to use the proper
spellcheck configuration for the platform,
and the proper spell check menu and highlight colors.

Flutter also makes the below adaptations while editing
the content of text fields to match the current platform.

### Keyboard gesture navigation

On **Android**,
horizontal swipes can be made on the soft keyboard's <kbd>space</kbd> key
to move the cursor in Material and Cupertino text fields.

On **iOS** devices with 3D Touch capabilities,
a force-press-drag gesture could be made on the soft
keyboard to move the cursor in 2D via a floating cursor.
This works on both Material and Cupertino text fields.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/text-keyboard-move-android.webp" caption="Android space key cursor move" alt="Moving the cursor via the space key on Android" />
  <DashImage figure image="platform-adaptations/text-keyboard-move-ios.webp" caption="iOS 3D Touch drag cursor move" alt="Moving the cursor via 3D Touch drag on the keyboard on iOS" />
</div>

### Text selection toolbar

With **Material on Android**,
the Android style selection toolbar is shown when
a text selection is made in a text field.

With **Material on iOS** or when using **Cupertino**,
the iOS style selection toolbar is shown when a text
selection is made in a text field.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/text-toolbar-android.png" caption="Android text selection toolbar" alt="Android appropriate text toolbar" />
  <DashImage figure image="platform-adaptations/text-toolbar-ios.png" caption="iOS text selection toolbar" alt="iOS appropriate text toolbar" />
</div>

### Single tap gesture

With **Material on Android**,
a single tap in a text field puts the cursor at the
location of the tap.

A collapsed text selection also shows a draggable
handle to subsequently move the cursor.

With **Material on iOS** or when using **Cupertino**,
a single tap in a text field puts the cursor at the
nearest edge of the word tapped.

Collapsed text selections don't have draggable handles on iOS.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/text-single-tap-android.webp" caption="Android tap" alt="Moving the cursor to the tapped position on Android" />
  <DashImage figure image="platform-adaptations/text-single-tap-ios.webp" caption="iOS tap" alt="Moving the cursor to the nearest edge of the tapped word on iOS" />
</div>

### Long-press gesture

With **Material on Android**,
a long press selects the word under the long press.
The selection toolbar is shown upon release.

With **Material on iOS** or when using **Cupertino**,
a long press places the cursor at the location of the
long press. The selection toolbar is shown upon release.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/text-long-press-android.webp" caption="Android long press" alt="Selecting a word with long press on Android" />
  <DashImage figure image="platform-adaptations/text-long-press-ios.webp" caption="iOS long press" alt="Selecting a position with long press on iOS" />
</div>

### Long-press drag gesture

With **Material on Android**,
dragging while holding the long press expands the words selected.

With **Material on iOS** or when using **Cupertino**,
dragging while holding the long press moves the cursor.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/text-long-press-drag-android.webp" caption="Android long-press drag" alt="Expanding word selection with a long-press drag on Android" />
  <DashImage figure image="platform-adaptations/text-long-press-drag-ios.webp" caption="iOS long-press drag" alt="Moving the cursor with a long-press drag on iOS" />
</div>

### Double tap gesture

On both Android and iOS,
a double tap selects the word receiving the
double tap and shows the selection toolbar.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/text-double-tap-android.webp" caption="Android double tap" alt="Selecting a word via double tap on Android" />
  <DashImage figure image="platform-adaptations/text-double-tap-ios.webp" caption="iOS double tap" alt="Selecting a word via double tap on iOS" />
</div>

## UI components

This section includes preliminary recommendations on how to adapt
Material widgets to deliver a natural and compelling experience on iOS.
Your feedback is welcomed on [issue #8427][8427].

[8427]: {{site.repo.this}}/issues/8427

### Widgets with .adaptive() constructors

Several widgets support `.adaptive()` constructors.
The following table lists these widgets.
Adaptive constructors substitute the corresponding Cupertino components
when the app is run on an iOS device.

Widgets in the following table are used primarily for input,
selection, and to display system information.
Because these controls are tightly integrated with the operating system,
users have been trained to recognize and respond to them.
Therefore, we recommend that you follow platform conventions.


| Material widget | Cupertino widget | Adaptive constructor |
|---|---|---|
|<img width=160 src="/assets/images/docs/platform-adaptations/m3-switch.png" alt="Switch in Material 3" /><br/>`Switch`|<img src="/assets/images/docs/platform-adaptations/hig-switch.png" alt="Switch in HIG" /><br/>`CupertinoSwitch`|[`Switch.adaptive()`][]|
|<img src="/assets/images/docs/platform-adaptations/m3-slider.png" width =160 alt="Slider in Material 3" /><br/>`Slider`|<img src="/assets/images/docs/platform-adaptations/hig-slider.png"  width =160  alt="Slider in HIG" /><br/>`CupertinoSlider`|[`Slider.adaptive()`][]|
|<img src="/assets/images/docs/platform-adaptations/m3-progress.png" width = 100 alt="Circular progress indicator in Material 3" /><br/>`CircularProgressIndicator`|<img src="/assets/images/docs/platform-adaptations/hig-progress.png" alt="Activity indicator in HIG" /><br/>`CupertinoActivityIndicator`|[`CircularProgressIndicator.adaptive()`][]|
|<img src="/assets/images/docs/platform-adaptations/m3-refresh.png" width = 100 alt="Refresh indicator in Material 3" /><br/>`RefreshProgressIndicator`|<img src="/assets/images/docs/platform-adaptations/hig-refresh.png" alt="Refresh indicator in HIG" /><br/>`CupertinoActivityIndicator`|[`RefreshIndicator.adaptive()`][]|
|<img src="/assets/images/docs/platform-adaptations/m3-checkbox.png" alt=" Checkbox in Material 3" /> <br/>`Checkbox`| <img src="/assets/images/docs/platform-adaptations/hig-checkbox.png" alt="Checkbox in HIG" /> <br/> `CupertinoCheckbox`|[`Checkbox.adaptive()`][]|
|<img src="/assets/images/docs/platform-adaptations/m3-radio.png" alt="Radio in Material 3" /> <br/>`Radio`|<img src="/assets/images/docs/platform-adaptations/hig-radio.png" alt="Radio in HIG" /><br/>`CupertinoRadio`|[`Radio.adaptive()`][]|
|<img src="/assets/images/docs/platform-adaptations/m3-alert.png" alt="AlertDialog in Material 3" /> <br/>`AlertDialog`|<img src="/assets/images/docs/platform-adaptations/cupertino-alert.png" alt="AlertDialog in HIG" /><br/>`CupertinoAlertDialog`|[`AlertDialog.adaptive()`][]|

[`AlertDialog.adaptive()`]: {{site.api}}/flutter/material/AlertDialog/AlertDialog.adaptive.html
[`Checkbox.adaptive()`]: {{site.api}}/flutter/material/Checkbox/Checkbox.adaptive.html
[`Radio.adaptive()`]: {{site.api}}/flutter/material/Radio/Radio.adaptive.html
[`Switch.adaptive()`]: {{site.api}}/flutter/material/Switch/Switch.adaptive.html
[`Slider.adaptive()`]: {{site.api}}/flutter/material/Slider/Slider.adaptive.html
[`CircularProgressIndicator.adaptive()`]: {{site.api}}/flutter/material/CircularProgressIndicator/CircularProgressIndicator.adaptive.html
[`RefreshIndicator.adaptive()`]: {{site.api}}/flutter/material/RefreshIndicator/RefreshIndicator.adaptive.html

### Top app bar and navigation bar

Since Android 12, the default UI for top app
bars follows the design guidelines defined in [Material 3][mat-appbar].
On iOS, an equivalent component called "Navigation Bars"
is defined in [Apple's Human Interface Guidelines][hig-appbar] (HIG).

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/mat-appbar.png" caption="Top App Bar in Material 3" alt="Top App Bar in Material 3" height="240px" />
  <DashImage figure image="platform-adaptations/hig-appbar.png" caption="Navigation Bar in Human Interface Guidelines" alt="Navigation Bar in Human Interface Guidelines" height="240px" />
</div>

Certain properties of app bars in Flutter apps should be adapted,
like system icons and page transitions.
These are already automatically adapted when using
the Material `AppBar` and `SliverAppBar` widgets.
You can also further customize the properties of these widgets to better
match iOS platform styles, as shown below.

```dart
// Map the text theme to iOS styles
TextTheme cupertinoTextTheme = TextTheme(
    headlineMedium: CupertinoThemeData()
        .textTheme
        .navLargeTitleTextStyle
         // fixes a small bug with spacing
        .copyWith(letterSpacing: -1.5),
    titleLarge: CupertinoThemeData().textTheme.navTitleTextStyle)
...

// Use iOS text theme on iOS devices
ThemeData(
      textTheme: Platform.isIOS ? cupertinoTextTheme : null,
      ...
)
...

// Modify AppBar properties
AppBar(
        surfaceTintColor: Platform.isIOS ? Colors.transparent : null,
        shadowColor: Platform.isIOS ? CupertinoColors.darkBackgroundGray : null,
        scrolledUnderElevation: Platform.isIOS ? .1 : null,
        toolbarHeight: Platform.isIOS ? 44 : null,
        ...
      ),
```

But, because app bars are displayed alongside
other content in your page, it's only recommended to adapt the styling
so long as it's cohesive with the rest of your application. You can see
additional code samples and a further explanation in
[the GitHub discussion on app bar adaptations][appbar-post].

[mat-appbar]: {{site.material}}/components/top-app-bar/overview
[hig-appbar]: {{site.apple-dev}}/design/human-interface-guidelines/components/navigation-and-search/navigation-bars/
[appbar-post]: {{site.repo.uxr}}/discussions/93

### Bottom navigation bars

Since Android 12, the default UI for bottom navigation
bars follow the design guidelines defined in [Material 3][mat-navbar].
On iOS, an equivalent component called "Tab Bars"
is defined in [Apple's Human Interface Guidelines][hig-tabbar] (HIG).

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/mat-navbar.png" caption="Bottom Navigation Bar in Material 3" alt="Bottom Navigation Bar in Material 3" height="160px" />
  <DashImage figure image="platform-adaptations/hig-tabbar.png" caption="Tab Bar in Human Interface Guidelines" alt="Tab Bar in Human Interface Guidelines" height="160px" />
</div>

Since tab bars are persistent across your app, they should match your
own branding. However, if you choose to use Material's default
styling on Android, you might consider adapting to the default iOS
tab bars.

To implement platform-specific bottom navigation bars,
you can use Flutter's `NavigationBar` widget on Android
and the `CupertinoTabBar` widget on iOS.
Below is a code snippet you can
adapt to show a platform-specific navigation bars.

```dart
final Map<String, Icon> _navigationItems = {
    'Menu': Platform.isIOS ? Icon(CupertinoIcons.house_fill) : Icon(Icons.home),
    'Order': Icon(Icons.adaptive.share),
  };

...

Scaffold(
  body: _currentWidget,
  bottomNavigationBar: Platform.isIOS
          ? CupertinoTabBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                _loadScreen();
              },
              items: _navigationItems.entries
                  .map<BottomNavigationBarItem>(
                      (entry) => BottomNavigationBarItem(
                            icon: entry.value,
                            label: entry.key,
                          ))
                  .toList(),
            )
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
                _loadScreen();
              },
              destinations: _navigationItems.entries
                  .map<Widget>((entry) => NavigationDestination(
                        icon: entry.value,
                        label: entry.key,
                      ))
                  .toList(),
            ));
```

[mat-navbar]: {{site.material}}/components/navigation-bar/overview
[hig-tabbar]: {{site.apple-dev}}/design/human-interface-guidelines/components/navigation-and-search/tab-bars/

### Text fields

Since Android 12, text fields follow the
[Material 3][m3-text-field] (M3) design guidelines.
On iOS, Apple's [Human Interface Guidelines][hig-text-field] (HIG) define
an equivalent component.

<div class="wrapping-row">
  <DashImage figure image="platform-adaptations/m3-text-field.png" caption="Text Field in Material 3" alt="Text Field in Material 3" width="320px" height="100px" />
  <DashImage figure image="platform-adaptations/hig-text-field.png" caption="Text Field in HIG" alt="Text Field in Human Interface Guidelines" width="320px" height="100px" />
</div>

Since text fields require user input,
their design should follow platform conventions.

To implement a platform-specific `TextField`
in Flutter, you can adapt the styling of the
Material `TextField`.

```dart
Widget _createAdaptiveTextField() {
  final _border = OutlineInputBorder(
    borderSide: BorderSide(color: CupertinoColors.lightBackgroundGray),
  );

  final iOSDecoration = InputDecoration(
    border: _border,
    enabledBorder: _border,
    focusedBorder: _border,
    filled: true,
    fillColor: CupertinoColors.white,
    hoverColor: CupertinoColors.white,
    contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
  );

  return Platform.isIOS
      ? SizedBox(
          height: 36.0,
          child: TextField(
            decoration: iOSDecoration,
          ),
        )
      : TextField();
}
```

To learn more about adapting text fields, check out
[the GitHub discussion on text fields][text-field-post].
You can leave feedback or ask questions in the discussion.

[text-field-post]: {{site.repo.uxr}}/discussions/95
[m3-text-field]: {{site.material}}/components/text-fields/overview
[hig-text-field]: {{site.apple-dev}}/design/human-interface-guidelines/text-fields

---
title: SafeArea & MediaQuery
description: >-
  Learn how to use SafeArea and MediaQuery
  to create an adaptive app.
---

This page discusses how and when to use the
`SafeArea` and `MediaQuery` widgets.

## SafeArea

When running your app on the latest devices,
you might encounter bits of the UI being blocked
by cutouts on the device's screen.
You can fix this with the [`SafeArea`][] widget,
which insets its child widget to avoid intrusions
(like notches and camera cutouts),
as well as operating system UI
(such as the status bar on Android),
or by rounded corners of the physical display.

If you don't want this behavior,
the `SafeArea` widget allows you to
disable padding on any of its four sides.
By default, all four sides are enabled.

It's generally recommended to wrap the body of a
`Scaffold` widget in `SafeArea` as a good place to start,
but you don't always need to put it this high in the
`Widget` tree.

For example, if you purposefully want your app to stretch
under the cutouts, you can move the `SafeArea` to wrap
whatever content makes sense,
and let the rest of the app take up the full screen.

Using `SafeArea` ensures that your app content won't be
cut off by physical display features or operating system UI,
and sets your app up for success even as new devices with
different shapes and styles of cutouts enter the market.

How does `SafeArea` do so much in a small amount of code?
Behind the scenes it uses the `MediaQuery` object.

[`SafeArea`]: {{site.api}}/flutter/widgets/SafeArea-class.html

## MediaQuery

As discussed in the [SafeArea](#safearea) section,
`MediaQuery` is a powerful widget for creating
adaptive apps. Sometimes you'll use `MediaQuery`
directly, and sometimes you'll use `SafeArea`,
which uses `MediaQuery` behind the scenes.

`MediaQuery` provides lots of information,
including the app's current window size.
It exposes accessibility settings like high contrast mode
and text scaling, or if the user is using an accessibility
service like TalkBack or VoiceOver.
`MediaQuery` also contains info about the features
of your device's display, such as having a hinge or a fold.

`SafeArea` uses the data from `MediaQuery` to figure out
how much to inset its child `Widget`.
Specifically, it uses the `MediaQuery` padding property,
which is basically the amount of the display that's
partially obscured by system UI, display notches, or status bar.

So, why not use `MediaQuery` directly?

The answer is that `SafeArea` does one clever thing
that makes it beneficial to use over just raw `MediaQueryData`.
Specifically, it modifies the `MediaQuery` exposed
to `SafeArea`'s children to make it appear as if the
padding added to `SafeArea` doesn't exist.
This means that you can nest `SafeArea`s,
and only the topmost one will apply the padding
needed to avoid the notches as system UI.

As your app grows and you move widgets around,
you don't have to worry about having too much
padding applied if you have multiple `SafeArea`s,
whereas you would have issues if using
`MediaQueryData.padding` directly.

You _can_ wrap the body of a `Scaffold` widget
with a `SafeArea`, but you don't _have_ to put it this high
in the widget tree.
The `SafeArea` just needs to wrap the contents
that would cause information loss if cut off by the
hardware features mentioned earlier.

For example, if you purposefully want your app to stretch
under the cutouts, you can move the `SafeArea` to wrap
whatever content makes sense,
and let the rest of the app take up the full screen.
A side note is that this is what the `AppBar` widget
does by default, which is how it goes underneath the
system status bar. This is also why wrapping the body
of a `Scaffold` in a `SafeArea` is recommended,
instead of wrapping the whole `Scaffold` itself.

`SafeArea` ensures that your app content won't be
cut off in a generic way and sets your app up
for success even as new devices with different
shapes and styles of cutouts enter the market.