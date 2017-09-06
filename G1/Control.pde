/**
 * A simple wrapper of EiBotBoard commands for quick sketches with an AxiDraw. 
 * Most of the methods are just wrappers around the EBB serial commands.
 * There is not much abstraction: 
 * the movement and position units are just 1/16 motor steps (int). 80 steps = 1mm.
 * 
 * Main methods: 
 *   Control.move(dx, dy)
 *   Control.moveTo(x, y)
 *   Control.up()
 *   Control.down()
 *   Control.doManualReset()
 *   Control.zero()
 *
 * EiBotBoard commands reference: 
 * http://evil-mad.github.io/EggBot/ebb.html
 *
 * NOTE: Tested only on an AxiDraw v2
 * 
 * @author Andreas Gysin
 */
class Control {

  public Serial port;  
  public Echo echo;

  final private int STEPS = 1;                 // hardcoded at 1/16. Always.

  private int delayAfterRaising;               // pen delay in ms
  private int delayAfterLowering;              // pen delay in ms
  private int motorSpeed;                      // motor speed for both steppers [1-5]
 
  private int penUpValue;                      // servo max for raised pen  [1..65535] 
  private int penDownValue;                    // servo min for lowered pen [1..65535] 

  private int[] min = new int[]{0, 0};         // asbolute minimum x,y in steps
  private int[] max = new int[]{24000, 17000}; // absolute maximum x,y in steps (around 24000, 17000 for AxiDraw v2)
  private int[] pos = new int[2];              // current x,y position of motors

  private int _time;                           // time we are allowed to begin the next movement (when the current move will be complete).
  private int _timeAccumulator;                // accumluates the millis for each move and each delay, can be resetted with resetTime() 

  private boolean isDown;
  private boolean isZero = true;               // We assume the AxiDraw is already resetted

  Control(Serial port) {
    this.port = port;
    echo = new Echo(port);                     // Echo keeps track of all the EBB commands and also act as a dummy port 
    setMotorSteps();                           // Force step size to 1/16   
    setServo(16000, 19000);                    // Servo min max
    setMotorSpeed(1500);                       // Set the motor speed    
    setServoDelay(200, 200);                   // Delay before rising and before lowering the pen 
    setPosFromQuery();                         // Read out the steps, set pos[] accordingly                
    addTime(0);                                // reset the timer

    echo.enableBuffer();
  }

  /**
   * Sets the steps per second 
   *
   * @param Integer s The number of steps.
   */
  void setMotorSpeed(int s) {
    motorSpeed = constrain(s, 100, 2000);
    println("motorSpeed = " + motorSpeed);
  }

  /**
   * Sets the delay after raising and lowering the pen: 
   * the pen needs some time and you don't want to move it while it's getting in position
   *
   * @param Integer beforeRaise, beforeLower
   */
  void setServoDelay(int beforeRaise, int beforeLower) {
    delayAfterRaising = max(0, beforeRaise);
    delayAfterLowering = max(0, beforeLower);
    println("delayAfterRaising  = " + delayAfterRaising);
    println("delayAfterLowering = " + delayAfterLowering);
  }

  /**
   * Force step size at 1/16 all the time. 
   * Should never be called, except in the constructor.
   */
  private void setMotorSteps() {
    echo.write("EM," + STEPS + "\r");
  }

  /**
   * Configure servo down / up limits (and speed).
   * With an up value of ~26700 the servo arm is vertical up.
   * NOTE: down should be smaller than up.
   *
   * @params Integer down, up 
   */
  // Configure servo limits (and speed):
  void setServo(int down, int up) {
    penUpValue   = constrain(up, 1, 65535);
    penDownValue = constrain(down, 1, 65535);
    echo.write("SC,5," + penUpValue + "\r");    // SC,5,servo_max   (1 to 65535, def: 16000), sets the "Pen UP"   position    
    echo.write("SC,4," + penDownValue + "\r");  // SC,4,servo_min   (1 to 65535, def: 12000), sets the "Pen DOWN" position
    echo.write("SC,10,65535\r");                // SC,10,servo_rate (0 to 65535, def: ?????), sets the servo speed
    println("penUpValue   = " + penUpValue);
    println("penDownValue = " + penDownValue);
  }

