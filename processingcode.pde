import processing.opengl.*;
import processing.serial.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

/**
 * This sketch is a more involved use of AudioSamples to create a simple drum machine. 
 * Click on the buttons to toggle them on and off. The buttons that are on will trigger 
 * samples when the beat marker passes over their column. You can change the tempo by 
 * clicking in the BPM box and dragging the mouse up and down.
 * <p>
 * We achieve the timing by using AudioOutput's playNote method and a cleverly written Instrument.
 * <p>
 *
 */


import ddf.minim.*;
import ddf.minim.ugens.*;

Minim       minim;
AudioOutput out;
int colnum = 20;
Sampler     kick;
Sampler     snare;
Sampler     hat;
Sampler     human;
FilePlayer filePlayer;
Gain gain;
String fileName = "BACKGROUND.mp3";

Serial myPort;
boolean[] hatRow = new boolean[colnum];
boolean[] snrRow = new boolean[colnum];
boolean[] kikRow = new boolean[colnum];
boolean[] humanRow = new boolean[colnum];


ArrayList<Rect> buttons = new ArrayList<Rect>();

int bpm = 60;
int volume = 100;
int alpha = 100;

int beat; // which beat we're on

int notePressed = -1;
boolean buttonPressed = false;


// Here is an Instrument implementation that we use 
// to trigger Samplers every twentieth note. 
// Notice how we get away with using only one instance
// of this class to have endless beat making by 
// having the class schedule itself to be played
// at the end of its noteOff method. 
class Tick implements Instrument
{
  void noteOn( float dur )
  {
    if ( hatRow[beat] ) hat.trigger();
    if ( snrRow[beat] ) snare.trigger();
    if ( kikRow[beat] ) kick.trigger();
    if ( humanRow[beat] ) human.trigger();
  }

  void noteOff()
  {
    // next beat
    beat = (beat+1)%20;
    // set the new tempo
    out.setTempo( bpm );
    // play this again right now, with a sixteenth note duration
    out.playNote( 0, 0.25f, this );
  }
}

// simple class for drawing the gui
class Rect 
{
  int x, y, w, h;
  boolean[] steps;
  int stepId;



  public Rect(int _x, int _y, boolean[] _steps, int _id)
  {
    x = _x;
    y = _y;
    w = 14;
    h = 30;
    steps = _steps;
    stepId = _id;
  }

  public void draw()
  {
    if ( steps[stepId] )
    {
      fill(0, 180, 150, 200);
    } else
    {
      fill(255, 30, 0, 200);
    }

    rect(x, y, w, h);
  }

  public void mousePressed()
  {
    if ( mouseX >= x && mouseX <= x+w && mouseY >= y && mouseY <= y+h )
    {
      steps[stepId] = !steps[stepId];
    }
  }

  public void buttonPressed() {
    steps[stepId] = !steps[stepId];
  }
}

void setup()
{
  size(495, 285);

  for (String str : Serial.list ())
    println(str);

  try {
    String portName = Serial.list()[3];
    myPort = new Serial(this, portName, 9600);

    myPort.bufferUntil('\n');
  } 
  catch(ArrayIndexOutOfBoundsException e) {
    e.printStackTrace();
  }
  minim = new Minim(this);
  filePlayer = new FilePlayer(minim.loadFileStream(fileName, 1024, true));
  filePlayer.loop();
  gain = new Gain(0.f);
  out = minim.getLineOut();
  filePlayer.patch(gain).patch(out);

  // load all of our samples, using 4 voices for each.
  // this will help ensure we have enough voices to handle even
  // very fast tempos.
  hat   = new Sampler( "HIHAT.wav", 4, minim );
  snare = new Sampler( "SNARE.wav", 4, minim );
  kick  = new Sampler( "KICK.wav", 4, minim );
  human = new Sampler( "SNAREDRUM.wav", 4, minim);

  // patch samplers to the output
  kick.patch( out );
  snare.patch( out );
  hat.patch( out );
  human.patch( out );

  for (int i = 0; i < 20; i++)
  {
    buttons.add( new Rect(10+i*24, 50, hatRow, i) );
    buttons.add( new Rect(10+i*24, 100, snrRow, i) );
    buttons.add( new Rect(10+i*24, 150, kikRow, i) );
    buttons.add( new Rect(10+i*24, 200, humanRow, i) );
  }

  beat = 0;

  // start the sequencer
  out.setTempo( bpm );
  out.playNote( 0, 0.25f, new Tick() );
}

void draw()
{
  background(alpha);
  out.setTempo( bpm );

  fill(255);
  for (int i = 0; i < buttons.size (); ++i)
  {
    buttons.get(i).draw();
  }

  if ( beat % 4 == 0 )
  {
    fill(random(0, 255), random(0, 255), random(0, 255));
  } else {
    fill(random(0, 255), random(0, 255), random(0, 255));
  }

  // beat marker
  stroke(255);
  strokeWeight(2);
  rect(10+beat*24, 35, 14, 9);

  if (buttonPressed) {
    int rownum = notePressed % 4;
    int[] randint_arr = new int[5];
    for (int i = 0; i < 5; i++) {
      int randint = round(random(0, 19));
      randint_arr[i] = rownum + randint*4;
    }
    for (int index : randint_arr) {
      buttons.get(index).buttonPressed();
    }
    buttonPressed = false;
  }
}

void mousePressed()
{
  for (int i = 0; i < buttons.size (); i++)
  {
    buttons.get(i).mousePressed();
  }
}

void serialEvent(Serial myPort) {
  String inputStr = myPort.readString();
  String[] inputList = split(inputStr, ",");
  if (inputList[0].equals("button")) {
    float val = Float.parseFloat(inputList[1]);
    notePressed = int(val);
    println("notePressed: "+notePressed);
    if (notePressed >= 0 && notePressed <= 15) {
      buttonPressed = true;
    }
  } else if (inputList[0].equals("bpm")) {
    float val = Float.parseFloat(inputList[1]);
    int temp_bpm = int(val);
    bpm = round(map(temp_bpm, 0, 1024, 10, 200));
    println("bpm: "+bpm);
  } else if (inputList[0].equals("color")){
    float val = Float.parseFloat(inputList[1]);
    int temp_alpha = int(val);
    alpha = round(map(temp_alpha, 0, 1024, 0, 255));
    println("alpha: "+alpha);
    
    
  }
  myPort.write('x');
}