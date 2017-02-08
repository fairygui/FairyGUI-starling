package fairygui
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.LoaderInfo;
	import flash.display3D.Context3DTextureFormat;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import fairygui.display.Frame;
	import fairygui.text.BMGlyph;
	import fairygui.text.BitmapFont;
	import fairygui.utils.GTimers;
	import fairygui.utils.PixelHitTestData;
	import fairygui.utils.ToolSet;
	
	import starling.textures.Texture;
	
	public class UIPackage
	{
		private var _id:String;
		private var _name:String;
		private var _basePath:String;
		private var _items:Vector.<PackageItem>;
		private var _itemsById:Object;
		private var _itemsByName:Object;
		private var _hitTestDatas:Object;
		private var _customId:String;
		private var _sprites:Object;
		
		private var _reader:IUIPackageReader;
		
		internal static var _constructing:int;
		
		private static var _packageInstById:Object = {};
		private static var _packageInstByName:Object = {};
		private static var _bitmapFonts:Object = {};
		private static var _loadingQueue:Array = [];
		private static var _stringsSource:Object = null;
		
		private static var sep0:String = ",";
		private static var sep1:String = "\n";
		private static var sep2:String = " ";
		private static var sep3:String = "=";
		
		public function UIPackage()
		{
			_items = new Vector.<PackageItem>();
			_hitTestDatas = {};
			_sprites = {};
		}
		
		public static function getById(id:String):UIPackage
		{
			return _packageInstById[id];
		}
		
		public static function getByName(name:String):UIPackage
		{
			return _packageInstByName[name];
		}
		
		public static function addPackage(desc:ByteArray, res:ByteArray):UIPackage
		{
			var pkg:UIPackage = new UIPackage();
			var reader:ZipUIPackageReader = new ZipUIPackageReader(desc, res);
			pkg.create(reader);
			_packageInstById[pkg.id] = pkg;
			_packageInstByName[pkg.name] = pkg;
			return pkg;
		}
		
		public static function addPackage2(reader:IUIPackageReader):UIPackage
		{
			var pkg:UIPackage = new UIPackage();
			pkg.create(reader);
			_packageInstById[pkg.id] = pkg;
			_packageInstByName[pkg.name] = pkg;
			return pkg;
		}
		
		public static function removePackage(packageId:String):void
		{
			var pkg:UIPackage = _packageInstById[packageId];
			pkg.dispose();
			delete _packageInstById[pkg.id];
			if(pkg._customId!=null)
				delete _packageInstById[pkg._customId];
			delete _packageInstByName[pkg.name];
		}
		
		public static function createObject(pkgName:String, resName:String, userClass:Object=null):GObject
		{
			var pkg:UIPackage = getByName(pkgName);
			if(pkg)
				return pkg.createObject(resName, userClass);
			else
				return null;
		}
		
		public static function createObjectFromURL(url:String, userClass:Object=null):GObject
		{
			var pi:PackageItem = getItemByURL(url);
			if(pi)
				return pi.owner.internalCreateObject(pi, userClass);
			else
				return null;	
		}
		
		public static function getItemURL(pkgName:String, resName:String):String
		{
			var pkg:UIPackage = getByName(pkgName);
			if(!pkg)
				return null;
			
			var pi:PackageItem = pkg._itemsByName[resName];
			if(!pi)
				return null;
			
			return "ui://"+pkg.id+pi.id;
		}
		
		public static function getItemByURL(url:String):PackageItem
		{
			var pos1:int = url.indexOf("//");
			if (pos1 == -1)
				return null;
			
			var pos2:int = url.indexOf("/", pos1 + 2);
			if (pos2 == -1)
			{
				if (url.length > 13)
				{
					var pkgId:String = url.substr(5, 8);
					var pkg:UIPackage = getById(pkgId);
					if (pkg != null)
					{
						var srcId:String = url.substr(13);
						return pkg.getItemById(srcId);
					}
				}
			}
			else
			{
				var pkgName:String = url.substr(pos1 + 2, pos2 - pos1 - 2);
				pkg = getByName(pkgName);
				if (pkg != null)
				{
					var srcName:String = url.substr(pos2 + 1);
					return pkg.getItemByName(srcName);
				}
			}
			
			return null;
		}
		
		public static function getBitmapFontByURL(url:String):BitmapFont
		{
			return _bitmapFonts[url];
		}
		
		public static function setStringsSource(source:XML):void
		{
			_stringsSource = {};
			var list:XMLList = source.string;
			for each(var xml:XML in list)
			{
				var key:String = xml.@name;
				var text:String = xml.toString();
				var i:int = key.indexOf("-");
				if(i==-1)
					continue;
				
				var key2:String = key.substr(0, i);
				var key3:String = key.substr(i+1);
				var col:Object = _stringsSource[key2];
				if(!col)
				{
					col = {};
					_stringsSource[key2] = col;
				}
				col[key3] = text;
			}
		}
		
		public static function loadingCount():int
		{
			return _loadingQueue.length;
		}
		
		public static function waitToLoadCompleted(callback:Function):void
		{
			GTimers.inst.add(10, 0, checkComplete, callback);
		}
		
		private static function checkComplete(callback:Function):void
		{
			if(_loadingQueue.length==0)
			{
				GTimers.inst.remove(checkComplete);
				callback();
			}
		}
		
		private function create(reader:IUIPackageReader):void
		{
			_reader = reader;

			var ba:ByteArray;
			var str:String;
			var arr:Array;
			
			ba = _reader.readResFile("sprites.bytes");
			str = ba.readUTFBytes(ba.length);
			arr = str.split(sep1);
			var cnt:int = arr.length;
			for (var i:int = 1; i < cnt; i++)
			{
				str = arr[i];
				if (!str)
					continue;
				
				var arr2:Array = str.split(sep2);
				
				var sprite:AtlasSprite = new AtlasSprite();
				var itemId:String = arr2[0];
				var binIndex:int = parseInt(arr2[1]);
				if(binIndex>=0)
					sprite.atlas = "atlas"+binIndex;
				else
				{
					var pos:int = itemId.indexOf("_");
					if(pos==-1)
						sprite.atlas = "atlas_"+itemId;
					else
						sprite.atlas = "atlas_"+itemId.substr(0, pos);
				}
				sprite.rect.x =  parseInt(arr2[2]);
				sprite.rect.y = parseInt(arr2[3]);
				sprite.rect.width = parseInt(arr2[4]);
				sprite.rect.height = parseInt(arr2[5]);
				sprite.rotated = arr2[6] == "1";
				_sprites[itemId] = sprite;
			}
			
			ba = _reader.readResFile("hittest.bytes");
			if(ba!=null)
			{
				while(ba.bytesAvailable)
				{
					var hitTestData:PixelHitTestData = new PixelHitTestData();
					_hitTestDatas[ba.readUTF()] = hitTestData;
					hitTestData.load(ba);
				}
			}
			
			str = _reader.readDescFile("package.xml");
			
			var ignoreWhitespace:Boolean = XML.ignoreWhitespace;
			XML.ignoreWhitespace = true;
			var xml:XML = new XML(str);
			XML.ignoreWhitespace = ignoreWhitespace;
			
			_id = xml.@id;
			_name = xml.@name;
			
			var resources:XMLList = xml.resources.elements();
			
			_itemsById = {};
			_itemsByName = {};
			var pi:PackageItem;
			var cxml:XML;

			for each(cxml in resources)
			{
				pi = new PackageItem();				
				pi.owner = this;
				pi.type = PackageItemType.parseType(cxml.name().localName);
				pi.id = cxml.@id;
				pi.name = cxml.@name;
				pi.file = cxml.@file;
				str = cxml.@size;
				arr = str.split(sep0);
				pi.width = int(arr[0]);
				pi.height = int(arr[1]);
				switch(pi.type)
				{
					case PackageItemType.Image:
					{
						str = cxml.@scale;
						if(str=="9grid")
						{
							pi.scale9Grid = new Rectangle();
							str = cxml.@scale9grid;
							arr = str.split(sep0);
							pi.scale9Grid.x = arr[0];
							pi.scale9Grid.y = arr[1];
							pi.scale9Grid.width = arr[2];
							pi.scale9Grid.height = arr[3];
							
							str = cxml.@gridTile;
							if(str)
								pi.tileGridIndice = parseInt(str);
						}
						else if(str=="tile")
						{
							pi.scaleByTile = true;
						}
						str = cxml.@smoothing;
						pi.smoothing = str!="false";
						break;
					}
						
					case PackageItemType.Component:
						UIObjectFactory.resolvePackageItemExtension(pi);
						break;
				}

				_items.push(pi);
				_itemsById[pi.id] = pi;
				if(pi.name!=null)
					_itemsByName[pi.name] = pi;
			}
			
			cnt = _items.length;
			for (i = 0; i < cnt; i++)
			{
				pi = _items[i];
				if (pi.type == PackageItemType.Font)
				{
					loadFont(pi);
					_bitmapFonts[pi.bitmapFont.id] = pi.bitmapFont;
				}
			}
		}
		
		public function loadAllImages():void
		{
			var cnt:int = _items.length;
			for(var i:int=0;i<cnt;i++)
			{
				var pi:PackageItem = _items[i];
				if(pi.type==PackageItemType.Image)
				{
					if(pi.texture!=null || pi.loading)
						continue;
					
					loadImage(pi);
				}
				else if(pi.type==PackageItemType.Atlas)
				{
					if(pi.texture!=null || pi.loading)
						continue;
					
					loadAtlas(pi);
				}
			}
		}
		
		public function dispose():void
		{
			var cnt:int=_items.length;
			for(var i:int=0;i<cnt;i++)
			{
				var pi:PackageItem = _items[i];
				var texture:Texture = pi.texture;
				if(texture!=null)
					texture.dispose();
				else if(pi.frames!=null)
				{
					var frameCount:int = pi.frames.length;
					for(var j:int=0;j<frameCount;j++)
					{
						texture = pi.frames[j].texture;
						if(texture!=null)
							texture.dispose();
					}
				}
				else if(pi.bitmapFont!=null)
				{
					delete _bitmapFonts[pi.bitmapFont.id];
				}
			}
		}
		
		public function get id():String
		{
			return _id;
		}
		
		public function get name():String
		{
			return _name;
		}
		
		public function get customId():String
		{
			return _customId;
		}
		
		public function set customId(value:String):void
		{
			if (_customId != null)
				delete _packageInstById[_customId];
			_customId = value;
			if (_customId != null)
				_packageInstById[_customId] = this;
		}
		
		public function createObject(resName:String, userClass:Object=null):GObject
		{
			var pi:PackageItem = _itemsByName[resName];
			if(pi)
				return internalCreateObject(pi, userClass);
			else
				return null;
		}
		
		internal function internalCreateObject(item:PackageItem, userClass:Object):GObject
		{
			var g:GObject = null;
			if (item.type == PackageItemType.Component)
			{
				if(userClass!=null)
				{
					if(userClass is Class)
						g = new userClass();
					else
						g = GObject(userClass);
				}
				else
					g = UIObjectFactory.newObject(item);
			}
			else
				g = UIObjectFactory.newObject(item);
			
			if (g == null)
				return null;
			
			_constructing++;
			g.packageItem = item;
			g.constructFromResource();
			_constructing--;
			return g;
		}
		
		public function getItemById(itemId:String):PackageItem
		{
			return _itemsById[itemId];
		}
		
		public function getItemByName(resName:String):PackageItem
		{
			return _itemsByName[resName];
		}
		
		private function getXMLDesc(file:String):XML
		{
			var ignoreWhitespace:Boolean = XML.ignoreWhitespace;
			XML.ignoreWhitespace = true;
			var ret:XML = new XML(_reader.readDescFile(file));
			XML.ignoreWhitespace = ignoreWhitespace;
			return ret;
		}
		
		public function getItemRaw(item:PackageItem):ByteArray
		{
			return _reader.readResFile(item.file);
		}
		
		public function getComponentData(item:PackageItem):XML
		{
			if(!item.componentData)
			{
				var xml:XML = getXMLDesc(item.id+".xml");
				item.componentData = xml;
				
				loadComponentChildren(item);
				translateComponent(item);
			}
			
			return item.componentData;
		}
		
		private function loadComponentChildren(item:PackageItem):void
		{
			var listNode:XML = item.componentData.displayList[0];
			if (listNode != null)
			{
				var col:XMLList = listNode.elements();
				var dcnt:int = col.length();
				item.displayList = new Vector.<DisplayListItem>(dcnt);
				var di:DisplayListItem;
				for (var i:int = 0; i < dcnt; i++)
				{
					var cxml:XML = col[i];
					var tagName:String = cxml.name().localName;
					
					var src:String = cxml.@src;
					if (src)
					{
						var pkgId:String = cxml.@pkg;
						var pkg:UIPackage;
						if (pkgId && pkgId != item.owner.id)
							pkg = UIPackage.getById(pkgId);
						else
							pkg = item.owner;
						
						var pi:PackageItem = pkg != null ? pkg.getItemById(src) : null;
						if (pi != null)
							di = new DisplayListItem(pi, null);
						else
							di = new DisplayListItem(null, tagName);
					}
					else
					{
						if (tagName == "text" && cxml.@input=="true")
							di = new DisplayListItem(null, "inputtext");
						else
							di = new DisplayListItem(null, tagName);
					}
					
					di.desc = cxml;
					item.displayList[i] = di;
				}
			}
			else
				item.displayList =new Vector.<DisplayListItem>(0);
		}
		
		public function getPixelHitTestData(itemId:String):PixelHitTestData
		{
			return _hitTestDatas[itemId];
		}
		
		private function translateComponent(item:PackageItem):void
		{
			if(_stringsSource==null)
				return;
			
			var strings:Object = _stringsSource[this.id + item.id];
			if(strings==null)
				return;
			
			var cnt:int = item.displayList.length;
			var value:*;
			var cxml:XML, dxml:XML;
			for(var i:int=0;i<cnt;i++)
			{
				cxml = item.displayList[i].desc;
				var ename:String = cxml.name().localName;
				var elementId:String = cxml.@id;
				
				if(cxml.@tooltips.length()>0)
				{
					value = strings[elementId+"-tips"];
					if(value!=undefined)
						cxml.@tooltips = value;
				}
				
				dxml = cxml.gearText[0];
				if (dxml)
				{
					value = strings[elementId+"-texts"];
					if(value!=undefined)
						dxml.@values = value;
					
					value = strings[elementId+"-texts_def"];
					if(value!=undefined)
						dxml.@["default"] = value;
				}
				
				if(ename=="text" || ename=="richtext")
				{
					value = strings[elementId];
					if(value!=undefined)
						cxml.@text = value;
					value = strings[elementId+"-prompt"];
					if(value!=undefined)
						cxml.@prompt = value;
				}
				else if(ename=="list")
				{
					var items:XMLList = cxml.item;
					var j:int = 0;
					for each(var exml:XML in items)
					{
						value = strings[elementId+"-"+j];
						if(value!=undefined)
							exml.@title = value;
						j++;
					}
				}
				else if(ename=="component")
				{
					dxml = cxml.Button[0];
					if(dxml)
					{
						value = strings[elementId];
						if(value!=undefined)
							dxml.@title = value;
						value = strings[elementId+"-0"];
						if(value!=undefined)
							dxml.@selectedTitle = value;
						continue;
					}
					
					dxml = cxml.Label[0];
					if(dxml)
					{
						value = strings[elementId];
						if(value!=undefined)
							dxml.@title = value;
						continue;
					}
					
					dxml = cxml.ComboBox[0];
					if(dxml)
					{
						value = strings[elementId];
						if(value!=undefined)
							dxml.@title = value;
						
						items = dxml.item;
						j = 0;
						for each(exml in items)
						{
							value = strings[elementId+"-"+j];
							if(value!=undefined)
								exml.@title = value;
							j++;
						}
						continue;
					}
				}
			}
		}
		
		public function getImage(resName:String):Texture
		{
			var pi:PackageItem = _itemsByName[resName];
			if(pi)
				return pi.texture;
			else
				return null;
		}
		
		public function getSound(item:PackageItem):Sound
		{
			if(!item.loaded)
				loadSound(item);
			return item.sound;
		}
		
		public function addCallback(resName:String, callback:Function):void
		{
			var pi:PackageItem = _itemsByName[resName];
			if(pi)
				addItemCallback(pi, callback);
		}
		
		public function removeCallback(resName:String, callback:Function):void
		{
			var pi:PackageItem = _itemsByName[resName];
			if(pi)
				removeItemCallback(pi, callback);
		}
		
		public function addItemCallback(pi:PackageItem, callback:Function):void
		{
			pi.lastVisitTime = getTimer();
			if(pi.type==PackageItemType.Image)
			{
				if(pi.loaded)
				{
					GTimers.inst.add(0, 1, callback);
					return;	
				}
				
				pi.addCallback(callback);
				if(pi.loading)
					return;
				
				loadImage(pi);
			}
			else if(pi.type==PackageItemType.Atlas)
			{
				if(pi.loaded)
				{
					GTimers.inst.add(0, 1, callback);
					return;	
				}
				
				pi.addCallback(callback);
				if(pi.loading)
					return;
				
				loadAtlas(pi);
			}
			else if(pi.type==PackageItemType.MovieClip)
			{
				if(pi.loaded)
				{
					GTimers.inst.add(0, 1, callback);
					return;	
				}
				
				pi.addCallback(callback);
				if(pi.loading)
					return;
				
				loadMovieClip(pi);
			}
			else if(pi.type==PackageItemType.Swf)
			{
				//pi.addCallback(callback);
				//loadSwf(pi);
			}
			else if(pi.type==PackageItemType.Sound)
			{
				if(!pi.loaded)
					loadSound(pi);
				
				GTimers.inst.add(0, 1, callback);
			}
		}
		
		public function removeItemCallback(pi:PackageItem, callback:Function):void
		{
			pi.removeCallback(callback);
		}
		
		private function loadImage(pi:PackageItem):void 
		{
			var sprite:AtlasSprite = _sprites[pi.id];
			if(!sprite)
			{
				GTimers.inst.callLater(pi.completeLoading);
				return;
			}
			
			var atlasItem:PackageItem = _itemsById[sprite.atlas];
			if (atlasItem != null)
			{
				pi.uvRect = new Rectangle(sprite.rect.x/atlasItem.width, sprite.rect.y/atlasItem.height,
					sprite.rect.width/atlasItem.width, sprite.rect.height/atlasItem.height);
				if(atlasItem.loaded)
				{
					pi.texture = Texture.fromTexture(atlasItem.texture, sprite.rect);
				}
				else
				{
					addItemCallback(atlasItem, pi.onAltasLoaded);
					pi.loading = true;
					return;
				}
			}
			GTimers.inst.callLater(pi.completeLoading);
		}
		
		private function loadAtlas(pi:PackageItem):void
		{
			var ba:ByteArray = _reader.readResFile(pi.file?pi.file:(pi.id+".png"));
			if(ba!=null)
			{
				var loader:PackageItemLoader = new PackageItemLoader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, __atlasLoaded);
				loader.loadBytes(ba);
				
				loader.item = pi;
				pi.loading = true;
				_loadingQueue.push(loader);
			}
			else
			{
				ba = _reader.readResFile(pi.id+".atf");
				if(ba!=null)
				{
					if(pi.texture!=null)
						pi.texture.root.uploadAtfData(ba);
					else
					{
						pi.loading = true;
						_loadingQueue.push(pi);
						Texture.fromAtfData(ba, 1, false, function(texture:Texture):void
						{
							var i:int = _loadingQueue.indexOf(pi);
							if(i==-1)
								return;
							
							_loadingQueue.splice(i, 1);
							
							pi.texture = texture;
							pi.texture.root.onRestore = function():void
							{
								loadAtlas(pi);
							};
							ba.clear();
							pi.completeLoading();
						});
					}
				}
			}
		}
		
		private function __atlasLoaded(evt:Event):void 
		{
			var loader:PackageItemLoader = PackageItemLoader(LoaderInfo(evt.currentTarget).loader);
			var i:int = _loadingQueue.indexOf(loader);
			if(i==-1)
				return;
			
			_loadingQueue.splice(i, 1);
			
			var pi:PackageItem = loader.item; 
			var bmd:BitmapData = Bitmap(loader.content).bitmapData;
			if(pi.texture!=null)
				pi.texture.root.uploadBitmapData(bmd);
			else
			{
				if(bmd.transparent)
					pi.texture = Texture.fromBitmapData(bmd, false);
				else
				{
					var format:String = "BGR_PACKED" in Context3DTextureFormat ? "bgrPacked565" : "bgra";
					pi.texture = Texture.fromBitmapData(bmd, false, false, 1, format);
				}
				pi.texture.root.onRestore = function():void
				{
					loadAtlas(pi);
				};
			}
			bmd.dispose();
			pi.completeLoading();
		}
		
		internal function notifyImageAtlasReady(pi:PackageItem, atlasItem:PackageItem):void
		{
			if(pi.type==PackageItemType.Image)
			{
				var sprite:AtlasSprite = _sprites[pi.id];
				pi.texture = Texture.fromTexture(atlasItem.texture, sprite.rect);
				pi.completeLoading();
			}
			else if(pi.type==PackageItemType.MovieClip)
			{
				var cnt:int = pi.frames.length;
				for(var i:int=0;i<cnt;i++)
				{
					var frame:Frame = pi.frames[i];
					sprite = _sprites[pi.id + "_" + i];
					if(sprite!=null)
						frame.texture = Texture.fromTexture(atlasItem.texture, sprite.rect);
				}
				pi.completeLoading();
			}
			else if(pi.type==PackageItemType.Font)
			{
				pi.bitmapFont.mainTexture = atlasItem.texture;
				pi.completeLoading();
			}
		}
		
		private function loadMovieClip(item:PackageItem):void
		{
			var xml:XML = getXMLDesc(item.id + ".xml");
			var str:String;
			var arr:Array;
			
			str = xml.@interval;
			if (str != null)
				item.interval = parseInt(str);
			str = xml.@swing;
			if (str != null)
				item.swing = str=="true";
			str = xml.@repeatDelay;
			if (str != null)
				item.repeatDelay = parseInt(str);
			
			var atlasItem:PackageItem;
			
			var frameCount:int = parseInt(xml.@frameCount);
			item.frames = new Vector.<Frame>(frameCount);
			var frameNodes:XMLList = xml.frames.elements();
			for (var i:int = 0; i < frameCount; i++)
			{
				var frame:Frame = new Frame();
				var frameNode:XML = frameNodes[i];
				str = frameNode.@rect;
				arr = str.split(sep0);
				frame.rect = new Rectangle(parseInt(arr[0]), parseInt(arr[1]), parseInt(arr[2]), parseInt(arr[3]));
				str = frameNode.@addDelay;
				frame.addDelay = parseInt(str);
				item.frames[i] = frame;
				
				if (frame.rect.width == 0)
					continue;
				
				str = frameNode.@sprite;
				if (str)
					str = item.id + "_" + str;
				else				
					str = item.id + "_" + i;
				
				var sprite:AtlasSprite = _sprites[str];
				if(sprite!=null)
				{
					if(atlasItem==null)
						atlasItem = _itemsById[sprite.atlas];
					if (atlasItem != null && atlasItem.loaded)
						frame.texture = Texture.fromTexture(atlasItem.texture, sprite.rect);
				}
			}
			
			if(atlasItem!=null && !atlasItem.loaded)
			{
				addItemCallback(atlasItem, item.onAltasLoaded);
			}
			else
				GTimers.inst.callLater(item.completeLoading);
		}
		
		private function loadSound(item:PackageItem):void
		{
			var sound:Sound = new Sound();
			var ba:ByteArray = _reader.readResFile(item.file);
			sound.loadCompressedDataFromByteArray(ba, ba.length);
			item.sound = sound;
			item.loaded = true;
		}
		
		private function loadFont(item:PackageItem):void
		{
			var font:BitmapFont = new BitmapFont();
			font.id = "ui://"+this.id+item.id;
			var str:String = _reader.readDescFile(item.id + ".fnt");
			
			var lines:Array = str.split(sep1);
			var lineCount:int = lines.length;
			var i:int;
			var kv:Object = {};
			var ttf:Boolean = false;
			var size:int = 0;
			var resizable:Boolean = false;
			var colored:Boolean = false;
			var xadvance:int = 0;
			var lineHeight:int = 0;
			var atlasOffsetX:int, atlasOffsetY:int;
			var atlasWidth:int, atlasHeight:int;
			var mainTexture:Texture;
			
			for(i=0;i<lineCount;i++)
			{
				str = lines[i];
				if(str.length==0)
					continue;
				
				str = ToolSet.trim(str);
				var arr:Array = str.split(sep2);
				for(var j:int=1;j<arr.length;j++)
				{
					var arr2:Array = arr[j].split(sep3);
					kv[arr2[0]] = arr2[1];
				}
				
				str = arr[0];
				if(str=="char")
				{
					var bg:BMGlyph = new BMGlyph();
					bg.x = kv.x;
					bg.y = kv.y;
					bg.offsetX = kv.xoffset;
					bg.offsetY = kv.yoffset;
					bg.width = kv.width;
					bg.height = kv.height;
					bg.advance = kv.xadvance;
					//todo: kv.chnl未支持 
					
					if(!ttf)
					{
						if(kv.img)
						{
							var charImg:PackageItem = _itemsById[kv.img];
							if(charImg!=null)
							{
								if(charImg.loaded)
								{
									if(mainTexture==null)
										mainTexture = charImg.texture.root;
								}
								else
								{
									loadImage(charImg);
									if(mainTexture==null)
										charImg.addCallback(item.onAltasLoaded);
								}
							
								bg.width = charImg.width;
								bg.height = charImg.height;
								bg.uvRect = charImg.uvRect;
							}
						}
					}
					else
					{
						bg.uvRect = new Rectangle((bg.x + atlasOffsetX)/ atlasWidth, (bg.y + atlasOffsetY) / atlasHeight,
							bg.width / atlasWidth, bg.height / atlasHeight);
					}
					
					if(ttf)
						bg.lineHeight = lineHeight;
					else
					{
						if(bg.advance==0)
						{
							if(xadvance==0)
								bg.advance = bg.offsetX + bg.width;
							else
								bg.advance = xadvance;
						}
						
						bg.lineHeight = bg.offsetY < 0 ? bg.height : (bg.offsetY + bg.height);
						if(size>0 && bg.lineHeight<size)
							bg.lineHeight = size;
					}
					
					font.glyphs[String.fromCharCode(kv.id)] = bg;
				}
				else if(str=="info")
				{
					ttf = kv.face!=null;
					colored = ttf;
					size = kv.size;
					resizable = kv.resizable=="true";
					if(kv.colored!=undefined)
						colored = kv.colored=="true";
					size = kv.size;
					if(ttf)
					{
						var sprite:AtlasSprite = _sprites[item.id];
						if(sprite!=null)
						{
							atlasOffsetX = sprite.rect.x;
							atlasOffsetY = sprite.rect.y;
							var atlasItem:PackageItem = _itemsById[sprite.atlas];
							if (atlasItem != null)
							{
								atlasWidth = atlasItem.width;
								atlasHeight = atlasItem.height;
								if(atlasItem.loaded)
									mainTexture = Texture.fromTexture(atlasItem.texture, sprite.rect);
								else
								{
									addItemCallback(atlasItem, item.onAltasLoaded);
									item.loading = true;
								}
							}
						}
					}
				}
				else if(str=="common")
				{
					lineHeight = kv.lineHeight;
					if(size==0)
						size = lineHeight;
					else if(lineHeight==0)
						lineHeight = size;
					xadvance = kv.xadvance;
				}
			}
			
			if(size==0 && bg)
				size = bg.height;
			
			font.mainTexture = mainTexture;
			font.ttf = ttf;
			font.size = size;
			font.resizable = resizable;
			font.colored = colored;
			item.bitmapFont = font;
		}
	}
}

import flash.display.Loader;
import flash.geom.Rectangle;

import fairygui.PackageItem;
import fairygui.display.Frame;

class PackageItemLoader extends Loader
{
	public function PackageItemLoader():void
	{
		
	}
	public var item:PackageItem;
}

class FrameLoader extends Loader
{
	public function FrameLoader():void
	{
		
	}
	
	public var item:PackageItem;
	public var frame:Frame;
}

class AtlasSprite
{
	public function AtlasSprite():void
	{
		rect = new Rectangle();
	}
	
	public var atlas:String;
	public var rect:Rectangle;
	public var rotated:Boolean;
}