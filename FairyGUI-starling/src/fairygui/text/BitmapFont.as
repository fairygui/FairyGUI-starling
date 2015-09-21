package fairygui.text
{
	import starling.textures.Texture;
	
	public class BitmapFont
	{
		public var id:String;
		public var lineHeight:int;
		public var ttf:Boolean;
		public var mainTexture:Texture;
		public var glyphs:Object;
		
		public function BitmapFont():void
		{
			glyphs = {};
		}
	}
}


