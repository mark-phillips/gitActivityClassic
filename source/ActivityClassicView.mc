using Toybox.ActivityMonitor as Act;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;

class ActivityClassicView extends Ui.WatchFace {
    // To make is quicker to grab screenshots with move arc set the following
    // to true
    var increment_move_arc = false;
    // To turn on trace set the following to true
    var trace = true;
    var trace_indent = 0;
    //
    // Resources
    var font;
    var background_icons;
    //
    // Constants
    var highPowerMode = false;
    var DEG2RAD = Math.PI/180;
    var CLOCKWISE = -1;
    var COUNTERCLOCKWISE = 1;

    // Screen type constants
    var SCREEN_UNKNOWN = -1;
    var SCREEN_ROUND = 0;
    var SCREEN_SEMI_ROUND = 1;

    // date format constants
    var DATE_MONTH = 0;
    var DATE_DAY_OF_WEEK = 1;
    var DATE_ALTERNATE = 2;
    //
    // Global display state
    var switch_date = false;
    var moveBarLevel = 0 ;
    var prevsteps = 0;
    var feetcolour = Gfx.COLOR_LT_GRAY;
    var firstUpdateAfterSleep = false;
    var updateSettings = false;
    var use3d = true;
    //
    // Global instance vars
    var radius = 0;
    var screen_width = -1;
    var screen_height = -1;
    var screen_type = SCREEN_UNKNOWN;
    var NotificationCountVisible = true;
    var NotificationCountColour = Gfx.COLOR_PURPLE;
    var SHOW_ICONS = true;
    var SMART_DATE = true;
    var DATE_FORMAT = 0;
    var PREVIOUS_MIN = -1;
    var ARROW = 1;
    var POINTER = 1;
    var SWORD= 2;
    var HourHandStyle = ARROW;
    var MinuteHandStyle = ARROW;
    var SecondHandStyle = POINTER;
    //! Constructor
    function initialize()
    {
      if (trace) { trace_entry("initialize","none"); }
      RetrieveSettings() ;
            font = Ui.loadResource(Rez.Fonts.id_font_black_diamond);
      if (use3d) {
        background_icons = Ui.loadResource(Rez.Drawables.background_icons_3d_id); //
      }
      else {
        background_icons = Ui.loadResource(Rez.Drawables.background_icons_id);
      }
      if (trace) { trace_exit("initialize"); }
    }

    //! Load resources
    function onLayout()
    {
      if (trace) { trace_entry("onLayout","none"); }

      if (trace) { trace_exit("onLayout"); }
    }

    function onShow()
    {
      if (trace) { trace_entry("onShow","none"); }
      if (trace) { trace_exit("onShow"); }
    }

    // Pick up settings changes
    // rmdir /s /q %temp%\garmin
    function RetrieveSettings() {
      if (trace) { trace_entry("RetrieveSettings","none"); }
        //
        // Date positioning options
        SMART_DATE = Application.getApp().getProperty("SMART_DATE");
        DATE_FORMAT = Application.getApp().getProperty("DATE_FORMAT");
        //
        // Notification Count options
        NotificationCountVisible = Application.getApp().getProperty("SHOW_NOTIFICATION_ARC");
        NotificationCountColour = Application.getApp().getProperty("NOTIFICATION_ARC_COLOUR");
        if (trace) { trace_data("NotificationCountVisible  " + NotificationCountVisible  + "Colour: " + NotificationCountColour ); }
        //
        // Icon visibiity options
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

      //background_icons = Ui.loadResource(Rez.Drawables.background_icons_3d_id);
      //Ui.loadResource(Rez.Drawables.background_icons_id);

      if (trace) { trace_exit("RetrieveSettings"); }
    }


    //! Nothing to do when going away
    function onHide()
    {
    }

    function drawTriangleImpl(dc, angle,  coords)
    {
        // Map out the coordinates
        var result = new [3];
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 3; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ xcenter+x, ycenter+y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
    }

    function drawTriangle(dc, angle, width, inner, length)
    {
        // Map out the coordinates
        var coords = [ [0,-inner], [-(adjustSemiRound(width)/2), -length], [adjustSemiRound(width)/2, -length] ];
        drawTriangleImpl(dc, angle, coords);
    }

