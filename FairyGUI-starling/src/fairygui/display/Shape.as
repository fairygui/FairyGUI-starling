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
		
		public function setShapeSize(width:Number, height:Number):void
		{
			setSize(width, height);
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
		
		private function rebuild():void
		{
			_needRebuild = false;
			
			this._batch.reset();
			if(_type==0)
				return;
			
			if (_lineSize == 0)
			{
				VertexHelper.beginFill();
				VertexHelper.color = _fillColor;
				VertexHelper.addQuad(0, 0, _width, _height);
				VertexHelper.flush(_batch, null, _fillAlpha);
			}
			else
			{
				VertexHelper.beginFill();
				VertexHelper.color = _lineColor;

				//left,right
				VertexHelper.addQuad(0, 0, _lineSize, _height);
				VertexHelper.addQuad(_width - _lineSize, 0, _lineSize, _height);

				//top, bottom
				VertexHelper.addQuad(_lineSize, 0, _width - _lineSize, _lineSize);
				VertexHelper.addQuad(_lineSize, _height - _lineSize, _width - _lineSize, _lineSize);
				VertexHelper.flush(_batch, null, _lineAlpha);
				
				//middle
				VertexHelper.beginFill();
				VertexHelper.color = _fillColor;				
				VertexHelper.addQuad(_lineSize, _lineSize, _width- _lineSize*2, _height - _lineSize*2);
				VertexHelper.flush(_batch, null, _fillAlpha);
			}
		}
	}
}


