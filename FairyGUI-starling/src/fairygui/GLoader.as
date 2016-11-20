package fairygui
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	import fairygui.display.ImageExt;
	import fairygui.display.MovieClip;
	import fairygui.display.UISprite;
	import fairygui.utils.ToolSet;
	
	import starling.display.DisplayObject;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;

	public class GLoader extends GObject implements IColorGear, IAnimationGear
	{
		private var _url:String;
		private var _align:int;
		private var _verticalAlign:int;
		private var _autoSize:Boolean;
		private var _fill:int;
		private var _showErrorSign:Boolean;
		private var _playing:Boolean;
		private var _frame:int;
		private var _color:uint;
		
		private var _contentItem:PackageItem;
		private var _contentSourceWidth:int;
		private var _contentSourceHeight:int;
		private var _contentWidth:int;
		private var _contentHeight:int;
		
		private var _container:UISprite;
		private var _image:ImageExt;
		private var _movieClip:MovieClip;
		private var _activeObject:DisplayObject;
		private var _errorSign:GObject;
		
		private var _updatingLayout:Boolean;
		
		private var _loading:int;
		private var _externalLoader:Loader;
		
		private static var _errorSignPool:GObjectPool = new GObjectPool();
		
		public function GLoader()
		{
			_playing = true;
			_url = "";
			_align = AlignType.Left;
			_verticalAlign = VertAlignType.Top;
			_showErrorSign = true;
			_color = 0xFFFFFF;
		}
		
		override protected function createDisplayObject():void
		{
			_container = new UISprite(this);
			_container.hitArea = new Rectangle();
			setDisplayObject(_container);
			
			_image = new ImageExt();
			_container.addChild(_image);
		}
		
		public override function dispose():void
		{
			if(_contentItem!=null)
			{
				if(_loading==1)
					_contentItem.owner.removeItemCallback(_contentItem, __imageLoaded);
				else if(_loading==2)
					_contentItem.owner.removeItemCallback(_contentItem, __movieClipLoaded);
			}
			else
			{
				//external
				if(_image.texture!=null)
					freeExternal(_image.texture);
			}
			
			_image.dispose();
			if (_movieClip != null)
				_movieClip.dispose();

			super.dispose();
		}

		public function get url():String
		{
			return _url;
		}

		public function set url(value:String):void
		{
			if(_url==value)
				return;
			
			_url = value;
			loadContent();
			updateGear(7);
		}
		
		override public function get icon():String
		{
			return _url;
		}
		
		override public function set icon(value:String):void
		{
			this.url = value;
		}
		
		public function get align():int
		{
			return _align;
		}
		
		public function set align(value:int):void
		{
			if(_align!=value)
			{
				_align = value;
				updateLayout();
			}
		}
		
		public function get verticalAlign():int
		{
			return _verticalAlign;
		}
		
		public function set verticalAlign(value:int):void
		{
			if(_verticalAlign!=value)
			{
				_verticalAlign = value;
				updateLayout();
			}
		}
		
		public function get fill():int
		{
			return _fill;
		}
		
		public function set fill(value:int):void
		{
			if(_fill!=value)
			{
				_fill = value;
				updateLayout();
			}
		}		
		
		public function get autoSize():Boolean
		{
			return _autoSize;
		}
		
		public function set autoSize(value:Boolean):void
		{
			if(_autoSize!=value)
			{
				_autoSize = value;
				updateLayout();
			}
		}

		public function get playing():Boolean
		{
			return _playing;
		}
		
		public function set playing(value:Boolean):void
		{
			if(_playing!=value)
			{
				_playing = value;
				if(_movieClip!=null)
					_movieClip.playing = value;
				updateGear(5);
			}
		}
		
		public function get frame():int
		{
			return _frame;
		}
		
		public function set frame(value:int):void
		{
			if(_frame!=value)
			{
				_frame = value;
				if(_movieClip!=null)
					_movieClip.currentFrame = value;
				updateGear(5);
			}
		}
		
		public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void 
		{
			if(_color != value)
			{
				_color = value;
				updateGear(4);
				applyColor();
			}
		}
		
		private function applyColor():void
		{
			_image.color = _color;
			if(_movieClip!=null)
				_movieClip.color = _color;
		}

		public function get showErrorSign():Boolean
		{
			return _showErrorSign;
		}
		
		public function set showErrorSign(value:Boolean):void
		{
			_showErrorSign = value;
		}
		
		public function get fillMethod():int
		{
			return _image.fillMethod;
		}
		
		public function set fillMethod(value:int):void
		{
			_image.fillMethod = value;
		}
		
		public function get fillOrigin():int
		{
			return _image.fillOrigin;
		}
		
		public function set fillOrigin(value:int):void
		{
			_image.fillOrigin = value;
		}
		
		public function get fillAmount():Number
		{
			return _image.fillAmount;
		}
		
		public function set fillAmount(value:Number):void
		{
			_image.fillAmount = value;
		}
		
		public function get fillClockwise():Boolean
		{
			return _image.fillClockwise;
		}
		
		public function set fillClockwise(value:Boolean):void
		{
			_image.fillClockwise = value;
		}
		
		public function get texture():Texture
		{
			return _image.texture;
		}

		public function set texture(value:Texture):void
		{
			this.url = null;
			
			_image.texture = value;
			if (value != null) {
				_contentSourceWidth = value.width;
				_contentSourceHeight = value.height;
			}
			else 
				_contentSourceWidth = _contentHeight = 0;
			
			updateLayout();
		}
		
		protected function loadContent():void
		{
			clearContent();
			
			if(!_url)
				return;

			if(ToolSet.startsWith(_url, "ui://"))
				loadFromPackage(_url);
			else
				loadExternal();
		}
		
		protected function loadFromPackage(itemURL:String):void
		{
			_contentItem = UIPackage.getItemByURL(itemURL);
			if(_contentItem!=null)
			{
				if(_contentItem.type==PackageItemType.Image)
				{
					if(_contentItem.loaded)
						__imageLoaded(_contentItem);
					else
					{
						_loading = 1;
						_contentItem.owner.addItemCallback(_contentItem, __imageLoaded);
					}
				}
				else if(_contentItem.type==PackageItemType.MovieClip)
				{
					if(_contentItem.loaded)
						__movieClipLoaded(_contentItem);
					else
					{
						_loading = 2;
						_contentItem.owner.addItemCallback(_contentItem, __movieClipLoaded);
					}
				}
				else
					setErrorState();
			}
			else
				setErrorState();
		}
		
		private function __imageLoaded(pi:PackageItem):void
		{
			_loading = 0;

			if(pi.texture==null)
			{
				setErrorState();
			}
			else
			{
				_activeObject = _image;
				_image.texture = pi.texture;
				_image.scale9Grid = pi.scale9Grid;
				_image.scaleByTile = pi.scaleByTile;
				_image.tileGridIndice = pi.tileGridIndice;
				_image.textureSmoothing = pi.smoothing?TextureSmoothing.BILINEAR:TextureSmoothing.NONE;
				_image.color = _color;
				_contentSourceWidth = pi.width;
				_contentSourceHeight = pi.height;
				updateLayout();
			}
		}
		
		private function __movieClipLoaded(pi:PackageItem):void
		{
			_loading = 0;
			if (_movieClip == null)
			{
				_movieClip = new MovieClip();
				_container.addChild(_movieClip);
			}
			
			_activeObject = _movieClip;
			_contentSourceWidth = pi.width;
			_contentSourceHeight = pi.height;
			_movieClip.interval = pi.interval;
			_movieClip.swing = pi.swing;
			_movieClip.repeatDelay = pi.repeatDelay;
			_movieClip.frames = pi.frames;
			_movieClip.boundsRect = new Rectangle(0,0,_contentSourceWidth,_contentSourceHeight);
			
			updateLayout();
		}
		
		protected function loadExternal():void
		{
			if(!_externalLoader)
			{
				_externalLoader = new Loader();
				_externalLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, __externalLoadCompleted);
				_externalLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, __externalLoadFailed);
			}
			_externalLoader.load(new URLRequest(url));
		}
		
		protected function freeExternal(texture:Texture):void
		{
			texture.dispose();
		}
		
		final protected function onExternalLoadSuccess(texture:Texture):void
		{
			_activeObject = _image;
			_image.texture = texture;
			_image.scale9Grid = null;
			_image.scaleByTile = false;
			_image.color = _color;
			_contentSourceWidth = texture.width;
			_contentSourceHeight = texture.height;
			updateLayout();
		}
		
		final protected function onExternalLoadFailed():void
		{
			setErrorState();
		}
		
		private function __externalLoadCompleted(evt:Event):void
		{
			var cc:flash.display.DisplayObject = _externalLoader.content;
			if(cc is Bitmap)
			{
				var bmd:BitmapData = Bitmap(cc).bitmapData;
				var texture:Texture = Texture.fromBitmapData(bmd, false);
				bmd.dispose();
				texture.root.onRestore = loadContent;
				onExternalLoadSuccess(texture);				
			}
			else
				onExternalLoadFailed();
		}

		private function __externalLoadFailed(evt:Event):void
		{
			onExternalLoadFailed();
		}
		
		private function setErrorState():void
		{
			if (!_showErrorSign)
				return;
			
			if (_errorSign == null)
			{
				if (UIConfig.loaderErrorSign != null)
				{
					_errorSign = _errorSignPool.getObject(UIConfig.loaderErrorSign);
				}
			}
			
			if (_errorSign != null)
			{
				_errorSign.width = this.width;
				_errorSign.height = this.height;
				_container.addChild(_errorSign.displayObject);
			}
		}
		
		private function clearErrorState():void
		{
			if (_errorSign != null)
			{
				_container.removeChild(_errorSign.displayObject);
				_errorSignPool.returnObject(_errorSign);
				_errorSign = null;
			}
		}
		
		private function updateLayout():void
		{
			if(_activeObject==null)
			{
				if(_autoSize)
				{
					_updatingLayout = true;
					this.setSize(50, 30);
					_updatingLayout = false;
				}
				return;
			}
			
			_activeObject.x = 0;
			_activeObject.y = 0;
			_contentWidth = _contentSourceWidth;
			_contentHeight = _contentSourceHeight;
			
			if(_autoSize)
			{
				_updatingLayout = true;
				
				if(_activeObject is ImageExt)
				{
					ImageExt(_activeObject).textureScaleX = 1;
					ImageExt(_activeObject).textureScaleY = 1;
				}
				else
				{
					_activeObject.scaleX =  1;
					_activeObject.scaleY =  1;
				}
				
				if(_contentWidth==0)
					_contentWidth = 50;
				if(_contentHeight==0)
					_contentHeight = 30;
				this.setSize(_contentWidth, _contentHeight);
				
				_updatingLayout = false;
			}
			else
			{
				var sx:Number = 1, sy:Number = 1;
				if(_fill!=LoaderFillType.None)
				{
					sx = this.width/_contentSourceWidth;
					sy = this.height/_contentSourceHeight;
					
					if(sx!=1 || sy!=1)
					{
						if (_fill == LoaderFillType.ScaleMatchHeight)
							sx = sy;
						else if (_fill == LoaderFillType.ScaleMatchWidth)
							sy = sx;
						else if (_fill == LoaderFillType.Scale)
						{
							if (sx > sy)
								sx = sy;
							else
								sy = sx;
						}
						_contentWidth = _contentSourceWidth * sx;
						_contentHeight = _contentSourceHeight * sy;
					}
				}
				
				if(_activeObject is ImageExt)
				{
					ImageExt(_activeObject).textureScaleX = sx;
					ImageExt(_activeObject).textureScaleY = sy;
				}
				else
				{
					_activeObject.scaleX =  sx;
					_activeObject.scaleY =  sy;
				}
				
				if(_align==AlignType.Center)
					_activeObject.x = int((this.width-_contentWidth)/2);
				else if(_align==AlignType.Right)
					_activeObject.x = this.width-_contentWidth;
				if(_verticalAlign==VertAlignType.Middle)
					_activeObject.y = int((this.height-_contentHeight)/2);
				else if(_verticalAlign==VertAlignType.Bottom)
					_activeObject.y = this.height-_contentHeight;
			}
		}
		
		private function clearContent():void 
		{
			clearErrorState();
			
			if(_contentItem!=null)
			{
				if(_loading==1)
					_contentItem.owner.removeItemCallback(_contentItem, __imageLoaded);
				else if(_loading==2)
					_contentItem.owner.removeItemCallback(_contentItem, __movieClipLoaded);
			}
			else
			{			
				//external
				if(_image.texture!=null)
					freeExternal(_image.texture);
			}
			
			_image.texture = null;
			if(_movieClip!=null)
				_movieClip.frames = null;

			_activeObject = null;
			_contentItem = null;
			_loading = 0;
		}
		
		override protected function handleSizeChanged():void
		{
			if(!_updatingLayout)
				updateLayout();
			
			_container.hitArea.setTo(0,0,this.width,this.height);
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String;
			str = xml.@url;
			if(str)
				_url = str;
			
			str = xml.@align;
			if(str)
				_align = AlignType.parse(str);
			
			str = xml.@vAlign;
			if(str)
				_verticalAlign = VertAlignType.parse(str);
			
			str = xml.@fill;
			if(str)
				_fill = LoaderFillType.parse(str);
			
			_autoSize = xml.@autoSize=="true";	
			
			str = xml.@errorSign;
			if(str)
				_showErrorSign = str=="true";
			
			_playing = xml.@playing != "false";
			
			str = xml.@color;
			if(str)
				this.color = ToolSet.convertFromHtmlColor(str);
			
			str = xml.@fillMethod;
			if (str)
				_image.fillMethod = FillType.parseFillMethod(str);
			
			if (_image.fillMethod != FillType.FillMethod_None)
			{
				str = xml.@fillOrigin;
				if(str)
					_image.fillOrigin = parseInt(str); 
				_image.fillClockwise = xml.@fillClockwise!="false";
				str = xml.@fillAmount;
				if(str)
					_image.fillAmount = parseInt(str) / 100;
			}
			
			if(_url)
				loadContent();
		}
	}
}