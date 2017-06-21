/*
 * This file implements a simple visual editor based on a grid of equilateral
 * triangular tiles.  Clicking on a tile cycles its state between 4 values.
 * Tiles are colored according to their state.  Tiles can also be modified by
 * clicking and dragging, enabling basic drawing.
 *
 * A color picker at the bottom of the display area allows the user to choose
 * a color on which the color palette is based.
 *
 * A Clear button in the lower right allows the state of all tiles to be cleared.
 *
 * If the program can gain access to a webcam, a Play/Pause button in the lower
 * left starts/pauses playback of video from the webcam on the triangular grid.
 * For security reasons, this only works across an HTTPS connection or when
 * served from localhost.  It also does not currently work in Safari or Internet
 * Explorer.
 *
 * A number of classes that would normally be broken apart into individual files
 * are combined here into a single file due to constraints of the assignment for
 * which this program was written.
 *
 *
 * Copyright 2017 Chris Immel
 */

/**
 * The length of a side of a triangular tile.
 */
final int TR_SIDE = 50;

/**
 * Half the length of a side of a triangular tile.
 */
final int TR_HALF_SIDE = TR_SIDE / 2;

/**
 * The square root of 3.  Widely used because it is the tangent of 60 degrees.
 */
final float SQRT3 = sqrt(3.0);

/**
 * The reciprocal of the square root of 3.
 */
final float SQRT3_RECIP = 1.0 / SQRT3;

/**
 * The width of a triangular tile.
 */
final float TR_WIDTH = TR_SIDE * SQRT3 / 2.0;

/**
 * A singleton TrigridBoard object.
 */
final TrigridBoard board;

/**
 * A singleton Palette object.
 */
final Palette palette;

/**
 * A singleton VideoCapture object.
 */
final VideoCapture videoCapture;

/**
 * A singleton ColorPicker object.
 */
final ColorPicker colorPicker;

/**
 * A singleton VideoCaptureButton object.
 */
final VideoCaptureButton videoCaptureButton;

/**
 * A singleton ClearButton object.
 */
final ClearButton clearButton;


/**
 * One-time initial Processing setup.
 */
void setup() {
  colorMode(HSB);
  noLoop();  // Don't run the animation loop since state changes only on click.
  if (online) {
    size(window.innerWidth, window.innerHeight);
  }
  else {
    size(800, 600);
  }

  // Create a palette with a random base color.
  palette = new Palette(random(256));

  // Create the trigrid board, filling the display area (minus the row of
  // interactive elements at the bottom).
  board = new TrigridBoard(ceil(width / TR_WIDTH), ceil(2 * height / TR_SIDE));

  // Create other interactive elements.
  colorPicker = new ColorPicker();
  videoCapture = new VideoCapture();
  videoCaptureButton = new VideoCaptureButton();
  clearButton = new ClearButton();

  background(palette.backgroundColor);

  redraw();
}


/**
 * Full Processing draw of the entire display area.
 */
void draw() {
  board.draw();
  colorPicker.draw();
  videoCaptureButton.draw();
  clearButton.draw();
}

/**
 * Handles a mouse press event.
 */
void mousePressed() {
  if (videoCaptureButton.isMouseOver()) {
    videoCaptureButton.mousePressed();
  } else if (clearButton.isMouseOver()) {
    clearButton.mousePressed();
  } else if (colorPicker.isMouseOver()) {
    colorPicker.mousePressed();
  } else {
    board.mousePressed();
  }
}

/**
 * Handles a mouse release event.
 */
void mouseReleased() {
  board.stopInteraction();
  colorPicker.stopInteraction();
}

/**
 * Handles a mouse drag event.
 */
void mouseDragged() {
  if (colorPicker.interacting) {
    colorPicker.mouseDragged();
  }
  else if (board.interacting) {
    board.mouseDragged();
  }
}


/**
 * Represents a single equilateral triangular tile.  Tiles are stacked in
 * vertical columns, with a flat side to the left or right.  This enables a
 * simple column and row coordinate system.  Each tile knows its address in
 * these coordinates, as well as the (x, y) coordinates of its display triangle.
 */
class Tile {
  final int col; // The index of the column in which this tile resides.
  final int row; // The index of the row in which this tile resides.
  final PVector vertices[] = new PVector[3]; // The vertices of the tile's triangle.
  int state; // The only mutable member.

