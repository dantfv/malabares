import processing.video.*;  //<>//

final int RIGHT_MOVE = 0;
final int LEFT_MOVE = 1;
final int UP_MOVE = 2;
final int DOWN_MOVE = 3;

final int TOP_RIGHT = 0;
final int TOP_LEFT = 1;
final int BOTTOM_RIGHT = 2;
final int BOTTOM_LEFT = 3;


final int POINT_ART = 0;
final int DASH_ART = 1;
final int CIRCLE_ART = 2;
final int CONE_ART = 3;
final int POINT_TOPLEFT_ART = 4;


final int BLOBS_DETECTION = 0;
final int POINTS_DETECTION = 1; 

Capture video;

//ART
boolean eraseCanvas = true;
boolean eraseCanvasMode = false;
boolean AllPointsMode = false;
boolean shadowMode = false;
int strokeWeightValue = 1;
int detectMode = BLOBS_DETECTION;
int artMode = POINT_ART;
int artDelay = 0;
int dashSize = 50;

//background
int backgroundColor = 255;
int menuColor = 0;
int backgroundMovement = RIGHT_MOVE;
int backgroundMoveSpeed = 0;

//Track
color trackColor; 
float threshold = 40;
float distThreshold = 50;
int maxLife = 200;
int blobCounter = 0;

//Menu
boolean showMenu = true;

//Camera
boolean showCameraView = true;
boolean eraseCamera = true; 
int cameraX = 0;
int cameraY = 0;
int cameraPosition = BOTTOM_RIGHT;

//Arrays
ArrayList<Blob> blobs = new ArrayList<Blob>();
ArrayList<Art_Point> art_point = new ArrayList<Art_Point>();
ArrayList<Art_Point> points = new ArrayList<Art_Point>();


void setup() {
  fullScreen();
    
  String[] cameras = Capture.list();
  printArray(cameras);
  video = new Capture(this, cameras[0]);
  video.start();  

  trackColor = color(0, 255, 00);  
  background(backgroundColor);
  cameraPosition(cameraPosition);
}

void captureEvent(Capture video) {  
  video.read();
}

void draw() {
  video.loadPixels();   
  
  if (detectMode == BLOBS_DETECTION){ 
    detectBlobs();
  }else{
    detectPoint();
  } 
  
  if (backgroundMoveSpeed > 0){
    moveBackground(backgroundMovement);  
  }
  else{
    if (eraseCanvas){
      background(backgroundColor);

      eraseCanvas = eraseCanvasMode;
    }    
  }
  
  if (showCameraView){
    image(video, cameraX, cameraY);
    eraseCamera = true;
  }
  else{
    if (eraseCamera)
    {
      stroke(backgroundColor);
      fill(backgroundColor);    
      rect(cameraX, cameraY, video.width, video.height);
      eraseCamera = false;
    }
  }

  for (Blob b : blobs) {
    if (showCameraView){
      b.show();
    }
    artCreate(b);
  } 

  if (showMenu){
    showMenu();
  }


}

