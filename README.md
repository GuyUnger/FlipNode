**⚠️ This plugin is in a very early state and should not be used for production ⚠️**


![GoolashTitle](https://github.com/GuyUnger/Goolash/assets/7023847/0843ade0-ae36-4444-99a1-b96f3c4ae770)

### Vector paint and animation addon for Godot 4 

- 🚲 Fast and easy drawing right inside your scene
- ✍️ Frame by frame animation
- 🧪 Great for prototyping
- ⚽ Draw physics objects, for e.g. quick level design


# How to use

## Drawing Tools
Use [LMB] to draw and [RMB] to erase

[ALT] for quick color picking
- [Q] 🖱️ Select
  - Click and drag strokes to move them
  - Click and drag stroke edges to warp them
- [B] 🖌️ Paint brush
- [O] ⚪ Oval brush
   - [ALT] Draw from center
   - [SHIFT] Uniform circles
- [R] ⬜ Rectangle brush
   - [ALT] Draw from center
   - [SHIFT] Uniform squares
- [G] 🪣 Fill bucket

## Brush2D
### For simple drawings and physics objects.

You can setup the physics mode in the inspector

## BrushClip2D
### For animations. Has layers, frame scripts and audio.
Adds children for all layers and frames. These can all be accessed through the timeline, but are exposed so you can add your own nodes to frames.

### Timeline
 - Set a custom fps for this object, if no value is input it will default to the project value
 - Enable onion skinning to see next/previous frames
 - Add/delete layers

Navigating and editing timeline
 - [A] ◀️ Previous frame
 - [D] ▶️ Next frame
 - [S] ⏯️ Play/pause
 - [5] ⬜ Insert frame
 - [6] ⚪ Insert keyframe
 - [7] ⚫ Insert blank keyframe


## To-do
### 📝 Not yet implemented/planned features:
- [ ] Undo/redo
- [ ] Selections
  - [ ] Transform
  - [ ] Clear
  - [ ] Copy/paste
- [ ] Allow filling holes between different colored strokes
- [ ] Layer tweening
- [ ] Rigid bodies

*Lower priority:*
- [ ] Scripts on frames
- [ ] Audio on frames
- [ ] Rectangle rounding
- [ ] Decouple editor and drawing tools to make in game editing easy to implement
- [ ] Soft bodies?
- [ ] 3D support?

### 🪲 Known issues:
- [ ] Filling shapes removes parts of strokes inside it
- [ ] Holes in eraser are still removed if it overlaps a stroke
- [ ] Sometimes strokes dont properly merge
- [ ] Mouse is sometimes hidden in places where it shouldnt
