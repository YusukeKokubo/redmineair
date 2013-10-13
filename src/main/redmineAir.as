// ActionScript files
import com.adobe.air.logging.FileTarget;
import com.appspot.redmineAir.model.Sticky;
import com.appspot.redmineAir.model.StickyProperties;
import com.appspot.redmineAir.util.FileIO;
import com.appspot.redmineAir.util.RedmineEvent;
import com.appspot.redmineAir.util.URLUtils;
import com.appspot.redmineAir.view.LogWindow;
import com.appspot.redmineAir.view.SaveRedmineWindow;
import com.appspot.redmineAir.util.RedmineAirErrorEvent;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.geom.Rectangle;
import flash.utils.*;

import mx.collections.ArrayList;
import mx.collections.XMLListCollection;
import mx.controls.Alert;
import mx.core.BitmapAsset;
import mx.events.CloseEvent;
import mx.logging.ILogger;
import mx.logging.Log;
import mx.logging.LogEventLevel;
import mx.managers.PopUpManager;
import mx.resources.ResourceManager;
import mx.rpc.AsyncToken;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;
import mx.utils.*;
import mx.utils.ObjectUtil;

private var initializeSucessed:Boolean = false;
private static var pattern:RegExp = /\/$/gi;
private static const log:ILogger = Log.getLogger("main");

static private const DB_FILE: String = "redmineAir.db";
private var conn: SQLConnection;
private var stmt:SQLStatement;
private var saveRedmineWindow:SaveRedmineWindow;
private var atom:Namespace = new Namespace("http://www.w3.org/2005/Atom");
private var ra:Namespace = new Namespace("http://com.appspot.redmineAir/redmineAir")
private var logFile:File;
private var stickies:Object = {};
//private var stickiesDir:File;

[Bindable]
private var issueXML:XML = <root/>;

[Bindable]
private var redmineXML:XML = <root/>;

[Bindable]
private var activityXML:XML = <root/>;

[Bindable]
private var projectXML:XML = <root><projects><project redmineId="" redmineName=""><name>All</name></project></projects></root>;

[Bindable]
private var targetProject:String;

private var bundleName:String = "messages";

[Embed(source="icons/icon_016.png")]
private static var icon016:Class;
[Embed(source="icons/icon_032.png")]
private static var icon032:Class;
[Embed(source="icons/icon_128.png")]
private static var icon128:Class;

private var menuChangeViewMode:ContextMenuItem;
private var menuExit:NativeMenuItem;

public static function get appName(): String 
{
	var ns: Namespace = getDescriptorNamespace();
	return NativeApplication.nativeApplication.applicationDescriptor.ns::name;	
}		

static private function getDescriptorNamespace(): Namespace 
{
	return NativeApplication.nativeApplication.applicationDescriptor.namespace();
}

