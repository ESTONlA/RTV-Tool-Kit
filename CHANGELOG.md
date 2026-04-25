 # 2.4.0

  Added the first major `Preview` pass to `RTV Tool Kit`.

  ## Added

  - Added a dedicated `Preview` tab
  - Added `Load from Selected Node`
  - Added `Load from Selected Property`
  - Added manual `res://` path loading
  - Added item and resource preview summary with:
    - display name
    - icon
    - inventory footprint
    - resolved world scene path
  - Added live scene and model preview viewport
  - Added texture preview fallback for icon and image-based resources
  - Added basic 2D and UI preview fallback support
  - Added free-look preview camera controls
  - Added scene report output for previewed content
  - Added special node detection and listing for:
    - audio
    - lights
    - collisions
    - markers
    - cameras
    - FX
  - Added preview controls for:
    - `Frame`
    - `Reset Camera`
    - `Focus Entry`
    - `Copy Report`
    - `Clear`
  - Added preview toggles for:
    - `Markers`
    - `Floor`
    - `Axes`
    - `Auto Spin`

  ## Changed

  - Reworked preview interaction to feel closer to an editor-style viewport
  - Improved preview camera movement and general navigation
  - Improved preview metadata so scenes and item-like resources show more useful information

  ## Fixed

  - Fixed preview interaction issues that made movement unreliable
  - Fixed unsafe preview loading paths that could break when trying to preview live runtime nodes
  - Preview now fails gracefully when a selected live node has no safe standalone preview target

# 2.3.0

  Added the first full `Modder Diagnostics` pass to `RTV Tool Kit`.

  ## Added

  - Added a new `Diagnostics` tab
  - Added a loaded mods panel
  - Added an issues/conflicts panel
  - Added a full diagnostics report view
  - Added a detail panel for selected mods and issues
  - Added diagnostics report export to clipboard
  - Added diagnostics report dump to `user://rtv_tool_kit_diagnostics.txt`

  ## Diagnostics Now Includes

  - loaded mods overview
  - autoload list
  - active hooks list
  - registry patch/meta visibility
  - override claim list
  - script override list
  - script source path visibility
  - object ownership summary:
    - `vanilla`
    - `modded`
    - `spawned`
  - conflict detection for duplicate override claims
  - suspicious script pattern warnings
  - missing resource detection
  - failed load and broken path tracking from loader state and `user://modloader_*` logs

  ## Changed

  - Expanded the toolkit from inspection/editing into mod conflict and loader diagnostics
  - Added focused detail views so users can inspect one mod or one issue without digging through raw logs


# 2.2.0

  UI layout overhaul for `RTV Tool Kit`.

  ## Changed

  - Reworked the toolkit layout to be much more responsive
  - Rebalanced major tabs so content panes get more space instead of being buried under stacked controls
  - Updated `Hierarchy` to use a proper split view with the scene tree as the main focus
  - Reworked `Inspector` into a split panel layout with:
    - property tree
    - summary/watch/resource panels
    - property editor
    - method runner
  - Reworked `Files` into a cleaner file list + info/preview split
  - Reworked `Watch` into a more usable layout with bookmarks/watch lists separated from selection history
  - Improved `Search`, `Groups`, `Overview`, and `Log` presentation with cleaner content panels
  - Added stronger section styling to make the toolkit feel more structured and readable
  - Reduced the minimum window size so the toolkit stays usable earlier without forcing excessive resizing

  ## Fixed

  - Fixed several tabs feeling cramped unless the window was enlarged a lot
  - Fixed important views like hierarchy, logs, files, and inspector losing too much space to stacked controls
  - Improved general readability and workflow across medium-sized window layouts

  ## Notes

  - This update is focused on layout, responsiveness, and usability
  - Existing toolkit systems remain, but the UI should feel much more practical during real use 

# 2.1.0

  Started the first major `3.0.0` feature pass for `RTV Tool Kit`.

  ## Added

  - Added real object pick mode
  - Added hover picking for live UI controls
  - Added world picking for live physics backed world objects
  - Added click to select flow directly from the game view
  - Added pick highlight visuals for hovered targets
  - Added on screen pick mode hint and target readout
  - Added `Freeze Hover` support during pick mode
  - Added quick `Pick Parent` action
  - Added quick `Script Owner` selection action
  - Added keyboard shortcuts for pick mode:
    - `Esc` cancel pick mode
    - `Right Click` cancel pick mode
    - `Space` toggle freeze

  ## Changed

  - Expanded the `Hierarchy` tab with picker controls
  - Integrated pick mode directly into the existing selection, inspector, and hierarchy workflow
  - Split picker logic into a dedicated helper script for cleaner structure

  ## Notes

  - World picking currently works best on objects with real physics bodies or areas
  - This is the first pass of the `3.0.0` picking system, with more improvements planned later




# 2.0.0

  Major UI overhaul for `RTV Tool Kit`.

  ## Added

  - Added a full draggable toolkit window
  - Added bottom right resize grip
  - Added persistent window position and size saving
  - Added `Center` button for quick recentering
  - Added `Reset` button to restore default window geometry
  - Added dimmed backdrop behind the toolkit window
  - Added cleaner footer/status area
  - Added dedicated UI modules for:
    - window chrome
    - theme loading
    - tab building
    - persistent config state

  ## Changed

  - Reworked the toolkit UI to feel closer to the base game
  - Refactored the old single file UI into a multi file structure
  - Moved tab construction out of the main runtime script
  - Improved layout behavior across tabs
  - Reworked crowded action rows to wrap more cleanly
  - Updated toolkit theme handling to use game resources where available
  - Updated the mod version to `2.0.0`

  ## Fixed

  - Fixed the resize interaction getting stuck after mouse release
  - Fixed the resize grip hitbox behaving incorrectly across the whole window
  - Fixed several broken or cramped tab layouts caused by oversized horizontal button rows
  - Fixed window geometry clamping and restore behavior

  ## Notes

  - This release is focused on UI structure and usability
  - Existing toolkit features remain, but the shell and layout system have been rebuilt

----------------


# 1.0.0

  Initial public release of `RTV Tool Kit`.

  ## Added

  - Added a full in game modding and debugging overlay
  - Added main menu access plus hotkeys:
    - `F8` toggle overlay
    - `F9` refresh all views
  - Added `Overview` tab with live runtime report output
  - Added `Hierarchy` tab with scene tree browsing, filtering, expand all, and collapse all
  - Added `Search` tab with search by:
    - name
    - class
    - path
    - group
    - script
    - method
    - property
  - Added selected subtree search mode for focused inspection
  - Added `Inspector` tab with:
    - node metadata
    - property list
    - property pull/apply tools
    - method calling
  - Added `World Edit` tab with:
    - rename
    - visibility toggle
    - transform editing
    - nudging
    - duplicate
    - delete
    - reparent
    - scene spawning by `res://` path
    - helper node creation
  - Added `Files` tab with:
    - `user://` browser
    - text preview
    - path copy tools
    - snapshot export
  - Added `Runtime` tab with controls for:
    - `Engine.time_scale`
    - `SceneTree.paused`
    - simulation values
    - game data flags
    - loader save/load hooks
    - custom loader messages
  - Added `Groups` tab with runtime group browsing and membership editing
  - Added `Watch` tab with:
    - persistent bookmarks
    - watch list
    - selection history
  - Added toolkit event log
  - Added report export and clipboard helpers
  - Added persistent toolkit state storage
  - Added support for save/config snapshots under `user://rtv_tool_kit_snapshots/`