    function drawTriangle3d(dc, angle, width, inner, length, light_colour, dark_colour)
    {
      if (trace) { trace_entry("drawTriangle3d","none"); }

        var colour1 = dark_colour;
        var colour2 = light_colour;
        if (trace) { trace_data("angle" + angle); }
        if (angle > 3.14159) {  // after 180 degrees (in rads), switch shadow
            colour1 = light_colour;
            colour2 = dark_colour;
        }
        var coords = [ [0,-inner], [-(adjustSemiRound(width)/2), -length], [0, -length] ];
        dc.setColor(colour1,colour1);
        drawTriangleImpl(dc, angle, coords);
        coords = [ [0,-inner], [0, -length], [adjustSemiRound(width)/2, -length] ];
        dc.setColor(colour2,colour2);
        drawTriangleImpl(dc, angle, coords);

        if (trace) { trace_exit("drawTriangle3d"); }
    }

    function drawBlockImpl(dc, angle, coords)
    {
        var result = new [4];
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ xcenter+x, ycenter+y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
    }
    function drawBlock(dc, angle, width, inner, length)
    {
        // Map out the coordinates
        var coords = [ [-(adjustSemiRound(width)/2),-inner], [-(adjustSemiRound(width)/2), -length], [adjustSemiRound(width)/2, -length], [adjustSemiRound(width)/2, -inner] ];
        drawBlockImpl(dc,angle,coords);
    }

    // ============================================================
    // Draw 3d Block
    // ============================================================
    function drawBlock3d(dc, angle, width, inner, length, light_colour, dark_colour)
    {
        var colour1 = dark_colour;
        var colour2 = light_colour;
        if (angle > 3.14159) {  // after minute 30, switch shadow
            colour1 = light_colour;
            colour2 = dark_colour;
        }
        var coords = [ [-(adjustSemiRound(width)/2),-inner], [-(adjustSemiRound(width)/2), -length], [0, -length], [0, -inner] ];
        dc.setColor(colour1,colour1);
        drawBlockImpl(dc,angle,coords);
        coords = [ [0,-inner], [0, -length], [adjustSemiRound(width)/2, -length], [adjustSemiRound(width)/2, -inner] ];
        dc.setColor(colour2,colour2);
        drawBlockImpl(dc,angle,coords);
    }

