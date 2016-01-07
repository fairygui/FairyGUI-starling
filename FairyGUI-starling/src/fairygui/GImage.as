package fairygui
{
	import fairygui.display.ImageExt;
	import fairygui.display.UIImage;
	import fairygui.utils.ToolSet;
	
	import starling.textures.TextureSmoothing;

	public class GImage extends GObject implements IColorGear
	{
		protected var _gearColor:GearColor;
		
		private var _content:ImageExt;
		
		public function GImage()
		{
			_gearColor = new GearColor(this);
		}
		
		public function get color():uint
		{
			return _content.color;
		}
		
		public function set color(value:uint):void 
		{
			if(_content.color != value)
			{
				_content.color = value;
				if (_gearColor.controller != null)
					_gearColor.updateState();
			}
		}
		
		public function get flip():int
		{
			return _content.flip;
		}
		
		public function set flip(value:int):void
		{
			_content.flip = value;
		}
		
		override protected function createDisplayObject():void
		{ 
			_content = new UIImage(this);
			setDisplayObject(_content);
		}
		
		final public function get gearColor():GearColor
		{
			return _gearColor;
		}
		
		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			if(_gearColor.controller==c)
				_gearColor.apply();
		}
		
		override public function dispose():void
		{
			if(!_packageItem.loaded)
				_packageItem.owner.removeItemCallback(_packageItem, __imageLoaded);
			super.dispose();
		}
		
		override public function constructFromResource(pkgItem:PackageItem):void
		{
			_packageItem = pkgItem;
			
			_sourceWidth = _packageItem.width;
			_sourceHeight = _packageItem.height;
			_initWidth = _sourceWidth;
			_initHeight = _sourceHeight;
			
			setSize(_sourceWidth, _sourceHeight);
			
			if(_packageItem.loaded)
				__imageLoaded(_packageItem);
			else
				_packageItem.owner.addItemCallback(_packageItem, __imageLoaded);
		}

		private function __imageLoaded(pi:PackageItem):void
		{
			if(pi.texture!=null)
			{
				_content.texture = pi.texture;
				_content.scale9Grid = pi.scale9Grid;
				_content.scaleByTile = pi.scaleByTile;
				_content.smoothing = pi.smoothing?TextureSmoothing.BILINEAR:TextureSmoothing.NONE;
			}
			
			handleSizeChanged();
		}
		
		override protected function handleSizeChanged():void
		{
			_content.scaleX = this.width/_sourceWidth*this.scaleX;
			_content.scaleY = this.height/_sourceHeight*this.scaleY;
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String;
			str = xml.@color;
			if(str)
				this.color = ToolSet.convertFromHtmlColor(str);
			
			str = xml.@flip;
			if(str)
				_content.flip = FlipType.parse(str);	
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			var cxml:XML = xml.gearAni[0];
			cxml = xml.gearColor[0];
			if(cxml)
				_gearColor.setup(cxml);
		}
	}
}