  /**
   * Constructs a tile, given its (column, row) location.
   */
  Tile(int col, int row) {
    this.col = col;
    this.row = row;
    this.state = 0;

    final float left = getLeft();
    final float right = left + TR_WIDTH;
    final float top = getTop();
    final float bottom = top + TR_SIDE;

    if (pointsLeft()) {
      this.vertices[0] = new PVector(left, top + TR_HALF_SIDE);
      this.vertices[1] = new PVector(right, top);
      this.vertices[2] = new PVector(right, bottom);
    }
    else {
      this.vertices[0] = new PVector(left, top);
      this.vertices[1] = new PVector(right, top + TR_HALF_SIDE);
      this.vertices[2] = new PVector(left, bottom);
    }
  }

  /**
   * Whether this tile points to the left.  True if the row and column are
   * either both even or both odd.
   */
  boolean pointsLeft() {
    return row % 2 == col % 2;
  }

  /**
   * Gets the x value of the left extremity.
   */
  float getLeft() {
    return (float)col * TR_WIDTH;
  }

  /**
   * Gets the x value of the right extremity.
   */
  float getRight() {
    return getLeft() + TR_WIDTH;
  }

  /**
   * Gets the y value of the top extremity.
   */
  float getTop() {
    return (float)(row - 1) * TR_HALF_SIDE;
  }

  /**
   * Gets the y value of the bottom extremity.
   */
  float getBottom() {
    return getTop() + TR_SIDE;
  }

  /**
   * Increments the state of the tile.
   * a tile.
   */
  void incState() {
    state = (state + 1) % 4;
  }

  /**
   * Resets the state to 0.
   */
  void reset() {
    state = 0;
  }

  /**
   * Gets the fill color for the current state.
   */
  color getFillColor() {
    return palette.getColor(state);
  }

  /**
   * Gets the stroke color for the current state.
   */
  color getStrokeColor() {
    return state > 0 ? palette.getColor(state) : palette.gridColor;
  }

  /**
   * Draws this tile.
   */
  void draw() {
    fill(getFillColor());
    stroke(getStrokeColor());

    triangle(
      vertices[0].x, vertices[0].y,
      vertices[1].x, vertices[1].y,
      vertices[2].x, vertices[2].y);
  }

  /**
   * Redraws this tile and shared borders as necessary to render a new state.
   * (Doesn't work well because of the inability to redraw only the strokes from
   * individual triangle sides.)
   */
  void redraw() {
    draw();

    if (pointsLeft()) {
      if (state == 0 && row > 0) {
        Tile upperNeighbor = tiles[col][row - 1];
        stroke(upperNeighbor.getStrokeColor());
        line(upperNeighbor.vertices[1].x, upperNeighbor.vertices[1].y,
             upperNeighbor.vertices[2].x, upperNeighbor.vertices[2].y);
      }
      if (col < numCols - 1) {
        Tile rightNeighbor = tiles[col + 1][row];
        if (rightNeighbor.state > 0) {
          stroke(rightNeighbor.getStrokeColor());
          line(rightNeighbor.vertices[2].x, rightNeighbor.vertices[2].y,
               rightNeighbor.vertices[0].x, rightNeighbor.vertices[0].y);
        }
      }
      if (row < numRows) {
        Tile lowerNeighbor = tiles[col][row + 1];
        if (lowerNeighbor.state > 0) {
          stroke(lowerNeighbor.getStrokeColor());
          line(lowerNeighbor.vertices[0].x, lowerNeighbor.vertices[0].y,
               lowerNeighbor.vertices[1].x, lowerNeighbor.vertices[1].y);
        }
      }
    }
    else {
      if (state == 0) {
        if (row > 0) {
          Tile upperNeighbor = tiles[col][row - 1];
          stroke(upperNeighbor.getStrokeColor());
          line(upperNeighbor.vertices[2].x, upperNeighbor.vertices[2].y,
               upperNeighbor.vertices[0].x, upperNeighbor.vertices[0].y);
        }
        if (col > 0) {
          Tile leftNeighbor = tiles[col - 1][row];
          stroke(leftNeighbor.getStrokeColor());
          line(leftNeighbor.vertices[1].x, leftNeighbor.vertices[1].y,
               leftNeighbor.vertices[2].x, leftNeighbor.vertices[2].y);
        }
      }
      if (row < numRows) {
        Tile lowerNeighbor = tiles[col][row + 1];
        stroke(lowerNeighbor.getStrokeColor());
        line(lowerNeighbor.vertices[0].x, lowerNeighbor.vertices[0].y,
             lowerNeighbor.vertices[1].x, lowerNeighbor.vertices[1].y);
      }
    }
  }
}


