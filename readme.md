# AS3 Animation Controller

The AnimationController class decorates any movie clip or loaded SWF with logic for controlling their playback. The animation of the decorated item is not controlled by the default `onEnterFrame` command; the decorator controls the timeline through timer events and has the ability to dynamically adjust frame rate, speed, and direction.

Labeled key frames may be placed in the timeline of the decorated object to denote stopping points to the AnimationController when the `stopAtLabel` parameter is set to `true`. This feature can ideally be used to control scripted simulation based scenarios.

# Release Notes
### 1.0 (7/27/2012):
* Initial commit
* Updated example fla to point to AS3AnimationController.swc