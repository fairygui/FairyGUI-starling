package fairygui.display
{
	import flash.geom.Rectangle;
	
	import fairygui.FlipType;
	import fairygui.GRoot;
	
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
		
		private var _scaleByTile:Boolean;
		private var _scale9Grid:Rectangle;
		
		public function ImageExt()
		{
			super();
			
			//ImageExt is by default touchable
			this.touchable = false;
			
			_batch = new QuadBatch();
			_batch.capacity = 1;
			_width = 0;
			_height = 0;
			_color = 0xFFFFFF;
			_smoothing = TextureSmoothing.BILINEAR;
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
					setSize(_texture.width, _texture.height);
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

		override public function render(support:RenderSupport, parentAlpha:Number):void
		{
			if(_needRebuild)
				rebuild();
			
			if(_batch.numQuads>0)
				support.batchQuadBatch(_batch, this.alpha*parentAlpha);
		}
		
		private static var sHelperTexCoords:Vector.<Number> = new Vector.<Number>(8);
		private static var sHelperRect:Rectangle = new Rectangle();
		private static var sHelperQuad:QuadExt;
		private static var QUADS_9_GRID:Array = [
			[0,0,1,0,0,1,1,1],
			[1,0,2,0,1,1,2,1],
			[2,0,3,0,2,1,3,1],
			
			[0,1,1,1,0,2,1,2],
			[1,1,2,1,1,2,2,2],
			[2,1,3,1,2,2,3,2], 
			
			[0,2,1,2,0,3,1,3],
			[1,2,2,2,1,3,2,3],
			[2,2,3,2,2,3,3,3]
		];
		private function rebuild():void
		{
			_needRebuild = false;
			
			this._batch.reset();
			if(_texture==null)
				return;
			
			if(sHelperQuad==null)
				sHelperQuad = new QuadExt();
			
			sHelperQuad.setPremultipliedAlpha(_texture.premultipliedAlpha);
			
			sHelperTexCoords.length = 0;			
			if(_flip==FlipType.None)
				sHelperTexCoords.push(0,0,1,0,0,1,1,1);
			if(_flip==FlipType.Both)
				sHelperTexCoords.push(1,1,0,1,1,0,0,0);
			else if(_flip==FlipType.Horizontal)
				sHelperTexCoords.push(1,0,0,0,1,1,0,1);
			else
				sHelperTexCoords.push(0,1,1,1,0,0,1,0);

			if (_scaleByTile)
			{
				var rx:Number = _scaleX / GRoot.contentScaleFactor;
				var ry:Number = _scaleY / GRoot.contentScaleFactor;
				var hc:int = Math.ceil(rx);
				var vc:int = Math.ceil(ry);
				var remainWidth:Number = _width * (rx - (hc - 1));
				var remainHeight:Number = _height * (ry - (vc - 1));

				_batch.capacity = hc*vc;
				
				for (var i:int = 0; i < hc; i++)
				{
					for (var j:int = 0; j < vc; j++)
					{
						sHelperQuad.fillVertsWithScale(i * _width, j * _height, 
							i==hc-1?remainWidth:_width, j==vc-1?remainHeight:_height, 
							GRoot.contentScaleFactor, GRoot.contentScaleFactor);

						if(i==hc-1 && j==vc-1)
							sHelperQuad.fillUVWithScale(sHelperTexCoords, _texture, rx-hc+1, ry-vc+1);
						else if(i==hc-1)
							sHelperQuad.fillUVWithScale(sHelperTexCoords, _texture, rx-hc+1, 1);
						else if(j==vc-1)
							sHelperQuad.fillUVWithScale(sHelperTexCoords, _texture, 1, ry-vc+1);
						else
							sHelperQuad.fillUV(sHelperTexCoords, _texture);
						
						sHelperQuad.color = _color;
						_batch.addQuad(sHelperQuad, 1.0, _texture, _smoothing);
					}
				}
			}
			else if(_scale9Grid==null || (_scaleX==1 && _scaleY==1))
			{
				sHelperQuad.fillVertsWithScale(0, 0, _width, _height, _scaleX, _scaleY);
				sHelperQuad.fillUV(sHelperTexCoords, _texture);
				sHelperQuad.color = _color;
				_batch.addQuad(sHelperQuad, 1.0, _texture, _smoothing);
			}
			else
			{				
				var scale9Width:Number = _width * _scaleX / GRoot.contentScaleFactor;
				var scale9Height:Number = _height * _scaleY / GRoot.contentScaleFactor;
				
				var rows:Array;
				var cols:Array;
				var dRows:Array;
				var dCols:Array;
	
				rows = [ 0, _scale9Grid.top, _scale9Grid.bottom, _height ];
				cols = [ 0, _scale9Grid.left, _scale9Grid.right, _width ];
				
				if (scale9Height >= (_height - _scale9Grid.height))
					dRows = [ 0, _scale9Grid.top, scale9Height - (_height - _scale9Grid.bottom), scale9Height ];
				else
				{
					var tmp:Number = _scale9Grid.top / (_height - _scale9Grid.bottom);
					tmp = scale9Height * tmp / (1 + tmp);
					dRows = [ 0, tmp, tmp, scale9Height ];
				}
				
				if (scale9Width >= (_width - _scale9Grid.width))
					dCols = [ 0, _scale9Grid.left, scale9Width - (_width - _scale9Grid.right), scale9Width ];
				else
				{
					tmp = _scale9Grid.left / (_width - _scale9Grid.right);
					tmp = scale9Width * tmp / (1 + tmp);
					dCols = [ 0, tmp, tmp, scale9Width ];
				}
				
				var texLeft:Number = sHelperTexCoords[0];
				var texTop:Number = sHelperTexCoords[1];
				var texWidth:Number = sHelperTexCoords[6]-sHelperTexCoords[0];
				var texHeight:Number = sHelperTexCoords[7]-sHelperTexCoords[1];
				
				_batch.capacity = 9;
				
				for (i = 0; i < 9; i++)
				{
					for(j = 0; j < 8; j+=2)
					{
						var cx:int = QUADS_9_GRID[i][j];
						var cy:int = QUADS_9_GRID[i][j+1];
						
						sHelperTexCoords[j] = texLeft + cols[cx] / _width * texWidth;
						sHelperTexCoords[j+1] = texTop + rows[cy] / _height * texHeight;
					
						switch(j)
						{
							case 0:
								sHelperRect.x = dCols[cx] * GRoot.contentScaleFactor;
								sHelperRect.y = dRows[cy] * GRoot.contentScaleFactor;
								break;
							
							case 2:
								sHelperRect.right = dCols[cx] * GRoot.contentScaleFactor;
								break;
							
							case 4:
								sHelperRect.bottom = dRows[cy] * GRoot.contentScaleFactor;
								break;
						}
					}
					if(sHelperRect.width==0 || sHelperRect.height==0)
						continue;

					sHelperQuad.fillVertsByRect(sHelperRect);
					sHelperQuad.fillUV(sHelperTexCoords, _texture);
					sHelperQuad.color = _color;
					_batch.addQuad(sHelperQuad, 1.0, _texture, _smoothing);
				}
			}
			
			_batch.blendMode = this.blendMode;
		}
	}
}



