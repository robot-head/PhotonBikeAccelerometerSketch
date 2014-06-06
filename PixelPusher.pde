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

void scrape() {
  // scrape for the strips
  loadPixels();
  if (testObserver.hasStrips) {
    registry.startPushing();
    List<Strip> strips = registry.getStrips();
    
    // yscale = how many pixels of y == one led strip.
    // xscale = how many pixels of x == one led pixel.
    float xscale = float(width) / float(strips.size());
    float yscale = float(height) / float(strips.get(0).getLength());
    
    // for each strip (x-direction)
    int stripx = 0;
    for (Strip strip : strips) {
      for (int stripy = 0; stripy < strip.getLength(); stripy++) {
        color c = get(int(float(stripx)*xscale),int(float(stripy)*yscale));
        strip.setPixel(c, stripy);
      }
      stripx++;
    }
  }
}