  /**
   * Queries the step position and sets the return values into pos[]. 
   * Works only when a correct manual reset has been done.
   */
  void setPosFromQuery() {
    if (port == null || !port.active()) return;
    print("Querying Step position... ");
    delay(100);
    port.clear();
    port.write("QS\r");
    delay(100);
    while (port.available () > 0) {
      String buf = port.readStringUntil('\n');    
      if (buf != null) {
        String[] p = buf.trim().split(",");
        if (p.length != 2) continue; // probably an "OK" string or something else...
        int mx = parseInt(p[0]); // stepper steps
        int my = parseInt(p[1]); 
        pos[0] = (mx + my) / 2;  // convert stepper steps to pen steps (mixed axis) 
        pos[1] = (mx - my) / 2;
        println("response: " + buf.trim());
        println("Position (pos[]) set to: " + pos[0] + "," + pos[1] + " (mixed axis)");
      }
    }
  }

  /**
   * De-energizes both motors to allow a manual reset. 
   * Call zero() when done.   
   */
  void doManualReset() {
    isZero = false;
    motorsOff();
    up(true);
  }

  /**
   * Marks the current pen location as (0,0) in step coordinates. 
   * Is usually combined (called after) with doManualReset().
   * NOTE: Manually move the motor carriage to the upper left corner before calling this command.
   */
  void zero() {
    if (isZero) return;           // need a manual reset before...
    pos[0] = 0;  
    pos[1] = 0;
    isZero = true;
    int delay = move(50, 50);   // add a micro offset for precision!
    delay(delay + 20);            // wait before resetting...
    echo.write("CS\r");            
    pos[0] = 0;                   // reset the position (the micro offset can be ignored...)
    pos[1] = 0;
    echo.clear();                 // clear the buffers... makes sense after a reset.
    _time = 0;                    // reset the "timer"
    _timeAccumulator = 0;
    addTime(0);
  }  

  int[] getPos() {
    return pos;
  }

  private void addTime(int t) {
    _time = millis() + t;
    _timeAccumulator += t;
  }

  public int getApproxTime() {
    return _timeAccumulator;  // TODO...
  }

  public void resetTime() {
    _timeAccumulator = 0;     // TODO...
  }

  /**
   * Rises the pen
   *
   * @param Boolean force when true bypasses the isDown test. Useful for initial reset.
   */
  int up(boolean force) {  
    if (isDown == true || force) {
      echo.write("SP,0," + delayAfterRaising + "\r");           
      isDown = false;
      addTime(delayAfterRaising);
    }
    return delayAfterRaising;
  }

  /**
   * Rises the pen
   */
  int up() {
    return up(false);
  }

  /**
   * Lowers the pen
   */
  int down() {
    if  (isDown == false) {      
      echo.write("SP,1," + delayAfterLowering + "\r"); 
      isDown = true;
      addTime(delayAfterLowering);
    }
    return delayAfterLowering;
  }  

  /**
   * Move dx,dy (delta) steps.
   * NOTE: the XM command is used for mixed axis plooters (AxiDraw)... won't work for the EggBot
   *
   * @param dx, dy amount of steps for both motors.
   * @return Integer Evaluation of elapsed time. 
   */
  int move(int dx, int dy) {
    if (!isZero) return 0;           // need a manual reset before...

    int mx = constrain(dx, min[0] - pos[0], max[0] - pos[0]);
    int my = constrain(dy, min[1] - pos[1], max[1] - pos[1]);

    int travelTime = 0; // motor travel time in millis (max of x or y)


    if ((mx != 0) || (my != 0)) {   
      pos[0] += mx;
      pos[1] += my;
      travelTime = int( 1000.0 * max(abs(mx), abs(my)) / motorSpeed);
      travelTime = max(travelTime, 1);
      addTime(travelTime);
      echo.write("XM," + travelTime + "," + mx + "," + my + "\r");
    }

    return travelTime;
  }

  /**
   * Move to x,y in absolute steps (based on pos[], and assumes the AxiDraw has been resetted)
   * 
   * @param x, y final step positions for both motors.
   * @return Integer Evaluation of elapsed time. 
   */
  int moveTo(int x, int y) {    
    return move(x - pos[0], y - pos[1]);
  }

