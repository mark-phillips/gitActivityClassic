using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class ActivityClassicApp extends App.AppBase {

    var view = null;

    function onSettingsChanged() {
      if (view != null) {
        view.updateSettings = true;
        //Ui.requestUpdate();
      }
    }
    //! onStart() is called on application start up
    function onStart(state) {
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        view = new ActivityClassicView();
        return [ view ];
    }
    function initialize() {
        AppBase.initialize();
    }


}