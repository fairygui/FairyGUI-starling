package fairygui
{
	import fairygui.display.UISprite;
	
	import starling.display.DisplayObject;
	
	public class GSwfObject extends GObject implements IAnimationGear
	{
		protected var _container:UISprite;
		protected var _content:DisplayObject;
		protected var _playing:Boolean;
		protected var _frame:int;
		
		public function GSwfObject()
		{
			_playing = true;
		}
		
		override protected function createDisplayObject():void
		{
			_container = new UISprite(this);
			setDisplayObject(_container);
		}
		
		final public function get playing():Boolean
		{
			return _playing;
		}
		
		public function set playing(value:Boolean):void
		{
			if(_playing!=value)
			{
				_playing = value;
				updateGear(5);
			}
		}
		
		final public function get frame():int
		{
			return _frame;
		}
		
		public function set frame(value:int):void
		{
			if(_frame!=value)
			{
				_frame = value;
				updateGear(5);
			}
		}
		
		final public function get timeScale():Number
		{
			return 1;
		}
		
		public function set timeScale(value:Number):void
		{
			//not supported.
		}
		
		public function advance(timeInMiniseconds:int):void
		{
			//not supported.
		}
		
		override protected function handleSizeChanged():void
		{
			_container.width = this.width;
			_container.height = this.height;
		}
		
		override public function constructFromResource():void
		{
			sourceWidth = packageItem.width;
			sourceHeight = packageItem.height;
			initWidth = sourceWidth;
			initHeight = sourceHeight;
			
			setSize(sourceWidth, sourceHeight);
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String = xml.@playing;
			_playing =  str!= "false";
		}
	}
}