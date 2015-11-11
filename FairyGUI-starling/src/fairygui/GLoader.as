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
		private var _gearAnimation:GearAnimation;
		private var _gearColor:GearColor;
		
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
		private var _content:DisplayObject;
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
			
			_gearAnimation = new GearAnimation(this);
			_gearColor = new GearColor(this);
		}
		
		override protected function createDisplayObject():void
		{
			_container = new UISprite(this);
			_container.hitArea = new Rectangle();
			_container.scaleX = GRoot.contentScaleFactor;
			_container.scaleY = GRoot.contentScaleFactor;
			setDisplayObject(_container);
		}
		
		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			if(_gearAnimation.controller==c)
				_gearAnimation.apply();
			if(_gearColor.controller==c)
				_gearColor.apply();
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
				if((_content is ImageExt) && ImageExt(_content).texture!=null)
					freeExternal(ImageExt(_content).texture);
			}
			
			//_content will dispose in super.dispose
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
				if(_content is MovieClip)
					MovieClip(_content).playing = value;

				if (_gearAnimation.controller != null)
					_gearAnimation.updateState();
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
				if(_content is MovieClip)
					MovieClip(_content).currentFrame = value;
				
				if (_gearAnimation.controller != null)
					_gearAnimation.updateState();
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
				if (_gearColor.controller != null)
					_gearColor.updateState();
				applyColor();
			}
		}
		
		private function applyColor():void
		{
			if(_content is ImageExt)
				ImageExt(_content).color = _color;
		}

		public function get showErrorSign():Boolean
		{
			return _showErrorSign;
		}
		
		public function set showErrorSign(value:Boolean):void
		{
			_showErrorSign = value;
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
				if(!(_content is ImageExt))
				{
					if(_content!=null)
						_content.dispose();
					_content = new ImageExt();
					_container.addChild(_content);
				}
				else
					_container.addChild(_content);
				ImageExt(_content).texture = pi.texture;
				ImageExt(_content).scale9Grid = pi.scale9Grid;
				ImageExt(_content).scaleByTile = pi.scaleByTile;
				ImageExt(_content).smoothing = pi.smoothing?TextureSmoothing.BILINEAR:TextureSmoothing.NONE;
				ImageExt(_content).color = _color;
				_contentSourceWidth = pi.width;
				_contentSourceHeight = pi.height;
				updateLayout();
			}
		}
		
		private function __movieClipLoaded(pi:PackageItem):void
		{
			_loading = 0;
			if(!(_content is MovieClip))
			{
				if(_content!=null)
					_content.dispose();
				
				_content = new MovieClip();
				_container.addChild(_content);
			}
			else
				_container.addChild(_content);
			
			_contentSourceWidth = pi.width;
			_contentSourceHeight = pi.height;
			MovieClip(_content).interval = pi.interval;
			MovieClip(_content).frames = pi.frames;
			MovieClip(_content).boundsRect = new Rectangle(0,0,_contentSourceWidth,_contentSourceHeight);
			
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
			if(!(_content is ImageExt))
			{
				if(_content!=null)
					_content.dispose();
				
				_content = new ImageExt();
				_container.addChild(_content);
			}
			else
				_container.addChild(_content);
			ImageExt(_content).texture = texture;
			ImageExt(_content).scale9Grid = null;
			ImageExt(_content).scaleByTile = false;
			ImageExt(_content).color = _color;
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
			if(_content==null)
			{
				if(_autoSize)
				{
					_updatingLayout = true;
					this.setSize(50, 30);
					_updatingLayout = false;
				}
				return;
			}
			
			_content.x = 0;
			_content.y = 0;
			_content.scaleX = 1;
			_content.scaleY = 1;
			_contentWidth = _contentSourceWidth;
			_contentHeight = _contentSourceHeight;
			
			if(_autoSize)
			{
				_updatingLayout = true;
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
				if(_fill==FillType.Scale || _fill==FillType.ScaleFree)
				{
					sx = this.width/_contentSourceWidth;
					sy = this.height/_contentSourceHeight;
					
					if(sx!=1 || sy!=1)
					{
						if(_fill==FillType.Scale)
						{
							if(sx>sy)
								sx = sy;
							else
								sy = sx;
						}
						_contentWidth = _contentSourceWidth * sx;
						_contentHeight = _contentSourceHeight * sy;
					}
				}	
				
				_content.scaleX =  sx;
				_content.scaleY =  sy;
				
				if(_align==AlignType.Center)
					_content.x = int((this.width-_contentWidth)/2);
				else if(_align==AlignType.Right)
					_content.x = this.width-_contentWidth;
				if(_verticalAlign==VertAlignType.Middle)
					_content.y = int((this.height-_contentHeight)/2);
				else if(_verticalAlign==VertAlignType.Bottom)
					_content.y = this.height-_contentHeight;
			}
		}
		
		private function clearContent():void 
		{
			clearErrorState();
			
			if(_content!=null && _content.parent!=null) 
				_container.removeChild(_content);
			
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
				if((_content is ImageExt) && ImageExt(_content).texture!=null)
					freeExternal(ImageExt(_content).texture);
			}
			
			if(_content is ImageExt)
				ImageExt(_content).texture = null;
			else if(_content is MovieClip)
				MovieClip(_content).frames = null;

			_contentItem = null;
			_loading = 0;
		}
		
		override protected function handleSizeChanged():void
		{
			if(!_updatingLayout)
				updateLayout();
			
			_container.hitArea.setTo(0,0,this.width,this.height);
			_container.scaleX = this.scaleX * GRoot.contentScaleFactor;
			_container.scaleY = this.scaleY * GRoot.contentScaleFactor;
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
				_fill = FillType.parse(str);
			
			_autoSize = xml.@autoSize=="true";	
			
			str = xml.@errorSign;
			if(str)
				_showErrorSign = str=="true";
			
			_playing = xml.@playing != "false";
			
			str = xml.@color;
			if(str)
				this.color = ToolSet.convertFromHtmlColor(str);
			
			if(_url)
				loadContent();
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			var cxml:XML = xml.gearAni[0];
			if(cxml)
				_gearAnimation.setup(cxml);
			cxml = xml.gearAni[0];
			cxml = xml.gearColor[0];
			if(cxml)
				_gearColor.setup(cxml);
		}
	}
}