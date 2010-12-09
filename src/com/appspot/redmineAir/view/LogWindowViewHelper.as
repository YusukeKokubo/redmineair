/**
 * 
 * @author akiko
 * 
 */
package com.appspot.redmineAir.view 
{
	
	import com.appspot.redmineAir.util.RedmineEvent;
	import com.appspot.redmineAir.util.RedmineAirErrorEvent;
	import com.appspot.redmineAir.util.URLUtils;
	import com.appspot.redmineAir.view.PopUpWindowViewHelper;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.filesystem.*;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;	
	
	public class LogWindowViewHelper extends PopUpWindowViewHelper
	{
		private var view:LogWindow;
		// XML as model
		private var _logFile:File;

		override public function initialize(event:FlexEvent):void
		{
			super.initialize(event);			
			view = document as LogWindow;
			super.openPopUp(view);
		}
		
		public function set logFile(logFile:File):void 
		{	
			_logFile = logFile;
			if(_logFile.exists) {    
				_logFile.load();
				_logFile.addEventListener(Event.COMPLETE,fileLoadCompleteHandler);
				view.addEventListener(MouseEvent.CLICK, showFileChooser);
			}
		}
		
		private function fileLoadCompleteHandler(event:Event):void
		{
			view.lbLogFile.label = _logFile.nativePath;
			view.txtlogContent.text = String(event.currentTarget.data);
		}
		
		public function OnCreationCompleteHandler(event:FlexEvent):void
		{
			view.addEventListener(CloseEvent.CLOSE, function(e:Event):void {
				closePopUp(view);
			});	
		}
		
		private function showFileChooser(event:Event):void 
		{
			if (!_logFile) return;
			
			try {
				_logFile.parent.browseForOpen("Open log file.");
			} catch (e:Error) {
				// throw custom event (Asks for parent to make alert & logging.)
				view.dispatchEvent(new RedmineAirErrorEvent(RedmineAirErrorEvent.LOG_ERROR,e.message)); 
			}
		}
		
	}
}