private function create(event:Event):void
{
	
	registerClassAlias("com.appspot.redmineAir.model.Sticky", Sticky);
	registerClassAlias("com.appspot.redmineAir.model.StickyProperties", StickyProperties);
	registerClassAlias("flash.geom.Rectangle", Rectangle);
	registerClassAlias("flash.geom.Point", Point);

	// タスクトレイに常駐化
	var menu:NativeMenu = new NativeMenu();
	menuExit = new NativeMenuItem(translate("label_exit"));
	// Switch show/hide all Stickies.
	menuChangeViewMode = new ContextMenuItem(translate("label_hide_all"));
	menuChangeViewMode.addEventListener(Event.SELECT,
		function(e:Event):void {
			e.target.checked = !e.target.checked;
			// hide all
			for each (var item:Sticky in stickies)
			{
				item.windowVisible(!e.target.checked);
			}
		});	
	menu.addItem(menuChangeViewMode);	
	menuExit.addEventListener(Event.SELECT, appExit);
	menu.addItem(menuExit);	

	if (NativeApplication.supportsMenu) {
		var doc:DockIcon = NativeApplication.nativeApplication.icon as DockIcon;
		var icon:BitmapData = (new icon128() as BitmapAsset).bitmapData;
		doc.bitmaps = [icon];
		doc.menu = menu;
		NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, systemTrayIconClickHandler);
		stage.nativeWindow.addEventListener(Event.CLOSE, appExit);
	} else {
		var tray:SystemTrayIcon = NativeApplication.nativeApplication.icon as SystemTrayIcon;
		var icon032:BitmapData = (new icon032() as BitmapAsset).bitmapData;
		var icon016:BitmapData = (new icon016() as BitmapAsset).bitmapData;
		tray.bitmaps = [icon032, icon016];
		tray.menu = menu;
		tray.tooltip = "RedmineAir";
		tray.addEventListener(MouseEvent.CLICK, systemTrayIconClickHandler);
	}
	
	var docRoot: File = File.documentsDirectory.resolvePath(appName);
	docRoot.createDirectory();
	var oldLogFile: File;
	for (var i: int = 2; i >= 0; i--) {
		oldLogFile = docRoot.resolvePath("Log" + (i == 0 ? "" : String(i)) + ".txt");
		if (oldLogFile.exists) {
			try {
				oldLogFile.moveTo(docRoot.resolvePath("Log" + String(i+1) + ".txt"), true);
			}
			catch (e: Error) {
				trace("Can't back up log file " + oldLogFile.name);
			}
		}			
	}
	initLog();
	log.info(appName + ": starting");
	
	initializeSucessed = true;
	
	btnAddRedmine.addEventListener(MouseEvent.CLICK,showSavePanel);
	btnEditRedmine.addEventListener(MouseEvent.CLICK,showSavePanel);
	btnRemoveRedmine.addEventListener(MouseEvent.CLICK,removeRedmine);
	lbShowLogPanel.addEventListener(MouseEvent.CLICK,showLogPanel);
	btnShowLogPanel.addEventListener(MouseEvent.CLICK,showLogPanel);
	btnRefresh.addEventListener(MouseEvent.CLICK,function(e:Event):void {
		getResult();
	});	
	lbRefresh.addEventListener(MouseEvent.CLICK,function(e:Event):void {
		getResult();
	});
	btnAbout.addEventListener(MouseEvent.CLICK,goProject);
	txtAuthorFilter.addEventListener(Event.CHANGE,applyFilters);
	trRedmine.addEventListener(Event.CHANGE, applyFilters);
	cmbProject.addEventListener(Event.CHANGE, applyFilters);
	
	btnFormat.addEventListener(MouseEvent.MOUSE_DOWN,changeFormat);
	
	conn = null;
	var dbFile: File = docRoot.resolvePath(DB_FILE);
	conn = new SQLConnection();
	conn.addEventListener(SQLEvent.OPEN, connectionOpenHandler);
	conn.addEventListener(SQLErrorEvent.ERROR, connectionErrorHandler);
	
	conn.open(dbFile);
	conn.compact();
}

private function onInitialize(event:Event):void 
{
	NativeApplication.nativeApplication.addEventListener(Event.EXITING, handleExiting);				
}

private function handleExiting(event:Event):void 
{
	log.info(appName + ": closing");
}

private function initLog():void
{
	var docRoot: File = File.documentsDirectory.resolvePath(appName);
	logFile = docRoot.resolvePath("log.txt");
	var fileTarget:FileTarget = new FileTarget(logFile);
	fileTarget.includeCategory = false;
	fileTarget.includeDate = true;
	fileTarget.includeTime = true;
	fileTarget.includeLevel = true;
	fileTarget.level = LogEventLevel.INFO; 
	Log.addTarget(fileTarget);
}

private function connectionOpenHandler(event: SQLEvent):void 
{
	log.info("DB connection Open: " + DB_FILE);
	initSettingDB();
	initStickyDB();
	loadStickes();
	loadRedmineSetting();
}

private function connectionErrorHandler(event: SQLEvent):void 
{
	log.error("Couldn't read or create the database file: " + event.target.details);
}

private function initSettingDB():void 
{
	stmt = new SQLStatement();
	stmt.sqlConnection = conn;
	stmt.text =
		"CREATE TABLE IF NOT EXISTS redmine_settings (" + 
		"    id INTEGER PRIMARY KEY AUTOINCREMENT, " +
		"    url TEXT, " + 
		"    key TEXT, " + 
		"    feedkey TEXT, " +
		"    name TEXT UNIQUE, " +
		"	  note TEXT," +
		"    lastAccessed DATETIME" +	
		")";
	stmt.execute();
}

