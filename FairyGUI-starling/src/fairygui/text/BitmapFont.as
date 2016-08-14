package fairygui.text
{
	import starling.textures.Texture;
	
	public class BitmapFont
	{
		public var id:String;
		public var size:int;
		public var ttf:Boolean;
		public var resizable:Boolean;
		public var colored:Boolean;
		public var mainTexture:Texture;
		public var glyphs:Object;
		
		public function BitmapFont():void
		{
			glyphs = {};
		}
	}
}


