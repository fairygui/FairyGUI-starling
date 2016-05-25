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
		private function rebuild():void
		{
			_needRebuild = false;
			
			var texture:Texture = this.texture;
			
			if(texture==null)
			{
				this.vertexData.clear();
				this.indexData.clear();
				this.setRequiresRedraw();
				return;
			}

			VertexHelper.getTextureUV(texture, uvRect);
			if(_flip!=0)
				VertexHelper.flipUV(uvRect, _flip);
			vertRect.copyFrom(_bounds);
			
			VertexHelper.beginFill();
			
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
				var hc:int = Math.ceil(_textureScaleX);
				var vc:int = Math.ceil(_textureScaleY);
				var remainWidth:Number = _bounds.width - (hc - 1) * texture.width;
				var remainHeight:Number = _bounds.height - (vc - 1) * texture.height;
				
				VertexHelper.alloc(hc*vc*4);

				for (var i:int = 0; i < hc; i++)
				{
					for (var j:int = 0; j < vc; j++)
					{
						VertexHelper.addQuad(i * texture.width, j * texture.height, 
							i==hc-1?remainWidth:texture.width, j==vc-1?remainHeight:texture.height);

						if(i==hc-1 || j==vc-1)
						{
							VertexHelper.fillUV3(uvRect,
								i==hc-1?remainWidth/texture.width:1,
								j==vc-1?remainHeight/texture.height:1);
						}
						else
							VertexHelper.fillUV2(uvRect);
					}
				}
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
				
				if (_bounds.height >= (texture.height - gridRect.height))
					dRows = [ 0, gridRect.top, _bounds.height - (texture.height - gridRect.bottom), _bounds.height ];
				else
				{
					var tmp:Number = gridRect.top / (texture.height - gridRect.bottom);
					tmp = _bounds.height * tmp / (1 + tmp);
					dRows = [ 0, tmp, tmp, _bounds.height ];
				}
				
				if (_bounds.width >= (texture.width - gridRect.width))
					dCols = [ 0, gridRect.left, _bounds.width - (texture.width - gridRect.right), _bounds.width ];
				else
				{
					tmp = gridRect.left / (texture.width - gridRect.right);
					tmp = _bounds.width * tmp / (1 + tmp);
					dCols = [ 0, tmp, tmp, _bounds.width ];
				}

				var cx:int, cy:int;
				var left:Number, right:Number, top:Number, bottom:Number;
				for (i = 0; i < 9; i++)
				{
					cx = i%3;
					cy = i/3;
					
					left = dCols[cx];
					top = dRows[cy];
					right = dCols[cx+1];
					bottom = dRows[cy+1];
					
					if(right==left || bottom==top)
						continue;
					
					VertexHelper.addQuad(left, top, right-left, bottom-top);
					
					left = uvRect.x + cols[cx] / texture.width * uvRect.width;
					top = uvRect.y + rows[cy] / texture.height * uvRect.height;
					right = uvRect.x + cols[cx+1] / texture.width * uvRect.width;
					bottom = uvRect.y + rows[cy+1] / texture.height * uvRect.height;
					VertexHelper.fillUV(left, top, right-left, bottom-top);
				}
			}
			else
			{
				VertexHelper.addQuad2(vertRect);
				VertexHelper.fillUV2(uvRect);
			}

			VertexHelper.flush(this.vertexData, this.indexData);
			vertexData.colorize("color", _color);
		}
	}
}
