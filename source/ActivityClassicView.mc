using Toybox.ActivityMonitor as Act;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;

class ActivityClassicView extends Ui.WatchFace {

    var font;
    var background;
    var background_icons;
    var deviceName;
    var highPowerMode = false;
    var deg2rad = Math.PI/180;
    var CLOCKWISE = -1;
    var COUNTERCLOCKWISE = 1;
    var moveBarLevel = 0 ;
    var radius = 0;
    var debug = false;
    var switch_date = false;
    var prevsteps = 0;
    var feetcolour = Gfx.COLOR_LT_GRAY;
    var firstUpdateAfterSleep = false;
    var drawName = false;
    var SHOW_ICONS = true;
    var SMART_DATE = true;
    var updateSettings = false;

    //! Constructor
    function initialize()
    {
      RetrieveSettings() ;
    }

    //! Load resources
    function onLayout()
    {
      font = Ui.loadResource(Rez.Fonts.id_font_black_diamond);
      background_icons = Ui.loadResource(Rez.Drawables.background_icons_id);
      deviceName = Ui.loadResource(Rez.Strings.id_device_type);
    }

    function onShow()
    {
    }

    // Pick up settings changes
    // rmdir /s /q %temp%\garmin
    function RetrieveSettings() {
      SMART_DATE = Application.getApp().getProperty("SMART_DATE");
      var icon_setting = Application.getApp().getProperty("SHOW_ICONS");
      if (icon_setting == 0) {
        if ( Sys.getDeviceSettings().is24Hour) {
          SHOW_ICONS = true;
        }
        else {
          SHOW_ICONS = false;
        }
      }
      else  if (icon_setting == 1) {
        SHOW_ICONS = true;
      }
      else if (icon_setting == 2) {
        SHOW_ICONS = false;
      }
    }


    //! Nothing to do when going away
    function onHide()
    {
    }

    function drawTriangle(dc, angle, width, inner, length)
    {
        // Map out the coordinates
        var coords = [ [0,-inner], [-(width/2), -length], [width/2, -length] ];
        var result = new [3];
        var centerX = radius;
        var centerY = radius;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 3; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX+x, centerY+y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
    }

