//!
//! Copyright 2015 by Garmin Ltd. or its subsidiaries.
//! Subject to Garmin SDK License Agreement and Wearables
//! Application Developer Agreement.
//!

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Activity as Act;
using Toybox.Time as Time;
using Toybox.Timer as Timer;
using Toybox.Sensor as Snsr;
using Toybox.ActivityRecording as Record;

// globals that store information about the current device
var device_width = 0;
var device_height = 0;
// the x coordinate for device center
var center_x = 0;
// the y coordinate for device center
var center_y = 0;

// used to determine where to put text that appears above
// and below packman.
// gets initialized in the main view
var top_text_y = 0;
var bottom_text_y = 0;



class MainView extends Ui.View
{

    var timer;

    //! Constructor
    function initialize()
    {
        // Set up a 1Hz update timer because we aren't registering
        // for any data callbacks that can kick our display update.
        timer = new Timer.Timer();
        timer.start( method(:onTimer), 1000, true );
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.clear();

        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;

        dc.drawText(x, y,
                    Gfx.FONT_MEDIUM, "Press Start", Gfx.TEXT_JUSTIFY_CENTER);
    }

    function onTimer()
    {
        //Kick the display update
        Ui.requestUpdate();
    }
}


class GameView extends Ui.View {

  var is_paused;
  var game_timer;
  var string_HR;
  var HR_graph;
  var session;

  function initialize(){
    game_timer = new Timer.Timer();
    Snsr.setEnabledSensors( [Snsr.SENSOR_HEARTRATE] );
    Snsr.enableSensorEvents( method(:onSnsr) );
    HR_graph = new LineGraph( 20, 10, Gfx.COLOR_RED );
    string_HR = "--- bpm";
    session = Record.createSession({:name=>"Elliptical", :sport=>Record.SPORT_FITNESS_EQUIPMENT, :subSport=>Record.SUB_SPORT_ELLIPTICAL});
  }

  function new_game() { 
    is_paused = false;
  }

  function start(){
    is_paused = false;
    game_timer.start(method(:tick), 1000, true);
    session.start();
    tick();
    Ui.requestUpdate();
  }

   function pause(){
        // pauses the game if running.
        // unpauses the game if already paused
        if(!is_paused){
            game_timer.stop();
            is_paused = true;
            Ui.requestUpdate();
        }
        else{
            is_paused = false;
            // start the game again
            start();
        }
    }

    function shutdown(){
     // called when the game is over or when the menu is displayed
     game_timer.stop();
     // make sure to draw anything new
     Ui.requestUpdate();
    }

  function save_session() {
    session.save();
  }

  function discard_session() {
    session.discard();
  }

  function tick(){
  }

  function onHide(){
        // this is fired when the menu is brought up
        debug("GameView onHide().");
        shutdown();
    }
 
  function onSnsr(sensor_info)
    {
        var HR = sensor_info.heartRate;
        var bucket;
        if( sensor_info.heartRate != null )
        {
            string_HR = HR.toString() + " bpm";
            //Add value to graph
            HR_graph.addItem(HR);
        }
        else
        {
            string_HR = "--- bpm";
        }

        Ui.requestUpdate();
    }

  function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        dc.clear();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );

        var activityInfo = Act.getActivityInfo();
        var elapsedTime = activityInfo.elapsedTime;
        var displayTime = "00:00:00";

        if (elapsedTime) {
         elapsedTime = elapsedTime /1000;
         var hours = elapsedTime / 3600;
         var minutes = (elapsedTime - ( hours * 3600 ) ) / 60;
         var seconds = elapsedTime - (hours*3600) - (minutes*60);
         displayTime = hours.format("%02u") + ":" + minutes.format("%02u") + ":" + seconds.format("%02u");
        } 
          
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2 - 50;
        var msg;
        if(!is_paused){
          //! HR_graph.draw( dc, [5,30], [200,129] );
          dc.drawText(x, y, Gfx.FONT_LARGE, string_HR, Gfx.TEXT_JUSTIFY_CENTER);
          dc.drawText(x, y + 50, Gfx.FONT_LARGE, displayTime, Gfx.TEXT_JUSTIFY_CENTER);

        } else {
          msg = "Paused";

        dc.drawText(x, y,
                    Gfx.FONT_MEDIUM, msg, Gfx.TEXT_JUSTIFY_CENTER);

        }
    }

}
