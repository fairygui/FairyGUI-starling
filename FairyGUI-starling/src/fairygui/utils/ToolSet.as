package fairygui.utils
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import fairygui.GObject;
	import fairygui.display.UIDisplayObject;
	
	import starling.display.DisplayObject;
	import starling.display.Stage;

	public class ToolSet
	{
		public static var GRAY_FILTERS_MATRIX:Vector.<Number> = new <Number>[
				0.299, 0.587, 0.114, 0, 0,
				0.299, 0.587, 0.114, 0, 0,
				0.299, 0.587, 0.114, 0, 0,
				0, 0, 0, 1, 0
		];
		
		public function ToolSet()
		{
		}
		
		public static function startsWith(source:String, str:String, ignoreCase:Boolean=false):Boolean {
			if(!source)
				return false;
			else if(source.length<str.length)
				return false;
			else {
				source = source.substring(0, str.length);
				if(!ignoreCase)
					return source==str;
				else
					return source.toLowerCase()==str.toLowerCase();
			}
		}
		
		public static function endsWith(source:String, str:String, ignoreCase:Boolean=false):Boolean {
			if(!source)
				return false;
			else if(source.length<str.length)
				return false;
			else {
				source = source.substring(source.length-str.length);
				if(!ignoreCase)
					return source==str;
				else
					return source.toLowerCase()==str.toLowerCase();
			}
		}
		
		public static function trim(targetString:String):String{
			return trimLeft(trimRight(targetString));
		}
		
		public static function trimLeft(targetString:String):String{
			var tempChar:String = "";
			for(var i:int=0; i<targetString.length; i++){
				tempChar = targetString.charAt(i);
				if(tempChar != " " && tempChar != "\n" && tempChar != "\r"){
					break;
				}
			}
			return targetString.substr(i);
		}
		
		public static function trimRight(targetString:String):String{
			var tempChar:String = "";
			for(var i:int=targetString.length-1; i>=0; i--){
				tempChar = targetString.charAt(i);
				if(tempChar != " " && tempChar != "\n" && tempChar != "\r"){
					break;
				}
			}
			return targetString.substring(0 , i+1);
		}
		
		
		public static function convertToHtmlColor(argb:uint, hasAlpha:Boolean=false):String {
			var alpha:String;
			if(hasAlpha)
				alpha = (argb >> 24 & 0xFF).toString(16);
			else
				alpha = "";
			var red:String = (argb >> 16 & 0xFF).toString(16);
			var green:String = (argb >> 8 & 0xFF).toString(16);
			var blue:String = (argb & 0xFF).toString(16);
			if(alpha.length==1)
				alpha = "0" + alpha;
			if(red.length==1)
				red = "0" + red;
			if(green.length==1)
				green = "0" + green;
			if(blue.length==1)
				blue = "0" + blue;
			return "#" + alpha + red +  green + blue;
		}
		
		public static function convertFromHtmlColor(str:String, hasAlpha:Boolean=false):uint {
			if(str.length<1)
				return 0;
			
			if(str.charAt(0)=="#")
				str = str.substr(1);
			
			if(str.length==8)
				return (parseInt(str.substr(0, 2), 16)<<24)+parseInt(str.substr(2), 16);
			else if(hasAlpha)
				return 0xFF000000+parseInt(str, 16);
			else
				return parseInt(str, 16);
		}
		
		public static function encodeHTML(str:String):String {
			if(!str)
				return "";
			else
				return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/'/g, "&apos;");
		}
		
		public static var defaultUBBParser:UBBParser = new UBBParser();
		public static function parseUBB(text:String):String {
			return defaultUBBParser.parse(text);
		}
		
		public static function scaleBitmapWith9Grid(source:BitmapData, scale9Grid:Rectangle,
													wantWidth:int, wantHeight:int, smoothing:Boolean=false):BitmapData {
			if(wantWidth==0 || wantHeight==0)
			{
				return new BitmapData(1,1,source.transparent, 0x00000000);
			}
			
			var bmpData : BitmapData = new BitmapData(wantWidth, wantHeight, source.transparent, 0x00000000);
			
			var rows : Array = [0, scale9Grid.top, scale9Grid.bottom, source.height];
			var cols : Array = [0, scale9Grid.left, scale9Grid.right, source.width];
			
			var dRows : Array = [0, scale9Grid.top, wantHeight - (source.height - scale9Grid.bottom), wantHeight];
			var dCols : Array = [0, scale9Grid.left, wantWidth - (source.width - scale9Grid.right), wantWidth];
			
			var origin : Rectangle;
			var draw : Rectangle;
			var mat:Matrix = new Matrix();
			
			for (var cx : int = 0;cx < 3; cx++) {
				for (var cy : int = 0 ;cy < 3; cy++) {
					origin = new Rectangle(cols[cx], rows[cy], cols[cx + 1] - cols[cx], rows[cy + 1] - rows[cy]);
					draw = new Rectangle(dCols[cx], dRows[cy], dCols[cx + 1] - dCols[cx], dRows[cy + 1] - dRows[cy]);
					mat.identity();
					mat.a = draw.width / origin.width;
					mat.d = draw.height / origin.height;
					mat.tx = draw.x - origin.x * mat.a;
					mat.ty = draw.y - origin.y * mat.d;
					bmpData.draw(source, mat, null, null, draw, smoothing);
				}
			}
			return bmpData;
		}
		
		public static function displayObjectToGObject(obj:DisplayObject):GObject
		{
			while (obj != null && !(obj is Stage))
			{
				if (obj is UIDisplayObject)
					return UIDisplayObject(obj).owner;
				
				obj = obj.parent;
			}
			return null;
		}
		
		//no mx.utils.Base64Decoder for pure as project, so use a third party one
		private static const decodeChars:Vector.<int> = InitDecodeChar();
		public static function decodeBase64(str:String):ByteArray
		{
			var c1:int;
			var c2:int;
			var c3:int;
			var c4:int;
			var i:int = 0;
			var len:int = str.length;

			var byteString:ByteArray = new ByteArray();
			byteString.writeUTFBytes(str);
			var outPos:int = 0;
			while (i < len)
			{
				//c1
				c1 = decodeChars[int(byteString[i++])];
				if (c1 == -1)
					break;

				//c2
				c2 = decodeChars[int(byteString[i++])];
				if (c2 == -1)
					break;

				byteString[int(outPos++)] = (c1 << 2) | ((c2 & 0x30) >> 4);

				//c3
				c3 = byteString[int(i++)];
				if (c3 == 61)  
				{
					byteString.length = outPos;
					return byteString;  
				}  

				c3 = decodeChars[int(c3)];
				if (c3 == -1)
					break;
				
				byteString[int(outPos++)] = ((c2 & 0x0f) << 4) | ((c3 & 0x3c) >> 2);
				
				//c4
				c4 = byteString[int(i++)];
				if (c4 == 61)
				{
					byteString.length = outPos;
					return byteString;
				}

				c4 = decodeChars[int(c4)];
				if (c4 == -1)
					break;

				byteString[int(outPos++)] = ((c3 & 0x03) << 6) | c4;
			}
			byteString.length = outPos;
			return byteString;
		}
		
		public static function InitDecodeChar():Vector.<int>
		{
			var decodeChars:Vector.<int> = new <int>[
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63,
				52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
				-1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
				15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
				-1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
				41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
				-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];

			return decodeChars;
		}
	}
}