private function initStickyDB():void 
{
	stmt = new SQLStatement();
	stmt.sqlConnection = conn;
	stmt.text =
		"CREATE TABLE IF NOT EXISTS stickies (" + 
		"    id int, " +
		"    redmine_id INTEGER, " +
		"    key TEXT," + 
		"    url TEXT," + 
		"    content XML," +
		"    note TEXT," + 
		"    lastAccessed DATETIME," +
		"    alwaysInFront BOOLEAN," +
		"    point_x INTEGER," + 
		"    point_y INTEGER," + 		
		"    width INTEGER," +
		"    height INTEGER," +
		"    alpha INTEGER," +
		"    textColor TEXT," +
		"    backgroundColor TEXT," +
		"    updatedOn DATETIME," +
		"    PRIMARY KEY(id, redmine_id)" + 
		")";
	stmt.execute();
}

// load Stikies
private function loadStickes():void
{
	getStickies();
}

private function loadRedmineSetting():void 
{
	getResult();
}

private function getResult():void
{	
	stmt = new SQLStatement();
	stmt.addEventListener(SQLEvent.RESULT, loadRedmineSettingHandler);
	stmt.addEventListener(SQLErrorEvent.ERROR,
		function(event:SQLErrorEvent):void {
			log.error("Couldn't read from target table / redmine_settings: " + event.target.details);
		});
	stmt.sqlConnection = conn;
	stmt.text = "SELECT id, url, key, feedkey, name, lastAccessed, note FROM redmine_settings";
	stmt.execute();	
}

private function getStickies():void
{	
	stmt = new SQLStatement();
	stmt.addEventListener(SQLEvent.RESULT, loadStickesHandler);
	stmt.addEventListener(SQLErrorEvent.ERROR,
		function(event:SQLErrorEvent):void {
			log.error("Couldn't read from target table / stickies: " + event.target.details);
		});
	stmt.sqlConnection = conn;
	stmt.text = "SELECT id, redmine_id, key, url, content, note, lastAccessed, "
			+ " alwaysInFront, point_x, point_y, width, height, textColor, "
			+ " backgroundColor, alpha, updatedOn FROM stickies";
	stmt.execute();	
}

private function loadStickesHandler(e:SQLEvent):void 
{
	var result:SQLResult = stmt.getResult();
	if(result.data != null) {
		// clear up
		for (var i: int = 0; i < result.data.length; i++) {
			var data:Object = result.data[i];
			var s:Sticky = new Sticky(data["url"], data["key"], data["content"] as XML);
			s.window.panel.alpha = data["alpha"];
			s.window.textColor = data["textColor"];
			s.window.alwaysInFront = data["alwaysInFront"];
			s.window.stage.nativeWindow.bounds = new Rectangle(data["point_x"], data["point_y"], data["width"], data["height"]);
			s.window.width = data["width"];
			s.window.height = data["height"];
			s.window.addEventListener(RedmineAirErrorEvent.HTTP_ERROR, errorLogging);
			s.updatedOn = new Date(data["updatedOn"].toString());
			s.lastAccessed = new Date(data["lastAccessed"].toString());
			stickies[s.issue.ra::redmineId  + "-" + s.issueId] = s;
			s.activate();			
		}
	}
}

