package fairygui.display
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.core.RenderSupport;
	import starling.display.QuadBatch;
	
	public class Shape extends FixedSizeObject
	{		
		private var _type:int;
		private var _lineSize:int;
		private var _lineColor:int;
		private var _lineAlpha:Number;
		private var _fillColor:int;
		private var _fillAlpha:Number;
		private var _corner:Array;
		
		private var _batch:QuadBatch;

		private static var sHelperMatrix:Matrix = new Matrix();
		private static var sHelperPoint:Point = new Point();
		private static var sHelperRect:Rectangle = new Rectangle();
		
		public function Shape()
		{
			super();
			
			_batch = new QuadBatch();
			_batch.capacity = 5;
			_width = 0;
			_height = 0;
			_lineSize = 1;
			_lineAlpha = 1;
			_fillAlpha = 1;
			_fillColor = 0xFFFFFF;
		}
		
		override public function dispose():void
		{
			_batch.dispose();
			
			super.dispose();
		}
		
		public function drawRect(lineSize:int, lineColor:int, lineAlpha:Number,
								 fillColor:int, fillAlpha:Number, corner:Array=null):void
		{
			_type = 1;
			_lineSize = lineSize;
			_lineColor = lineColor;
			_lineAlpha = lineAlpha;
			_fillColor = fillColor;
			_fillAlpha = fillAlpha;
			_corner = corner;
			_needRebuild = true;
		}
		
		public function drawEllipse(lineSize:int, lineColor:int, lineAlpha:Number,
									fillColor:int, fillAlpha:Number):void
		{
			_type = 2;
			_lineSize = lineSize;
			_lineColor = lineColor;
			_lineAlpha = lineAlpha;
			_fillColor = fillColor;
			_fillAlpha = fillAlpha;
			_corner = null;
			_needRebuild = true;
		}
		
		public function clear():void
		{
			if(_type!=0)
			{
				_type = 0;
				_needRebuild = true;
			}
		}
		
		override public function render(support:RenderSupport, parentAlpha:Number):void
		{
			if(_needRebuild)
				rebuild();
			
			support.batchQuadBatch(_batch, this.alpha*parentAlpha);
		}
		
		private static var sHelperTexCoords:Vector.<Number> = new Vector.<Number>(8);
		private static var sHelperQuad:QuadExt;
		private function rebuild():void
		{
			_needRebuild = false;
			
			this._batch.reset();
			if(_type==0)
				return;
			
			if(sHelperQuad==null)
			{
				sHelperQuad = new QuadExt();
				sHelperQuad.setPremultipliedAlpha(false);
			}
			
			var rectWidth:int = _width * _scaleX;
			var rectHeight:int = _height * _scaleY;
			
			if (_lineSize == 0)
			{
				sHelperQuad.color = _fillColor;
				sHelperQuad.alpha = _fillAlpha;
				sHelperQuad.fillVerts(0, 0, rectWidth, rectHeight);
				_batch.addQuad(sHelperQuad, 1.0);
			}
			else
			{
				var lineSize:int = Math.ceil(Math.min(_lineSize*_scaleX, _lineSize*_scaleY));
				
				//left,right
				sHelperQuad.color = _lineColor;
				sHelperQuad.alpha = _lineAlpha;
				sHelperQuad.fillVerts(0, 0, lineSize, rectHeight);
				_batch.addQuad(sHelperQuad, 1.0);
				
				sHelperQuad.fillVerts(rectWidth - lineSize, 0, lineSize, rectHeight);
				_batch.addQuad(sHelperQuad, 1.0);
				
				//top, bottom
				sHelperQuad.fillVerts(lineSize, 0, rectWidth - lineSize, lineSize);
				_batch.addQuad(sHelperQuad, 1.0);
				
				sHelperQuad.fillVerts(lineSize, rectHeight - lineSize, rectWidth - lineSize, lineSize);
				_batch.addQuad(sHelperQuad, 1.0);
				
				//middle
				sHelperQuad.color = _fillColor;
				sHelperQuad.alpha = _fillAlpha;
				sHelperQuad.fillVerts(lineSize, lineSize, rectWidth- lineSize*2, rectHeight - lineSize*2);
				_batch.addQuad(sHelperQuad, 1.0);
			}
		}
	}
}


