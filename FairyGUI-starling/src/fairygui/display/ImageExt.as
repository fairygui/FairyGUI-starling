package fairygui.display
{
	import flash.geom.Rectangle;
	
	import fairygui.FillType;
	
	import starling.core.RenderSupport;
	import starling.display.QuadBatch;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;

	public class ImageExt extends FixedSizeObject
	{		
		private var _texture:Texture;
		private var _batch:QuadBatch;
		private var _smoothing:String;
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
			
			//ImageExt is by default touchable
			this.touchable = false;
			
			_batch = new QuadBatch();
			_width = 0;
			_height = 0;
			_color = 0xFFFFFF;
			_smoothing = TextureSmoothing.BILINEAR;
			_textureScaleX = 1;
			_textureScaleY = 1;
			_fillAmount = 100;
			_fillClockwise = true;
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
				_needRebuild = true;
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
				_needRebuild = true;
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
				_needRebuild = true;
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
				_needRebuild = true;
			}
		}

		override public function dispose():void
		{
			_batch.dispose();
			
			super.dispose();
		}

		public function get texture():Texture
		{
			return _texture;
		}

		public function set texture(value:Texture):void
		{
			if(_texture!=value)
			{
				_texture = value;
				if(_texture!=null)
					setSize(_texture.width * _textureScaleX, _texture.height * _textureScaleY);
				else
					setSize(0,0);
				_needRebuild = true;
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
				_needRebuild = true;
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
				_needRebuild = true;
			}
		}
		
		public function get smoothing():String
		{
			return _smoothing;
		}
		
		public function set smoothing(value:String):void
		{
			if(_smoothing != value)
			{
				_smoothing = value;
				_needRebuild = true;
			}
		}
		
		override public function set blendMode(value:String):void
		{
			super.blendMode = value;
			_batch.blendMode = value;
		}
		
		public function get scale9Grid():Rectangle
		{
			return _scale9Grid;
		}
		
		public function set scale9Grid(value:Rectangle):void
		{
			_scale9Grid = value;
			_needRebuild = true;
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
				_needRebuild = true;
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
				if(_texture!=null)
					setSize(_texture.width * _textureScaleX, _texture.height * _textureScaleY);
				_needRebuild = true;
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
				if(_texture!=null)
					setSize(_texture.width * _textureScaleX, _texture.height * _textureScaleY);
				_needRebuild = true;
			}
		}

		override public function render(support:RenderSupport, parentAlpha:Number):void
		{
			if(_needRebuild)
				rebuild();
			
			if(_batch.numQuads>0)
				support.batchQuadBatch(_batch, this.alpha*parentAlpha);
		}
		
		private static var vertRect:Rectangle = new Rectangle();
		private static var uvRect:Rectangle = new Rectangle();
		private function rebuild():void
		{
			_needRebuild = false;
			
			this._batch.reset();
			if(_texture==null)
				return;

			VertexHelper.getTextureUV(_texture, uvRect);
			if(_flip!=0)
				VertexHelper.flipUV(uvRect, _flip);
			vertRect.setTo(0,0,_width,_height);
			
			VertexHelper.beginFill();
			VertexHelper.color = _color;
			
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
				var remainWidth:Number = _width - (hc - 1) * _texture.width;
				var remainHeight:Number = _height - (vc - 1) * _texture.height;
				
				VertexHelper.alloc(hc*vc*4);

				for (var i:int = 0; i < hc; i++)
				{
					for (var j:int = 0; j < vc; j++)
					{
						VertexHelper.addQuad(i * _texture.width, j * _texture.height, 
							i==hc-1?remainWidth:_texture.width, j==vc-1?remainHeight:_texture.height);

						if(i==hc-1 || j==vc-1)
						{
							VertexHelper.fillUV3(uvRect,
								i==hc-1?remainWidth/_texture.width:1,
								j==vc-1?remainHeight/_texture.height:1);
						}
						else
							VertexHelper.fillUV2(uvRect);
					}
				}
			}
			else if(_scale9Grid!=null)
			{				
				var rows:Array;
				var cols:Array;
				var dRows:Array;
				var dCols:Array;
	
				rows = [ 0, _scale9Grid.top, _scale9Grid.bottom, _texture.height ];
				cols = [ 0, _scale9Grid.left, _scale9Grid.right, _texture.width ];
				
				if (_height >= (_texture.height - _scale9Grid.height))
					dRows = [ 0, _scale9Grid.top, _height - (_texture.height - _scale9Grid.bottom), _height ];
				else
				{
					var tmp:Number = _scale9Grid.top / (_texture.height - _scale9Grid.bottom);
					tmp = _height * tmp / (1 + tmp);
					dRows = [ 0, tmp, tmp, _height ];
				}
				
				if (_width >= (_texture.width - _scale9Grid.width))
					dCols = [ 0, _scale9Grid.left, _width - (_texture.width - _scale9Grid.right), _width ];
				else
				{
					tmp = _scale9Grid.left / (_texture.width - _scale9Grid.right);
					tmp = _width * tmp / (1 + tmp);
					dCols = [ 0, tmp, tmp, _width ];
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
					
					left = uvRect.x + cols[cx] / _texture.width * uvRect.width;
					top = uvRect.y + rows[cy] / _texture.height * uvRect.height;
					right = uvRect.x + cols[cx+1] / _texture.width * uvRect.width;
					bottom = uvRect.y + rows[cy+1] / _texture.height * uvRect.height;
					VertexHelper.fillUV(left, top, right-left, bottom-top);
				}
			}
			else
			{
				VertexHelper.addQuad2(vertRect);
				VertexHelper.fillUV2(uvRect);
			}
			
			VertexHelper.flush(_batch, _texture, 1, _smoothing);
			_batch.blendMode = this.blendMode;
		}
	}
}
