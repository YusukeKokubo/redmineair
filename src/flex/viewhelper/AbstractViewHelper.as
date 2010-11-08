/**
 *  The MIT License
 *
 *  @author      Copyright (c) 2008 Shigenobu Kondo ( nobu@FxUG )
 *  @version     1.0.0
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 * 
 */
package flex.viewhelper
{
    import flash.utils.describeType;

	import mx.core.IMXMLObject;
	import mx.events.FlexEvent;
	import mx.states.State;
	import flash.events.Event;
	import mx.collections.ArrayCollection;
	import mx.managers.SystemManager;
	import flash.events.IEventDispatcher;


	public class AbstractViewHelper implements IMXMLObject
	{
        private static var HANDLER:String = "Handler";
        private static var ON:String = "On";

		protected var document:Object;
		
        private var describeTypeXmlforView:XML;		// View(MXML)の構成情報
       	private var describeTypeXmlforLogic:XML;		// Logic(AS)の構成情報
		private var compoNameXMLList:XMLList;			// View(MXML)のから取得したdocument上に配置されているコンポーネントのリスト

		protected var registComponentCache:ArrayCollection = new ArrayCollection();


		public function initialized(document:Object, id:String):void
		{
			this.document = document;
			
            describeTypeXmlforView = describeType(document);
       	    describeTypeXmlforLogic = describeType(this);

			// Viewに属するコンポーネントの一覧を取得(describeTypeXmlforView.@nameがポイント)
		    compoNameXMLList = describeTypeXmlforView.accessor.(@declaredBy == describeTypeXmlforView.@name).@name;

			// view.initializeはスーパークラスで登録する
            document.addEventListener(FlexEvent.INITIALIZE,initialize);
		}
		

		/**
		 * document.initializeイベントで、コンポーネントとイベントハンドラの関連付けを行う
		 * 
		 * ■イベントの順番
		 * 1.preinitialize
		 * 2.initialize
		 * 3.(addChild)
		 * 4.createCompete
		 * 5.application_complete
		 * 6.update_complete
		 * 7.InvokeEvent.INVOKE
		 * 
		 */
		public function initialize(event:FlexEvent):void
		{
			bindingAll();
			this.document.addEventListener(Event.ADDED,added);
		}
		
		/**
		 * document.addedイベント。State(等)を使用する場合、遅延読込を行う事があるため、
		 * addedイベントが発生したタイミングで追加コントロールの自動登録を行う。
		 * 
		 */
		public function added(e:Event):void
		{
			// Viewに属するコンポーネントのイベントハンドラを関連付け
			bindingChildren(this.document);
		}

		/**
		 * 関連付けの再実行
		 * 
		 * 利用者側が明示的に関連付けをやり直したい場合に実行するメソッド
		 * 
		 */		
		public function rebinding():void
		{
			bindingAll();
		}
		

		/**
		 * イベントの関連付け一括実行
		 * 
		 * ・View自身のイベントハンドラ関連付け
		 * ・State(使用している場合)のイベントハンドラ関連付け
		 * ・コンポーネントのイベントハンドラ関連付け
		 */
		private function bindingAll():void
		{
			// キャッシュのクリア
			registComponentCache.removeAll();
			
			// View自身のイベントハンドラを関連付け
			bindingViewSelf(this.document);

			// Statesのイベントハンドラを関連付け
			bindingStates(this.document);

			// Viewに属するコンポーネントのイベントハンドラを関連付け
			bindingChildren(this.document);
		}
		

		/**
		 * View自身のイベントハンドラ自動登録
		 * 
		 * 
		 * @document ･･･ Viewオブジェクト
		 */		
		private function bindingViewSelf(document:Object):void
		{
			var componentName:String = "";

			// Logicクラス内に対象コンポに対するイベントハンドラのリストを取得
			// ■命名規約
			//     On ＋ <イベント名> ＋ Handler
			//
		    var methodNameXMLList:XMLList = describeTypeXmlforLogic.method.(String(@name).substr(0,String(componentName+ON).length) == String(componentName+ON)).@name;
		    
		    // 取得したイベントハンドラの分だけ関連付けを行う
			for each(var methodName:String in methodNameXMLList)
			{
				var eventName:String = createEventName(methodName);

				if (eventName != "") 
				{
					document.removeEventListener(eventName,this[methodName]);
					document.addEventListener(eventName,this[methodName]);
				}
			}			    
		}


		/**
		 * Statesのイベントハンドラ自動登録
		 * 
		 * Stateクラスは登録のされかたが特殊な為、個別に実装する。
		 * 
		 * @document ･･･ Viewオブジェクト
		 */		
		private function bindingStates(document:Object):void
		{
			for each (var state:Object in document.states)
			{
				var componentName:String = State(state).name;
				
				// キャッシュ済みコンポーネントの場合は処理を迂回
				if (registComponentCache.getItemIndex(componentName) >= 0) 
				{
					continue;
				}
				
				// コンポーネントをキャッシュ
				registComponentCache.addItem(componentName);

				// Logicクラス内に対象コンポに対するイベントハンドラのリストを取得
				// ■命名規約
				//     <Stete名> ＋ On ＋ <イベント名> ＋ Handler
				//
			    var methodNameXMLList:XMLList = describeTypeXmlforLogic.method.(String(@name).substr(0,String(componentName+ON).length) == String(componentName+ON)).@name;
		    
			    // 取得したイベントハンドラの分だけ関連付けを行う
				for each(var methodName:String in methodNameXMLList)
				{
					var eventName:String = createEventName(methodName);

					if (eventName != "")
					{
						State(state).removeEventListener(eventName,this[methodName]);
						State(state).addEventListener(eventName,this[methodName]);
					}
				}			    
			}
		}


		/**
		 * コンポーネントのイベントハンドラ自動登録
		 * 
		 * @document ･･･ Viewオブジェクト
		 */		
		private function bindingChildren(docment:Object):void
		{
			for each (var componentName:String in compoNameXMLList)
			{
				// キャッシュ済みコンポーネントの場合は処理を迂回
				if (registComponentCache.getItemIndex(componentName) >= 0) 
				{
					continue;
				}
				
				// コンポーネントをキャッシュ
				// State等を使用してインスタンス化が遅延している場合を想定し、nullの場合はキャッシュしない
				if (document.hasOwnProperty(componentName) && document[componentName] != null)
				{
					registComponentCache.addItem(componentName);
				}
				else 
				{
					continue;
				}

				// Logicクラス内に対象コンポに対するイベントハンドラのリストを取得
				// ■命名規約
				//     <コンポーネント名> ＋ On ＋ <イベント名> ＋ Handler
				//
			    var methodNameXMLList:XMLList = describeTypeXmlforLogic.method.(String(@name).substr(0,String(componentName+ON).length) == String(componentName+ON)).@name;
			    
			    // 取得したイベントハンドラの分だけ関連付けを行う
				for each(var methodName:String in methodNameXMLList)
				{
					var eventName:String = createEventName(methodName);

					if (eventName != "")
					{
						IEventDispatcher(document[componentName]).removeEventListener(eventName,this[methodName]);
						IEventDispatcher(document[componentName]).addEventListener(eventName,this[methodName]);
					}
				}			    
			}
		} 
		

		/**
		 * イベントハンドラからイベント名を抽出する
		 * 
		 * @methodName ･･･ イベントハンドラ名
		 * 
		 */
		private function createEventName(methodName:String):String
		{
			var idx:int;
			var eventName:String = "";

			eventName = methodName.toString();
					
			idx = eventName.indexOf(HANDLER);
			eventName = eventName.substring(0,idx);
			idx = eventName.indexOf(ON);
			eventName = eventName.substring(idx+ON.length,eventName.length);
			eventName = String(eventName.charAt(0)).toLowerCase() + eventName.substring(1,eventName.length);
			
			return eventName;   // キャッシュに登録済みのイベントハンドラの場合、イベント名を空白で戻し、その後のaddListenerEventを迂回する
		}
	}
}