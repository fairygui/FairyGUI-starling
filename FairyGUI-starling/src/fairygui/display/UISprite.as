package fairygui.display
{
	import flash.geom.Point;
	
	import fairygui.GObject;
	import fairygui.utils.PixelHitTest;
	
	import starling.display.DisplayObject;
	import starling.display.Sprite;

	public class UISprite extends Sprite implements UIDisplayObject 
	{
		private var _owner:GObject;
		private var _hitArea:Object;
		
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
			super.dispose();
		}
		
		public override function hitTest(localPoint:Point):DisplayObject
		{
			var localX:Number = localPoint.x;
			var localY:Number = localPoint.y;
			
			var ret:DisplayObject = super.hitTest(localPoint);
			if(_hitArea!=null && this.touchable)
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
	}
}