    function drawLineFromMin(dc, min, width, inner, length, colour)
    {
        var angle = (min / 60.0) * Math.PI * 2;
        // Map out the coordinates
        var coords = [ [0,-inner], [0, -length] ];
        var result = new [2];
        var centerX = radius;
        var centerY = radius;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 2; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX+x, centerY+y];
        }

        // Draw the Line
        dc.setColor(colour,colour);
        dc.drawLine(result[0][0],result[0][1],result[1][0],result[1][1]);
    }

    function drawBlock(dc, angle, width, inner, length)
    {
        // Map out the coordinates
        var coords = [ [-(width/2),-inner], [-(width/2), -length], [width/2, -length], [width/2, -inner] ];
        var result = new [4];
        var centerX = radius;
        var centerY = radius;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX+x, centerY+y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
    }

    //! Draw the Hour hand
    function drawHourHand(dc, min)
    {
        // Map out the coordinates of the watch hand
        var length = 46;
        var width = 14;
//        var start = 18;
        var start = 16;

        dc.setColor(Gfx.COLOR_DK_GRAY,Gfx.COLOR_BLACK);
//        drawTriangle(dc, min, width, 0, start);// Draw the base Triangle
//        drawBlock(dc, min, width, start, length);
        drawBlock(dc, min, width, 0, length);
        drawTriangle(dc, min, width+10, length+20, length);

        // Fill the interior
        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE);
        drawBlock(dc, min, width/2, start-2 , length);
        drawTriangle(dc, min, width , length+16, length+2);
    }

    function drawMinuteHand(dc, min)
    {
        var length = 72;
        var width = 10;
 //       var start = 16;
        var start = 16;
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        //drawTriangle(dc, min, width+2, 0, start);// Draw the base Triangle
        //drawBlock(dc, min, width+2, start, length);
        drawBlock(dc, min, width+2, 0, length);
        drawTriangle(dc, min, 2+width*2 , length+24, length);

        dc.setColor(Gfx.COLOR_DK_GRAY,Gfx.COLOR_LT_GRAY);
//        drawTriangle(dc, min, width, 0, start);// Draw the base Triangle
//        drawBlock(dc, min, width, start, length);
        drawBlock(dc, min, width, 0, length);
        drawTriangle(dc, min, width*2 , length+20, length);

        // Fill the interior
        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE);
        drawBlock(dc, min, width/2, start-2, length-1);
        drawTriangle(dc, min, width, length+16, length+2);
    }

    function drawSecondHandOld(dc,sec)
    {
        var length = 82;
        var width =  8;
        var start = 20;
        var angle  = ( sec / 60.0) * Math.PI * 2;
        var reverse_angle  = angle -  Math.PI; // opposite angle

        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        drawBlock(dc, angle, width+2, 0, length+2);
        drawBlock(dc, reverse_angle, width+2, 0, 3+length/3);
        drawTriangle(dc, angle, 4+width*2 , length+2+width*2, length);

        dc.setColor(Gfx.COLOR_DK_GRAY,Gfx.COLOR_LT_GRAY);
        drawBlock(dc, angle, width, 0, length);
        drawBlock(dc, reverse_angle, width, 0, 3+length/3);
        drawTriangle(dc, angle, 2+width*2 , length+20, length);

        // Fill the interior
        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE);
        drawBlock(dc, angle, width/3, 0, length-2); // main
        dc.fillCircle(radius, radius, 5);
        drawBlock(dc, reverse_angle, width/3, 0, length/3);
        drawTriangle(dc, angle, -6+2*width, length+14, length+2);
    }
    function drawSecondHand(dc,sec)
    {
        var length = 96;
        var width =  4;
        var start = 20;
        var angle  = ( sec / 60.0) * Math.PI * 2;
        var reverse_angle  = angle -  Math.PI; // opposite angle

//        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
//        drawBlock(dc, reverse_angle, width+2, 0, 2+length/3);
//        drawTriangle(dc, angle, 4+width, length, 0);

        // Fill the interior
        dc.setColor(Gfx.COLOR_RED,Gfx.COLOR_WHITE);
        dc.fillCircle(radius, radius, 5);
        drawBlock(dc, reverse_angle, width, 0, length/4);
        drawBlock(dc, angle, width, 0, 74);
        drawTriangle(dc, angle, width, length, 74);
    }

    function drawTwelve(dc)
    {
        dc.setColor(Gfx.COLOR_LT_GRAY,Gfx.COLOR_LT_GRAY);
        drawTriangle(dc, 0, 30, radius-49, radius-12);

        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE);
        drawTriangle(dc, 0, 23, radius-44, radius-14);
        if (Sys.getDeviceSettings().phoneConnected)
        {
            dc.setColor(Gfx.COLOR_BLUE,Gfx.COLOR_BLUE);
            drawTriangle(dc, 0,  12, radius-39, radius-17, Gfx.COLOR_BLUE);
        }
        else
        {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(radius, 10 , Gfx.FONT_MEDIUM, "!", Gfx.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
    }




    function onExitSleep()
    {
        highPowerMode = true;
        Ui.requestUpdate();
    }

    function onEnterSleep()
    {
        highPowerMode = false;
        firstUpdateAfterSleep = true;
        Ui.requestUpdate();
    }

    // ============================================================
    // Draw segment from center
    // ============================================================
    function drawSegment(dc, startmin, endmin, colour)
    {
        var startangle = (180- startmin * 6 ) * deg2rad;
        var endangle = (180- endmin * 6 )  * deg2rad;
        var xcenter = radius;
        var ycenter = radius;
        var startx = xcenter + (50+ radius) * Math.sin(startangle);
        var starty = ycenter + (50+ radius) * Math.cos(startangle);
        var   endx = xcenter + (50+ radius) * Math.sin(  endangle);
        var   endy = ycenter + (50+ radius) * Math.cos(  endangle);
        // Map out the coordinates
        var coords = [ [radius,radius], [startx, starty], [endx,endy] ];

        // Draw the polygon
        dc.setColor(colour,colour);
        dc.fillPolygon(coords);
    }

    // ============================================================
    //! Handle the update event
    function onUpdate(dc)
    {
        var width, height;
        width = dc.getWidth();
        height = dc.getHeight();
        radius = height/2;
        var clockTime = Sys.getClockTime();
        var hour;
        var min;
        var activityInfo;
        var bar_width = 8;

        if (updateSettings) {
          RetrieveSettings();
          updateSettings = false;
          //Ui.requestUpdate();
        }

        activityInfo = Act.getInfo();
        //prevent divide by 0 if stepGoal is 0
        if( activityInfo != null && activityInfo.stepGoal == 0 )
        {
            activityInfo.stepGoal = 5000;
        }

        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);

        var dateStr = Lang.format("$1$$2$", [info.month, info.day]);
        hour = ( ( ( clockTime.hour % 12 ) * 60 ) + clockTime.min );
        // ============================================================
        // Adjust the date position
        switch_date = false;
        if (SMART_DATE == true) {
          if  ((hour >  160  && hour < 200) ||
               (clockTime.min > 13 && clockTime.min < 17))
          {
              switch_date = true;
          }
        }
        // ============================================================
        // Clear the screen
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0,0,width, height);

        // ============================================================
        // Draw the move bar
        if (debug && activityInfo != null)
        {
            activityInfo.moveBarLevel = moveBarLevel/10;
            moveBarLevel = moveBarLevel+1;
            if (moveBarLevel == 60) { moveBarLevel=0;}
        }
        var bar_length = 9;
        if (activityInfo != null)
        {
            if (activityInfo.moveBarLevel > 0 )
            {
                drawSegment(dc,   30,35  , Gfx.COLOR_RED );
                if (activityInfo.moveBarLevel >1 )
                {
                      drawSegment(dc,   35.5,37.5, Gfx.COLOR_RED );
                    if (activityInfo.moveBarLevel >2 )
                    {
                          drawSegment(dc,   38,40  , Gfx.COLOR_RED );
                        if (activityInfo.moveBarLevel >3 )
                        {
                              drawSegment(dc,   40.5,42.5  , Gfx.COLOR_RED );
                            if (activityInfo.moveBarLevel >4 )
                            {
                                  drawSegment(dc,   43,45  , Gfx.COLOR_RED );
                            }
                        }
                    }
                }
            }
        }

        // ============================================================
        // Draw the activity arc
        if (activityInfo != null)
        {
            var progress = 1f*activityInfo.steps/activityInfo.stepGoal;
            if (progress > 1)
            {
                progress = 1;
            }
            drawSegment(dc, 30, 30-15*progress, Gfx.COLOR_BLUE );

           // 12 hour mode - hide icons
            if (SHOW_ICONS == false)
            {
              feetcolour = Gfx.COLOR_BLACK;
            }
            // else determin icon colour as long as we are not updating every second
            // (results are unpredictable for steps in high power mode so just use previous color)
            // (Also use last colour if we just dropped into low power mode)
            else {
              if (highPowerMode == false && firstUpdateAfterSleep == false)
              {
                if (activityInfo.steps-prevsteps >= 30) // steps per minute to be considered walking
                {
                  feetcolour = Gfx.COLOR_BLUE;
                }
                else
                {
                  if (progress == 1)
                  {
                    feetcolour = Gfx.COLOR_GREEN;
                  }
                  else
                  {
                    feetcolour = Gfx.COLOR_LT_GRAY;
                  }
                }
              }
              else
              {
                feetcolour = Gfx.COLOR_LT_GRAY;
              }
            }
            dc.setColor(feetcolour ,feetcolour );
            var step_icon_x = width*0.66;
            var step_icon_y = height*.69;
            dc.fillRectangle(step_icon_x-1, step_icon_y-2, 25, 22); // colour feet
            prevsteps = activityInfo.steps;
            firstUpdateAfterSleep = false;
        }

        // ============================================================
        // Draw the battery arc
        var battery = Sys.getSystemStats().battery/100;
        var NUM_SEGMENTS = 6;
        var segment_colour = [ Gfx.COLOR_DK_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_DK_GREEN, Gfx.COLOR_DK_GREEN, Gfx.COLOR_GREEN, Gfx.COLOR_GREEN];
        var BOUNDARY = 1f/NUM_SEGMENTS;
        var SEGMENT_SIZE = 15f/NUM_SEGMENTS;
        var GAUGE_START = 45;
        var count = 1;
        for (count = 1; count <= NUM_SEGMENTS ; count++)
        {
            if (battery > (BOUNDARY*count)) // Draw full segment
            {
                drawSegment(dc,   GAUGE_START + (count-1)*SEGMENT_SIZE,
                                  GAUGE_START+(count)*SEGMENT_SIZE,
                                  segment_colour[count-1] );
            }
            else// Draw partial segment
            {
              var partial = GAUGE_START + (count-1)*SEGMENT_SIZE + ((battery-(count-1)*BOUNDARY) / BOUNDARY) * SEGMENT_SIZE;
              var remain =  ((battery-(count-1)*BOUNDARY));
                drawSegment(dc, GAUGE_START + (count-1)*SEGMENT_SIZE,
                                partial,
                                segment_colour[count-1] );
                break;
            }
        }
        //
        // Draw battery icon with same colour as last battery segment
        if (SHOW_ICONS)
        {
          if ( count > NUM_SEGMENTS ) { count = NUM_SEGMENTS ;}
          dc.setColor( segment_colour[count-1], segment_colour[count-1] );
        }
        else
        {
          dc.setColor( Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        }
        var batt_icon_x = width*0.24;
        var batt_icon_y = height*0.24;
        dc.fillRectangle (batt_icon_x-1 , batt_icon_y-2 ,30, 22);

        // ============================================================
        // Draw the background
        dc.drawBitmap(0,0,background_icons);

        // ============================================================
        // Draw the Sleep icon

        var sleep_move_icon_x = width*.23;
        var sleep_move_icon_y = height*.70;
        if (activityInfo != null && activityInfo.isSleepMode  )
        {
            var dimensions =  dc.getTextDimensions(" zzZZ ",Gfx.FONT_XTINY);
            dc.setColor(Gfx.COLOR_DK_BLUE,Gfx.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(sleep_move_icon_x, sleep_move_icon_y ,
                                    dimensions[0]+5, dimensions[1]-2, 4);
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(sleep_move_icon_x+3, sleep_move_icon_y -2,
                        Gfx.FONT_XTINY, " zzZZ ", Gfx.TEXT_JUSTIFY_LEFT);
        }
        // Or the Move icon
        else if (activityInfo != null && activityInfo.moveBarLevel > 0 )
        {
            var dimensions =  dc.getTextDimensions("Move!",Gfx.FONT_XTINY);
            dc.setColor(Gfx.COLOR_DK_RED,Gfx.COLOR_DK_RED);
            dc.fillRoundedRectangle(sleep_move_icon_x, sleep_move_icon_y ,
                                    dimensions[0]+5, dimensions[1]-2, 4);
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(sleep_move_icon_x+3, sleep_move_icon_y-2 ,
                        Gfx.FONT_XTINY, "Move!", Gfx.TEXT_JUSTIFY_LEFT);
        }

        // ============================================================
        // Draw the numbers
        drawTwelve(dc);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(width/2,height-45,font,"6", Gfx.TEXT_JUSTIFY_CENTER);

        // ============================================================
        // Draw the name
        if (drawName == true)
        {
        var d = dc.getTextDimensions(deviceName,Gfx.FONT_XTINY);
//        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
//        dc.drawText(-2+width* 0.80 -d[0]/2 ,-2+height*.21 , // drop shadow
//                    Gfx.FONT_XTINY, deviceName, Gfx.TEXT_JUSTIFY_CENTER);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(width* 0.80 -d[0]/2 ,height*.21 ,
                    Gfx.FONT_XTINY, deviceName, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width* 0.78 -d[0]/2 ,
                    height*.19 + 14, Gfx.FONT_XTINY, "100m/330ft", Gfx.TEXT_JUSTIFY_CENTER);
        }
        // ============================================================
        // Draw the date
        var date_pos = 0;
        var dimensions =  dc.getTextDimensions(dateStr,Gfx.FONT_SMALL);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        if (switch_date)
        {
            date_pos = 20;
            dc.drawText(width-22,-15+height/2,font, "3", Gfx.TEXT_JUSTIFY_RIGHT);
        }
        else
        {
            date_pos = width-22-dimensions[0];
            dc.drawText(16,-15+height/2,font,"9",Gfx.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT); // drop shadow
        dc.fillRoundedRectangle(date_pos-3, -dimensions[1]/2+height/2-2,
                                dimensions[0]+4, dimensions[1]-2, 4);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(date_pos, -dimensions[1]/2+height/2,
                                dimensions[0]+4, dimensions[1]-2, 4);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(date_pos+1, -dimensions[1]/2 -1 + height/2,
                    Gfx.FONT_SMALL, dateStr, Gfx.TEXT_JUSTIFY_LEFT);

        // ============================================================
        // Draw the hour hand. Convert it to minutes and
        // compute the angle.
        hour = hour / (12 * 60.0);
        drawHourHand(dc, hour * Math.PI * 2);

        // ============================================================
        // Draw the minute hand
        min = ( clockTime.min / 60.0) * Math.PI * 2;
        drawMinuteHand(dc, min);


        // ============================================================
        // Draw the second hand
        if (highPowerMode == true)
        {
          var sec  =  clockTime.sec;
          drawSecondHand(dc, sec);
        }
        else
        {
          // ============================================================
          // Draw the inner circle
          dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK);
          dc.fillCircle(radius, radius, 7);
          dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
          dc.drawCircle(radius, radius, 7 );
        }

        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        dc.fillCircle(radius, radius, 2 );
    }
}
