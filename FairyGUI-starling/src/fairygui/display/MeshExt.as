package fairygui.display
{
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	import starling.display.DisplayObject;
	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.styles.MeshStyle;
	import starling.utils.RectangleUtil;

	public class MeshExt extends Mesh
	{
		protected var _bounds:Rectangle;
		protected var _needRebuild:Boolean;
		
		private static var sHelperMatrix:Matrix = new Matrix();
		private static var sHelperPoint:Point = new Point();
		private static var sHelperRect:Rectangle = new Rectangle();
		
		public function MeshExt()
		{
			var vertexData:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT, 4);
			var indexData:IndexData = new IndexData(6);
			
			super(vertexData, indexData);
			
			_bounds = new Rectangle();
		}
		
		protected function setSize(aw:Number, ah:Number):void
		{
			if(_bounds.width!=aw || _bounds.height!=ah)
			{
				_bounds.width = aw;
				_bounds.height = ah;
				setRequiresRebuild();
			}
		}
		
		protected function setRequiresRebuild():void
		{
			_needRebuild = true;
			setRequiresRedraw();
		}
		
		override public function hitTest(localPoint:Point):DisplayObject
		{
			if (!visible || !touchable || !hitTestMask(localPoint)) return null;
			else if (_bounds.containsPoint(localPoint)) return this;
			else return null;
		}
		
		// helper objects
		private static var sPoint3D:Vector3D = new Vector3D();
		private static var sMatrix:Matrix = new Matrix();
		private static var sMatrix3D:Matrix3D = new Matrix3D();
		public override function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
		{
			if (out == null) out = new Rectangle();
			
			if (targetSpace == this) // optimization
			{
				out.copyFrom(_bounds);
			}
			else if (targetSpace == parent && rotation == 0.0) // optimization
			{
				var scaleX:Number = this.scaleX;
				var scaleY:Number = this.scaleY;
				
				out.setTo(   x - pivotX * scaleX,     y - pivotY * scaleY,
					_bounds.width * scaleX, _bounds.height * scaleY);
				
				if (scaleX < 0) { out.width  *= -1; out.x -= out.width;  }
				if (scaleY < 0) { out.height *= -1; out.y -= out.height; }
			}
			else if (is3D && stage)
			{
				stage.getCameraPosition(targetSpace, sPoint3D);
				getTransformationMatrix3D(targetSpace, sMatrix3D);
				RectangleUtil.getBoundsProjected(_bounds, sMatrix3D, sPoint3D, out);
			}
			else
			{
				getTransformationMatrix(targetSpace, sMatrix);
				RectangleUtil.getBounds(_bounds, sMatrix, out);
			}
			
			return out;
		}
	}
}