/**
 * A board tesselated by triangular tiles.
 */
class TrigridBoard {
  /**
   * The tiles covering the display area, as a (column, row) array.
   */
  Tile[][] tiles = null;

  /**
   * The number of columns.
   */
  int numCols;

  /**
   * The number of rows.
   */
  int numRows;

  /**
   * Keeps track of the last tile modified by clicking or dragging.
   */
  Tile lastTile = null;

  /**
   * Whether a mouse action is in progress to change tile states.
   */
  boolean interacting = false;

  /**
   * Constructs a new TrigridBoard of the given dimensions.
   */
  TrigridBoard(int numCols, int numRows) {
    this.numCols = numCols;
    this.numRows = numRows;

    populate();
  }

  /**
   * Populates the full board display area with tiles.
   */
  void populate() {
    tiles = new Tile[numCols][numRows];

    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        tiles[col][row] = new Tile(col, row);
      }
    }
  }

  /**
   * Draws the board.
   */
  vod draw() {
    // First, clear the background (since not running an animation loop and not
    // redrawing empty tiles).
    stroke(palette.backgroundColor);
    fill(palette.backgroundColor);
    rect(0, 0, width, height);

    /*
    // Draw the empty tiles.  This is the simplest way to draw the grid and clear
    // the background, but is expensive because it draws every edge of every tile.
    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        Tile tile = tiles[col][row];
        if (tile.state == 0) {
          tile.draw();
        }
      }
    }
    */
    // Draw the grid.
    drawGrid();

    // Finally, draw the colored tiles, overwriting shared borders with earlier tiles.
    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        final Tile tile = tiles[col][row];
        if (tile.state > 0) {
          tile.draw();
        }
      }
    }
  }

  /**
   * Draws a single grid line connecting a given pair of column/row points.
   */
  void drawGridLine(int c0, int r0, int c1, int r1) {
    final int x0 = (int)(c0 * TR_WIDTH);
    final int y0 = r0 * TR_HALF_SIDE;
    final int x1 = (int)(c1 * TR_WIDTH);
    final int y1 = r1 * TR_HALF_SIDE;
    line(x0, y0, x1, y1);
  }

  /**
   * Quickly draws the background grid by connecting the points along the grid perimeter.
   */
  void drawGrid() {
    stroke(palette.gridColor);

    // Draw vertical lines.
    for (float x = 0.0; x < width; x += TR_WIDTH) {
      line(x, 0, x, height);
    }

    // Draw 30 degree downward lines from left edge.
    int r0 = floor(numRows / 2) * 2;
    int c0 = 0;
    int r1 = r0 + 1;
    int c1 = 1;
    while (r0 >= 0) {
      drawGridLine(c0, r0, c1, r1);
      r0 -= 2;
      if (c1 < numCols) {
        c1 += 2;
      }
      else {
        r1 -= 2;
      }
    }

    // Draw 30 degree downward lines from top edge.
    while (c0 < numCols) {
      drawGridLine(c0, r0, c1, r1);
      c0 += 2;
      if (c1 < numCols) {
        c1 += 2;
      }
      else {
        r1 -= 2;
      }
    }

    // Draw 150 degree downward lines from top edge.
    r0 = 0;
    c0 = 2;
    r1 = 2;
    c1 = 0;
    while (c0 < numCols) {
      drawGridLine(c0, r0, c1, r1);
      c0 += 2;
      if (r1 < numRows) {
        r1 += 2;
      }
      else {
        c1 += 2;
      }
    }

    // Draw 150 degree downward lines from right edge.
    while (r0 < numRows) {
      drawGridLine(c0, r0, c1, r1);
      r0 += 2;
      if (r1 < numRows) {
        r1 += 2;
      }
      else {
        c1 += 2;
      }
    }
  }

  /**
   * Clears the board state.
   */
  void clear() {
    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        final Tile tile = tiles[col][row];
        tile.reset();
      }
    }

    redraw();
  }

  /**
   * Finds the tile under the given point.
   */
  Tile getTile(int x, int y) {
    // First, find the (column, row) location of the most compact rectangle.
    // containing the triangle.
    final int col = (int)(x / TR_WIDTH);
    final int blockRow = (int)(y / TR_SIDE);

    // Now compute the (x, y) offset in that rectangle.
    int xOff = x - (int)(col * TR_WIDTH);
    final int yOff = y - (int)(blockRow * TR_SIDE);

    if (col % 2 == 1) {
      // Flip the x offset for odd columns.
      xOff = (int)(TR_WIDTH - xOff);
    }

    // Now find in which triangle covered by the rectangle the point falls.
    final int rowOff;
    if (yOff < xOff * SQRT3_RECIP) {
      // The row above.
      rowOff = -1;
    }
    else if (yOff > (TR_SIDE - xOff * SQRT3_RECIP)) {
      // The row below.
      rowOff = 1;
    }
    else {
      rowOff = 0;
    }
    int row = blockRow * 2 + 1 + rowOff;

    final Tile tile;
    if (col >= 0 && col < numCols && row >= 0 && row < numRows) {
      tile = tiles[col][row];
    }
    else {
      tile = null;
    }

    return tile;
  }

  /**
   * Handles a mouse press by finding the tile under the mouse, incrementing its
   * state, and redrawing as necessary.
   */
  void mousePressed() {
    final Tile tile = getTile(mouseX, mouseY);
    if (tile != null) {
      tile.incState();
      lastTile = tile;
      interacting = true;
      //tile.redraw();
      redraw();
    }
  }

  /**
   * Handles a mouse drag by finding the tile under the mouse, incrementing its
   * state if not the last tile updated in this interaction, and redrawing as
   * necessary.
   */
  void mouseDragged() {
    final Tile tile = getTile(mouseX, mouseY);
    // If the mouse is over a new tile, increment the tile's state.
    if (tile != null && tile != lastTile) {
      tile.incState();
      redraw();
      lastTile = tile;
    }
  }

  /**
   * Stops the interaction in progress, if any.
   */
  void stopInteraction() {
    interacting = false;
    lastTile = null;
  }

  /**
   * Copies the board state from an image.
   *
   * invertBrightness whether to invert the image in terms of brightness and x-axis.
   */
  void setStateFromImage(PImage img, boolean invertImage) {
    img.resize(numCols, numRows);
    float maxBrightness = 0;
    float minBrightness = 255 * 255;
    final float brightnesses = new float[numCols][numRows];

    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        final color c = img.get(col, row);
        final float b = alpha(c) * brightness(c);
        if (invertImage) {
          brightnesses[numCols - (col + 1)][row] = b;
        }
        else {
          brightnesses[col][row] = b;
        }
        if (b > maxBrightness) {
          maxBrightness = b;
        }
        if (b < minBrightness) {
          minBrightness = b;
        }
      }
    }

    final float normalizer = (maxBrightness == minBrightness) ? 1 : (maxBrightness - minBrightness);

    for (int col = 0; col < board.numCols; col++) {
      for (int row = 0; row < board.numRows; row++) {
        final Tile tile = board.tiles[col][row];
        final float normBrightness = invertImage ?
          (maxBrightness - brightnesses[col][row]) / normalizer :
          (brightnesses[col][row] - minBrightness) / normalizer;  // Ranges 0-1.
        tile.state = (int)(3 * normBrightness);
      }
    }
  }
}


