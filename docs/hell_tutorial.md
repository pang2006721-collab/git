# Hell tutorial first pass

- Original red frame is sampled from the supplied four-frame JPG without repainting. The shader removes the white matte, preserves the irregular hole, and crops the recording without stretching it.
- Original Shift and close PNGs are retained unchanged.
- `tests/record_hell_tutorial.gd` records the real possession and fork automatic-exchange controllers, with enemies disabled for clarity. Recording: 1280x720, 60 FPS, 335 frames. Shift beats: 1.0 and 3.667 seconds. Runtime Theora file: `assets/video/hell_shift.ogv` (~1.6 MB).
- On the first hell opening, the popup pauses level processing (including nodes previously configured ALWAYS), dims the world and plays the clip. Separate UI feedback handles entry, synchronized key squashes, two short accent strokes and close/finish exit.
- Full playback persists `watched/hell=true` to `user://tutorials.cfg`. Closing early leaves it unwatched. Tests use separate config files; they do not alter the player's watched state. Existing script-driven tests and recording opt out of automatic offers; the tutorial test starts it explicitly.
- This pass implements hell only. Other stage recordings and homepage replay are not connected yet.
- Validation: native ANGLE tutorial test covers playback, both beats, frozen player, automatic close, persistence, process-mode restoration and early dismissal; existing demon automatic teleport regression passes. Native preview exported for review. No upload or main merge.

Edge refinement: continuous white-matte coverage replaces the hard color threshold. Frame and movie now composite together in premultiplied space with four coverage samples per screen pixel. Linear mipmapped sampling applies to the frame, Shift and close artwork, including their bounce scaling. Before the first decoded frame the hole stays transparent rather than flashing white. Original image bytes remain unchanged. Native playback/dismissal regression and 1280x720 visual review pass.

Presentation/replay adjustment: backdrop opacity is now 0.84 (was 0.62). Only the outer black outline expands by 3.5 source pixels, with extra render padding to avoid clipping; the video hole and inner outline retain their dimensions. Key 1 arms a forced replay before the opening entry starts, bypassing the watched check without clearing progress. Native key-event regression passes twice, including restarting while a tutorial is paused; closing restores control and preserves the watched flag.