private function loadRedmineSettingHandler(e:SQLEvent):void 
{
	var result:SQLResult = stmt.getResult();
	if(result.data != null) {
		// clear up
		trRedmine.enabled = true;
		vdRedmineData.enabled = true;
		redmineXML = <redmine name="All"/>;
		issueXML = <root/>;
		activityXML = <root/>;
		for (var i: int = 0; i < result.data.length; i++) {
			// this might be handled within a Model class,
			var target:XML = <redmine/>;
			target.@id = result.data[i]["id"];
			target.@name = result.data[i]["name"];
			target.@url = result.data[i]["url"];
			target.@key = result.data[i]["key"];
			target.@feedkey = result.data[i]["feedkey"];
			target.@note = result.data[i]["note"];
			
			redmineXML.appendChild(target);
			
			// HTTP service for issues.
			var httpService:HTTPService = new HTTPService();
			httpService.useProxy = false;
			// httpService.requestTimeout = 10;
			httpService.resultFormat = "e4x";
			httpService.addEventListener(ResultEvent.RESULT, loadComplete);
			httpService.addEventListener(FaultEvent.FAULT, ioErrorHandler);
			var requestStr:String = result.data[i]["url"];
			requestStr = requestStr + "issues.xml?assigned_to_id=me";
			if (result.data[i]["key"] != null && result.data[i]["key"].length > 0)
				requestStr = requestStr + "&key=" + result.data[i]["key"]
			httpService.url = URLUtils.correctURL(requestStr);
			var at:AsyncToken = httpService.send()
			at.redmineId = result.data[i]["id"];
			at.redmineName = result.data[i]["name"];
			
			// HTTP service for activity.
			var feedService:HTTPService = new HTTPService();
			feedService.useProxy = false;
			feedService.resultFormat = "e4x";
			feedService.addEventListener(ResultEvent.RESULT, loadFeedComplete);
			feedService.addEventListener(FaultEvent.FAULT, ioErrorHandler);
			var rs:String = result.data[i]["url"];
			rs = rs + "activity.atom";
			if (result.data[i]["feedkey"] != null && result.data[i]["feedkey"].length > 0)
				rs = rs + "?key=" + result.data[i]["feedkey"]
			feedService.url = URLUtils.correctURL(rs);
			var fd:AsyncToken = feedService.send()
			fd.redmineId = result.data[i]["id"];
			fd.redmineName = result.data[i]["name"];
			
			// HTTP service for projects.
			var projectService:HTTPService = new HTTPService();
			projectService.useProxy = false;
			projectService.resultFormat = "e4x";
			projectService.addEventListener(ResultEvent.RESULT, loadProjectComplete);
			projectService.addEventListener(FaultEvent.FAULT, ioErrorHandler);
			var projectRs:String = result.data[i]["url"];
			projectRs = projectRs + "projects.xml?";
			if (result.data[i]["key"] != null && result.data[i]["key"].length > 0)
				projectRs =projectRs + "&key=" + result.data[i]["key"]
			projectService.url = URLUtils.correctURL(projectRs);
			var pt:AsyncToken = projectService.send()
			pt.redmineId = result.data[i]["id"];
			pt.redmineName = result.data[i]["name"];
		}
		trRedmine.selectedIndex = 0;
		callLater(treeInit);
		
	} else {
		redmineXML = <root name="Please add any redmine."/>;
		trRedmine.enabled = false;
		vdRedmineData.enabled = false;
	}
}

private function treeInit():void
{
	var TreeCollection:XMLListCollection = new XMLListCollection (new XMLList (redmineXML)); 
	trRedmine.expandItem(TreeCollection.getItemAt(0),true);
}

private function loadComplete(event:ResultEvent):void
{
	var resultXML:XML = event.target.lastResult as XML;
	resultXML.ra::redmineId = event.token.redmineId.toString();
	resultXML.ra::redmineName = event.token.redmineName.toString();
	resultXML.ra::lastAccessed = new Date();
	redmineXML.redmine.(@id == event.token.redmineId).@hasError = 0;
	
	issueXML.appendChild(resultXML);
}

private function loadFeedComplete(event:ResultEvent):void
{
	var resultXML:XML = event.target.lastResult as XML;
	atom = resultXML.namespace();
	resultXML.ra::redmineId = event.token.redmineId.toString();
	resultXML.ra::redmineName = event.token.redmineName.toString();
	resultXML.ra::lastAccessed = new Date();
	
	activityXML.appendChild(resultXML);
}

private function loadProjectComplete(event:ResultEvent):void
{
	var resultXML:XML;
	var xml:XML;
	var event:* = event;
	log.info(resultXML);
	
	resultXML = event.target.lastResult as XML;
	resultXML.ra::redmineId = event.token.redmineId.toString();
	resultXML.ra::redmineName = event.token.redmineName.toString();
	
	for (var i:int = 0; i < resultXML.project.length; i++) {
		xml = resultXML.project[i];
		xml.ra::redmineId = resultXML.ra::redmineId;
		xml.ra::redmineName = resultXML.ra::redmineName;
		
		resultXML.project[i] = xml;
	}
	
	this.projectXML.appendChild(resultXML);
	return;
}


