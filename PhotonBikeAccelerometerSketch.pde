import ketai.net.nfc.record.*;
import ketai.camera.*;
import ketai.net.*;
import ketai.ui.*;
import ketai.cv.facedetector.*;
import ketai.sensors.*;
import ketai.net.nfc.*;
import ketai.net.wifidirect.*;
import ketai.data.*;
import ketai.net.bluetooth.*;

import java.util.*;
import android.view.View;
import com.heroicrobot.dropbit.registry.*;
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel;
import com.heroicrobot.dropbit.devices.pixelpusher.Strip;


class Line {
  int y = 0;
  int weight = 10;
  final float direction;
  final color c;
  
  Line() {
    direction = speed;
    c = lineColor;
  }
  
  void draw() {
    strokeWeight(weight);
    stroke(c);
    line(0, y, width, y);
  }
  
  void move() {
    y += direction;
    
  }
}

class ThreeVector {
   float x;
   float y;
   float z;
   ThreeVector(float x, float y, float z) {
    this.x=x;
    this.y=y;
    this.z=z; 
   }
   float magnitude() {
     return sqrt(pow(x,2) + pow(y,2) + pow(z,2));
   }
   void add(ThreeVector addend) {
      this.x += addend.x;
      this.y += addend.y;
      this.z += addend.z;
   }
   void subtract(ThreeVector subtrahend) {
      this.x -= subtrahend.x;
      this.y -= subtrahend.y;
      this.z -= subtrahend.z;
   }
   void divide(float divisor) {
    this.x /= divisor;
    this.y /= divisor;
    this.z /= divisor; 
   }
}


float gravityX, gravityY, gravityZ;
ArrayList<ThreeVector> accelFifo;
ArrayList<Line> lines;
ThreeVector integrator;
int framesSinceEmit = 0;
int frameInterval = 1;
int frameIntervalIncr = 10;
int maxFrameInterval = 120;
float sensitivity = 1;
float recentAdds = 1;
float speed;
color lineColor;
KetaiSensor sensor;
DeviceRegistry registry;
TestObserver testObserver;
int ringBufferSize = 256;

void setup() {
  accelFifo = new ArrayList<ThreeVector>();
  integrator = new ThreeVector(0,0,0);
  size(400, 660); // needs to be a multiple of 330
  colorMode(RGB, 100);
  orientation(PORTRAIT);
  final View surfaceView = this.getSurfaceView();
  runOnUiThread(new Runnable() {
    public void run() {
      surfaceView.setKeepScreenOn(true);
    }
  });
  
  lines = new ArrayList<Line>();
  sensor = new KetaiSensor(this);
  sensor.start();
  registry = new DeviceRegistry();
  testObserver = new TestObserver();
  registry.addObserver(testObserver);
  registry.setAntiLog(true);
}

void emitLines() {
  if (framesSinceEmit > frameInterval) {
    framesSinceEmit = 0;
    recentAdds++;
//    frameInterval += frameIntervalIncr;
//    if (frameInterval > maxFrameInterval){
//      frameInterval = 1;
//    }
    lines.add(new Line());
    
    return;
  }
  framesSinceEmit++;
}

void removeLines() {
  ArrayList<Line> linesToRemove = new ArrayList<Line>();
  for (Line line : lines) {
    if (line.y > height) {
      linesToRemove.add(line);
    }
  }
  lines.removeAll(linesToRemove);
}

void draw() {
  emitLines();
  removeLines();
  //background(0,0,0);
  recentAdds*=0.95;
  
  if (recentAdds > 5) {
     sensitivity *= 0.95; 
  }
  
  if (recentAdds < 1) {
     sensitivity *= 1.001; 
  }
  
  noStroke();
  rectMode(CORNERS);
  fill(color(0,0,0,10));
  rect(0,0,width,height);
  for (Line line : lines) {
    line.draw();   
    line.move(); 
    
  }
  scrape();
  
}

void onGravityEvent(float x, float y, float z)
{
  gravityX = x;
  gravityY = y;
  gravityZ = z;
}

void onAccelerometerEvent(float x, float y, float z)
{
  ThreeVector v = new ThreeVector(x,y,z);
  accelFifo.add(v);
  if (accelFifo.size() > 256) {
    accelFifo.remove(0);
  }
   
  // simple kalman filter
  ThreeVector k = new ThreeVector(0,0,0);
  for (ThreeVector p: accelFifo)
    k.add(p);
  k.divide(float(accelFifo.size()));
  
  ThreeVector gravity = new ThreeVector(gravityX, gravityY, gravityZ);
  k.subtract(gravity);
  integrator.add(k);

  float total = v.magnitude() - 9.81;
  
  // protect against integrator windup
  integrator.divide(1.1);
  
  println("Gyro = "+gravityX+", "+gravityY+", "+gravityZ+" Acceleration = "+x+", "+y+", "+z+", integrated velocity = "+integrator.x+", "+integrator.y+", "+integrator.z+" total = "+total);

  lineColor = color(abs(integrator.x) % 256, abs(integrator.y) %256, abs(integrator.z) % 256);
  frameInterval = int(100 - (total*sensitivity*10));
  speed = total*sqrt(sensitivity);
  
}
