**⚠️ This plugin is in a very early state and should not be used for production ⚠️**


![GoolashTitle](https://github.com/GuyUnger/Goolash/assets/7023847/0843ade0-ae36-4444-99a1-b96f3c4ae770)

### Vector paint and animation addon for Godot 4.2+

- 🚲 Fast and easy drawing right inside your scene
- ✍️ Frame by frame animation
- 🧪 Great for prototyping
- ⚽ Draw physics objects, for e.g. quick level design


# Shortcuts and how to use

Use <kbd>LMB</kbd> to draw and <kbd>RMB</kbd> to erase

- 🖱️ **Select** <kbd>Q</kbd>
  - Click and drag strokes to move them
  - Click and drag stroke edges to warp them
- 🖌️ **Paint brush** <kbd>B</kbd>
- ⚪ **Oval brush** <kbd>O</kbd>
   - Draw from center <kbd>ALT</kbd>
   - Uniform circles <kbd>SHIFT</kbd>
- ⬜ **Rectangle brush** <kbd>R</kbd>
   - Draw from center <kbd>ALT</kbd>
   - Uniform squares <kbd>SHIFT</kbd>
- 🪣 **Fill bucket** <kbd>G</kbd>

Hold <kbd>ALT</kbd> for quick color picking

<kbd>[</kbd> and <kbd>]</kbd> to shrink/grow brush size

## Brush2D
### For simple drawings and physics objects.

You can setup the physics mode in the inspector

## BrushClip2D
### For animations. Has layers, frame scripts and audio.
Creates nodes for all layers and frames. These can all be accessed through the timeline, but are exposed so you can add your own nodes to frames.

### Timeline
Here you can:
- Set a custom `fps` for this BrushClip, if left empty it will use the project default value
- Enable onion skinning to see next/previous frames
- Add/delete layers

Navigating and editing timeline
- ⏯️ Play/pause <kbd>S</kbd>
- ◀️ Previous frame <kbd>A</kbd>
- ▶️ Next frame <kbd>D</kbd>
- ⬜ Insert frame <kbd>5</kbd>
- ❌ Erase frame <kbd>SHIFT+5</kbd>
- ⚪ Insert keyframe <kbd>6</kbd>
- ❌ Remove keyframe<kbd>SHIFT+6</kbd>
- ⚫ Insert blank keyframe <kbd>7</kbd> 

*The <kbd>5</kbd> and <kbd>SHIFT+5</kbd> shortcuts conflict with godot shortcuts, but these are so useless i recommend clearing the godot ones*

## To-do
### 📝 Not yet implemented/planned features:
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
- [ ] Editing multiple brushes with multi-select?

### 🪲 Known issues:
- [ ] Sometimes mouse is hidden
- [ ] Erasing has some issues
- [ ] Can't warp holes
- [ ] Warping edges is glitchy
