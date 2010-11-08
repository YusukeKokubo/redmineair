package com.appspot.redmineAir.view
{
	import mx.collections.ItemResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.mxml.RemoteObject;

	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	import mx.managers.PopUpManager;
	import mx.core.IFlexDisplayObject;
	
	import flex.viewhelper.AbstractViewHelper;	
	
	public class PopUpWindowViewHelper extends AbstractViewHelper
	{
		private static const log:ILogger = Log.getLogger("main");
	
		public function openPopUp(view:IFlexDisplayObject): void
		{
			log.info(view.name + ": Open.");
		}

        public function closePopUp(view:IFlexDisplayObject): void
		{
			log.info(view.name + ": Close.");
			PopUpManager.removePopUp(view);
		}
	}
}