package com.appspot.redmineAir.model {

    import com.appspot.redmineAir.util.URLUtils;
    import com.appspot.redmineAir.view.StickyWindow;
	import com.appspot.redmineAir.util.RedmineAirErrorEvent;
    
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.net.*;
    import flash.system.*;
    import flash.text.*;
    import flash.ui.*;
    
    import mx.controls.*;
    import mx.events.*;
    import mx.managers.PopUpManager;
    import mx.rpc.events.ResultEvent;
    import mx.rpc.http.HTTPService;
	import mx.rpc.events.FaultEvent;
	import mx.utils.ObjectUtil;

    [RemoteClass]
    public class Sticky {

        // 付箋ウィンドウ (public指定だけれど、データ保存時にObjectとしては書き出さない)
        [Transient]
        public var window:StickyWindow;

        private var initilized:Boolean = false;
        private var httpService:HTTPService = new HTTPService();
		private var ra:Namespace = new Namespace("http://com.appspot.redmineAir/redmineAir")
		
        private var menu:ContextMenu = new ContextMenu();
        private var menuToRedmine:ContextMenuItem	= new ContextMenuItem("to Redmine");
        private var menuReload:ContextMenuItem	    = new ContextMenuItem("reload");
        private var menuKeepFront:ContextMenuItem	= new ContextMenuItem("always in front");
        private var menuClose:ContextMenuItem		= new ContextMenuItem("close");

        // 透明度用のメニュー
        private var menuTransparency:ContextMenuItem = new ContextMenuItem("Transparency");
        private var menuTransparencySubMenu:ContextMenu = new ContextMenu();
        private var alpha0:ContextMenuItem	= new ContextMenuItem("0%");
        private var alpha30:ContextMenuItem	= new ContextMenuItem("30%");
        private var alpha60:ContextMenuItem	= new ContextMenuItem("60%");
        private var alpha80:ContextMenuItem	= new ContextMenuItem("80%");

        // 背景色設定用のメニュー
        private var menuBackColor:ContextMenuItem = new ContextMenuItem("Background Color");
        private var menuBackColorSubMenu:ContextMenu = new ContextMenu();
        private var bNormal:ContextMenuItem	= new ContextMenuItem("normal");
        private var bRed:ContextMenuItem	= new ContextMenuItem("red");
        private var bBrue:ContextMenuItem	= new ContextMenuItem("brue");
        private var bYellow:ContextMenuItem	= new ContextMenuItem("yellow");
        private var bGreen:ContextMenuItem	= new ContextMenuItem("green");
        private var bWhite:ContextMenuItem	= new ContextMenuItem("white");
        private var bBlack:ContextMenuItem	= new ContextMenuItem("black");
        private var bGlay:ContextMenuItem	= new ContextMenuItem("glay");

        // 文字色設定用のメニュー
        private var menucolor:ContextMenuItem = new ContextMenuItem("Text Color");
        private var menucolorSubMenu:ContextMenu = new ContextMenu();
        private var tRed:ContextMenuItem	= new ContextMenuItem("red");
        private var tBrue:ContextMenuItem	= new ContextMenuItem("brue");
        private var tYellow:ContextMenuItem	= new ContextMenuItem("yellow");
        private var tGreen:ContextMenuItem	= new ContextMenuItem("green");
        private var tWhite:ContextMenuItem	= new ContextMenuItem("white");
        private var tBlack:ContextMenuItem	= new ContextMenuItem("black");
        private var tGlay:ContextMenuItem	= new ContextMenuItem("glay");

        public var uri:String;
        public var key:String;
        public var issue:XML;
        //public var prop:StickyProperties;
        public var isShowXml:Boolean = false;
		public var updatedOn:Date = null;
		public var lastAccessed:Date = null;

        public static const HIDE_STICKY:String = "hideStickyEvt";
        public static const SHOW_STICKY:String = "showStickyEvt";

        // 付箋ウィンドウを生成
        public function Sticky(uri:String="", key:String="", issue:XML = null):void {
            this.uri = uri;
            this.key = key;
            this.issue = issue;
            window = new StickyWindow();
            // openしてからでないと、子オブジェクトが生成されません。順番に注意。
            window.open();

            window.panel.setStyle("backgroundColor",0xFFFF99);
            window.btnFormat.addEventListener(MouseEvent.MOUSE_DOWN,changeFormat);

            window.contextMenu = makeMenu();			

			// 付箋情報更新
			httpService.useProxy = false;
			httpService.resultFormat = "e4x";
			httpService.showBusyCursor = true;
			httpService.addEventListener(ResultEvent.RESULT, reload);
			httpService.addEventListener(FaultEvent.FAULT, ioErrorHandler);			
			
        } // end of function Sticky

        private function makeMenu():ContextMenu {
            menuToRedmine.addEventListener(Event.SELECT,
                function():void {
                    navigateToURL(new URLRequest(uri));
                });
            menuReload.addEventListener(Event.SELECT,
                function():void {
                    httpService.url = uri + ".xml?key=" + key;
                    httpService.send();
                });
            menuKeepFront.addEventListener(Event.SELECT,
                function selectAlwaysInFront(e:Event):void {
                    e.target.checked = !e.target.checked;
                    window.alwaysInFront = e.target.checked;
                });
            menuClose.addEventListener(Event.SELECT,
                function():void {
                    window.close();
                });

            menuTransparencySubMenu.customItems = [alpha0, alpha30, alpha60, alpha80];
            menuTransparency.submenu = menuTransparencySubMenu;

            // 透明度の指定
            alpha0.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.alpha = 1.0;
                });
            alpha30.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.alpha = 0.7;
                });
            alpha60.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.alpha = 0.4;
                });
            alpha80.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.alpha = 0.2;
                });

            menuBackColorSubMenu.customItems = [bNormal, bRed, bBrue, bYellow, bGreen, bWhite, bBlack, bGlay];
            menuBackColor.submenu = menuBackColorSubMenu;

            bNormal.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.setStyle("backgroundColor","0xE6E082");
                });
            bRed.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.setStyle("backgroundColor","0xff3300");
                });
            bBrue.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.setStyle("backgroundColor","0x0066ff");
                });
            bYellow.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.setStyle("backgroundColor","0xffff00");
                });
            bGreen.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.setStyle("backgroundColor","0x00cc00");
                });
            bWhite.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.setStyle("backgroundColor","0xffffff");
                });
            bBlack.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.setStyle("backgroundColor","0x000000");
                });
            bGlay.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.panel.setStyle("backgroundColor","0xc0c0c0");
                });

            menucolorSubMenu.customItems = [tRed, tBrue, tYellow, tGreen, tWhite, tBlack, tGlay];
            menucolor.submenu = menucolorSubMenu;

            tRed.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.textColor = "0xff3300";
                });
            tBrue.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.textColor = "0x0066ff";
                });
            tYellow.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.textColor = "0xffff00";
                });
            tGreen.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.textColor = "0x00cc00";
                });
            tWhite.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.textColor = "0xffffff";
                });
            tBlack.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.textColor = "0x000000";
                });
            tGlay.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
                function(e:Event):void {
                    window.textColor = "0xc0c0c0";
                });

            menu.customItems.push(menuToRedmine, menuReload, menuKeepFront, menuBackColor, menucolor, menuTransparency, menuClose);
            return menu;
        }
        /**
         * 現在の表示情報を切り替える
         * @param visibled 表示される場合にtrue
         */
        public function windowVisible(visibled:Boolean):void
        {
            this.window.visible = visibled;
        }

        private function init():void {
            /*if (prop != null) {
                prop.setup(window);
            } else {
                prop = new StickyProperties();
            }
			*/
            showText();
            menuKeepFront.checked = window.alwaysInFront;
            initilized = true;
        }

        private function showText(event:Event = null):void 
        {
            window.lbIssueTitle.text = issue.id +  " : " + issue.subject;
            if (!isBlank(issue.due_date))	
                window.iconDueDate.toolTip = "DueDate : " + issue.due_date;

            // Issue Header (ヘッダ情報)は編集できないようにする
            window.txtIssueHeader.text = 
                "Project : " + issue.project.@name + "\n" +
                "Subject : " + issue.subject + "\n" +
				"RedmineId : " +  issue.ra::redmineId + "\n" +
                "DueDate : " + issue.due_date + "\n";
            window.txtIssueHeader.selectable = false;		
            window.txtIssueBody.selectable = false;
            window.txtIssueBody.text = issue.description;
        }

        private function changeFormat(event:Event = null):void 
        {
            if (window.btnFormat.getStyle("icon") == com.appspot.redmineAir.util.IconSet.xmlIcon) {
                window.txtIssueBody.selectable = true;
                window.txtIssueBody.text = issue.toString();
                window.btnFormat.setStyle("icon", com.appspot.redmineAir.util.IconSet.textIcon);
                window.btnFormat.toolTip = "Show Text";
            } else {
                window.txtIssueBody.selectable = false;
                window.txtIssueBody.text =
                    issue.description;
                window.btnFormat.setStyle("icon", com.appspot.redmineAir.util.IconSet.xmlIcon);
                window.btnFormat.toolTip = "Show XML";					
            }
        }

        private function reload(event:ResultEvent):void 
        {
			lastAccessed = new Date();
			var updatedIssue:XML = event.result as XML;
			updatedIssue.ra::redmineId = issue.ra::redmineId;
			updatedIssue.ra::lastAccessed = lastAccessed.toString();
			issue = updatedIssue;
            showText();
        }

        public function show():void 
        {
            if (!initilized) init();
            window.visible = true;
        }

        public function activate():void 
        {
            show();
            window.activate();
        }

        public function close():void 
        {
            window.close();
        }

        public function get issueId():String 
        {
            return issue.id;
        }

        public function get closed():Boolean 
        {
            return window.closed;
        }

        public function setPerment():void 
        {
            //prop.teardown(window);
			this.updatedOn = new Date();
        }

        //yyyy-mm-dd形式をDate型にする
        private function getDateByDate(strDate:String):Date 
        {
            var datDate:Date = null;
            try {
                var arrayDate:Array = strDate.split("-");
                var y:int = parseInt(arrayDate[0]);
                var m:int = parseInt(arrayDate[1]) - 1;
                var d:int = parseInt(arrayDate[2]);
                datDate = new Date(y, m, d);
            } catch (error:Error) {
                // do nothing;
            }
            return datDate;
        }

        private function isBlank(s:String):Boolean 
        {
            if (s == null)
                return true;
            if (s == '')
                return true;
            return false;	
        }
		
		private function ioErrorHandler(event:FaultEvent):void
		{
			Alert.show(ObjectUtil.toString(event.fault),"Error");
			window.dispatchEvent((new RedmineAirErrorEvent(RedmineAirErrorEvent.HTTP_ERROR,event.message.toString())));			
		}		

    } // end of class Sticky		
}
// end of package

