package fairygui
{
	import flash.geom.Rectangle;
	
	import fairygui.display.MovieClip;
	import fairygui.display.UIMovieClip;
	import fairygui.utils.ToolSet;
	
	import starling.textures.TextureSmoothing;
	
	public class GMovieClip extends GObject implements IAnimationGear, IColorGear
	{			
		private var _movieClip:MovieClip;
		
		public function GMovieClip()
		{
			_sizeImplType = 1;
		}
		
		public function get color():uint
		{
			return _movieClip.color;
		}
		
		public function set color(value:uint):void
		{
			_movieClip.color = value;
			updateGear(4);
		}
		
		override protected function createDisplayObject():void
		{
			_movieClip = new UIMovieClip(this);
			setDisplayObject(_movieClip);
		}
		
		final public function get playing():Boolean
		{
			return _movieClip.playing;
		}
		
		final public function set playing(value:Boolean):void
		{
			if(_movieClip.playing!=value)
			{
				_movieClip.playing = value;
				updateGear(5);
			}
		}
		
		final public function get frame():int
		{
			return _movieClip.currentFrame;
		}
		
		public function set frame(value:int):void
		{
			if(_movieClip.currentFrame!=value)
			{
				_movieClip.currentFrame = value;
				updateGear(5);
			}
		}
		
		//从start帧开始，播放到end帧（-1表示结尾），重复times次（0表示无限循环），循环结束后，停止在endAt帧（-1表示参数end）
		public function setPlaySettings(start:int = 0, end:int = -1, 
										times:int = 0, endAt:int = -1, 
										endCallback:Function = null):void
		{
			_movieClip.setPlaySettings(start, end, times, endAt, endCallback);	
		}

		override public function constructFromResource():void
		{
			sourceWidth = packageItem.width;
			sourceHeight = packageItem.height;
			initWidth = sourceWidth;
			initHeight = sourceHeight;

			setSize(sourceWidth, sourceHeight);
			
			if(packageItem.loaded)
				__movieClipLoaded(packageItem);
			else
				packageItem.owner.addItemCallback(packageItem, __movieClipLoaded);
		}
		
		private function __movieClipLoaded(pi:PackageItem):void
		{
			_movieClip.interval = packageItem.interval;
			_movieClip.swing = packageItem.swing;
			_movieClip.repeatDelay = packageItem.repeatDelay;
			_movieClip.frames = packageItem.frames;
			_movieClip.boundsRect = new Rectangle(0, 0, sourceWidth, sourceHeight);
			_movieClip.textureSmoothing = packageItem.smoothing?TextureSmoothing.BILINEAR:TextureSmoothing.NONE;
		}

		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String;
			str = xml.@frame;
			if(str)
				_movieClip.currentFrame = parseInt(str);
			str = xml.@playing;
			_movieClip.playing = str!= "false";
			str = xml.@color;
			if(str)
				this.color = ToolSet.convertFromHtmlColor(str);
		}
	}
}