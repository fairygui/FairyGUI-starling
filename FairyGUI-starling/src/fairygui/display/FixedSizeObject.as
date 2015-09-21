package fairygui.display
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.display.DisplayObject;
	import starling.utils.MatrixUtil;

	public class FixedSizeObject extends DisplayObject
	{
		protected var _width:Number;
		protected var _height:Number;
		protected var _scaleX:Number;
		protected var _scaleY:Number;
		protected var _needRebuild:Boolean;
		
		private static var sHelperMatrix:Matrix = new Matrix();
		private static var sHelperPoint:Point = new Point();
		private static var sHelperRect:Rectangle = new Rectangle();
		
		public function FixedSizeObject()
		{
			_width = 0;
			_height = 0;
			_scaleX = 1;
			_scaleY = 1;
		}
		
		override public function get width():Number
		{
			return _width;
		}
		
		public function setSize(aw:Number, ah:Number):void
		{
			if(_width!=aw || _height!=ah)
			{
				_width = aw;
				_height = ah;
				_needRebuild = true;
			}
		}
		
		override public function get scaleX():Number
		{
			return _scaleX;
		}
		
		override public function set scaleX(value:Number):void
		{
			if(_scaleX!=value)
			{
				_scaleX = value;
				_needRebuild = true;
			}
		}
		
		override public function get scaleY():Number
		{
			return _scaleY;
		}
		
		override public function set scaleY(value:Number):void
		{
			if(_scaleY!=value)
			{
				_scaleY = value;
				_needRebuild = true;
			}
		}
		
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			if(!resultRect)
			{
				resultRect = new Rectangle();
			}
			
			if (targetSpace == this || _width==0 || _height==0) // optimization
			{
				resultRect.setTo(0,0,_width*_scaleX, _height*_scaleY);
			}
			else if (targetSpace == parent && rotation == 0.0) // optimization
			{
				resultRect.setTo(x - pivotX,  y - pivotY, _width*_scaleX, _height*_scaleY);
			}
			else
			{
				getTransformationMatrix(targetSpace, sHelperMatrix);
				
				var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
				var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
				
				var ax:Number, ay:Number;
				for (var i:int=0; i<4; ++i)
				{
					switch(i)
					{
						case 0: ax = 0;  ay = 0;    break;
						case 1: ax = _width*_scaleX;  ay = 0; break;
						case 2: ax = 0; ay = _height*_scaleY;    break;
						case 3: ax = _width*_scaleX; ay = _height*_scaleY; break;
					}
					var transformedPoint:Point = MatrixUtil.transformCoords(sHelperMatrix, ax, ay, sHelperPoint);
					
					if (minX > transformedPoint.x) minX = transformedPoint.x;
					if (maxX < transformedPoint.x) maxX = transformedPoint.x;
					if (minY > transformedPoint.y) minY = transformedPoint.y;
					if (maxY < transformedPoint.y) maxY = transformedPoint.y;
				}
				
				resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
			}
			
			return resultRect;
		}
	}
}