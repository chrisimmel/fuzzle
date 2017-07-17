# fuzzle

A simple visual editor based on a grid of equilateral triangular tiles, implemented
in the Processing.js language.

Tiles are colored according to their state.  Clicking on a tile cycles its state between
the number of available colors in the palette.  Tiles can also be modified by clicking
and dragging.

A color picker at the bottom of the display area allows the user to choose
a color on which the color palette is based.

A Clear button in the lower right allows the state of all tiles to be cleared.

If the program can gain access to a webcam, a Play/Pause button in the lower
left starts/pauses playback of video from the webcam on the triangular grid.
For security reasons, this only works across an HTTPS connection or when
served from localhost.  It also does not currently work in Safari or Internet
Explorer.

When video capture is in progress, tile coloration is drawn directly from the
video stream, not from the 3-color palette used when drawing.

A number of classes that would normally be broken apart into individual files
are combined here into a single file due to constraints of the assignment for
which this program was written.

Try this out live at:  http://luminifera.net/fuzzle/

Copyright 2017 Chris Immel
 
-----------------------------------

File Contents

index.html
The single page of this single-page application.

fuzzle.pde
The entire Fuzzle application.
