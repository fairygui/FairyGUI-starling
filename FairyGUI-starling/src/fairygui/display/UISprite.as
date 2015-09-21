package fairygui.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import fairygui.GObject;
	
	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.Sprite;

	public class UISprite extends Sprite implements UIDisplayObject 
	{
		private var _owner:GObject;
		private var _hitArea:Rectangle;
		private var _skipRendering:Boolean;
		
		public var renderCallback:Function;
		
		public function UISprite(owner:GObject)
		{
			_owner = owner;
		}
		
		public function get owner():GObject
		{
			return _owner;
		}
		
		public function get hitArea():Rectangle
		{
			return _hitArea;
		}
		
		public function set hitArea(value:Rectangle):void
		{
			if (_hitArea && value) _hitArea.copyFrom(value);
			else _hitArea = (value ? value.clone() : null);
		}
		
		override public function dispose():void
		{
			renderCallback = null;
			super.dispose();
		}
		
		public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
		{
			if(_skipRendering)
				return null;
			
			var localX:Number = localPoint.x;
			var localY:Number = localPoint.y;
			
			var ret:DisplayObject = super.hitTest(localPoint, forTouch);
			if(ret==null && (this.touchable || !forTouch) 
				&& _hitArea!=null && _hitArea.contains(localX, localY))
				ret = this;
			
			return ret;				
		}
		
		override public function render(support:RenderSupport, parentAlpha:Number):void
		{
			_skipRendering = _owner.parent!=null && !_owner.parent.isChildInView(_owner);
			if(_skipRendering)
				return;
			
			if(renderCallback!=null)
				renderCallback();
			
			super.render(support, parentAlpha);
		}
	}
}
