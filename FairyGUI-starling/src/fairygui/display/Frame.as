package fairygui.display
{
	import flash.geom.Rectangle;
	
	import starling.textures.Texture;

	public class Frame
	{
		public var rect:Rectangle;
		public var addDelay:int;
		public var texture:Texture;
		public var sprite:String;
		
		public function Frame()
		{
			rect = new Rectangle();
		}
	}
}