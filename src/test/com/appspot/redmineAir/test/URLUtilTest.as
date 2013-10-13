package com.appspot.redmineAir.test
{
	import com.appspot.redmineAir.util.URLUtils;
	
	import flash.net.URLRequest;
	
	import flexunit.framework.Assert;
	
	public class URLUtilTest
	{		
		[Before]
		public function setUp():void
		{
		}
		
		[After]
		public function tearDown():void
		{
		}
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		[Test]
		public function testCorrectURL():void
		{
			var url:String = "http://www.r-labs.org/";
			var result:String = URLUtils.correctURL(url);
			Assert.assertEquals("Expecting url is -  http://www.r-labs.org",  "http://www.r-labs.org", result);
		}
		
		
		[Test]
		public function testCreateIssuesURL():void
		{
			var url:String = "http://www.r-labs.org/";
			var id:String = "5";
			var result:String = (URLUtils.createIssuesURL(url, id) as URLRequest).url;
			Assert.assertEquals("Expecting URL is - http://www.r-labs.org/issues/5", 
				"http://www.r-labs.org/issues/5", result);
		}
		
		
		[Test]
		public function testValidate():void
		{
			Assert.assertEquals("Expecting boolean is - false", false, URLUtils.validate("httpd://www.r-labs.org/"));
			if (URLUtils.validate("httpd://www.r-labs.org/")) {
				Assert.fail("Expecting boolean is - false.");
			}
			
		}
	}
}