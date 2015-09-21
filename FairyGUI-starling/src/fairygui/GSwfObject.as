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
		protected var _gearAnimation:GearAnimation;
		
		public function GSwfObject()
		{
			_playing = true;
			
			_gearAnimation = new GearAnimation(this);
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
				if(_gearAnimation.controller)
					_gearAnimation.updateState();
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

				if(_gearAnimation.controller)
					_gearAnimation.updateState();
			}
		}
		
		final public function get gearAnimation():GearAnimation
		{
			return _gearAnimation;
		}
		
		override protected function handleSizeChanged():void
		{
			if(_content)
			{
				_container.scaleX = this.width/_sourceWidth*this.scaleX*GRoot.contentScaleFactor;
				_container.scaleY = this.height/_sourceHeight*this.scaleY*GRoot.contentScaleFactor;
			}
		}

		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			if(_gearAnimation.controller==c)
				_gearAnimation.apply();
		}
		
		override public function constructFromResource(pkgItem:PackageItem):void
		{
			_packageItem = pkgItem;
			
			_sourceWidth = _packageItem.width;
			_sourceHeight = _packageItem.height;
			_initWidth = _sourceWidth;
			_initHeight = _sourceHeight;
			
			setSize(_sourceWidth, _sourceHeight);
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String = xml.@playing;
			_playing =  str!= "false";
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			var cxml:XML = xml.gearAni[0];
			if(cxml)
				_gearAnimation.setup(cxml);
		}
	}
}