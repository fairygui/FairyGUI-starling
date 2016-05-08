package fairygui.display
{
	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.text.TextField;
	
	import fairygui.text.BitmapFont;
	
	import starling.rendering.Painter;
	import starling.textures.Texture;
	import starling.utils.MathUtil;
	
	public class TextCanvas extends MeshExt
	{
		public var renderCallback:Function;

		private static var sDefaultTextureFormat:String = Context3DTextureFormat.BGRA_PACKED;

		private var _ownsTexture:Boolean;
		
		public function TextCanvas()
		{
			//TextCanvas is by default touchable
			this.touchable = false;
		}
		
		override public function dispose():void
		{
			clear();

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
				bw = MathUtil.getNextPowerOfTwo(nw);
				if(bw>2048)
					bw = 2048;
				bh = MathUtil.getNextPowerOfTwo(textHeight);
				if(bh>2048)
					bh = 2048;
				
				var bmd:BitmapData =  new BitmapData(bw,bh,true,0);
				bmd.draw(nativeTextField);
				
				var texture:Texture = this.style.texture;
				if(texture==null)
				{
					texture = Texture.fromBitmapData(bmd, false, false, 1, sDefaultTextureFormat);
					this.style.texture = texture;
				}
				else
				{
					if(bw<texture.width && bh<texture.height)
						texture.root.uploadBitmapData(bmd);
					else
					{
						texture.dispose();
						texture = Texture.fromBitmapData(bmd, false, false, 1, sDefaultTextureFormat);
						this.style.texture = texture;
					}
				}
				texture.root.onRestore = restoreFunc;
				_ownsTexture = true;
				
				bmd.dispose();
				
				VertexHelper.beginFill();
				VertexHelper.addQuad(0, 0, bw, bh);
				VertexHelper.fillUV4(texture);
				VertexHelper.flush(this.vertexData, this.indexData);
				vertexData.colorize("color", 0xFFFFFF);
				setRequiresRedraw();
			}			
		}
		
		public function renderBitmapText(font:BitmapFont, color:uint):void
		{
			_ownsTexture = false;
			this.style.texture = font.mainTexture;
			this.vertexData.premultipliedAlpha = font.mainTexture.premultipliedAlpha;
			VertexHelper.flush(this.vertexData, this.indexData);
			vertexData.colorize("color", color);
			setRequiresRedraw();
		}
		
		public function clear():void
		{
			if(_ownsTexture && this.texture!=null)
			{
				this.style.texture.dispose();
				this.style.texture = null;
				setRequiresRedraw();
			}
		}

		override public function render(painter:Painter):void
		{
			if(renderCallback!=null)
				renderCallback();
			
			super.render(painter);
		}
	}
}