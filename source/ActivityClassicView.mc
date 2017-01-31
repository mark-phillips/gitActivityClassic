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
    var demo_mode = false;
    // To turn on trace set the following to true
    var trace = false;
//var moontest = 1470170640;
    var trace_indent = 0;
    //
    // Resources
    var font;
    var moonfont;
    var background_icons;

    //
    // Constants
    var highPowerMode = false;
    var DEG2RAD = Math.PI/180;
    var CLOCKWISE = -1;
    var COUNTERCLOCKWISE = 1;
    var PHASES= ["@","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","A","B","C","D","E","F","G","H","I","J","K","L","M"];


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
    var moveBarLevel = 0 ;
    var prevsteps = 0;
    var feetcolour = Gfx.COLOR_LT_GRAY;
    var firstUpdateAfterSleep = false;
    var updateSettings = false;

    var PREVIOUS_MINUTE_OF_DAY = -1;
    var PREVIOUS_SUN_CALC_DAY = -1;
    var NEXT_SUNRISE_OR_SUNSET = -1;
    var todaySunTimes = null;
    var tomorrowSunTimes = null;
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
    var POINTER = 100;
    var ARROW = 101;
    var CIRCLE= 102;
    var SWORD= 103;
    var ARROW3D= 104;

    var MAIN_HAND_STYLE = ARROW;
    var SECOND_HAND_STYLE = POINTER;
    var SHOW_UTC_HAND = false;
    var UTC_HAND_OFFSET = 0;
    var UTC_HAND_STYLE = CIRCLE;
    var UTC_HIGHLIGHT_COLOUR = 11141120;
    var NO_MOONPHASE = 0;
    var MOONPHASE_AT_6 = 1;
    var MOONPHASE_AT_9 = 2;
    var MOONPHASE_LOCATION = MOONPHASE_AT_9;

    var NUMBER_THREE = "3";
    var NUMBER_SIX = "6";
    var NUMBER_NINE = "9";
    var NUMBER_FONT = font;
    //! Constructor
    function initialize()
    {
      if (trace) { trace_entry("initialize","none"); }
      WatchFace.initialize();
      font = Ui.loadResource(Rez.Fonts.id_font_black_diamond);
      moonfont = Ui.loadResource(Rez.Fonts.id_font_moonphase);
      RetrieveSettings() ;
      background_icons = Ui.loadResource(Rez.Drawables.background_icons_id);
      if (trace) { trace_exit("initialize"); }
    }

    //! Load resources
    function onLayout(dc)
    {
      if (trace) { trace_entry("onLayout","none"); }

      if (trace) { trace_exit("onLayout"); }
    }

    function onShow()
    {
      if (trace) { trace_entry("onShow","none"); }
      if (trace) { trace_exit("onShow"); }
    }

    // Return a app setting or use default vakue if not set
    function getSetting(constant,default_value) {
        var setting = Application.getApp().getProperty(constant);
        if (setting != null) {
            return setting;
        }
        else {
            return default_value;
        }
    }
    // rmdir /s /q %temp%\garmin
    // Pick up settings changes
    function RetrieveSettings() {
      if (trace) { trace_entry("RetrieveSettings","none"); }
        //
        // Date positioning options
        SMART_DATE = getSetting("SMART_DATE",SMART_DATE);
        DATE_FORMAT = getSetting("DATE_FORMAT",DATE_FORMAT);
        //
        // Notification Count options
        NotificationCountVisible = getSetting("SHOW_NOTIFICATION_ARC",NotificationCountVisible );
        NotificationCountColour  = getSetting("NOTIFICATION_ARC_COLOUR",NotificationCountColour  );
        //
        // Icon visibiity options
        var icon_setting = getSetting("SHOW_ICONS",0);
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
        MAIN_HAND_STYLE = getSetting("MAIN_HAND_STYLE",MAIN_HAND_STYLE);
        SECOND_HAND_STYLE = getSetting("SECOND_HAND_STYLE",SECOND_HAND_STYLE);
        SHOW_UTC_HAND = getSetting("SHOW_UTC_HAND",SHOW_UTC_HAND);
        UTC_HAND_OFFSET = getSetting("UTC_HAND_OFFSET",UTC_HAND_OFFSET);
        UTC_HAND_STYLE = getSetting("UTC_HAND_STYLE",UTC_HAND_STYLE);
        UTC_HIGHLIGHT_COLOUR = getSetting("UTC_HIGHLIGHT_COLOUR",UTC_HIGHLIGHT_COLOUR);
        MOONPHASE_LOCATION = getSetting("SHOW_MOONPHASE",MOONPHASE_LOCATION);
      if (trace) { trace_exit("RetrieveSettings"); }
    }


    //! Nothing to do when going away
    function onHide()
    {
    }

    function drawTriangleImpl(dc, angle_in_radians,  coords)
    {
        // Map out the coordinates
        var result = new [3];
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
        var cos = Math.cos(angle_in_radians);
        var sin = Math.sin(angle_in_radians);

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

    function drawTriangle(dc, angle_in_radians, width, inner, length)
    {
        // Map out the coordinates
        var coords = [ [0,-inner], [-(adjustSemiRound(width)/2), -length], [adjustSemiRound(width)/2, -length] ];
        drawTriangleImpl(dc, angle_in_radians, coords);
    }

    function drawTriangle3d(dc, angle_in_radians, width, inner, length, light_colour, dark_colour)
    {
//      if (trace) { trace_entry("drawTriangle3d","none"); }

        var colour1 = dark_colour;
        var colour2 = light_colour;
//        if (trace) { trace_data("angle" + angle); }
        if (angle_in_radians > 3.14159) {  // after 180 degrees (in rads), switch shadow
            colour1 = light_colour;
            colour2 = dark_colour;
        }
        var coords = [ [0,-inner], [-(adjustSemiRound(width)/2), -length], [0, -length] ];
        dc.setColor(colour1,colour1);
        drawTriangleImpl(dc, angle_in_radians, coords);
        coords = [ [0,-inner], [0, -length], [adjustSemiRound(width)/2, -length] ];
        dc.setColor(colour2,colour2);
        drawTriangleImpl(dc, angle_in_radians, coords);

        //if (trace) { trace_exit("drawTriangle3d"); }
    }

    function drawBlockImpl(dc, angle_in_radians, coords)
    {
        var result = new [4];
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
        var cos = Math.cos(angle_in_radians);
        var sin = Math.sin(angle_in_radians);

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
    function drawBlock(dc, angle_in_radians, width, inner, length)
    {
        // Map out the coordinates
        var coords = [ [-(adjustSemiRound(width)/2),-inner], [-(adjustSemiRound(width)/2), -length], [adjustSemiRound(width)/2, -length], [adjustSemiRound(width)/2, -inner] ];
        drawBlockImpl(dc,angle_in_radians,coords);
    }

    // ============================================================
    // Draw 3d Block
    // ============================================================
    function drawBlock3d(dc, angle_in_radians, width, inner, length, light_colour, dark_colour)
    {
        var colour1 = dark_colour;
        var colour2 = light_colour;
        if (angle_in_radians > 3.14159) {  // after minute 30, switch shadow
            colour1 = light_colour;
            colour2 = dark_colour;
        }
        var coords = [ [-(adjustSemiRound(width)/2),-inner], [-(adjustSemiRound(width)/2), -length], [0, -length], [0, -inner] ];
        dc.setColor(colour1,colour1);
        drawBlockImpl(dc,angle_in_radians,coords);
        coords = [ [0,-inner], [0, -length], [adjustSemiRound(width)/2, -length], [adjustSemiRound(width)/2, -inner] ];
        dc.setColor(colour2,colour2);
        drawBlockImpl(dc,angle_in_radians,coords);
    }

    function drawArrowHand(dc,min,length,arrowLength, width, start, fillcolour,use3d)
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
            drawTriangle3d(dc, min, width+(arrowLength/1.5), length+arrowLength,length, Gfx.COLOR_LT_GRAY, Gfx.COLOR_DK_GRAY);
        }
        else {
            drawBlock(dc, min, width, 0, length);
            drawTriangle(dc, min, width+(arrowLength/1.5), length+arrowLength, length);
        }

        // Fill the interior
          dc.setColor(fillcolour,fillcolour);
          drawBlock(dc, min, width/3, start-2 , length-2);
          drawTriangle(dc, min, width , length+arrowLength*.6, length+2);
   //     }
    }

    function drawPointerHand(dc,angle_in_radians,bodylength,arrowLength,width,colour1,colour2,use3d)
    {
        var length = (bodylength+arrowLength);
        var reverse_angle_in_radians  = angle_in_radians -  Math.PI; // opposite angle
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;

        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        drawTriangle(dc, angle_in_radians, width+4, length+2, bodylength);

        dc.setColor(colour1,Gfx.COLOR_WHITE);
        dc.fillCircle(xcenter, ycenter, 5);
        if (use3d) {
          drawBlock3d(dc, reverse_angle_in_radians, width*1.4, 0, length/3,colour2,colour1);
          drawBlock3d(dc, angle_in_radians, width*1.4, 0, bodylength,colour1,colour2);
          drawTriangle3d(dc, angle_in_radians, width*1.4, length, bodylength,colour1,colour2);
        }
        else {
          drawBlock(dc, reverse_angle_in_radians, width, 0, length/3);
          drawBlock(dc, angle_in_radians, width, 0, bodylength);
          drawTriangle(dc, angle_in_radians, width, length, bodylength);
        }
    }

    function drawCircleHand(dc,angle_in_radians,bodylength,arrowLength,width,colour1,colour2,highlight_colour)
    {
        var length = (bodylength+arrowLength);
        var reverse_angle_in_radians  = angle_in_radians -  Math.PI; // opposite angle
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
        var radius = (width*2.5);
        var inner_radius = radius*.75;


        // Draw the circle
        var cos = Math.cos(angle_in_radians);
        var sin = Math.sin(angle_in_radians);
        var circle_x = (0 * cos) + ((bodylength-inner_radius) * sin) + xcenter;
        var circle_y =(0 * sin) - ((bodylength-inner_radius) * cos) + ycenter;
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        dc.fillCircle(circle_x, circle_y, radius+1);

        drawPointerHand(dc,angle_in_radians,bodylength,arrowLength,width,colour1,colour2,true);

        dc.setColor(colour1,Gfx.COLOR_WHITE);
        dc.fillCircle(circle_x, circle_y, radius);
        dc.setColor(highlight_colour,highlight_colour);
        dc.fillCircle(circle_x, circle_y, inner_radius);
    }
    function drawArrowPointerHand(dc,angle_in_radians,bodylength,arrowLength,width,colour1,colour2,highlight_colour)
    {
        arrowLength = arrowLength;
        var outline = width/1.75;
        var pointLength = bodylength*.8;
        var length = (bodylength+pointLength)-3;
        var reverse_angle_in_radians  = angle_in_radians -  Math.PI; // opposite angle
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;

        drawPointerHand(dc,angle_in_radians,bodylength,pointLength,width,colour1,colour2,true);
        // Draw arrow
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        drawTriangle(dc, angle_in_radians, width+arrowLength+4, length+arrowLength+2,length-1);
        dc.setColor(colour1,colour1);
        drawTriangle(dc, angle_in_radians, width+arrowLength, length+arrowLength,length-1);
        dc.setColor(highlight_colour,highlight_colour);
        drawTriangle(dc, angle_in_radians, arrowLength-outline*2, length+arrowLength-outline-1,length+outline-1);

    }
    function drawArrowHandExtended(dc,min,length,arrowLength, width, start, fillcolour,use3d)
    {
        drawArrowHand(dc,min,length,arrowLength, width, start, fillcolour,use3d);
        // Black outline
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        drawBlock(dc, min, width+2, 0, -(length+2)/3);
        dc.setColor(Gfx.COLOR_DK_GRAY,Gfx.COLOR_BLACK);
        if (use3d) {
            drawBlock3d(dc, min, width, 0, -length/3, Gfx.COLOR_LT_GRAY, Gfx.COLOR_DK_GRAY);
        }
        else {
            drawBlock(dc, min, width, 0, -length/3);
        }

    }


    function drawMinuteHand(dc, min, topHand)
    {
        var length = adjustSemiRound(70);
        var width = 12;
        var arrowLength = 20;
        var start = 16;
        if (MAIN_HAND_STYLE == ARROW3D) {
            drawArrowHand(dc,min,length,arrowLength,width,start,Gfx.COLOR_WHITE,true);
        }
        else if (MAIN_HAND_STYLE == ARROW)  {
            drawArrowHand(dc,min,length,arrowLength,width,start,Gfx.COLOR_WHITE,false);
        }
        // If we're not drawing a second hand then draw the inner circle now because the
        // minute hand is the top hand
        if (topHand == true) {
          drawInnerCircle(dc);
        }
    }

    //! Draw the Hour hand
    function drawHourHand(dc, min)
    {
        var length = adjustSemiRound(46);
        var width = 14;
        var start = 16;
        var arrowLength = 20;
        if (MAIN_HAND_STYLE == ARROW3D) {
            drawArrowHand(dc,min,length,arrowLength,width,start,Gfx.COLOR_WHITE,true);
        }
        else if (MAIN_HAND_STYLE == ARROW)  {
            drawArrowHand(dc,min,length,arrowLength,width,start,Gfx.COLOR_WHITE,false);
        }
        else if (MAIN_HAND_STYLE == POINTER) {
        }
        else if (MAIN_HAND_STYLE == SWORD) {
        }
        else {
        }
    }

    function drawSecondHand(dc,sec)
    {
        var length = adjustSemiRound(74);
        var start = 20;
        var arrowLength = 20;
        sec = (sec/ 60.0) * Math.PI * 2;
        if (SECOND_HAND_STYLE == ARROW) {
            drawArrowHandExtended(dc,sec,length,arrowLength,8,start,Gfx.COLOR_WHITE,false);
           // draw the inner circle now because the second hand is the top hand
            drawInnerCircle(dc);
        }
        else if (SECOND_HAND_STYLE == ARROW3D) {
            drawArrowHandExtended(dc,sec,length,arrowLength,8,start,Gfx.COLOR_WHITE,true);
        }
        else if (SECOND_HAND_STYLE == POINTER) {
            drawPointerHand(dc,sec,length,arrowLength,4,Gfx.COLOR_RED,Gfx.COLOR_DK_RED,true);
        }
        else {
        }
    }
    function drawUTCHand(dc,hour)
    {
        if (UTC_HAND_STYLE == ARROW) {
            drawArrowPointerHand(dc,hour,adjustSemiRound(25),adjustSemiRound(21),5,Gfx.COLOR_LT_GRAY,Gfx.COLOR_DK_GRAY,UTC_HIGHLIGHT_COLOUR);
        } else {
            drawCircleHand(dc,hour,adjustSemiRound(50),adjustSemiRound(25),4,Gfx.COLOR_LT_GRAY,Gfx.COLOR_DK_GRAY,UTC_HIGHLIGHT_COLOUR);
        }
    }
    function minutes_to_rads(minutes) {
        return ( minutes / 60.0) * Math.PI * 2;
    }

    function minuteOfDayToTimeString(minute_of_day) {
        return Lang.format("$1$:$2$", [(minute_of_day/60).toNumber().format("%.2d"),(minute_of_day.toNumber()%60).format("%.2d")]);
    }

    function drawSunHand(dc,minute_of_day)
    {
        var fillColour = Gfx.COLOR_DK_RED;
        if (todaySunTimes != null && minute_of_day <= todaySunTimes.mSunrise) {
            NEXT_SUNRISE_OR_SUNSET = todaySunTimes.mSunrise;
        }
        else if (todaySunTimes != null && minute_of_day <= todaySunTimes.mSunset) {
            NEXT_SUNRISE_OR_SUNSET = todaySunTimes.mSunset;
            fillColour = Gfx.COLOR_BLACK;
        }
        else if (todaySunTimes != null && minute_of_day > todaySunTimes.mSunset) {
            NEXT_SUNRISE_OR_SUNSET = tomorrowSunTimes.mSunrise;
            if (trace) { trace_data("Next sun event is tomorrow's sunrise" );}
        }
        if (trace) { trace_data("Next Sunrise/Sunset: " + minuteOfDayToTimeString(NEXT_SUNRISE_OR_SUNSET));}
        if (NEXT_SUNRISE_OR_SUNSET != -1) {
            drawCircleHand(dc,minutes_to_rads(NEXT_SUNRISE_OR_SUNSET/12),
                   adjustSemiRound(42),adjustSemiRound(23),2,
                   Gfx.COLOR_YELLOW,Gfx.COLOR_ORANGE,fillColour);
        }
    }

    function calculateSunEvents(clockTime,calendar_info)    {
        var position = Activity.getActivityInfo().currentLocation;
        var se = new SunriseEquation();
        if (position == null) { // or PREVIOUS_SUN_CALC_DAY == calendar_info.day) {
            if (trace) { trace_data("Sunrise/Sunset not shown - no position data!");}
            return;
        }
        if (PREVIOUS_SUN_CALC_DAY == calendar_info.day) {
            return;  // already calculated today
        }
        else  // New day - new calc
        {
          PREVIOUS_SUN_CALC_DAY = calendar_info.day;
          var hour = 0;
          var min = 0;
          var lonW = position.toDegrees()[1].abs().toDouble();
          var latN = position.toDegrees()[0].toDouble();
          var utcOffset = new Time.Duration(-clockTime.timeZoneOffset);
          System.println("utcOffset: " + utcOffset.value());
          var JulianDayNow = se.evaluateJulianDay(utcOffset);

          todaySunTimes = se.evaluateSunriseAndSetAsTime(lonW, latN,
                                                         JulianDayNow,utcOffset);
          tomorrowSunTimes = se.evaluateSunriseAndSetAsTime(lonW, latN,
                                                            JulianDayNow+1,utcOffset);
          if (trace) {
            trace_data("utcOffset: " + utcOffset.value());
            trace_data("today Sunrise: " + todaySunTimes.mSunrise + "(" + minuteOfDayToTimeString(todaySunTimes.mSunrise));
            trace_data("today Sunset: " + todaySunTimes.mSunset + "(" +minuteOfDayToTimeString(todaySunTimes.mSunset));
            trace_data("tomorrow Sunrise: " +tomorrowSunTimes.mSunrise + "(" +minuteOfDayToTimeString(tomorrowSunTimes.mSunrise));
            trace_data("tomorrow Sunset: " + tomorrowSunTimes.mSunset+ "(" +minuteOfDayToTimeString(tomorrowSunTimes.mSunset) );
          }
        }
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
        var startangle_in_radians = (180- startmin * 6 ) * DEG2RAD;
        var endangle_in_radians = (180- endmin * 6 )  * DEG2RAD;
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
        var startx = xcenter + (50+ radius) * Math.sin(startangle_in_radians);
        var starty = ycenter + (50+ radius) * Math.cos(startangle_in_radians);
        var   endx = xcenter + (50+ radius) * Math.sin(  endangle_in_radians);
        var   endy = ycenter + (50+ radius) * Math.cos(  endangle_in_radians);
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

    function drawInnerCircle(dc) {
          // Draw the inner circle
        var xcenter = screen_width/2;
        var ycenter = screen_height/2;
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_BLACK);
        dc.fillCircle(xcenter, ycenter, 7);
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        dc.drawCircle(xcenter, ycenter, 7 );
    }


    function getDateString(clockTime, now, calendar_info) {
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
            dateStr = Lang.format("$1$$2$", [calendar_info.day_of_week.substring(0,3), calendar_info.day]);
        }
        return dateStr;
    }
    // ============================================================
    // Draw the battery arc
    function drawBatteryArc(dc) {
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

    }

    // ============================================================
    //! get the moon phase
    function getMoonphase(clockTime,now) {
        if (demo_mode) {
          return 5;
        }
        var lp = 2551443;
        //options = { :second => 0, :hour => 20, :minute => 35, :year => 1970, :month => 1, :day => 7};
        var options = { :second => 0, :hour => 20, :minute => 44, :year => 2016, :month => 8, :day => 2};
        var new_moon = Calendar.moment(options);
        var phase = (now.value() - new_moon.value()) % lp;
        //moontest = moontest+40000;
        //var phase = (moontest - new_moon.value()) % lp;
        var moonage = (phase.toFloat() / 2551443) *28;  // ratio of 28 phases
        var moonphase = moonage.toNumber(); // round down
        if (trace) { trace_data("New moon " + new_moon.value() + " Now " +  now.value() + " phase " + phase + " moonage " + moonage + " moonphase " + moonphase) ; }
        return moonphase;
    }

    // ============================================================
    function drawDateAndNumerals(dc,clockTime,now,hour,calendar_info) {
        // Get date string
        var dateStr = getDateString(clockTime,now,calendar_info);
        // ============================================================
        // Adjust the date position?
        var switch_date = false;
        if (SMART_DATE == true) {
          if  ((hour >  160  && hour < 200) ||
               (clockTime.min > 13 && clockTime.min < 17))
          {
              switch_date = true;
          }
        }

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var inset = 45;
        if (screen_type == SCREEN_SEMI_ROUND) {
          inset = 42;
          font =  Gfx.FONT_LARGE;
        }

        if (MOONPHASE_LOCATION == MOONPHASE_AT_6) {
            NUMBER_SIX = PHASES[getMoonphase(clockTime,now)];
            NUMBER_FONT = moonfont;
        }
        else
        {
            NUMBER_FONT = font;
            NUMBER_SIX = "6";
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(screen_width/2,screen_height-inset,NUMBER_FONT,NUMBER_SIX, Gfx.TEXT_JUSTIFY_CENTER);

        // ============================================================
        // Draw the date and 3 or 9 numerals
        var date_pos = 0;
        var dimensions =  dc.getTextDimensions(dateStr,Gfx.FONT_SMALL);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        inset = 16;
        if (screen_type == SCREEN_SEMI_ROUND) {
          inset = 32;
          font =  Gfx.FONT_LARGE;
        }
        if (MOONPHASE_LOCATION == MOONPHASE_AT_9) {
            NUMBER_NINE = PHASES[getMoonphase(clockTime,now)];
            NUMBER_THREE = NUMBER_NINE;
            NUMBER_FONT = moonfont;
        }
        else
        {
            NUMBER_FONT = font;
            NUMBER_NINE = "9";
            NUMBER_THREE = "3";
        }
        if (switch_date)
        {
            date_pos = inset;
            dc.drawText(screen_width-(inset),-15+screen_height/2,NUMBER_FONT, NUMBER_THREE, Gfx.TEXT_JUSTIFY_RIGHT);
        }
        else
        {
            date_pos = screen_width-(inset+2)-dimensions[0];
            dc.drawText((inset),-15+screen_height/2,NUMBER_FONT,NUMBER_NINE,Gfx.TEXT_JUSTIFY_LEFT);
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

    }
    // ============================================================
    //! Handle the update event
    // ============================================================
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
        var now = Time.now();
        var minute_of_day_12_hour_clock =( ( ( clockTime.hour % 12 ) * 60 ) + clockTime.min );  // 12 hour time in minutes
        var minute_of_day =( ( ( clockTime.hour ) * 60 ) + clockTime.min );  // 24 hour time in minutes
        var activityInfo;

        if (updateSettings) {
          RetrieveSettings();
          updateSettings = false;
        }
        else
        if ( PREVIOUS_MINUTE_OF_DAY == minute_of_day &&
             highPowerMode == false &&
             firstUpdateAfterSleep == false)
        {
          return;  // Don't update > once a minute
        }

        activityInfo = Act.getInfo();
        //prevent divide by 0 if stepGoal is 0
        if( activityInfo != null && activityInfo.stepGoal == 0 )
        {
            activityInfo.stepGoal = 5000;
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
            if (demo_mode) {
               progress =.45;
            }
            if (progress > 1)
            {
                progress = 1;
            }
//            else {
            drawSegment(dc, 30, 30-15*progress, Gfx.COLOR_BLUE );
 //           }

           // 12 hour mode - hide icons
            if (SHOW_ICONS == false)
            {
              feetcolour = Gfx.COLOR_BLACK;
            }
            // else determine icon colour as long as we are not updating every second
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
        drawBatteryArc(dc);

        // ============================================================
        // Draw the background
        dc.drawBitmap(0,0,background_icons);

        // ============================================================
        // Draw the Sleep icon

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
        // Draw the numbers and mooon phase
        drawTwelve(dc);
        var calendar_info = Calendar.info(now, Time.FORMAT_MEDIUM);
        drawDateAndNumerals(dc,clockTime,now,minute_of_day_12_hour_clock, calendar_info );

        calculateSunEvents(clockTime,calendar_info);
        drawSunHand(dc,minute_of_day);

        // ============================================================
        // Draw the UTC hour hand.
        if (SHOW_UTC_HAND ) {
            var UTC_hour = 0;
            if ( UTC_HAND_OFFSET == 0 ) {
                UTC_hour = hour - (clockTime.timeZoneOffset / 60) ;
            }
            else {
                if (trace) { trace_data("minute_of_day " + minute_of_day  + " UTC Offset " +  UTC_HAND_OFFSET) ; }
                UTC_hour = minute_of_day_12_hour_clock + UTC_HAND_OFFSET ;
            }
            //UTC_hour = UTC_hour / (12 * 60.0);
            drawUTCHand(dc, minutes_to_rads(UTC_hour /12));
        }

        // Draw the hour hand. Convert time to clock minutes and compute the angle.
        drawHourHand(dc, minutes_to_rads(minute_of_day_12_hour_clock / 12));

        // ============================================================
        // Draw the minute hand
        drawMinuteHand(dc, minutes_to_rads( clockTime.min ), !highPowerMode);

        // ============================================================
        // Draw the second hand
        if (highPowerMode == true)
        {
          //var sec  =  ;
          drawSecondHand(dc, clockTime.sec);
        }

      // ============================================================
      // Draw the inner circle
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        dc.fillCircle(xcenter, ycenter, 2 );

      PREVIOUS_MINUTE_OF_DAY = minute_of_day;
      if (trace) { trace_exit("onUpdate"); }
    }

    // Draw move bar
    function drawMoveBar(dc,activityInfo) {
        if (demo_mode && activityInfo != null)
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
        System.println( "< " + method + "() - UsedMemory: " + System.getSystemStats().usedMemory);
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
