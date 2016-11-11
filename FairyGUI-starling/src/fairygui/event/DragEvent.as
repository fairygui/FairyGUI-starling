package fairygui.event
{
	import starling.events.Event;
	
	public class DragEvent extends Event
	{
		public var stageX:Number;
		public var stageY:Number;
		public var touchPointID:int;
		
		private var _prevented:Boolean;
		
		public static const DRAG_START:String = "startDrag";
		public static const DRAG_END:String = "endDrag";
		public static const DRAG_MOVING:String = "dragMoving";
		
		public function DragEvent(type:String, stageX:Number=0, stageY:Number=0, touchPointID:int=-1)
		{
			super(type, false);

			this.stageX = stageX;
			this.stageY = stageY;
			this.touchPointID = touchPointID;
		}
		
		public function preventDefault():void
		{
			_prevented = true;
		}
		
		public function isDefaultPrevented():Boolean
		{
			return _prevented;
		}
	}
}