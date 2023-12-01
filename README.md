**⚠️ This plugin is still cooking ⚠️**


![GoolashTitle](https://github.com/GuyUnger/Goolash/assets/7023847/0843ade0-ae36-4444-99a1-b96f3c4ae770)

### Vector paint and animation addon for Godot 4.2+

  🚲 Fast and easy drawing right inside your scene  
  ✍️ Frame by frame animation  
  🧪 Great for prototyping  
  ⚽ Draw physics objects, cool for e.g. quick level design


# Shortcuts and how to use
*Shortcuts can be edited in project settings.*

Use <kbd>LMB</kbd> to Draw and <kbd>RMB</kbd> to Erase. To reverse these you can toggle <kbd>![Eraser](https://github.com/GuyUnger/Goolash/assets/7023847/4fd35a9b-2e60-4d92-91dd-1e3cd6de3ff2)</kbd> Erase Mode from the tool menu or by holding <kbd>X</kbd>, this is useful for drawing with a tablet.

- ![ToolSelect](https://github.com/GuyUnger/Goolash/assets/7023847/4eb3842f-a2cc-4115-ba44-3facb1f1e311) **Select** <kbd>Q</kbd>
  - Click and drag strokes to move them
  - Click and drag stroke edges to warp them
- ![Paint](https://github.com/GuyUnger/Goolash/assets/7023847/23864ec6-a544-4cf4-883a-f6830840a56e) **Paint Brush** <kbd>B</kbd>
- ![ToolOval](https://github.com/GuyUnger/Goolash/assets/7023847/50b85d2d-c17e-442c-a370-1a2dc92d1e59) **Oval Brush** <kbd>O</kbd>
   - Draw from center <kbd>ALT</kbd>
   - Uniform circles <kbd>SHIFT</kbd>
- ![ToolRectangle](https://github.com/GuyUnger/Goolash/assets/7023847/677133f1-2f40-4695-bed8-e708ad9c41f0) **Rectangle Brush** <kbd>R</kbd>
   - Draw from center <kbd>ALT</kbd>
   - Uniform squares <kbd>SHIFT</kbd>
- ![ToolShape](https://github.com/GuyUnger/Goolash/assets/7023847/81173c1b-10cb-475a-9fcf-0e66319a9318) **Shape Brush** <kbd>R</kbd>
- ![Bucket](https://github.com/GuyUnger/Goolash/assets/7023847/d6b8d845-4ad5-457f-832a-2b3f6c1937f0) **Fill Bucket** <kbd>G</kbd>

![ColorPick](https://github.com/GuyUnger/Goolash/assets/7023847/298b90f9-3bfd-47a9-8da2-e418ea952d99) Hold <kbd>ALT</kbd> for quick Color Picking  
![Bucket](https://github.com/GuyUnger/Goolash/assets/7023847/d6b8d845-4ad5-457f-832a-2b3f6c1937f0) Hold <kbd>CTRL</kbd> for quick Fill Bucket  

<kbd>[</kbd> and <kbd>]</kbd> to shrink/grow tool size.

## ![Brush2D](https://github.com/GuyUnger/Goolash/assets/7023847/733e6067-de70-457d-8ea5-752eb3c3399d) Brush2D
### For simple drawings and physics objects.

You can setup the physics mode in the inspector.

## ![BrushClip2D](https://github.com/GuyUnger/Goolash/assets/7023847/1804c5d6-831e-4b21-b4bf-7842e6563ca6) BrushClip2D
### For animations.
It's recommended to interact with the Layers and Keyframe nodes from the Timeline panel, they are exposed so you can add any nodes to Keyframes.

## Timeline
BrushClips can have their own FPS, if left empty it will use the project default value.

![Onion](https://github.com/GuyUnger/Goolash/assets/7023847/f6701b01-a758-4bb0-8a4e-6a42c6e5937d) Toggle onion skinning to see previews of next/previous frames.

### Navigation
- ![Play](https://github.com/GuyUnger/Goolash/assets/7023847/1ce3bef7-b00e-4efe-b6e0-210a211360fa) Play/Pause <kbd>S</kbd>
- ![PagePrevious](https://github.com/GuyUnger/Goolash/assets/7023847/ee053bb3-538d-4b41-9932-148d8ba83f8d) Previous Frame <kbd>A</kbd>
- ![PageNext](https://github.com/GuyUnger/Goolash/assets/7023847/6ef4e6dd-f462-49f1-8834-12fe982aee57) Next Frame <kbd>D</kbd>

### Creating and removing Frames/Keyframes:
*A Keyframe holds a Brush drawing, and can be shown longer by adding more frames after it.*
- Insert Frame <kbd>5</kbd>
- ![keyframe](https://github.com/GuyUnger/Goolash/assets/7023847/b3622783-b352-4f90-be0d-ca29c53f9f9c) Insert Keyframe <kbd>6</kbd>
- ![keyframe_blank](https://github.com/GuyUnger/Goolash/assets/7023847/24c50233-57cd-455a-88cf-b5bbaf4274ca) Insert Blank Keyframe <kbd>7</kbd>
- Remove Frame <kbd>SHIFT+5</kbd>
- Remove Keyframe <kbd>SHIFT+6</kbd> / <kbd>SHIFT+7</kbd>


*The <kbd>5</kbd> and <kbd>SHIFT+5</kbd> shortcuts conflict with godot shortcuts, but these are so useless i recommend clearing the godot ones.*

## To-do
### 📝 Not yet implemented/planned features:
- [ ] Selections
  - [ ] Transform
  - [ ] Clear
  - [ ] Copy/paste
- [ ] Allow filling holes between different colored strokes
- [ ] Layer tweening
- [ ] Moving frames by dragging them
- [ ] Rigid bodies
- [ ] Audio on frames

*Lower priority:*
- [ ] Scripts on frames
- [ ] Rectangle rounding
- [ ] Decouple editor and drawing tools to make in game editing easy to implement
- [ ] Soft bodies (?)
- [ ] 3D support (?)

### 🪲 Known issues:
- [ ] Sometimes mouse is hidden
- [ ] Erasing has some issues
- [ ] Can't warp holes
- [ ] Warping edges is glitchy