void detectPoint(){
  for (int x = 0; x < video.width; x++ ) {
    for (int y = 0; y < video.height; y++ ) {
      int loc = x + y * video.width;
      // What is current color
      color currentColor = video.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      float r2 = red(trackColor);
      float g2 = green(trackColor);
      float b2 = blue(trackColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      if (d < threshold*threshold) {
        //add Point
        if (AllPointsMode){
          printPoint(new PVector(x,y));
        }
      }
    }
  }
}

void detectBlobs(){
  
   ArrayList<Blob> currentBlobs = new ArrayList<Blob>();

  // Begin loop to walk through every pixel
  for (int x = 0; x < video.width; x++ ) {
    for (int y = 0; y < video.height; y++ ) {
      int loc = x + y * video.width;
      // What is current color
      color currentColor = video.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      float r2 = red(trackColor);
      float g2 = green(trackColor);
      float b2 = blue(trackColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      if (d < threshold*threshold) {
        if (AllPointsMode){
          printPoint(new PVector(x,y));
        }
        boolean found = false;
        for (Blob b : currentBlobs) {
          if (b.isNear(x, y)) {
            b.add(x, y);
            found = true;
            break;
          }
        }

        if (!found) {
          Blob b = new Blob(x, y);
          currentBlobs.add(b);
        }
      }
    }
  }
  for (int i = currentBlobs.size()-1; i >= 0; i--) {
    if (currentBlobs.get(i).size() < 500) {
      currentBlobs.remove(i);
    }
  }

  // There are no blobs!
  if (blobs.isEmpty() && currentBlobs.size() > 0) {
    println("Adding blobs!");
    for (Blob b : currentBlobs) {
      b.id = blobCounter;
      blobs.add(b);
      blobCounter++;
    }
  } else if (blobs.size() <= currentBlobs.size()) {
    // Match whatever blobs you can match
    for (Blob b : blobs) {
      float recordD = 1000;
      Blob matched = null;
      for (Blob cb : currentBlobs) {
        PVector centerB = b.getCenter();
        PVector centerCB = cb.getCenter();         
        float d = PVector.dist(centerB, centerCB);
        if (d < recordD && !cb.taken) {
          recordD = d; 
          matched = cb;
        }
      }
      matched.taken = true;
      b.become(matched);
    }

    // Whatever is leftover make new blobs
    for (Blob b : currentBlobs) {
      if (!b.taken) {
        b.id = blobCounter;
        blobs.add(b);
        blobCounter++;
      }
    }
  } else if (blobs.size() > currentBlobs.size()) {
    for (Blob b : blobs) {
      b.taken = false;
    }


    // Match whatever blobs you can match
    for (Blob cb : currentBlobs) {
      float recordD = 1000;
      Blob matched = null;
      for (Blob b : blobs) {
        PVector centerB = b.getCenter();
        PVector centerCB = cb.getCenter();         
        float d = PVector.dist(centerB, centerCB);
        if (d < recordD && !b.taken) {
          recordD = d; 
          matched = b;
        }
      }
      if (matched != null) {
        matched.taken = true;
        matched.become(cb);
      }
    }

    for (int i = blobs.size() - 1; i >= 0; i--) {
      Blob b = blobs.get(i);
      if (!b.taken) {
        blobs.remove(i);
      }
    }
  }
}

void moveBackground(int direction){
  
  switch (direction){
    case RIGHT_MOVE:{
      printMovement(backgroundMoveSpeed,0,0);
      break;
    }
    case LEFT_MOVE:{
      printMovement(-backgroundMoveSpeed,0,0);
      break;
    }
    case UP_MOVE:{
      printMovement(0,backgroundMoveSpeed,0);
      break;
    }
    case DOWN_MOVE:{
      printMovement(0,-backgroundMoveSpeed,0);
      break;
    }
    default:
      break;
  }
  
}

void printMovement(int xMove, int yMove, int spread){
  background(backgroundColor);
  for (int i = 0; i< points.size(); i++){
    Art_Point art = points.get(i);
    art.x = art.x + xMove;
    art.y = art.y + yMove;
    points.set(i,art);
    if ((art.x > width) || (art.x < 0) || (art.y > height) || (art.y < 0)){
      points.remove(i);
    }
    stroke(trackColor);
    fill(trackColor);
    strokeWeight(strokeWeightValue);
    point(art.x*(width/video.width),art.y*2);//(height/video.height));
  }
}

void artCreate(Blob b){
  PVector center = b.getCenter();
  PVector topLeft = new PVector(b.minx,b.maxy);
  boolean direction = ((b.maxx - b.minx)>=(b.maxy-b.miny)); //TRUE = Horizontal; FALSE = Vertical
  switch (artMode){
    case POINT_ART:
      printPoint(center);
      break;
    case POINT_TOPLEFT_ART:
      printPoint(topLeft);
      break;
    case DASH_ART:
      printDash(center,direction);
      break;
    case CIRCLE_ART:
      printCircle(center);
      break;
    case CONE_ART:
      printStar(center);
      break;      
    default:
      printPoint(center);
      break;
  }
}

void printCircle(PVector center){
  float radius=dashSize;
  int numPoints=dashSize;
  float angle=TWO_PI/(float)numPoints;
  for(int i=0;i<numPoints;i++)
  {
    printPoint(new PVector(radius*sin(angle*i)+center.x,radius*cos(angle*i)+center.y));
  } 
}

void printStar(PVector center){
  stroke(trackColor);
  fill(trackColor);
  strokeWeight(strokeWeightValue);
  int radius1 = 30;
  int radius2 = dashSize;
  int npoints = 5;
  float angle = TWO_PI / npoints;
  float halfAngle = angle/2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = center.x + cos(a) * radius2;
    float sy = 2*center.y + sin(a) * radius2;
    vertex(sx, sy);
    sx = center.x + cos(a+halfAngle) * radius1;
    sy = 2*center.y + sin(a+halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

void printDash(PVector center, boolean direction){
  for (int i=0;i<=dashSize;i++){
    if (direction) {    
          printPoint(new PVector(center.x+i,center.y));
    } else{
           printPoint(new PVector(center.x,center.y+i));
    }

  }
}

void printPoint(PVector center){
      
  stroke(trackColor);
  fill(trackColor);
  strokeWeight(strokeWeightValue);
  point(center.x*(width/video.width),center.y*2);//(height/video.height));
  
  Art_Point point = new Art_Point();
  point.x = center.x;
  point.y = center.y;
  point.stroke = strokeWeightValue;
  point.colorPoint = trackColor;
  points.add(point);
  if (points.size()>10000){
    points.remove(0);
  }
  
  if (shadowMode){
    Art_Point art = new Art_Point();
    art.x = center.x;
    art.y = center.y;
    art.stroke = strokeWeightValue;
    art.colorPoint = trackColor;
    art_point.add(art);
  
    if (art_point.size() > 1000){
         art = art_point.get(0);
         art_point.remove(0);
        stroke(backgroundColor);
        fill(backgroundColor);
        strokeWeight(art.stroke+1);
        point(art.x*(width/video.width),art.y*2);//(height/video.height));              
    }
  }
}


float distSq(float x1, float y1, float x2, float y2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
  return d;
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

void mousePressed() {
  // Save color where the mouse is clicked in trackColor variable
  int loc = (mouseX-cameraX) + (mouseY-cameraY)*video.width;
  trackColor = video.pixels[loc];
  println(red(trackColor), green(trackColor), blue(trackColor));
}


void keyPressed() {
  menu(key);
}

void showMenu(){
    textAlign(RIGHT);
    fill(menuColor);
    textSize(22);
    text("Menu (On/Off - Space): ",width-10, 20);
    textSize(20);
    text("Track Config: ",width-10, 55);
    textSize(12);
    text("Color Track (use mouse to save new): " + trackColor, width-10, 70);
    text("Color threshold (s/x): " + threshold, width-10, 85);  
    text("Distance threshold (a/z): " + distThreshold, width-10, 100);
    textSize(20);
    text("Camera Config :",width-10, 130);
    textSize(12);
    text("Camera On/Off (v):",width-10, 150);
    text("Camera Position (p):"+cameraPosition,width-10, 165);    
    textSize(20);
    text("Art Config: ",width-10, 200);
    textSize(12);
    text("Stroke weight (d/c): " + strokeWeightValue, width-10, 220);
    text("BackGround Direction (q): " + backgroundMovement + " Speed (+/-): " + backgroundMoveSpeed, width-10, 235);
    text("BackGround Color (o):",width-10, 250);
    text("BackGround Clear (u):",width-10, 265);
    text("Detect mode (t): " + detectMode, width-10, 280);
    text("Erase mode (e): " + eraseCanvasMode, width-10, 295);
    text("All Points mode(i): " + AllPointsMode, width-10, 310);
    text("Shadow mode (r): " + shadowMode, width-10, 325);
    text("Change form art (/): " + artMode, width-10, 340);
    text("Art delay (,/.): " + artDelay, width-10, 355);
    text("Art Size (</>): " + dashSize, width-10, 370);
}

void menu(char action){
  if (action == 'a') {
    distThreshold+=5;    
  } else if (action == 'z') {
    distThreshold-=5;
  } else if (action == 's') {
    threshold+=5;
  } else if (action == 'x') {
    threshold-=5;
  } else if (action == 'd') {
    strokeWeightValue+=1;
  } else if (action == 'c') {
    strokeWeightValue-=1;    
  } else if (action == 'u') {
    eraseCanvas = true;  
  } else if (action == 'v') {
    showCameraView = !showCameraView;  
  } else if (action == ',') {
    artDelay++;  
  } else if (action == '.') {
    artDelay--;  

  } else if (action == '<') {
    dashSize++;  
  } else if (action == '>') {
    dashSize--;  

} else if (action == ' ') {
    //blobCounter=0;
    showMenu = !showMenu;
    eraseCanvas = true;
  } else if (action == 'o') {
    if (backgroundColor == 0){
        backgroundColor = 255;
        menuColor = 0;
    }else{
        backgroundColor = 0;
        menuColor = 255;      
    }
    eraseCanvas = true;
  } else if (action == 'i') {
    AllPointsMode = !AllPointsMode;
  } else if (action == 'r') {    
     shadowMode = !shadowMode;
  } else if (action == 'e') {
    eraseCanvasMode = !eraseCanvasMode;
  } else if (action == 't') {    
    if (detectMode == BLOBS_DETECTION){
      detectMode = POINTS_DETECTION;
      AllPointsMode = true;
    }else{
      detectMode = BLOBS_DETECTION;
    }
  } else if (action == '+') {
    if (backgroundMoveSpeed == 0)
    {
      points.clear();
    }
    backgroundMoveSpeed++;
  } else if (action == '-') {
    backgroundMoveSpeed--;
    if (backgroundMoveSpeed < 0){
      backgroundMoveSpeed = 0;
    }
  } else if (action == 'p') {
   switch (cameraPosition){
    case TOP_LEFT:
      cameraPosition = BOTTOM_LEFT; 
      break;
    case BOTTOM_LEFT:      
      cameraPosition = BOTTOM_RIGHT;
      break;
    case BOTTOM_RIGHT:
      cameraPosition = TOP_RIGHT;
      break;
    case TOP_RIGHT:
      cameraPosition = TOP_LEFT;
      break;
    default:
      cameraPosition = TOP_LEFT;
      break;      
    }
    cameraPosition(cameraPosition);
    eraseCanvas = true;  
  } else if (action == 'q') {
    points.clear();
   switch (backgroundMovement){
    case RIGHT_MOVE:
      backgroundMovement = LEFT_MOVE; 
      break;
    case LEFT_MOVE:      
      backgroundMovement = UP_MOVE;
      break;
    case UP_MOVE:
      backgroundMovement = DOWN_MOVE;
      break;
    case DOWN_MOVE:
      backgroundMovement = RIGHT_MOVE;
      break;
    default:
      cameraPosition = RIGHT_MOVE;
      break;      
    }
  } else if (action == '/') {
   switch (artMode){
    case POINT_ART:
      artMode = DASH_ART; 
      AllPointsMode = false;
      break;
    case DASH_ART:      
      artMode = CIRCLE_ART;
      AllPointsMode = false;
      break;
    case CIRCLE_ART:
      artMode = CONE_ART;
      AllPointsMode = false;
      break;
    case CONE_ART:
      artMode = POINT_TOPLEFT_ART;
      break;
    case POINT_TOPLEFT_ART:
      artMode = POINT_ART;
      break;
    default:
      artMode = POINT_ART;
      break;
    }
      
  }  
  

}

void cameraPosition(int position){
  switch (position){
    case TOP_LEFT:
      cameraX =0;
      cameraY =0;
      break;
    case BOTTOM_LEFT:
      cameraX =0;
      cameraY = height-video.height;
      break;
    case BOTTOM_RIGHT:
      cameraX = width - video.width;
      cameraY = height-video.height;
      break;
    case TOP_RIGHT:
      cameraX = width - video.width;    
      cameraY =0;
      break;      
    default:
      break;
  }
}
