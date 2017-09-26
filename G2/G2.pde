/**
 * Genau 2 - Typewriter 
 * An example of interactive use of the Control class.
 *
 * Position the pen with the cursor keys, then start typing.
 * This example uses the font of the HP1345A vector display.
 * For more infos see Poul-Henning Kamp's excellent article 
 * about the history of the font and the original font data:
 * http://phk.freebsd.dk/hacks/Wargames/index.html
 *
 * Note:
 * The position coordinates are expressed in motor steps: 
 * 80 steps = 1mm
 *
 * Keys:
 * F1      If not resetted press F1 to reset the AxiDraw, 
 *         manually move the head top-left and press F1 again. 
 *         This is necessary only the first time, as afterwards 
 *         the steps are queried from the controller.
 */

Control c;
HashMap<Integer, GShape>chars;

int offsX = -1;      // offset of the first letter
int offsY = -1;
int charWidth = 18;  // width of the monospaced font
int lineHeight = 24; // font height plus leading
int scale = 25;      // extra scale 
int nextX, nextY;    // current pos

void setup() {
  size(400, 400);
  textFont(loadFont("f14.vlw"));

  // Load the HP1345A font (converted from PHK rom dump):
  String[] s = loadStrings("hp1345_font.txt");

  // Parse the file and store the characters in GShape format: 
  chars = new HashMap<Integer, GShape>();
  GShape chr = null;   
  for (String line : s) {
    if (line.charAt(0) == '#') {
      int index = Integer.decode("0x" + line.substring(2, 4));   
      if (index >= 0 && index < 256) {
        chr = new GShape();
        chars.put(index, chr);
      }
    } else {
      String[] tokens = line.split(" ");
      chr.begin();
      for (int i=0; i<tokens.length; i+=2) {
        int x = parseInt(tokens[i]);
        int y = parseInt(tokens[i+1]); 
        chr.vertex(x, -y); // flip the Y
      }
      chr.end();
    }
  }

  // we don't need it really... but could be handy
  for (int i=0; i<256; i++) {       
    chars.get(i).computeBB();
  }

  c = new Control(this);  // Initialize the control class
  Serial p = c.open();    // Open the serial port
  if (p == null) {  
    println("Axidraw not found.");
    exit();               // No AxiDraw - no joy!
    return;
  } 
  c.motorSpeed(1200);     // A slow one
  c.readPos();            // Read out the steps from the EBB, set internal pos[] accordingly;
  // this makes sure that the position is updated when re-launching the program
  // so a "reset" (via zero()) is not needed
  c.up(true);             // Force the pen to be "up"
}

void draw() {

  // c.version();
  // c.querysteps();      // Uncomment for some extra info in the console
  // c.queryMotor();
  // c.queryPen();

  messageLoop(c.port); 

  String out = "";
  out += "pos[]: " + c.x() + "," + c.y() + " (steps)\n";
  out += "time: " + millis() + "ms\n";
  out += "idle: " + (c.idle()) + "\n";

  if (!c.enabled()) {
    out += "\nManually move the pen\nto the top left corner... \n\nPress F1 again when done.";
    background(220, 60, 60);
  } else {
    background(220);
  }

  fill(0, 140);
  text(out, 30, 30);

  // Quick display of the glyphs:
  noFill();
  float s = 1.0; // scale
  for (int i=32; i<126; i++) {       
    pushMatrix();
    translate(30 + i % 16 * 20 * s, 160 + i / 16 * 26 * s);
    if (key == i) {
      stroke(255);
    } else {
      stroke(0, 140);
    }
    drawRel(g, chars.get(i), s);
    popMatrix();
  }
}

void keyPressed() {
       
  int stepsH = charWidth * scale;
  int stepsV = lineHeight * scale;

  if (keyCode == RIGHT) {
    if (!c.idle()) return;
    c.move(stepsH, 0);
    nextX += stepsH;            // CAUTION: probably needs a better check
  } else if (keyCode == LEFT) {
    if (!c.idle()) return;
    c.move(-stepsH, 0);
    nextX -= stepsH;
  } else if (keyCode == UP) {
    if (!c.idle()) return;
    c.move(0, -stepsV);
    nextY -= stepsV;
  } else if (keyCode == DOWN) {
    if (!c.idle()) return;
    c.move(0, stepsV);
    nextY += stepsV;
  } else if (keyCode == 112) {   // F1 manually reset the AxiDraw, press again to set "Zero"
    if (c.enabled()) {
      c.up(true);                // force the pen up
      c.off();
      offsX = -1;                // reset the typewriter's offset
    } else {   
      c.on();
      c.zero();
    }
  } 
  // space
  else if (key == ' ') {
    if (offsX == -1) setOffset();
    nextX += stepsH;
    c.moveTo(nextX, nextY);
  }
  // return
  else if (key == ENTER) {
    if (offsX == -1) setOffset();   
    nextX = offsX;
    nextY += stepsV;
    c.moveTo(nextX, nextY);
  }  
  // a key
  else if (int(key) > 32 && int(key) < 128) {
    if (offsX == -1) setOffset();
    GShape chr = chars.get(int(key));
    c.moveTo(nextX, nextY);
    drawRel(c, chr, scale);
    c.up(); 
    nextX += stepsH;
  }
}

// A dirty little method to set the "upper left" corner of the typewriter 
void setOffset() {
  offsX = c.x();
  offsY = c.y();
  nextX = offsX;
  nextY = offsY;
}