private function ioErrorHandler(event:FaultEvent):void
{
	Alert.show(ObjectUtil.toString(event.fault),"Error");
	log.error(appName + ": " + ObjectUtil.toString(event.fault));
	redmineXML.redmine.(@id == event.token.redmineId).@hasError = 1;
	trRedmine.dataProvider = redmineXML;
	callLater(treeInit);
}

private function applyFilters(event:Event): void 
{
	var aList:XMLList;
	var iList:XMLList;
	var child:String;
	var arry:ArrayList;
	
	var o:Object;
	var p:Object;
	var reg:RegExp;
	var event:* = event;
	var projectTarget:XML;
	if (event.target.id == "cmbProject") {
		projectTarget = event.target.selectedItem as XML;
	}
	
	var target:* = this.trRedmine.selectedItem as XML;
	var aXML:* = this.activityXML.copy();
	var iXML:* = this.issueXML.copy();
	var pXML:* = this.projectXML.copy();
	if (target == null || target.@name == "All") {
		iList = iXML.children();
		aList = aXML.atom::feed.entry;
	} else {
		var t:XMLListCollection = new XMLListCollection();
		var xml:XML;
		for (var c:int = 0; c < pXML.projects.length(); c++) {
			xml = pXML.projects[c] as XML;
			if (xml.ra::redmineId == target.@id) {
				t.addItem(xml);
			}			
		}		
		cmbProject.dataProvider = (t.source).project;
		var xmlList:XMLList = new XMLList("");
		iList = iXML.children();
		for (var i:int = 0; i < iXML.issues.length(); i++) {
			xml = iXML.issues[i] as XML;
			if (xml.ra::redmineId == target.@id) {
				xmlList[i] = xml;
			}			
		}
		
		var aXmlList:XMLList = new XMLList("");	
		for (var l:int = 0; l < (aXML.atom::feed as XMLList).length(); l++) {
			xml = aXML.atom::feed[l] as XML;
			if (xml.ra::redmineId == target.@id) {
				aXmlList[l] = xml;
			}			
		}	
		
		aList = aXmlList.atom::entry;
		iList = iXML.issues.(ra::redmineId == target.@id);

	}
	aList = this.applyAuthorFilter(aList);
	iList = this.applyProjectFilter(iList, projectTarget);

	iXML = <root/>;
	iXML.appendChild(iList);
	this.dgAssigned.dataProvider = iXML.issues.issue;
	this.dgActivity.dataProvider = aList;
}


private function showSavePanel(event:Event):void
{
	switch(true) {
		case event.target.id == "btnAddRedmine":
			saveRedmineWindow = PopUpManager.createPopUp(this, SaveRedmineWindow, true) as SaveRedmineWindow;
			saveRedmineWindow.addEventListener(RedmineEvent.ADD,saveRedmine);
			var xml:XML =  <redmine/>; 	
			saveRedmineWindow.viewHelper.redmineXML = xml;
			PopUpManager.centerPopUp(saveRedmineWindow);
			break;
		case event.target.id == "btnEditRedmine":
			saveRedmineWindow = PopUpManager.createPopUp(this, SaveRedmineWindow, true) as SaveRedmineWindow;
			saveRedmineWindow.addEventListener(RedmineEvent.EDIT,saveRedmine);
			saveRedmineWindow.viewHelper.redmineXML = trRedmine.selectedItem as XML;			
			PopUpManager.centerPopUp(saveRedmineWindow);	
			break;
		default: 
			// do nothing.
			break;
	}	
}

private function showLogPanel(event:Event):void
{
	var logWindow:LogWindow = PopUpManager.createPopUp(this, LogWindow, true) as LogWindow;	
	logWindow.viewHelper.logFile = logFile;
	PopUpManager.centerPopUp(logWindow);
}

private function removeRedmine(event:Event):void
{
	var target:XML = trRedmine.selectedItem as XML;
	if (target == null || target.@name == "All") {
		return;
	}
	if (target.@id) {
		Alert.show("Remove this Redmine?\nName: " + target.@name, "Confirmation",
			Alert.OK | Alert.CANCEL, this,
			alertListener, null, Alert.OK);
	}
}

