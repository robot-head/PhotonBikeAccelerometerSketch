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

ArrayList<Line> lines;
int framesSinceEmit = 0;
int frameInterval = 1;
int frameIntervalIncr = 10;
int maxFrameInterval = 120;
float speed;
color lineColor;
KetaiSensor sensor;
DeviceRegistry registry;
TestObserver testObserver;

void setup() {
  size(400, 400);
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


void onAccelerometerEvent(float x, float y, float z)
{
  float total = (abs(x) + abs(y) + abs(z)) - 9.81;
  lineColor = color(abs(x) * 10, abs(y) * 10, abs(z) * 10);
  frameInterval = int(100 - (total*10));
  speed = total;
  
}