/**
 * A simple color palette.
 */
class Palette {
  /*
   * The background color.
   */
  final color backgroundColor = color(0, 0, 255);

  /**
   * The grid color.
   */
  final color gridColor = color(0, 0, 240);

  /**
   * The palette of colors representing all tile states.  The first is the
   * background color, followed by the 3 non-empty states.  To be filled by
   * update().
   */
  final color colors[] = {
     backgroundColor,
     color(0, 0, 0),
     color(0, 0, 0),
     color(0, 0, 0) };

  /**
   * Constructs a Palette based on the given hue.
   */
  Palette(int baseHue) {
    update(baseHue);
  }

  /**
   * Gets the color for the given state.  States can range from 0 to 3.
   */
  color getColor(int state) {
    return colors[state];
  }

  /**
   * Updates the palette based on a given base hue.
   */
  void update(int baseHue) {
    colors[1] = color(baseHue, 100, 248);
    colors[2] = color((baseHue + 10) % 256, 120, 216);
    colors[3] = color((baseHue + 20) % 256, 140, 184);
  }
}

/**
 * An abstract button class.
 */
class Button {
  int left;
  int top;
  int right;
  int bottom;

  Button(int left, int top, int width, int height) {
    this.left = left;
    this.top = top;
    this.right = left + width;
    this.bottom = top + height;
  }

