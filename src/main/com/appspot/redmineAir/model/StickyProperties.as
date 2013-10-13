/**
 * @author y.kokubo
 */
package com.appspot.redmineAir.model {
	import flash.text.*;
	import flash.display.*;
	import flash.geom.*;
	import mx.controls.TextArea;
	import com.appspot.redmineAir.view.StickyWindow;

	/**
	 * Stickyのプロパティをローカル保存するためのクラスです。
	 */
	public class StickyProperties {
		// NativeWindow
		public var bounds:Rectangle;
		public var alwaysInFront:Boolean;
		public var width:int;
		public var height:int;
		
		// TextField
		public var alpha:Number;
		public var textColor:String;
		public var backgroundColor:String;		

		public function StickyProperties() 
		{
		}

		/**
		 * このメソッドは引数のオブジェクトに対して副作用を起こすので注意
		 */
		public function setup(window:StickyWindow):void 
		{
			if (this.bounds != null) window.stage.nativeWindow.bounds = this.bounds;
			window.alwaysInFront = this.alwaysInFront;
			window.panel.alpha = this.alpha;
			window.textColor = this.textColor;
			window.panel.setStyle("backgroundColor", this.backgroundColor);
			window.height = this.height;
			window.width = this.width;
		}

		public function teardown(window:StickyWindow):void 
		{
			bounds = window.stage.nativeWindow.bounds;
			alwaysInFront = window.alwaysInFront;
			alpha = window.panel.alpha;
			textColor = window.textColor;
			backgroundColor = window.panel.getStyle("backgroundColor");
			height = window.height;
			width = window.width;
		}
	}
}
