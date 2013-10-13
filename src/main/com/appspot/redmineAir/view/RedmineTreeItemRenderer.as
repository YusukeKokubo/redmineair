package com.appspot.redmineAir.view
{
	// itemRenderers/tree/myComponents/MyTreeItemRenderer.as
	import mx.collections.*;
	import mx.controls.treeClasses.*;
	
	public class RedmineTreeItemRenderer extends TreeItemRenderer
	{
		
		// Define the constructor.      
		public function RedmineTreeItemRenderer() {
			super();
		}
		
		// Override the set method for the data property
		// to set the font color and style of each node.        
		override public function set data(value:Object):void {
			super.data = value;
			var itemXML:XML = TreeListData(super.listData).item as XML;

			if(itemXML.@hasError == 1)
			{
				setStyle("color", 0xa33936);
				setStyle("fontStyle", 'normal');
			}
			else
			{
				setStyle("color", 0x000000);
				setStyle("fontWeight", 'normal');
			}  
		}
		
		// Override the updateDisplayList() method 
		// to set the text for each tree node.      
		override protected function updateDisplayList(unscaledWidth:Number, 
													  unscaledHeight:Number):void 
		{
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if(super.data)
			{
				if(TreeListData(super.listData).hasChildren)
				{
					var tmp:XMLList = 
						new XMLList(TreeListData(super.listData).item);
					var myStr:int = tmp[0].children().length();
					super.label.text =  TreeListData(super.listData).label + 
						"(" + myStr + ")";
				} else {
					var xml:XML = super.data as XML;
					if(xml.@hasError == 1) {
						setStyle("color", 0xa33936);
						setStyle("fontStyle", 'italic');
						super.label.text = TreeListData(super.listData).label + " (Error)";
						super.label.toolTip = "Error reading URL.....Please check log info.";
					} else {
						setStyle("color", 0x000000);
						setStyle("fontWeight", 'normal');
						setStyle("fontStyle", 'normal');
						super.label.toolTip = xml.@name + ":\n" + xml.@note;
					}
				}
			}
		}
	}
}

