package fairygui.display
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.geom.Polygon;
	import starling.rendering.Painter;
	
	public class Shape extends MeshExt
	{		
		private var _type:int;
		private var _lineSize:int;
		private var _lineColor:int;
		private var _lineAlpha:Number;
		private var _fillColor:int;
		private var _fillAlpha:Number;
		private var _corner:Array;

		private static var sHelperMatrix:Matrix = new Matrix();
		private static var sHelperPoint:Point = new Point();
		private static var sHelperRect:Rectangle = new Rectangle();
		
		public function Shape()
		{
			super();
			
			_lineSize = 1;
			_lineAlpha = 1;
			_fillAlpha = 1;
			_fillColor = 0xFFFFFF;
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
			setRequiresRebuild();
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
			setRequiresRebuild();
		}
		
		public function setShapeSize(width:Number, height:Number):void
		{
			setSize(width, height);
		}
		
		public function get fillColor():uint
		{
			return _fillColor;
		}
		
		public function set fillColor(value:uint):void 
		{
			if(_fillColor != value)
			{
				_fillColor = value;
				setRequiresRebuild();
			}
		}
		
		public function clear():void
		{
			if(_type!=0)
			{
				_type = 0;
				setRequiresRebuild();
			}
		}
		
		override public function render(painter:Painter):void
		{
			if(_needRebuild)
				rebuild();
			
			super.render(painter);
		}
		
		private function rebuild():void
		{
			_needRebuild = false;
			
			if(_type==0)
			{
				vertexData.numVertices = 0;
				indexData.numIndices = 0;
				return;
			}
			
			if(_type == 1)
			{
				if (_lineSize == 0)
				{
					VertexHelper.beginFill();
					VertexHelper.addQuad(0, 0, _bounds.width, _bounds.height);
					VertexHelper.updateAll(vertexData, indexData);
					vertexData.colorize("color", _fillColor, _fillAlpha);
				}
				else
				{
					VertexHelper.beginFill();
					
					//left,right
					VertexHelper.addQuad(0, 0, _lineSize, _bounds.height);
					VertexHelper.addQuad(_bounds.width - _lineSize, 0, _lineSize, _bounds.height);
	
					//top, bottom
					VertexHelper.addQuad(_lineSize, 0, _bounds.width - _lineSize, _lineSize);
					VertexHelper.addQuad(_lineSize, _bounds.height - _lineSize, _bounds.width - _lineSize, _lineSize);
					
					//middle
					VertexHelper.addQuad(_lineSize, _lineSize, _bounds.width-_lineSize*2, _bounds.height -_lineSize*2);
					
					VertexHelper.updateAll(vertexData, indexData);
					vertexData.colorize("color", _lineColor, _lineAlpha, 0, 16);
					vertexData.colorize("color", _fillColor, _fillAlpha, 16, 4);
				}
			}
			else if(_type==2)
			{
				var polygon:Polygon = Polygon.createEllipse(_bounds.width/2, _bounds.height/2, _bounds.width/2, _bounds.height/2);
				
				vertexData.numVertices = 0;
				indexData.numIndices = 0;
					
				polygon.triangulate(indexData);
				polygon.copyToVertexData(vertexData);
				
				vertexData.colorize("color", _fillColor, _fillAlpha);
			}
		}
	}
}