    function drawArrowHand(dc,min,length,arrowLength, width, start)
    {
        // Map out the coordinates of the watch hand

        // Black outline
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        drawBlock(dc, min, width+2, 0, length+2);
        drawTriangle(dc, min, 2+width*2 , length+arrowLength+2, length);

        // Draw hand
        dc.setColor(Gfx.COLOR_DK_GRAY,Gfx.COLOR_BLACK);
        if (use3d) {
            drawBlock3d(dc, min, width, 0, length, Gfx.COLOR_LT_GRAY, Gfx.COLOR_DK_GRAY);
            drawTriangle3d(dc, min, width+(arrowLength/2), length+arrowLength,length, Gfx.COLOR_LT_GRAY, Gfx.COLOR_DK_GRAY);
        }
        else {
            drawBlock(dc, min, width, 0, length);
            drawTriangle(dc, min, width+(arrowLength/2), length+arrowLength, length);

        }

        // Fill the interior
          dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE);
          drawBlock(dc, min, width/2, start-2 , length);
          drawTriangle(dc, min, width , length+arrowLength*.6, length+2);
   //     }

    }

    function drawMinuteHand(dc, min)
    {
        var length = adjustSemiRound(72);
        var width = 10;
        var arrowLength = 20;
        var start = 16;
        //drawMinuteHandArrow2D(dc,min);
        drawArrowHand(dc,min,length,arrowLength,width,start);
    }

    //! Draw the Hour hand
    function drawHourHand(dc, min)
    {
        var length = adjustSemiRound(46);
        var width = 14;
        var start = 16;
        var arrowLength = 20;
        if (HourHandStyle == ARROW) {
            drawArrowHand(dc,min,length,arrowLength,width,start);
        }
        else if (HourHandStyle == POINTER) {
        }
        else {
        }
    }
    function drawMinuteHandArrow2D(dc, min)
    {
        var length = adjustSemiRound(72);
        var width = 10;
        var arrowLength = 20;
        var start = 16;
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        // Black outline
        drawBlock(dc, min, width+2, 0, length);
        drawTriangle(dc, min, 2+width*2 , length+arrowLength+4, length);

        dc.setColor(Gfx.COLOR_DK_GRAY,Gfx.COLOR_LT_GRAY);
        drawBlock3d(dc, min, width, 0, length, Gfx.COLOR_LT_GRAY, Gfx.COLOR_DK_GRAY);
//        drawBlock(dc, min, width, 0, length);
        drawTriangle(dc, min, width*2 , length+arrowLength, length);

        // Fill the interior
        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE);
        drawBlock(dc, min, width/2, start-2, length-1);
        drawTriangle(dc, min, width, length+16, length+2);
    }

    function drawSecondHandOld(dc,sec)
    {
        var length = adjustSemiRound(82);
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
        var length = adjustSemiRound(96);
        var bodylength = adjustSemiRound(74);
        var width =  4;
        var start = 20;
        var angle  = ( sec / 60.0) * Math.PI * 2;
        var reverse_angle  = angle -  Math.PI; // opposite angle
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;

        // Fill the interior
        dc.setColor(Gfx.COLOR_RED,Gfx.COLOR_WHITE);
        dc.fillCircle(xcenter, ycenter, 5);
        drawBlock(dc, reverse_angle, width, 0, length/4);
        drawBlock(dc, angle, width, 0, bodylength);
        drawTriangle(dc, angle, width, length, bodylength);
    }

    function drawTwelve(dc)
    {
        dc.setColor(Gfx.COLOR_LT_GRAY,Gfx.COLOR_LT_GRAY);
        drawTriangle(dc, 0, (30), radius-49, radius-12);

        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE);
        drawTriangle(dc, 0, (23), radius-(44), radius-(14));
        if (Sys.getDeviceSettings().phoneConnected)
        {
            dc.setColor(Gfx.COLOR_DK_BLUE,Gfx.COLOR_DK_BLUE);
            drawTriangle(dc, 0,  14, radius-(39), radius-(17));
        }
        else
        {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(screen_width/2, 10 , Gfx.FONT_MEDIUM, "!", Gfx.TEXT_JUSTIFY_CENTER);
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
    }


    function onExitSleep()
    {
      if (trace) { trace_entry("onExitSleep","none"); }
        highPowerMode = true;
        Ui.requestUpdate();
      if (trace) { trace_exit("onExitSleep"); }
    }

    function onEnterSleep()
    {
      if (trace) { trace_entry("onEnterSleep","none"); }
        highPowerMode = false;
        firstUpdateAfterSleep = true;
        Ui.requestUpdate();
      if (trace) { trace_exit("onEnterSleep"); }
    }

    // ============================================================
    // Draw segment from center
    // ============================================================
    function drawSegment(dc, startmin, endmin, colour)
    {
        var startangle = (180- startmin * 6 ) * DEG2RAD;
        var endangle = (180- endmin * 6 )  * DEG2RAD;
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
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
    function adjustSemiRound(xvalue) {
        if (screen_type == SCREEN_SEMI_ROUND) {
            return (1.0 * xvalue * (170.0 / 218.0));
        }
        return xvalue;
    }

    // ============================================================
    //! Handle the update event
    function onUpdate(dc)
    {
      if (trace) { trace_entry("onUpdate","none"); }
        // First time in, work out screen constants
        if (screen_type == SCREEN_UNKNOWN) {
          screen_width = dc.getWidth();
          screen_height = dc.getHeight();
          if (screen_width == 218 and screen_height == 218) {
            screen_type = SCREEN_ROUND;
          }
          else if (screen_width == 215 and screen_height == 180) {
            screen_type = SCREEN_SEMI_ROUND;
          }
          radius = screen_height/2;
        }

        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
        var clockTime = Sys.getClockTime();
        var hour;
        var min;
        var activityInfo;
        var bar_width = 8;

        if (updateSettings) {
          RetrieveSettings();
          updateSettings = false;
        }

        activityInfo = Act.getInfo();
        //prevent divide by 0 if stepGoal is 0
        if( activityInfo != null && activityInfo.stepGoal == 0 )
        {
            activityInfo.stepGoal = 5000;
        }

        var now = Time.now();
        var calendar_info = Calendar.info(now, Time.FORMAT_MEDIUM);

        //
        // Compute the date string & location
        var dateStr = "";
        var date_type = DATE_FORMAT;
        //
        // Handle alternating date formats
        if (DATE_FORMAT == DATE_ALTERNATE ) {
            if ( clockTime.min % 2 == 0 ) {
                date_type = DATE_DAY_OF_WEEK;
            }
            else {
                date_type = DATE_MONTH;
            }
        }
        //
        // Now get the date string
        if (date_type == DATE_MONTH) {
            dateStr = Lang.format("$1$$2$", [calendar_info.month, calendar_info.day]);
        }
        else {
            dateStr = Lang.format("$1$$2$", [calendar_info.day_of_week, calendar_info.day]);
        }
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
        dc.fillRectangle(0,0,screen_width, screen_height);

        // ============================================================
        // Draw the move bar
        drawMoveBar(dc,activityInfo);

        // ============================================================
        // Draw the Notifications arc between 0 and the 15 minute marker
        // To grab your attention when you have a single notification the watch
        // draws an arc betweeen 12 and the 5 minute marker.  Each subsequent
        // notification appears as another minute up to 15.
        if (NotificationCountVisible == true) {
            var notificationCount = Sys.getDeviceSettings().notificationCount;
            if (notificationCount > 0) {
                notificationCount = (notificationCount > 11) ? 11 : notificationCount ;
                drawSegment(dc, 0, 4+(notificationCount-1)+0.7  , NotificationCountColour );
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
              //else
              //{
              //  feetcolour = Gfx.COLOR_LT_GRAY;
              //}
            }
            dc.setColor(feetcolour ,feetcolour );
            var step_icon_x = screen_width*0.66;
            var step_icon_y = screen_height*.69;
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
        var batt_icon_x = screen_width*0.24;
        var batt_icon_y = screen_height*0.24;
        dc.fillRectangle (batt_icon_x-1 , batt_icon_y-2 ,40, 22);

        // ============================================================
        // Draw the background
        dc.drawBitmap(0,0,background_icons);

        // ============================================================
        // Draw the Sleep icon

        //var sleep_move_icon_x = screen_width - *.23;
        var sleep_move_icon_x = screen_width - screen_width*.77;
        var sleep_move_icon_y = screen_height*.70;
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
        var inset = 45;
        if (screen_type == SCREEN_SEMI_ROUND) {
          inset = 42;
          font =  Gfx.FONT_LARGE;
        }
        dc.drawText(screen_width/2,screen_height-inset,font,"6", Gfx.TEXT_JUSTIFY_CENTER);
        // ============================================================
        // Draw the date
        var date_pos = 0;
        var dimensions =  dc.getTextDimensions(dateStr,Gfx.FONT_SMALL);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        inset = 16;
        if (screen_type == SCREEN_SEMI_ROUND) {
          inset = 32;
          font =  Gfx.FONT_LARGE;
        }
        if (switch_date)
        {
            date_pos = inset;
            dc.drawText(screen_width-(inset),-15+screen_height/2,font, "3", Gfx.TEXT_JUSTIFY_RIGHT);
        }
        else
        {
            date_pos = screen_width-(inset+2)-dimensions[0];
            dc.drawText((inset),-15+screen_height/2,font,"9",Gfx.TEXT_JUSTIFY_LEFT);
        }
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT); // drop shadow
        dc.fillRoundedRectangle(date_pos-3, -dimensions[1]/2+screen_height/2-2,
                                dimensions[0]+4, dimensions[1]-2, 4);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(date_pos, -dimensions[1]/2+screen_height/2,
                                dimensions[0]+4, dimensions[1]-2, 4);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(date_pos+1, -dimensions[1]/2 -1 + screen_height/2,
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
          dc.fillCircle(xcenter, ycenter, 7);
          dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
          dc.drawCircle(xcenter, ycenter, 7 );
        }

        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        dc.fillCircle(xcenter, ycenter, 2 );

      PREVIOUS_MIN = clockTime.min;
      if (trace) { trace_exit("onUpdate"); }
    }

    // Draw move bar
    function drawMoveBar(dc,activityInfo) {
        if (increment_move_arc && activityInfo != null)
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
    }    //
    // Trace methods
    function trace_data(data) {
        print_trace_time();
        print_trace_indent(trace_indent);
        System.println( "d " + data);
    }
    function trace_entry(method, parms) {
        trace_indent++;
        print_trace_time();
        print_trace_indent(trace_indent);
        System.println( "> " + method + "()" + "[" + parms + "]");
    }
    function trace_exit(method) {
        print_trace_time();
        print_trace_indent(trace_indent);
        System.println( "< " + method + "()");
        trace_indent--;
    }
    function print_trace_time() {
        var clockTime = Sys.getClockTime();
        System.print( clockTime.hour + ":" + clockTime.min + ":" + clockTime.sec +  "  " + System.getTimer() +"  ");

    }
    function print_trace_indent(trace_indent) {
        var indent_string = "";
        for (var c=0; c<trace_indent; c++) {
            indent_string = indent_string + "-";
        }
        System.print(indent_string);
    }
}
