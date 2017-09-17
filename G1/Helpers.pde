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