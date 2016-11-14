package fairygui.display
{
	import flash.geom.Rectangle;
	
	import fairygui.FillType;
	import fairygui.FlipType;
	
	import starling.rendering.Painter;
	import starling.textures.Texture;

	public class ImageExt extends MeshExt
	{		
		private var _color:uint;
		private var _flip:int;
		private var _fillMethod:int;
		private var _fillOrigin:int;
		private var _fillAmount:Number;
		private var _fillClockwise:Boolean;
		private var _textureScaleX:Number;
		private var _textureScaleY:Number;
		
		private var _scaleByTile:Boolean;
		private var _scale9Grid:Rectangle;
		private var _tileGridIndice:int;
		
		public function ImageExt()
		{			
			super();
			
			//ImageExt is by default not touchable
			this.touchable = false;
			_color = 0xFFFFFF;

			_textureScaleX = 1;
			_textureScaleY = 1;
			_fillAmount = 100;
			_fillClockwise = true;
		}

		override public function get color():uint
		{
			return _color;
		}
		
		override public function set color(value:uint):void
		{
			_color = value;
			this.style.color = value;
		}
		
		public function get fillMethod():int
		{
			return _fillMethod;
		}
		
		public function set fillMethod(value:int):void
		{
			if(_fillMethod != value)
			{
				_fillMethod = value;
				setRequiresRebuild();
			}
		}
		
		public function get fillOrigin():int
		{
			return _fillOrigin;
		}

		public function set fillOrigin(value:int):void
		{
			if(_fillOrigin != value)
			{
				_fillOrigin = value;
				setRequiresRebuild();
			}
		}

		public function get fillAmount():Number
		{
			return _fillAmount;
		}

		public function set fillAmount(value:Number):void
		{
			if(_fillAmount != value)
			{
				_fillAmount = value;
				setRequiresRebuild();
			}
		}

		public function get fillClockwise():Boolean
		{
			return _fillClockwise;
		}

		public function set fillClockwise(value:Boolean):void
		{
			if(_fillClockwise != value)
			{
				_fillClockwise = value;
				setRequiresRebuild();
			}
		}

		override public function set texture(value:Texture):void
		{
			if (value != texture)
			{
				super.texture = value;
				if(this.texture!=null)
				{
					vertexData.premultipliedAlpha = value.premultipliedAlpha;
					setSize(this.texture.width * _textureScaleX, this.texture.height * _textureScaleY);
				}
				else
					setSize(0,0);
				setRequiresRebuild();
			}
		}
		
		public function get flip():int
		{
			return _flip;
		}
		
		public function set flip(value:int):void
		{
			if(_flip!=value)
			{
				_flip = value;
				setRequiresRebuild();
			}
		}

		public function get scale9Grid():Rectangle
		{
			return _scale9Grid;
		}
		
		public function set scale9Grid(value:Rectangle):void
		{
			_scale9Grid = value;
			setRequiresRebuild();
		}
		
		public function get scaleByTile():Boolean
		{
			return _scaleByTile;
		}
		
		public function set scaleByTile(value:Boolean):void
		{
			if(_scaleByTile!=value)
			{
				_scaleByTile = value;
				setRequiresRebuild();
			}
		}
		
		public function get tileGridIndice():int
		{
			return _tileGridIndice;
		}
		
		public function set tileGridIndice(value:int):void
		{
			if(_tileGridIndice != value)
			{
				_tileGridIndice = value;
				setRequiresRebuild();
			}
		}
		
		public function get textureScaleX():Number
		{
			return _textureScaleX;
		}
		
		public function set textureScaleX(value:Number):void
		{
			if(_textureScaleX != value)
			{
				_textureScaleX = value;
				if(this.texture!=null)
					setSize(this.texture.width * _textureScaleX, this.texture.height * _textureScaleY);
				setRequiresRebuild();
			}
		}
		
		public function get textureScaleY():Number
		{
			return _textureScaleY;
		}
		
		public function set textureScaleY(value:Number):void
		{
			if(_textureScaleY != value)
			{
				_textureScaleY = value;
				if(this.texture!=null)
					setSize(this.texture.width * _textureScaleX, this.texture.height * _textureScaleY);
				setRequiresRebuild();
			}
		}

		override public function render(painter:Painter):void
		{
			if(_needRebuild)
				rebuild();

			super.render(painter);
		}
		
		private static var vertRect:Rectangle = new Rectangle();
		private static var uvRect:Rectangle = new Rectangle();
		private static var tileIndice:Array = [ -1, 0, -1, 2, 4, 3, -1, 1, -1 ];
		
		private function rebuild():void
		{
			_needRebuild = false;
			
			var texture:Texture = this.texture;
			if(texture==null)
			{
				this.vertexData.clear();
				this.indexData.clear();
				return;
			}

			VertexHelper.getTextureUV(texture, uvRect);
			if(_flip!=0)
				VertexHelper.flipUV(uvRect, _flip);
			vertRect.copyFrom(_bounds);
			
			VertexHelper.beginFill();
			var i:int, j:int;
			
			if (_fillMethod != FillType.FillMethod_None)
			{
				VertexHelper.fillImage(_fillMethod, _fillAmount, _fillOrigin, _fillClockwise, vertRect, uvRect);
			}
			else if(_textureScaleX==1 && _textureScaleY==1)
			{
				VertexHelper.addQuad2(vertRect);
				VertexHelper.fillUV2(uvRect);
			}
			else if (_scaleByTile)
			{
				doTile(texture.width, texture.height, vertRect, uvRect);
			}
			else if(_scale9Grid!=null)
			{				
				var gridRect:Rectangle;
				if(_flip!=FlipType.None)
				{
					gridRect = _scale9Grid.clone();
					if(_flip==FlipType.Horizontal || _flip==FlipType.Both)
					{
						gridRect.x = texture.width - gridRect.right;
						gridRect.right = gridRect.x + gridRect.width;
					}
					
					if(_flip==FlipType.Vertical || _flip==FlipType.Both)
					{
						gridRect.y = texture.height - gridRect.bottom;
						gridRect.bottom = gridRect.y + gridRect.height;
					}
				}
				else
					gridRect = _scale9Grid;
				
				var rows:Array;
				var cols:Array;
				var dRows:Array;
				var dCols:Array;
	
				rows = [ 0, gridRect.top, gridRect.bottom, texture.height ];
				cols = [ 0, gridRect.left, gridRect.right, texture.width ];
				
				if (vertRect.height >= (texture.height - gridRect.height))
					dRows = [ 0, gridRect.top, vertRect.height - (texture.height - gridRect.bottom), vertRect.height ];
				else
				{
					var tmp:Number = gridRect.top / (texture.height - gridRect.bottom);
					tmp = Math.round(vertRect.height * tmp / (1 + tmp));
					dRows = [ 0, tmp, tmp, vertRect.height ];
				}
				
				if (vertRect.width >= (texture.width - gridRect.width))
					dCols = [ 0, gridRect.left, vertRect.width - (texture.width - gridRect.right), vertRect.width ];
				else
				{
					tmp = gridRect.left / (texture.width - gridRect.right);
					tmp = Math.round(vertRect.width * tmp / (1 + tmp));
					dCols = [ 0, tmp, tmp, vertRect.width ];
				}

				var cx:int, cy:int;
				var tilePart:int;
				var r1:Number = uvRect.width / texture.width;
				var r2:Number = uvRect.height / texture.height;
				var offsetX:Number = uvRect.x, offsetY:Number = uvRect.y;
				for (i = 0; i < 9; i++)
				{
					cx = i%3;
					cy = i/3;
					
					vertRect.setTo(dCols[cx], dRows[cy], dCols[cx+1]-dCols[cx], dRows[cy+1]-dRows[cy]);
					if(vertRect.isEmpty())
						continue;
					
					uvRect.setTo(cols[cx], rows[cy], cols[cx+1]-cols[cx], rows[cy+1]-rows[cy]);
					uvRect.x *= r1;
					uvRect.y *= r2;
					uvRect.width *= r1;
					uvRect.height *= r2;
					uvRect.offset(offsetX, offsetY);
					
					tilePart = tileIndice[i];
					if(i!=-1 && (tileGridIndice & (1<<tilePart))!=0)
					{
						doTile(cols[cx+1]-cols[cx], cols[cy+1]-cols[cy], vertRect, uvRect);
					}
					else
					{
						VertexHelper.addQuad2(vertRect);
						VertexHelper.fillUV2(uvRect);
					}
				}
			}
			else
			{
				VertexHelper.addQuad2(vertRect);
				VertexHelper.fillUV2(uvRect);
			}

			VertexHelper.updateAll(this.vertexData, this.indexData);
			vertexData.colorize("color", _color);
		}
		
		private static function doTile(textureWidth:int, textureHeight:int, 
									   drawRect:Rectangle, uvRect:Rectangle):void
		{
			var hc:int = Math.ceil(drawRect.width/textureWidth);
			var vc:int = Math.ceil(drawRect.height/textureHeight);
			var remainWidth:Number = drawRect.width - (hc - 1) * textureWidth;
			var remainHeight:Number = drawRect.height - (vc - 1) * textureHeight;
			
			VertexHelper.allocMore(hc*vc*4+36);
			
			var i:int;
			var j:int;
			for (i= 0; i < hc; i++)
			{
				for (j = 0; j < vc; j++)
				{
					VertexHelper.addQuad(drawRect.x+i * textureWidth, drawRect.y+j * textureHeight, 
						i==hc-1?remainWidth:textureWidth, j==vc-1?remainHeight:textureHeight);
					
					if(i==hc-1 || j==vc-1)
					{
						VertexHelper.fillUV3(uvRect,
							i==hc-1?remainWidth/textureWidth:1,
							j==vc-1?remainHeight/textureHeight:1);
					}
					else
						VertexHelper.fillUV2(uvRect);
				}
			}
		}
	}
}