private function alertListener(event:CloseEvent):void
{
	if (event.detail == Alert.OK) {
		var target:XML = trRedmine.selectedItem as XML;
		log.debug("Removed " + target.@name);
		delete redmineXML.redmine.(@id == target.@id)[0];
		delete issueXML.issues.(ra::redmineId == target.@id)[0];
		delete activityXML.feed.(ra::redmineId == target.@id)[0];
		txtIssueDetail.text = null;
		deleteRedmine(target);
		getResult();
	}
}

private function deleteRedmine(target:XML):void
{
	stmt = new SQLStatement();
	stmt.sqlConnection = conn;
	stmt.text =
		"DELETE FROM redmine_settings WHERE id = " +  target.@id;
	stmt.execute();
}

public function saveRedmine(event:RedmineEvent):void
{
	stmt = new SQLStatement();
	stmt.sqlConnection = conn;
	saveRedmineWindow.viewHelper.closePopUp(saveRedmineWindow);
	stmt.addEventListener(SQLEvent.RESULT,
		function(e:Event):void {
			loadRedmineSetting();
		});
	var target:XML = event.redmineXML as XML;
	log.info(target.toXMLString());

	// parameters
	stmt.parameters[':url'] = target.@url;
	stmt.parameters[':key'] = target.@key;
	stmt.parameters[':feedkey'] = target.@feedkey;
	stmt.parameters[':name'] = target.@name;
	stmt.parameters[':note'] = target.@note;		
	
	if (event.type == RedmineEvent.EDIT) {
		stmt.text =
			"UPDATE redmine_settings SET url = :url, key = :key, "
			+ "feedkey = :feedkey, name = :name, "
			+ "note = :note WHERE id = :id";
		stmt.parameters[':id'] = target.@id;
	}

	if (event.type == RedmineEvent.ADD) {
		stmt.text =
			"INSERT INTO redmine_settings(url, key, feedkey, name) "
			+ "VALUES (:url, :key, :feedkey, :name, :note)";
	}
	log.info(stmt.text);
	stmt.execute();
}

public function displayIssueInfo(event:Event):void
{
	var targetXML:XML = event.target.selectedItem as XML
	txtIssueDetail.text = targetXML.toString();
	var redmineId:String = targetXML.parent().ra::redmineId;
	log.debug("target1: " + redmineId);	
	log.debug("target: " + redmineXML.redmine.(@id == redmineId).@name);
}

public function showEntryInfo(event:Event):void 
{
	var entryXML:XML = event.target.selectedItem as XML;
	txtEntryDetail.htmlText = entryXML.*::content.toString();
	lnkEntry.label = URLUtils.correctURL(entryXML.*::id.toString()).substring(0, 50) + '...';
}

// for handling xml namespace 
private function genericLabelFunction(dgcXML:Object,dcg:DataGridColumn):String 
{
	var currentItem:XML = XML(dgcXML);
	var ns:Namespace = currentItem.namespace();
	var displayValue:String = currentItem.ns::[dcg.dataField];
	return displayValue;
}

private function authorLabelFunction(dgcXML:Object,dcg:DataGridColumn):String 
{
	var currentItem:XML = XML(dgcXML);
	var ns:Namespace = currentItem.namespace();
	var displayValue:String = currentItem.ns::author.ns::name;
	return displayValue;
}

private function goProject(event:Event):void 
{
	var u:URLRequest = new URLRequest("http://www.r-labs.org/projects/redmineair");
	navigateToURL(u,"_blank");
}

private function applyAuthorFilter(param:XMLList):XMLList
{
	var list:XMLList = param;
	var result:XMLList = list;
	var key:String = this.txtAuthorFilter.text;
	if (key != null && key.length > 0) {
		try {
			var resultList:XMLListCollection = new XMLListCollection();
			for (var i:int = 0; i<list.length(); i++) {
				var xml:XML = list[i] as XML;
				if (xml.(*::author.atom::name.indexOf(key)) > -1) {
					resultList.addItem(xml);
				}
			}
			return resultList.source;
		} catch (error:Error) {
			// do nothing.
			log.debug(error.toString());
		}
	}
	return list;
}

