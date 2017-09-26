/**
 * Draws a shape relative to the current position. 
 * The shape can be scaled.
 */
void drawRel(Control c, GShape s, float scale) {

  if (s.vertices.size() == 0) return;

  int pX = 0;
  int pY = 0;
    
  for (Integer idx : s.indices) { 

    int[] p = s.vertices.get(abs(idx));
    int vX = round(p[0] * scale); 
    int vY = round(p[1] * scale);

    int dx = vX - pX; 
    int dy = vY - pY;
    pX = vX;
    pY = vY;
    
    if (idx <= 0) {
      c.up();
      c.move(dx, dy);
      c.down();
    } else {  
      c.move(dx, dy);
    }
  }
} 

/**
 * Draws a shape to the canvas relative to zero. 
 * The shape can be scaled.
 */
void drawRel(PGraphics g, GShape s, float scale) {
  g.beginShape(POLYGON);
  for (Integer idx : s.indices) {      
    if (idx < 0) {
      g.endShape();   // close before
      g.beginShape(); // open new
      idx = -idx;   // flip the index
    }
    int[] p = s.vertices.get(idx);
    g.vertex(p[0] * scale, p[1] * scale);
  }
  g.endShape();
}

/**
 * Helper function: a crappy way to read the serial buffer from the EBB board:
 * this is meant to be used in the sync draw() loop so it shouldn't block the loop for too loong,
 * but it should also read out only complete messages and not only half buffers (readStringUntil).
 *
 * @param Serial port An active serial port to monitor in the loop.
 */
void messageLoop(Serial port) {
  char terminator = '\n';
  if (port != null) {
    String a = "";
    if (port.available() > 0) {                // Ok, we have something... may be complete (terminated) or not.
      boolean loop = true;
      while (loop) {
        String b = port.readStringUntil(terminator); // Try to read out all the complete (terminated) messages...
        if (b != null) {
          a += b;                              // Combine with the found ones.
        } else {
          loop = false;                        // Nothing to do anymore. We try the next cycle.
        }
      }
      if (a.length() > 0) {
        String[] c = a.split(terminator + ""); // Do something with the fetched messaged:
        for (String d : c) {
          d = d.trim();
          if (d.equals("OK")) continue;        // Skip all the "OK" messages from AxiDraw 
          println("AxiDraw says [" + millis() + "ms]: " + d );
        }
      }
    }
  }
}