/**
* Custom class to handling RedmineAir Error event.
*/
package com.appspot.redmineAir.util {
	import flash.events.Event;

	public class RedmineAirErrorEvent extends Event {
	    public static const LOG_ERROR:String = "log_error";
		public static const HTTP_ERROR:String = "http_error";

		public var errorMessage:String;
		public function RedmineAirErrorEvent(type:String, message:String):void {
			super(type, true);
			errorMessage = message;
		}
	}
}