private function applyProjectFilter(param:XMLList, target:XML):XMLList
{
	var list:XMLList = param;
	var key:String;
	
	if (list == null || list[0] == null) {
		return list;
	}
	
	if (target == null) {
		return list;
	}
	
	var keyObj:XML = target;
	var xml:XML = <issues type="array"></issues>;
	if (keyObj != null && keyObj.name != "All") {
		xml.ra::redmineId = keyObj.parent().ra::redmineId;
		xml.ra::redmineName = keyObj.parent().ra::redmineName;
		key = keyObj.name.text();
	}
	
	if (key != null && key.length > 0) {
		try {
			var resultList:XMLList = new XMLList();
			resultList = list.issue.(project.@name == key);
			return new XMLList(xml.appendChild(resultList));
		} catch (error:Error) {
			// do nothing.
			log.debug(error.toString());
		}
	}
	return list;
}

public function itemSelect(item: XML):void
{
	var id:String = item.id;
	var redmine:XML = redmineXML.redmine.(@id == item.parent().ra::redmineId)[0];
	item.ra::redmineId = item.parent().ra::redmineId;
	item.ra::lastAccessed = item.parent().ra::lastAccessed;
	item.@key = redmine.@key;
	var url:String = URLUtils.correctURL(redmine.@url) + "/issues/" + item.id;
	trace("IssueId: " + id);
		
	var s:Sticky = stickies[item.ra::redmineId + "-" + item.id];
	if (s == null || s.closed) {
		s = new Sticky(url, item.@key, item as XML);
		s.lastAccessed = new Date(item.ra::lastAccessed.toString());
		s.show();		
		stickies[item.ra::redmineId  + "-" + item.id] = s;
	} else {
		s.activate();
	}
}

public function showOpenStickyHelp(data:Object):String
{
	return translate("tips_open_sticky") + data.id;
}

private function translate(key:String):String 
{
	if (resourceManager == null) {
		ResourceManager.getInstance();
	}
	if (key != null && resourceManager != null) {
		return resourceManager.getString(bundleName, key);
	}
	return "";	
}

/*
private function saveStickies():void
{
	if (stickiesDir.exists) stickiesDir.deleteDirectory(true);
	stickiesDir.createDirectory();
	
	for each (var s:Sticky in stickies) {
		if (s.closed) {
			continue;
		}
		s.setPerment();
		var item:XML = s.issue;
		var f:File = stickiesDir.resolvePath(item.ra::redmineId + "-" + s.issueId + ".dat");
		FileIO.writeObject(f, s);
		s.close();
	}	
}
*/

private function saveStickiesToDB():void
{
	
	stmt = new SQLStatement();
	stmt.addEventListener(SQLErrorEvent.ERROR,
		function(event:SQLErrorEvent):void {
			log.debug("Couldn't insert/update to target table / stickies: " + event.target.details);
		});	
	stmt.sqlConnection = conn;
	
	var editText:String = "UPDATE stickies SET id = :id, redmine_id = :redmine_id, "
		+ "key = :key, "
		+ "url = :url, "
		+ "content = :content, "
		+ "alwaysInFront = :alwaysInFront, "
		+ "alpha = :alpha,"
		+ "textColor = :textColor,"
		+ "backgroundColor = :backgroundColor,"
		+ "updatedOn = datetime('now', 'localtime'), "
		+ "lastAccessed = :lastAccessed, "		
		+ "width = :width,"
		+ "height = :height, "
		+ "point_x = :point_x, "
		+ "point_y = :point_y "
		+ " WHERE id = :id";
	
	var insertText:String = "INSERT INTO stickies(id, redmine_id, key, url, content, lastAccessed, "
		+ "alwaysInFront, alpha, textColor, backgroundColor, updatedOn, height, width, point_x, point_y) "
		+ "VALUES (:id, :redmine_id, :key, :url, :content, :lastAccessed, "
		+ ":alwaysInFront, :alpha, :textColor, :backgroundColor, datetime('now', 'localtime'), :height, :width,"
		+ ":point_x, :point_y)";
	
	
	log.info(stmt.text);
	
	// Save SQLite
	
	for each (var s:Sticky in stickies){
		if (s.closed) {
			deleteStickies(s.issue);
			continue;
		}
		
		stmt.text = insertText;
		if (s.updatedOn != null) {
			stmt.text = editText;
		}
		//s.setPerment();
		
		s.issue.addNamespace(ra);
		
		// parameters
		stmt.parameters[':url'] = s.uri;
		stmt.parameters[':key'] = s.key;
		stmt.parameters[':id'] = s.issueId;
		stmt.parameters[':redmine_id'] = s.issue.ra::redmineId.text();
		stmt.parameters[':content'] = s.issue;
		stmt.parameters[':alwaysInFront'] = s.window.alwaysInFront;
		stmt.parameters[':alpha'] = s.window.panel.alpha;
		stmt.parameters[':textColor'] = s.window.textColor;
		stmt.parameters[':backgroundColor'] = s.window.panel.getStyle("backgroundColor");
		stmt.parameters[':height'] = s.window.height;
		stmt.parameters[':width'] = s.window.width;
		stmt.parameters[':lastAccessed'] = s.lastAccessed;
		
		var bounds:Rectangle = s.window.nativeWindow.bounds;
		stmt.parameters[':point_x'] = bounds.x;
		stmt.parameters[':point_y'] = bounds.y;		
		
		log.info(stmt.text);
		stmt.execute();	
	}		
}

