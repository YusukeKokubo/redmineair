/**
 * @author akiko
 */

// Class for Icon setting. (can invoke icons via static method.)
package com.appspot.redmineAir.util {
	public class IconSet 
	{
		public function IconSet() 
		{
		}

		[Bindable]
		[Embed(source="iconImages/information.png")] 
		public static var infoIcon:Class;

		[Bindable]
		[Embed(source="iconImages/exclamation.png")] 
		public static var warningIcon:Class; 

		[Bindable]
		[Embed(source="iconImages/error.png")] 
		public static var errorIcon:Class;

		[Bindable]
		[Embed(source='iconImages/star.png')]
		public static var watchIcon:Class;

		[Bindable]
		[Embed(source='iconImages/user.png')]
		public static var userIcon:Class;

		[Bindable]
		[Embed(source='iconImages/user_edit.png')]
		public static var userEditIcon:Class;

		[Bindable]
		[Embed(source='iconImages/save.png')]
		public static var saveIcon:Class;

		[Bindable]
		[Embed(source='iconImages/reload.png')]
		public static var reloadIcon:Class;

		[Bindable]
		[Embed(source='iconImages/jp.png')]
		public static var ja_JP_Icon:Class;

		[Bindable]
		[Embed(source='iconImages/us.png')]
		public static var en_US_Icon:Class;

		[Bindable]
		[Embed(source='iconImages/world_go.png')]
		public static var worldGoIcon:Class;

		[Bindable]
		[Embed(source='iconImages/calendar.png')]
		public static var calendarIcon:Class;

		[Bindable]
		[Embed(source='iconImages/grid_yellow.png')]
		public static var resizeIcon:Class;

		[Bindable]
		[Embed(source='iconImages/wrench.png')]
		public static var configIcon:Class;

		[Bindable]
		[Embed(source='iconImages/copy.png')]
		public static var copyIcon:Class;

		[Bindable]
		[Embed(source='iconImages/date.png')]
		public static var dateIcon:Class;

		[Bindable]
		[Embed(source='iconImages/xml.png')]
		public static var xmlIcon:Class;
		
		[Bindable]
		[Embed(source='iconImages/text.png')]
		public static var textIcon:Class;
		
		[Bindable]
		[Embed(source='iconImages/watch.png')]
		public static var stickyIcon:Class;

		// 期限区別用のアイコン
		[Bindable]
		[Embed(source='iconImages/pin_g.png')]
		public static var greenIcon:Class;		

		[Bindable]
		[Embed(source='iconImages/pin_r.png')]
		public static var redIcon:Class;		

		[Bindable]
		[Embed(source='iconImages/pin_y.png')]
		public static var yellowIcon:Class;

		[Bindable]
		[Embed(source='iconImages/pin_w.png')]
		public static var whiteIcon:Class;

		[Bindable]
		[Embed(source='iconImages/square_normal.png')]
		public static var normalIcon:Class;			
	}
}