  int buttonWidth() {
    return right - left;
  }

  int buttonHeight() {
    return bottom - top;
  }

  /**
  * Determines whether the mouse is over the button.
  */
  boolean isMouseOver() {
    return mouseY > top && mouseY < bottom &&
           mouseX > left && mouseX < right;
  }

  /**
   * Handles a mouse pressed event.  Subclass must override.
   */
  void mousePressed() {
  }

  /**
   * Draw the button.  Subclass must override.
   */
  void draw() {
  }
}


/**
 * A color picker, drawn across the bottom of the display area.  The user can
 * click and drag to modify the color palette.
 */
class ColorPicker extends Button {
  /**
   * Half the width of the color picker caret.
   */
  final int CARET_HALF_WIDTH = 4;

  /**
   * Whether a mouse action is in progress to select colors.
   */
  boolean interacting = false;

  ColorPicker() {
    super(0, height - TR_SIDE, width, TR_SIDE);
  }

  /**
   * Calculates a hue based on an X offset.
   */
  int hueFromX(int x) {
    return ((mouseX - left) * 256) / buttonWidth();
  }

  /**
   * Handles a mouse press by beginning an interaction and updating the colors.
   */
  void mousePressed() {
    palette.update(hueFromX(mouseX));
    interacting = true;
    redraw();
  }

  /**
   * Handles a mouse drag by updating the colors.
   */
  void mouseDragged() {
    palette.update(hueFromX(mouseX));
    redraw();
  }

  /**
   * Stops the interaction in progress, if any.
   */
  void stopInteraction() {
    interacting = false;
  }

  /**
   * Draws the color picker.
   */
  void draw() {
    final int btnWidth = buttonWidth();
    final int btnHeight = buttonHeight();
    final float swatchWidth = (float)btnWidth / 256.0;

    // Draw the color palette.
    for (int h = 0; h < 256; h++) {
      final float swatchLeft = swatchWidth * h;
      final color c = color(h, 120, 216);
      stroke(c);
      fill(c);
      rect(swatchLeft, top, swatchWidth, btnHeight);
    }

    // Draw a caret indicating the selected base hue.
    final int hueBase = hue(palette.getColor(1));
    final int xHue = (hueBase * btnWidth) / 256;
    for (int x = xHue - CARET_HALF_WIDTH; x < xHue + CARET_HALF_WIDTH; x++) {
      stroke(0, 0, 64, (CARET_HALF_WIDTH - abs(xHue - x)) * 128 / CARET_HALF_WIDTH);
      line(x, top, x, bottom);
    }
  }
}


/**
 * A button to start or stop video capture.
 */
class VideoCaptureButton extends Button {

  VideoCaptureButton() {
    super(0, height - TR_SIDE, TR_WIDTH, TR_SIDE);
  }

  /**
   * Toggles video capture.
   */
  void mousePressed() {
    videoCapture.toggleCapture();
  }

  void draw() {
    fill(palette.gridColor);
    stroke(palette.gridColor);
    final int btnWidth = buttonWidth();
    final int btnHeight = buttonHeight();
    final int barWidth = btnWidth / 5;
    final int barHeight = btnHeight - (2 * barWidth);

    if (videoCapture.capturing) {
      // Draw a pause button.
      rect(left + barWidth, top + barWidth,
           barWidth, barHeight);
      rect(left + 3 * barWidth, top + barWidth,
           barWidth, barHeight);
    } else {
      // Draw a play button.
      final int playSide = btnHeight - 2 * barWidth;
      triangle(left + barWidth, top + barWidth,
               right - barWidth, top + (btnHeight / 2),
               left + barWidth, bottom - barWidth);
    }
  }
}


/**
 * A button to clear the board.
 */
class ClearButton extends Button {

  ClearButton() {
    super(width - TR_SIDE, height - TR_SIDE,
          TR_SIDE, TR_SIDE);
  }

