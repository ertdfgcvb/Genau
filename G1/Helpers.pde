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
