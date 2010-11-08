/**
* Custom class to handling RedmineAir event.
*/
package com.appspot.redmineAir.util {
	import flash.events.Event;

	public class RedmineEvent extends Event {
	    public static const ADD:String = "add";
	    public static const EDIT:String = "edit";

		public var redmineXML:XML;
		public function RedmineEvent(type:String, xml:XML):void {
			super(type, true);
			redmineXML = xml;
		}
	}
}