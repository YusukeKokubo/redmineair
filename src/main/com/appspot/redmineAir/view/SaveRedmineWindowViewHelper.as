/**
 * 
 * @author akiko
 * 
 */
package com.appspot.redmineAir.view 
{
	
	import com.appspot.redmineAir.util.RedmineEvent;
	import com.appspot.redmineAir.util.URLUtils;
	import com.appspot.redmineAir.view.PopUpWindowViewHelper;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	
	import flex.viewhelper.AbstractViewHelper;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	import mx.managers.PopUpManager;
		
	public class SaveRedmineWindowViewHelper extends PopUpWindowViewHelper
	{
		private var view:SaveRedmineWindow;
		// XML as model
		private var _redmineXML:XML = <redmine/>;		
		private static const log:ILogger = Log.getLogger("main");
		
		override public function initialize(event:FlexEvent):void
		{
			super.initialize(event);			
			view = document as SaveRedmineWindow;
			openPopUp(view);
		}
		
		public function set redmineXML(xml:XML):void {	
			_redmineXML = xml;
			if (_redmineXML.@id != null && parseInt(_redmineXML.@id) > 0) {
				view.title = "Edit Redmine : " + _redmineXML.@id;
			} else {
				view.title = "Add Redmine";					
			}	
			view.txtUrl.text = _redmineXML.@url;
			view.txtName.text = _redmineXML.@name;
			view.txtKey.text = _redmineXML.@key;
			view.txtFeedKey.text = _redmineXML.@feedkey;
			view.txtNote.text = _redmineXML.@note;				
		}		
		
		public function btnSaveOnClickHandler(event:MouseEvent):void
		{
			_redmineXML.@name = parseValue(view.txtName.text);
			_redmineXML.@url = parseValue(view.txtUrl.text);
			_redmineXML.@key = parseValue(view.txtKey.text);
			_redmineXML.@feedkey = parseValue(view.txtFeedKey.text);
			_redmineXML.@note = parseValue(view.txtNote.text);
			
			// validation check
			if (!URLUtils.validate(_redmineXML.@url)) {
				Alert.show("Please enter validate URL.");
				return;
			}
			
			if (view.title == "Add Redmine") {
				view.dispatchEvent(new RedmineEvent(RedmineEvent.ADD,_redmineXML));
			}
			if (_redmineXML.@id != null && parseInt(_redmineXML.@id) > -1) {
				view.dispatchEvent(new RedmineEvent(RedmineEvent.EDIT,_redmineXML));       	    	
			}
		}
		
		public function btnCancelOnClickHandler(event:MouseEvent):void
		{
			super.closePopUp(view);
		}

		public function OnCreationCompleteHandler(event:FlexEvent):void
		{
			view.addEventListener(CloseEvent.CLOSE, function():void {
				closePopUp(view);		
			});	
		}
		
		private function parseValue(s:String):String
		{
			if (s == null || s.length == 0)
				return "";
			return s;
		}
	}
}