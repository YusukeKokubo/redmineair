/**
* @author y.kokubo
*/

package com.appspot.redmineAir.util {
	import flash.filesystem.*;

	public class FileIO {
		public function FileIO() {
		}

		public static function readObject(file:File):Object
		{
			if (!file.exists) return null;

			var fs:FileStream = new FileStream();
			fs.open(file,FileMode.READ);
			var result:Object = null;
			while (fs.bytesAvailable){
				result = fs.readObject();
			}
			fs.close();
			return result;
		}

		public static function writeObject(file:File, data:Object):void
		{
			var fs:FileStream;
			try {
				fs = new FileStream();
				fs.open(file,FileMode.WRITE);
				fs.writeObject(data);
			} finally {
				fs.close();
			}
		}

		public static function readFile(fileName:String):String
		{
			var file:File=File.applicationStorageDirectory.resolvePath(fileName);
			if (!file.exists) {
				return "";
			}

			var stream:FileStream;
			var result:String

			try {
				stream = new FileStream();
				stream.open(file, FileMode.READ);
				result = stream.readUTFBytes(stream.bytesAvailable);
			} finally {
				stream.close();
			}
			return result;
		}

		public static function writeFile(fileName:String, data:String):void
		{
			var file:File=File.applicationStorageDirectory.resolvePath(fileName);
			var stream:FileStream;

			try {
				stream = new FileStream();
				stream.open(file, FileMode.WRITE);
				stream.writeUTFBytes(data);
			} finally {
				stream.close();
			}
		}
	}

}