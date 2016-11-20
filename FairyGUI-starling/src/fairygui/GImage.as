package fairygui
{
	import fairygui.display.ImageExt;
	import fairygui.display.UIImage;
	import fairygui.utils.ToolSet;
	
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;

	public class GImage extends GObject implements IColorGear
	{
		private var _content:ImageExt;
		
		public function GImage()
		{
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
				updateGear(4);
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
		
		public function get fillMethod():int
		{
			return _content.fillMethod;
		}
		
		public function set fillMethod(value:int):void
		{
			_content.fillMethod = value;
		}
		
		public function get fillOrigin():int
		{
			return _content.fillOrigin;
		}
		
		public function set fillOrigin(value:int):void
		{
			_content.fillOrigin = value;
		}
		
		public function get fillAmount():Number
		{
			return _content.fillAmount;
		}
		
		public function set fillAmount(value:Number):void
		{
			_content.fillAmount = value;
		}
		
		public function get fillClockwise():Boolean
		{
			return _content.fillClockwise;
		}
		
		public function set fillClockwise(value:Boolean):void
		{
			_content.fillClockwise = value;
		}
		
		public function get texture():Texture {
			return _content.texture;
		}
		
		public function set texture(value:Texture):void {
			if (value != null)
			{
				this._sourceWidth = value.width;
				this._sourceHeight = value.height;
			}
			else
			{
				this._sourceWidth = 0;
				this._sourceHeight = 0;
			}
			this._initWidth =  this._sourceWidth;
			this._initHeight = this._sourceHeight;
			this._content.scale9Grid = null;
			this._content.scaleByTile = false;
			this._content.texture = value;
		}
		
		override protected function createDisplayObject():void
		{ 
			_content = new UIImage(this);
			setDisplayObject(_content);
		}
		
		override public function dispose():void
		{
			if(!packageItem.loaded)
				packageItem.owner.removeItemCallback(packageItem, __imageLoaded);
			super.dispose();
		}
		
		override public function constructFromResource():void
		{
			_sourceWidth = packageItem.width;
			_sourceHeight = packageItem.height;
			_initWidth = _sourceWidth;
			_initHeight = _sourceHeight;
			
			setSize(_sourceWidth, _sourceHeight);
			
			if(packageItem.loaded)
				__imageLoaded(packageItem);
			else
				packageItem.owner.addItemCallback(packageItem, __imageLoaded);
		}

		private function __imageLoaded(pi:PackageItem):void
		{
			if(pi.texture!=null)
			{
				_content.texture = pi.texture;
				_content.scale9Grid = pi.scale9Grid;
				_content.scaleByTile = pi.scaleByTile;
				_content.tileGridIndice = pi.tileGridIndice;
				_content.textureSmoothing = pi.smoothing?TextureSmoothing.BILINEAR:TextureSmoothing.NONE;
			}
			
			handleSizeChanged();
		}
		
		override protected function handleSizeChanged():void
		{
			_content.textureScaleX = this.width/this.sourceWidth;
			_content.textureScaleY = this.height/this.sourceHeight;
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
			
			str = xml.@fillMethod;
			if (str)
				_content.fillMethod = FillType.parseFillMethod(str);
			
			if (_content.fillMethod != FillType.FillMethod_None)
			{
				str = xml.@fillOrigin;
				if(str)
					_content.fillOrigin = parseInt(str); 
				_content.fillClockwise = xml.@fillClockwise!="false";
				str = xml.@fillAmount;
				if(str)
					_content.fillAmount = parseInt(str) / 100;
			}
		}
	}
}