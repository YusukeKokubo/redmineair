package com.appspot.redmineAir.util
{
	import flash.errors.IllegalOperationError;
	import flash.net.URLRequest;

	/**
	 * URL関連のユーティリティクラス
	 */
	public final class URLUtils
	{
		/** チケット詳細画面へのURL */
		public static const ISSUES_URL:String = "/issues/";
		private static var pattern:RegExp = /\/$/gi;
		private static var urlPattern:RegExp =  /(http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;
		
		
		/** インスタンス化禁止 */
		[Deprecated]
		public function URLUtils()
		{
			throw new IllegalOperationError("Cannot creatre instance...");
		}
		
		/**
		 * 遷移対象のチケット詳細のURLを持つURLRequestを返す
		 * *** このメソッドは、事前にApplicationData.applicationConfigにURLが設定されている事が前提となる
		 *     設定が行われていない場合にはErrorを返す ***
		 * @param issuesId 対象のチケットID
		 * @return 遷移先URLを保持したURLRequest
		 */
		public static function createIssuesURL(url:String, issuesId:String):URLRequest
		{
			if (url == null)
			{
				throw new ArgumentError("ApplicationConfig::URL is null.");
			}
			if (issuesId == null)
			{
				throw new ArgumentError("issuesId is null.");
			}
			url = correctURL(url);
			url = url.concat(ISSUES_URL, issuesId);
			return new URLRequest(url);
		}
		
		/**
		 * @param ユーザから入力されたURL
		 * @return Boolean (URLとして正しいかどうかを返す）
		 */
		public static function validate(url:String):Boolean 
		{
			return urlPattern.test(url); 
		}
		
		/**
		 * Railsの規則により、"//"が許容されないので、URLを調整するための関数
		 * Ref. IssueID 423, 457, 517
		 * @param ユーザから入力されたURL
		 * @return 末尾の"/"を取り除いたURL
		 */
		public static function correctURL(url:String):String
		{
			var retval:String = "";
			try {
				retval = url.replace(pattern, "");
			} catch (e:Error) {
				retval = "";	
			}
			return retval;		
		}		
	}
}