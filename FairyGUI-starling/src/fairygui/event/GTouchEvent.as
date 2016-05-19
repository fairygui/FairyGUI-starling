package fairygui.event
{
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	
	public class GTouchEvent extends Event
	{
		private var _stopPropagation:Boolean;
		
		private var _realTarget:DisplayObject;
		private var _clickCount:int;
		private var _stageX:Number;
		private var _stageY:Number;
		private var _shiftKey:Boolean;
		private var _ctrlKey:Boolean;
		private var _touchPointID:int;
		
		public static const BEGIN:String = "beginGTouch";
		public static const DRAG:String = "dragGTouch";
		public static const END:String = "endGTouch";
		public static const CLICK:String = "clickGTouch";
		public static const ROLL_OVER:String = "rollOverGTouch";
		public static const ROLL_OUT:String = "rollOutGTouch";
		
		public function GTouchEvent(type:String):void
		{
			super(type, false);
		}
		
		public function copyFrom(evt:TouchEvent, touch:Touch, clickCount:int=1):void
		{
			if(touch!=null)
			{
				_stageX = touch.globalX;
				_stageY = touch.globalY;
				_touchPointID = touch.id;
			}
			_shiftKey = evt.shiftKey;
			_ctrlKey = evt.ctrlKey;
			
			_realTarget = evt.target as DisplayObject;
			_clickCount = clickCount;
			_stopPropagation = false;
		}
		
		final public function get realTarget():DisplayObject
		{
			return _realTarget;
		}
		final public function get clickCount():int
		{
			return _clickCount;
		}
		final public function get stageX():Number
		{
			return _stageX;
		}
		final public function get stageY():Number
		{
			return _stageY;
		}
		final public function get shiftKey():Boolean
		{
			return _shiftKey;
		}
		final public function get ctrlKey():Boolean
		{
			return _ctrlKey;
		}
		final public function get touchPointID():int
		{
			return _touchPointID;
		}
		override public function stopPropagation():void
		{
			_stopPropagation = true;
		}
		
		final public function get isPropagationStop():Boolean
		{
			return _stopPropagation;
		}
	}
}