  /**
   * Checks if the AxiDraw is currently moving (steppers / servo ).
   * NOTE: this is based on an estimate of accumulated time... also considers delays.
   *
   * @return Boolean 
   */
  boolean isIdle() {    
    return _time > millis() == false;
  }

  /**
   * Used to check if the AxiDraw has been resetted manually (top-left).
   * By default we assume this has been done prior startup.
   *
   * @return Boolean 
   */
  boolean isZero() {
    return isZero;
  }

  /**
   * Used to check the pen position.
   *
   * @return Boolean 
   */
  boolean isDown() {
    return isDown;
  }

  /**
   * De-energize both motors.
   */
  void motorsOff() {       
    echo.write("EM,0,0\r");
  }

  /**
   * Stop both motors.
   */
  void stop() {
    echo.write("ES\r");      // stop!
  }

  /**
   * RESPONSE: QM,CommandStatus,Motor1Status,Motor2Status,FIFOStatus<NL><CR>
   * Use this command to see what the EBB is currently doing.
   * It will return the current state of the 'motion system', 
   * each motor's current state, and the state of the FIFO.
   * - CommandStatus is nonzero if any "motion commands" are presently executing, and zero otherwise.
   * - Motor1Status is 1 if motor 1 is currently moving, and 0 if it is idle.
   * - Motor2Status is 1 if motor 2 is currently moving, and 0 if it is idle.
   * - FIFOStatus is non zero if the FIFO is not empty, and 0 if the FIFO is empty.
   */
  void queryMotor() {
    if (port == null || !port.active()) return;
    port.write("QM\r");
  }

  /**
   * RESPONSE: PenStatus<NL><CR>OK<NL><CR>
   * This command queries the EBB for the current pen state. 
   * It will return PenStatus of 1 if the pen is up and 0 if the pen is down. 
   * If a pen up/down command is pending in the FIFO, 
   * it will only report the new state of the pen after the pen move has been started.
   */
  void queryPen() {
    if (port == null || !port.active()) return;
    port.write("QP\r");
  }

  /**
   * RESPONSE: GlobalMotor1StepPosition,GlobalMotor2StepPosition<NL><CR>OK<CR><NL>
   * This command prints out the current Motor 1 and Motor 2 global step positions. 
   * Each of these positions is a 32 bit signed integer, that keeps track of the positions of each axis. 
   * The CS command can be used to set these positions to zero.
   * Every time a step is taken, the appropriate global step position is incremented 
   * or decrimented depnding on the direction of that step.
   * The global step positions can be be queried even while the motors are stepping, 
   * and it will be accurate the instant that the command is executed, 
   * but the values will change as soon as the next step is taken. 
   * It is normally good practice to wait until stepping motion is complete 
   * (you can use the QM command to check if the motors have stopped moving) before checking the current positions.
   */
  void querySteps() {
    if (port == null || !port.active()) return;
    port.write("QS\r");
  }

  /**
   * RESPONSE: EBBv13_and_above EB Firmware Version 2.4.2<NL><CR> (or similar)
   */
  void version() {
    if (port == null || !port.active()) return;
    port.write("V\r");
  }

  /**
   * Closes the port
   */
  void closePort() {
    port.clear(); 
    port.stop();
    port = null;
  }

  /** 
   * A wrapper for the serial port.
   * Attempts to record some of the EBB commands... coul be useufl for preview, etc.
   */
  private class Echo {
    Serial port;
    String buffer;
    boolean portEnabled = true;
    boolean bufferEnabled = false;

    public Echo(Serial port) {
      this.port = port;
      clear();
    }

    void clear() {
      if (port != null && port.active()) port.clear();
      buffer = "";
    }

    void write(String str) {
      if (portEnabled && port != null && port.active()) {
        port.write(str);
      }
      if (bufferEnabled) {
        buffer += str;
      }
    }

    void enablePort(boolean e) {
      if (port != null) {
        portEnabled = e;
      }
    }

    void enablePort() {
      enablePort(true);
    }  

    void disablePort() {
      enablePort(false);
    }

    void enableBuffer(boolean e) {
      bufferEnabled = e;
    }

    void enableBuffer() {
      enableBuffer(true);
    }  

    void disableBuffer() {
      enableBuffer(false);
    }
  }
}