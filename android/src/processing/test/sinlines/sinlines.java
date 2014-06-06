package processing.test.sinlines;

import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

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
import com.heroicrobot.dropbit.registry.*; 
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel; 
import com.heroicrobot.dropbit.devices.pixelpusher.Strip; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class sinlines extends PApplet {


















class Line {
  int y = 0;
  int weight = 10;
  final float direction;
  final int c;
  
  Line() {
    direction = speed;
    c = lineColor;
  }
  
  public void draw() {
    strokeWeight(weight);
    stroke(c);
    line(0, y, width, y);
  }
  
  public void move() {
    y += direction;
    
  }
}

ArrayList<Line> lines;
int framesSinceEmit = 0;
int frameInterval = 1;
int frameIntervalIncr = 10;
int maxFrameInterval = 120;
float speed;
int lineColor;
KetaiSensor sensor;
DeviceRegistry registry;
TestObserver testObserver;

public void setup() {
  colorMode(RGB, 100);
  orientation(PORTRAIT);
  lines = new ArrayList<Line>();
  sensor = new KetaiSensor(this);
  sensor.start();
  registry = new DeviceRegistry();
  testObserver = new TestObserver();
  registry.addObserver(testObserver);
  registry.setAntiLog(true);
}

public void emitLines() {
  if (framesSinceEmit > frameInterval) {
    framesSinceEmit = 0;
//    frameInterval += frameIntervalIncr;
//    if (frameInterval > maxFrameInterval){
//      frameInterval = 1;
//    }
    lines.add(new Line());
    
    return;
  }
  framesSinceEmit++;
}

public void removeLines() {
  ArrayList<Line> linesToRemove = new ArrayList<Line>();
  for (Line line : lines) {
    if (line.y > height) {
      linesToRemove.add(line);
    }
  }
  lines.removeAll(linesToRemove);
}

public void draw() {
  emitLines();
  removeLines();
  background(0,0,0);
  for (Line line : lines) {
    line.draw();   
    line.move(); 
    
  }
  
}


public void onAccelerometerEvent(float x, float y, float z)
{
  float total = (abs(x) + abs(y) + abs(z)) - 9.81f;
  lineColor = color(abs(x) * 10, abs(y) * 10, abs(z) * 10);
  frameInterval = PApplet.parseInt(100 - (total*10));
  speed = total;
  
}
class TestObserver implements Observer {
  public boolean hasStrips = false;
  public void update(Observable registry, Object updatedDevice) {
    println("Registry changed!");
    if (updatedDevice != null) {
      println("Device change: " + updatedDevice);
    }
    this.hasStrips = true;
  }
};

public void scrape() {
  // scrape for the strips
  loadPixels();
  if (testObserver.hasStrips) {
    registry.startPushing();
    List<Strip> strips = registry.getStrips();
    
    // yscale = how many pixels of y == one led strip.
    // xscale = how many pixels of x == one led pixel.
    float xscale = PApplet.parseFloat(width) / PApplet.parseFloat(strips.size());
    float yscale = PApplet.parseFloat(height) / PApplet.parseFloat(strips.get(0).getLength());
    
    // for each strip (x-direction)
    int stripx = 0;
    for (Strip strip : strips) {
      for (int stripy = 0; stripy < strip.getLength(); stripy++) {
        int c = get(PApplet.parseInt(PApplet.parseFloat(stripx)*xscale),PApplet.parseInt(PApplet.parseFloat(stripy)*yscale));
        strip.setPixel(c, stripy);
      }
      stripx++;
    }
  }
}

}
