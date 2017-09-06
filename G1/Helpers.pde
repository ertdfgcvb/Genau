/**
 * Helper function: scans all the serial ports abailable trough Serial.list()
 * and tries to determine if if there is an AxiDraw connected.
 * NOTE: Tested only on macOS.
 *
 * @return Serial An open port if detected, otherwise null.
 */
Serial findSerial() {  

  final int RATE = 115200; //38400;
  Serial port = null;
  String[] ports = Serial.list();

  for (int i=0; i<ports.length; i++) {
    try {    
      port = new Serial(this, ports[i], RATE);
    } 
    catch (Exception e) {
      println("Serial port " + ports[i] + " could not be initialized... Skipping.");
      continue;
    } 

    print("Looking for EBB on port: " + ports[i] + "... ");    
    port.clear();
    port.write("V\r");   // request the version string
    delay(100);          // give it some breath...

    while (port.available () > 0) {
      String buf = port.readString();    
      if (buf != null && buf.contains("EBB")) {
        println("Found!");
        println("Version string: " + trim(buf));
        return port;
      }
    } 

    port.clear(); 
    port.stop();
    port = null;
    println("EBB not detected.");
  }

  return null;
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
        String[] c = a.split(terminator + "");            // Do something with the fetched messaged:
        for (String d : c) {
          println("AxiDraw says [" + millis() + "ms]: " + d.trim() );
        }
      }
    }
  }
}

/**
 * Helper function: caclculates the length of a bezier curve.
 * Uses the native Processing bezierPoint function.
 * NOTE: Highly unoptimized.
 *
 * @param x1, y1, cx1, cy1, cy1, cy2, cy2, x2, y2 Bezier points and control points.
 * @param precision Increment value.
 * @return Float The approximated length of the bezier curve.
 */
float bezierLength(float x1, float y1, float cx1, float cy1, float cx2, float cy2, float x2, float y2, float precision) {
  if (precision <= 0 || precision > 1) return -1;

  float l = 0;
  float i = 0;
  float v = 0;

  while (v <= 1) {
    v = i + precision;
    float px1 = bezierPoint(x1, cx1, cx2, x2, i);
    float px2 = bezierPoint(x1, cx1, cx2, x2, v);
    float py1 = bezierPoint(y1, cy1, cy2, y2, i);
    float py2 = bezierPoint(y1, cy1, cy2, y2, v);
    l += dist(px1, py1, px2, py2);
    i += precision;
  }

  return l;
}