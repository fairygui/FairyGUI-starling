package fairygui
{
	import fairygui.display.Shape;
	import fairygui.display.UIShape;
	import fairygui.display.UISprite;
	import fairygui.utils.ToolSet;
	
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.utils.deg2rad;
	
	public class GGraph extends GObject implements IColorGear
	{
		private var _shape:UIShape;

		public function GGraph()
		{

		}
		
		public function get color():uint
		{
			return this.shape.fillColor;
		}
		
		public function set color(value:uint):void 
		{
			this.shape.fillColor = value;
		}
		
		public function drawRect(lineSize:int, lineColor:int, lineAlpha:Number,
								 fillColor:int, fillAlpha:Number, corner:Array=null):void
		{
			shape.drawRect(lineSize, lineColor, lineAlpha, fillColor, fillAlpha, corner);
		}

		public function drawEllipse(lineSize:int, lineColor:int, lineAlpha:Number,
									fillColor:int, fillAlpha:Number):void
		{
			shape.drawEllipse(lineSize, lineColor, lineAlpha, fillColor, fillAlpha);
		}
		
		public function clearGraphics():void
		{
			if(_shape!=null)
				_shape.clear();
		}

		public function replaceMe(target:GObject):void
		{
			if(!_parent)
				throw new Error("parent not set");
			
			target.name = this.name;
			target.alpha = this.alpha;
			target.rotation = this.rotation;
			target.visible = this.visible;
			target.touchable = this.touchable;
			target.grayed = this.grayed;
			target.setXY(this.x, this.y);
			target.setSize(this.width, this.height);
			
			var index:int = _parent.getChildIndex(this);
			_parent.addChildAt(target, index);
			target.relations.copyFrom(this.relations);
			
			_parent.removeChild(this, true);			
		}
		
		public function addBeforeMe(target:GObject):void
		{
			if (_parent == null)
				throw new Error("parent not set");
			
			var index:int = _parent.getChildIndex(this);
			_parent.addChildAt(target, index);
		}
		
		public function addAfterMe(target:GObject):void
		{
			if (_parent == null)
				throw new Error("parent not set");
			
			var index:int = _parent.getChildIndex(this);
			index++;
			_parent.addChildAt(target, index);
		}
		
		public function setNativeObject(obj:DisplayObject):void
		{
			if(displayObject==_shape)
			{
				if(_shape)
					_shape.dispose();
				_shape = null;
				
				setDisplayObject(new UISprite(this));
				if(_parent)
					_parent.childStateChanged(this);
				handlePositionChanged();
				displayObject.alpha = this.alpha;
				displayObject.rotation = deg2rad(this.normalizeRotation);
				displayObject.visible = this.visible;
				Sprite(displayObject).touchable = this.touchable;
			}
			else
				Sprite(displayObject).removeChildren();
			
			if(obj!=null)
				Sprite(displayObject).addChild(obj);
		}
		
		private function get shape():Shape
		{
			if (_shape != null)
				return _shape;
			
			if (displayObject != null)
				displayObject.dispose();
			
			_shape = new UIShape(this);
			setDisplayObject(_shape);
			if (parent!=null)
				parent.childStateChanged(this);
			handlePositionChanged();
			handleSizeChanged();
			handleScaleChanged();
			_shape.alpha = this.alpha;
			_shape.rotation = this.normalizeRotation;
			_shape.visible = this.visible;
			
			return _shape;
		}
		
		override protected function handleSizeChanged():void
		{
			if(_shape!=null)
				_shape.setShapeSize(this.width, this.height);
		}

		override public function setup_beforeAdd(xml:XML):void
		{
			var type:String = xml.@type;
			if(type && type!="empty")
				this.shape;//create shape now
			
			super.setup_beforeAdd(xml);
			
			if(_shape!=null)
			{
				var str:String;
				
				var lineSize:int = 1;
				str = xml.@lineSize;
				if(str)
					lineSize = parseInt(str);
				
				var lineColor:int = 0;
				var lineAlpha:Number = 1;
				str = xml.@lineColor;
				if(str)
				{
					var c:uint = ToolSet.convertFromHtmlColor(str,true);
					lineColor = c & 0xFFFFFF;
					lineAlpha = ((c>>24)&0xFF)/0xFF;
				}
				
				var fillColor:int = 0xFFFFFF;
				var fillAlpha:Number = 1;
				str = xml.@fillColor;
				if(str)
				{
					c = ToolSet.convertFromHtmlColor(str,true);
					fillColor = c & 0xFFFFFF;
					fillAlpha = ((c>>24)&0xFF)/0xFF;
				}
				
				var corner:Array;
				str = xml.@corner;
				if(str)
					corner = str.split(",");

				if(type=="rect")
					drawRect(lineSize, lineColor, lineAlpha, fillColor, fillAlpha, corner);
				else
					drawEllipse(lineSize, lineColor, lineAlpha, fillColor, fillAlpha);
				
				_shape.setShapeSize(this.width, this.height);
			}
		}
	}
}