  /**
   * Clears the board state.
   */
  void mousePressed() {
    board.clear();
  }

  void draw() {
    final int barWidth = buttonWidth() / 5;

    fill(palette.gridColor);
    stroke(palette.gridColor);

    // Draw an X.
    quad(left, top + barWidth,
         left + barWidth, top + barWidth,
         right - barWidth, bottom - barWidth,
         right - 2 * barWidth, bottom - barWidth);
    quad(right - 2 * barWidth, top + barWidth,
         right - barWidth, top + barWidth,
         left + barWidth, bottom - barWidth,
         left, bottom - barWidth);
  }
}


/**
 * Enables copying an image from the webcam (if any) to the trigrid board.
 * Failing to gain access to the camera (e.g., for security reasons, technical
 * reasons, or because the user refuses) produces a harmless, silent failure,
 * and the trigrid remains blank.
 *
 * Note that getUserMedia() will fail on an HTTP connection other than to
 * localhost.  For video capture to work, this file must be served either via
 * HTTPS or from localhost.
 */
class VideoCapture {
  /*
   * An invisible element to receive the video from the camera.
   */
  Object videoSource = null;

  /**
   * The frame interval, in milliseconds.
   */
  final int frameInterval = 100;

  /**
   * Whether capture is in progress.
   */
  boolean capturing = false;

  /**
   * True if there has been an error setting up capture.
   */
  boolean captureError = false;

  /**
   * Constructs a new VideoCapture object.  This class is expected to be a
   * singleton.
   */
  VideoCapture() {
  }

  /**
   * Sets up access to the video camera, and grabs an image from it.
   */
  void initVideo() {
    if (online && !captureError) {
      videoSource = document.createElement("video");
      videoSource.setAttribute("style", "display:none");
      videoSource.setAttribute("id", "videoOutput");
      videoSource.setAttribute("width", "500px");
      videoSource.setAttribute("height", "660px");
      videoSource.setAttribute("autoplay", "true");
      if (document.body!=null) {
        document.body.appendChild(videoSource);
      }

      navigator.getMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

      if (navigator.getMedia) {
        // Request the camera.
        navigator.getMedia(
           {
             video: true
           },
           // Success Callback
           function(stream) {
             // Chrome needs to convert the stream to an object URL, but Firefox's stream already is one.
             if (window.URL) {
               // Create an object URL for the video stream and
               // set it as src of our HTLM video element.
               videoSource.src = window.URL.createObjectURL(stream);
             } else if (window.webkitURL) {
               videoSource.src = window.webkitURL.createObjectURL(stream);
             } else {
               videoSource.src = stream;
             }

             startStream(300);
           },
           // Error Callback
           function(err){
             console.log("There was an error with accessing the camera stream: " + err.name, err);
             captureError = true;
           }
         );
       } else {
         console.log("The browser doesn't support getUserMedia.");
         captureError = true;
       }
    }
  }

  /**
   * Toggles video capture.
   */
  void toggleCapture() {
    if (capturing) {
      stopCapture();
    } else {
      startCapture();
    }
  }

  /**
   * Starts video capture.
   */
  void startCapture() {
    if (videoSource == null) {
      initVideo();
    }
    else {
      startStream(0);
    }
  }

  /**
   * Stops video capture.
   */
  void stopCapture() {
    if (videoSource != null) {
      videoSource.pause();
    }
    capturing = false;
    redraw();
  }

  /**
   * Starts the video stream.
   */
  void startStream(int delay) {
    if (!captureError) {
      // Play the video element to start the stream.
      videoSource.play();
      videoSource.onplay = function() {
        setTimeout(captureFrame, delay);
      }
      capturing = true;
    }
  }

  /**
   * Captures a frame from the video stream and copies it to the board state.
   */
  void captureFrame() {
    if (capturing) {
      setBoardStateFromElement(videoSource);
      redraw();
      setTimeout(captureFrame, frameInterval);
    }
  }

  /**
   * Copies the board state from the given element, which must be an HTMLImageElement,
   * an HTMLVideoElement, an HTMLCanvasElement or an ImageBitmap.
   */
  void setBoardStateFromElement(Object element) {
    externals.context.drawImage(element, 0, 0, width, height);
    final PImage img = get();
    board.setStateFromImage(img, true);
  }
}
