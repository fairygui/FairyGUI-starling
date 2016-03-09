package fairygui.display
{
	import flash.geom.Point;
	
	import fairygui.GObject;
	import fairygui.utils.PixelHitTest;
	
	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.Sprite;

	public class UISprite extends Sprite implements UIDisplayObject 
	{
		private var _owner:GObject;
		private var _hitArea:Object;
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
		
		public function get hitArea():Object
		{
			return _hitArea;
		}
		
		public function set hitArea(value:Object):void
		{
			_hitArea = value;
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
			if(_hitArea!=null && (this.touchable || !forTouch))
			{
				if(ret==null)
				{
					if(_hitArea.contains(localX, localY))
						ret = this;
				}
				else
				{
					if((_hitArea is PixelHitTest) && !_hitArea.contains(localX, localY))
						ret = null;
				}
			}

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
