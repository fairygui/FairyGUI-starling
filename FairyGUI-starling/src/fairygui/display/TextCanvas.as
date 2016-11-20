package fairygui.display
{
	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.text.TextField;
	
	import fairygui.text.BitmapFont;
	
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.utils.MathUtil;
	
	public class TextCanvas extends MeshExt
	{
		//to save memory. If you dont like this, change to false
		public static var freeTextureOnRemoved:Boolean = true;
		
		private static var sDefaultTextureFormat:String = Context3DTextureFormat.BGRA_PACKED;

		private var _ownsTexture:Boolean;
		private var _restoreFunction:Function;
		private var _needRestore:Boolean;
		
		public function TextCanvas()
		{
			//TextCanvas is by default touchable
			this.touchable = false;
			
			if(freeTextureOnRemoved)
			{
				this.addEventListener(Event.ADDED_TO_STAGE, __addedToStage);
				this.addEventListener(Event.REMOVED_FROM_STAGE, __removeFromStage);
			}
		}
		
		override public function dispose():void
		{
			freeTexture();
			_restoreFunction = null;
			
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
				setRequiresRedraw();
				_restoreFunction = null;
			}
			else
			{
				_restoreFunction = restoreFunc;
				
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
						try
						{
							texture.dispose();
						}
						catch(err:Error)
						{
							
						}
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
				VertexHelper.updateAll(this.vertexData, this.indexData);
				vertexData.colorize("color", 0xFFFFFF);
				setRequiresRedraw();
			}			
		}
		
		public function renderBitmapText(font:BitmapFont, color:uint):void
		{
			_ownsTexture = false;
			this.style.texture = font.mainTexture;
			VertexHelper.updateAll(this.vertexData, this.indexData);
			vertexData.colorize("color", font.colored?color:0xFFFFFF);
			setRequiresRedraw();
		}
		
		public function freeTexture():void
		{
			if(_ownsTexture && this.style.texture!=null)
			{
				this.style.texture.dispose();
				this.style.texture = null;
			}
		}
		
		public function clear():void
		{
			freeTexture();
			
			this.vertexData.numVertices = 0;
			this.indexData.numIndices = 0;
		}
		
		private function __addedToStage(evt:Event):void
		{
			if(_needRestore && _restoreFunction!=null)
				_restoreFunction();
		}
		
		private function __removeFromStage(evt:Event):void
		{
			if(_ownsTexture)
			{
				freeTexture();
				_needRestore = true;
			}
			else
				_needRestore = false;
		}
	}
}