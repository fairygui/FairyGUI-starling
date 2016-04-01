package fairygui.display
{
	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.text.TextField;
	
	import fairygui.text.BitmapFont;
	
	import starling.core.RenderSupport;
	import starling.display.QuadBatch;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.getNextPowerOfTwo;
	
	public class TextCanvas extends FixedSizeObject
	{
		private var _batch:QuadBatch;
		private var _texture:Texture;
		
		public var renderCallback:Function;

		private static var sDefaultTextureFormat:String =
			"BGRA_PACKED" in Context3DTextureFormat ? "bgraPacked4444" : "bgra";
		
		public static var textureMemoryTrack:int = 0;
		
		public function TextCanvas()
		{
			_batch = new QuadBatch();

			//TextCanvas is by default touchable
			this.touchable = false;
		}
		
		override public function dispose():void
		{
			clear();
			_batch.dispose();
			renderCallback = null;
			
			super.dispose();
		}
		
		public function setCanvasSize(width:Number, height:Number):void
		{
			setSize(width, height);
		}
		
		public function renderText(nativeTextField:TextField, textWidth:int, textHeight:int, restoreFunc:Function):void
		{
			var nw:int = nativeTextField.width;
			if(textWidth==0 || textHeight==0 || nw==0)
			{
				clear();
			}
			else
			{
				var bw:int, bh:int;
				bw = getNextPowerOfTwo(nw);
				if(bw>2048)
					bw = 2048;
				bh = getNextPowerOfTwo(textHeight);
				if(bh>2048)
					bh = 2048;
				
				var bmd:BitmapData =  new BitmapData(bw,bh,true,0);
				bmd.draw(nativeTextField);
				
				if(_texture==null)
				{
					_texture = Texture.fromBitmapData(bmd, false, false, 1, sDefaultTextureFormat);
					textureMemoryTrack += _texture.width*_texture.height*4;
				}
				else
				{
					if(bw<_texture.width && bh<_texture.height)
						_texture.root.uploadBitmapData(bmd);
					else
					{
						textureMemoryTrack -= textureMemory;
						_texture.dispose();
						_texture = Texture.fromBitmapData(bmd, false, false, 1, sDefaultTextureFormat);
						textureMemoryTrack += textureMemory;
					}
				}
				_texture.root.onRestore = restoreFunc;

				bmd.dispose();
				
				_batch.reset();
				
				VertexHelper.beginFill();
				VertexHelper.color = 0xffffff;
				VertexHelper.addQuad(0, 0, bw, bh);
				VertexHelper.fillUV4(_texture);
				VertexHelper.flush(_batch, _texture, 1.0, TextureSmoothing.BILINEAR);
			}
		}
		
		public function renderBitmapText(font:BitmapFont):void
		{
			VertexHelper.flush(_batch, font.mainTexture, 1, TextureSmoothing.BILINEAR);
		}
		
		public function get textureMemory():int
		{
			if(_texture!=null) 
				return _texture.width*_texture.height*4;
			else
				return 0;
		}
		
		public function clear():void
		{
			_batch.reset();
			if(_texture!=null)
			{
				textureMemoryTrack -= textureMemory;
				_texture.dispose();
				_texture = null;
			}
		}

		override public function render(support:RenderSupport, parentAlpha:Number):void
		{
			if(renderCallback!=null)
				renderCallback();
			
			if(_batch.numQuads>0)
				support.batchQuadBatch(_batch, this.alpha*parentAlpha);
		}
	}
}