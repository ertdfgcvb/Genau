/**
 * Genau 1
 * An example of use of the Control class.
 * Note:
 * The position coordinates are expressed in motor steps: 
 * 80 steps = 1mm
 * Keys:
 * R       If not resetted press R to reset the AxiDraw, 
 *         manually move the head top-left and press R again. 
 *         This is necessary only the first time, as afterwards 
 *         the steps are queried from the controller.
 * SPACE   Toggles the pen
 * 1-9     Toggle motor speed
 * CURSORS Move the pen around
 * B       Prints echo.buffer
 */

Control c;

void setup() {
  size(400, 400);
  textFont(loadFont("f14.vlw"));

  c = new Control();
  Serial port = c.open(this);
  if (port == null) {
    println("Axidraw not found.");
    // exit();
    // return;
  } 
}

void draw() {

  // c.querySteps();
  // c.queryMotor();

  messageLoop(c.port);

  String out = "";

  out += "pos[]: " + c.getPos()[0] + "," + c.getPos()[1] + " (steps)\n";
  out += "time: " + millis() + "ms\n";
  out += "idle: " + (c.isIdle()) + "\n";

  if (!c.isZero()) {
    out += "\nManually move the pen\nto the top left corner... \n\nPress R again when done.";
    background(220, 60, 60);
  } else {
    background(220);
  }

  fill(0, 140);
  text(out, 30, 30);
}

void keyPressed() {

  int STEPS = 800; // 800 steps = 1cm

  if (keyCode == RIGHT) {
    c.move(STEPS, 0);
  } else if (keyCode == LEFT) {
    c.move(-STEPS, 0);
  } else if (keyCode == UP) {
    c.move(0, -STEPS);
  } else if (keyCode == DOWN) {
    c.move(0, STEPS);
  } else if ( key == 'h') {  // go home
    delay(c.up());     // wait that the pen is lifted before moving around...
    c.moveTo(0, 0);
  } else if ( key == ' ') {  // Toggles the pen position
    if (c.isDown()) {
      c.up();
    } else {
      c.down();
    }
  } else if (key == 'r') {   // manually reset the AxiDraw, press again to set "Zero"
    if (c.isZero()) {
      c.doManualReset();
    } else {                
      c.zero();
    }
  } else if ( key == '1') c.setMotorSpeed( 100);  
  else if ( key == '2') c.setMotorSpeed( 250);        
  else if ( key == '3') c.setMotorSpeed( 500);        
  else if ( key == '4') c.setMotorSpeed( 750);        
  else if ( key == '5') c.setMotorSpeed(1000);        
  else if ( key == '6') c.setMotorSpeed(1250);        
  else if ( key == '7') c.setMotorSpeed(1500);      
  else if ( key == '8') c.setMotorSpeed(1750);        
  else if ( key == '9') c.setMotorSpeed(2000);

  else if (key == 'b') {
    String[] commands = split(c.echo.buffer.trim(), '\r');
    int n = 0;
    for (String l : commands) println("["+n+++"]", l);
  } else if (key == 'p') {
    // c.port.write(c.echo.buffer); // better not... as all commands are relative!
  } else if (key == 'c') {

    int cx = 5000;
    int cy = 5000;
    int res = 1000;
    float rad = random(2000, 3000);

    int time = 0; // or use c.resetTime()
    time += c.up();
    for (int i=0; i<res+1; i++) {   
      int x = round(cx + cos(TWO_PI / res * i) * rad);
      int y = round(cy + sin(TWO_PI / res * i) * rad);
      time += c.moveTo(x, y);
      if (i == 0) time += c.down();
    }
    time += c.up();
    println("Approx time to draw the circle: " + time); // or use c.getApproxTime()
  }
}