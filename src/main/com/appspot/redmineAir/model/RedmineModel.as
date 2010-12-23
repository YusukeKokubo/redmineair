package com.appspot.redmineAir.model
{
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
		
	public class RedmineModel extends EventDispatcher
	{
		public var:issueXML:XML;
		public var:projectXML:XML;
		public var:activityXML:XML;
		
		private var _configXML:XML;
		
		public function RedmineModel(config:XML)
		{
			_config = config;
		}
		
		// send request for issues.
		public function getIssue():void
		{
			
		}
		
		// send request for projects.
		public function getProject():void
		{
			
		}

		// send request for activities
		public function getActivity():void
		{
			
		}		
	}
}