private function appExit(e:Event):void
{
	stage.nativeWindow.removeEventListener(Event.CLOSE, appExit);
	saveStickiesToDB();
	//saveStickies();
	NativeApplication.nativeApplication.exit();
}

public function onWindowClosing(e:Event):void
{
	if (!initializeSucessed) {
		return;
	}
	// windowをcloseしてもアプリを終了しない
	visible = false;
	e.preventDefault();
}

private function systemTrayIconClickHandler(event:Event) :void 
{
	if (!visible || nativeWindow.displayState == NativeWindowDisplayState.MINIMIZED) {
		if (!nativeWindow.visible) {
			nativeWindow.visible = true;
		}
		visible = true;
		nativeWindow.restore();
		activate();
		setFocus();
	}
}

// Delete stickies object from DB
private function deleteStickies(target:XML):void
{
	stmt = new SQLStatement();
	stmt.sqlConnection = conn;
	stmt.text =
		"DELETE FROM stickies WHERE id = " +  target.id
			+ " AND redmine_id = " + target.ra::redmineId;
	log.info(stmt.text);
	stmt.execute();
}

public function lpad(original:Object, length:int, pad:String):String
{
	var padded:String = original == null ? "" : original.toString();
	while (padded.length < length) padded = pad + padded;
	return padded;
}

public function toSqlDate(dateVal:Date):String
{
	return dateVal == null ? null : dateVal.fullYear
		+ "-" + lpad(dateVal.month + 1,2,'0')  // month is zero-based
		+ "-" + lpad(dateVal.date,2,'0')
		+ " " + lpad(dateVal.hours,2,'0')
		+ ":" + lpad(dateVal.minutes,2,'0')
		+ ":" + lpad(dateVal.seconds,2,'0')
		;
}

public function errorLogging(event:RedmineAirErrorEvent):void 
{
	log.error(event.errorMessage);
}

public function showIssueInfo(item:Object):String  
{ 
	return item.subject + "\n------------------------\n" + item.description.substring(0, 100) + '...';
}

private function changeFormat(event:Event = null):void 
{
	if (dgAssigned.selectedItem == null) {
		return;
	}
	
	var issue:XML = dgAssigned.selectedItem as XML;
	if (btnFormat.getStyle("icon") == com.appspot.redmineAir.util.IconSet.xmlIcon) {
        txtIssueDetail.text = issue.toXMLString();
        btnFormat.setStyle("icon", com.appspot.redmineAir.util.IconSet.textIcon);
        btnFormat.toolTip = "Show Text";
    } else {
        txtIssueDetail.text = issue.description;
        btnFormat.setStyle("icon", com.appspot.redmineAir.util.IconSet.xmlIcon);
        btnFormat.toolTip = "Show XML";					
    }
}
