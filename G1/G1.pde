/**
 * Genau 1
 * An example of interactive use of the Control class.
 * Note:
 * The position coordinates are expressed in motor steps: 
 * 80 steps = 1mm
 * Keys:
 * R       If not resetted press R to reset the AxiDraw, 
 *         manually move the head top-left and press R again. 
 *         This is necessary only the first time, as afterwards 
 *         the steps are queried from the controller.
 * 1-9     Toggle motor speed
 * CURSORS Move the pen around
 * SPACE   Toggles the pen
 * C       Draw some circles
 * X       Draw an oblique cross
 * D,F,G,H Number of steps 400, 800, 1600, 3200 (cell size)
 * B       Print echo.buffer
 */

Control c;

void setup() {
  size(400, 400);
  textFont(loadFont("f14.vlw"));

  c = new Control(this);
  Serial p = c.open();
  if (p == null) {
    println("Axidraw not found.");
    exit();
    return;
  } 
  c.readPos();       // Read out the steps from the EBB, set internal pos[] accordingly;
                     // this makes sure that the position is updated when re-launching the program
                     // so a "reset" (via zero()) is not needed
  c.up(true);        // Force the pen to be "up" 
}

void draw() {

  // c.version();
  // c.querysteps(); // Uncomment for some extra info in the console
  // c.queryMotor();
  // c.queryPen();

  messageLoop(c.port); 

  String out = "";
  out += "pos[]: " + c.x() + "," + c.y() + " (steps)\n";
  out += "time: " + millis() + "ms\n";
  out += "idle: " + (c.idle()) + "\n";

  if (!c.enabled()) {
    out += "\nManually move the pen\nto the top left corner... \n\nPress R again when done.";
    background(220, 60, 60);
  } else {
    background(220);
  }

  fill(0, 140);
  text(out, 30, 30);
}

int steps = 800;             // 800 steps = 1cm

void keyPressed() {

  //if(!c.idle()) return;    // Commands can be stacked...

  if (keyCode == RIGHT) {
    c.move(steps, 0);
  } else if (keyCode == LEFT) {
    c.move(-steps, 0);
  } else if (keyCode == UP) {
    c.move(0, -steps);
  } else if (keyCode == DOWN) {
    c.move(0, steps);
  } else if ( key == ' ') {  // Toggles the pen position
    if (c.pen() == Control.DOWN) {
      c.up();
    } else {
      c.down();
    }
  } else if (key == 'r') {   // manually reset the AxiDraw, press again to set "Zero"
    if (c.enabled()) {
      c.up(true);            // force the pen up
      c.off();
    } else {   
      c.on();
      c.zero();
      println("ZERO");
    }
  } 
  //
  else if ( key == '1') c.motorSpeed( 500); // sloow 
  else if ( key == '2') c.motorSpeed(1000); // slow       
  else if ( key == '3') c.motorSpeed(1500); // default               
  else if ( key == '4') c.motorSpeed(2000); // ok for most cases       
  else if ( key == '5') c.motorSpeed(2500); // quick       
  else if ( key == '6') c.motorSpeed(3000); // quicker      
  else if ( key == '7') c.motorSpeed(3500); // pretty fast        
  else if ( key == '8') c.motorSpeed(4000); // probably the max useful speed
  else if ( key == '9') c.motorSpeed(4500); // not so precise anymore

  else if (key == 'b') {
    String[] commands = split(c.echo.buffer.trim(), '\r');
    int n = 0;
    for (String l : commands) println("["+n+++"]", l);
  } else if (key == 'p') {
    // c.port.write(c.echo.buffer);      // better not... as all commands are relative!
  } else if (key == 'c') {
    int time = 0;
    int ox = c.x();                      // store current x
    int oy = c.y();                      // store current y
    int max = steps / 2 / 80;            // max number of circles 
    int num = floor(random(1, max + 1));    
    for (int i=0; i<num; i++) {
      time += circle(ox + steps/2, oy + steps/2, steps/2 - 80 * i);
    }
    time += c.moveTo(ox + steps, oy);    // go back to the previosu pos + 1 tile
    println("Approx time to draw the circle(s): " + time + "ms");
  } else if (key == 'x') {    
    int time = 0;
    int w = steps;
    int h = steps;
    time += c.down();
    time += c.move(w, h);
    time += c.up();
    time += c.move(-w, 0);
    time += c.down();
    time += c.move(w, -h);
    println("Approx time to draw the crossed square: " + time + "ms");
  } 
  //
  else if (key == 'd') steps =  400;
  else if (key == 'f') steps =  800;
  else if (key == 'g') steps = 1600;
  else if (key == 'h') steps = 3200;
}


int circle(int ox, int oy, float radius) {
  int res  = 64;
  int time = 0;    // or use c.resetTime()
  time += c.up();
  for (int i=0; i<res+1; i++) {   
    int x = round(cos(TWO_PI / res * i) * radius);
    int y = round(sin(TWO_PI / res * i) * radius);
    time += c.moveTo(ox + x, oy + y);
    if (i == 0) time += c.down();
  }
  time += c.up(); 
  return time;
}