/**
 * A simple shape object. 
 * Stores points (in int[2] form) and connectivity.
 *  
 * Example: a shape in form of an 'X':
 * GShape s = new GShape();
 * s.begin(); // creates a new line
 * s.vertex(0, 0);
 * s.vertex(100, 100);
 * s.end();
 * s.begin();
 * s.vertex(100, 0);
 * s.vertex(0, 100);
 * s.end();
 *
 * use .close() instead of .end() to connect the last vertex to the first.
 * The list 'indices' stores the connectivity of the vertices by pointig at 'vertices'.
 * A negative index indicates the beginning of a new connected line.
 */
class GShape {
  public int[] bb;                      // stores the bounding box in [x, y, w, h] format 
  public ArrayList<int[]> vertices;
  public ArrayList<Integer> indices;
  private int count = -1;

  GShape() {
    vertices = new ArrayList<int[]>();  // vertices are stored as array [2]
    indices = new ArrayList<Integer>();
    bb = new int[4];                    // empty boundg box, use .computeBB() 
  }
  
  // Helpers for alternate implementation with int[] instead of ArrayLists:
  // private int[] concat(int[] arr, int[] add) {
  //   int[] tmp = new int[arr.length + add.length];
  //   System.arraycopy(arr, 0, tmp, 0, arr.length);
  //   System.arraycopy(add, 0, tmp, arr.length, add.length);
  //   return tmp;
  // }

  // private int[] expand(int[] arr){
  //   // find new length: doubled and rounded to a power of 2
  //   int l = (int)pow(2, ceil(log(arr.length)/log(2)));    
  //   int[] tmp = new int[l];
  //   System.arraycopy(arr, 0, tmp, 0, arr.length);    
  //   return tmp;
  // }

  public void begin() {
    count = 0;
  }

  public void end() {
    count = -1;
  }
  
  public void close(){    
    if (count <= 2) {
      println("Can't close.");
      return;
    }    
    indices.add(vertices.size());
    int idx = vertices.size() - count;
    vertices.add(vertices.get(idx));     
    count = -1;
  }  

  public void vertex(int x, int y) {
    if (count == -1) {
      println("Call GShape.begin before adding a vertex.");
      return;
    }
    
    int idx = count == 0 ? -vertices.size() : vertices.size();
    indices.add(idx);
    vertices.add(new int[]{x, y});
    count++;
  }

  public int[] computeBB() {
    int x = Integer.MAX_VALUE;
    int y = Integer.MAX_VALUE;
    int X = Integer.MIN_VALUE;
    int Y = Integer.MIN_VALUE;
    for (int[] p : vertices) {
      x = min(x, p[0]);
      y = min(y, p[1]);
      X = max(X, p[0]);
      Y = max(Y, p[1]);
    }
    bb = new int[]{x, y, X-x, Y-y};
    return bb;
  }
}