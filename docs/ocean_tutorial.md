# Ocean dodge tutorial

Uses the original blue frame from the supplied JPG and the existing Shift/close artwork. The shared recorded-tutorial presentation uses the same shared 84% backdrop as hell, while retaining the outer outline, smooth scaling, button squash and automatic dismissal.

The 4.883-second, 60 FPS recording runs the real fish teleport and real shark locking/dash/swept-hit controller on the authored ocean map. The shark locks and commits before the fish blinks upward; it continues along its committed line and misses. Recording assertions verify a 300+ pixel upward displacement, unchanged committed aim, exactly one blink and no shark hit. The single Shift cue time is stored in ocean_dodge.json.

Natural entry offers the lesson after fish possession. Completion writes only watched/ocean. Early close does not mark it complete. Quick key 3 forces replay even if watched. Pausing covers all level descendants including ALWAYS hazards; the UI restores their original modes on exit.

The hell and ocean hooks are separate small scripts over recorded_tutorial.gd. Frame geometry is parameterized in the common matte/outline shader. Original source images are unchanged. Native ocean test covers actual key 3, blue frame, cue, freeze, completion, separate watched key, repeat and early close. Hell tutorial regression also checks shared presentation.

Local feature work only; no main merge or upload.

Blue-frame left-edge cleanup: the JPG matte contained blue/gray compression fringe beside the black stroke, visible as a short light line. An ocean-only shader option removes color contamination and faint matte noise within the outermost five source columns; the blue band, inner hole and hell frame remain unchanged. Native ocean playback/replay/close checks pass, and the 1280x720 screenshot confirms the left short line is gone.
