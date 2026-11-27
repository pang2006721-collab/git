# Hell left wall outer padding

The cutout foreground tiles retain transparent padding at their left edge (typically 1-4 columns), while their tile registration differs from the background. The previous eight-column patch sampled background art rather than the foreground wall.

The existing edge-cover module now samples the original foreground wall's column 16, forces opaque coverage and spans x=-8 through x=12. Each patch follows the actual corresponding wall tile's vertical registration and height. No source artwork, wall collision, inner contour or right wall is moved.

Validation: six-tile continuous vertical coverage and bottom coverage pass; existing left-wall junction test passes. Native ANGLE render places a green test object behind the outer padding: it remains covered, and edge/adjacent wall pixels both read RGBA (0.4157, 0.1333, 0.1333, 1). Screenshot inspected at 1280x720. Local feature only; no main merge or upload.
