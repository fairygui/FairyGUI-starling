package fairygui.event
{
	import fairygui.GObject;
	
	import starling.events.Event;
	
	public class ItemEvent extends Event 
	{
		public var itemObject:GObject;
		public var stageX:Number;
		public var stageY:Number;
		public var clickCount:int;
		public var rightButton:Boolean;
		
		public static const CLICK:String = "itemClick";
		
		public function ItemEvent(type:String, itemObject:GObject=null,
								  stageX:Number=0, stageY:Number=0, clickCount:int=1, rightButton:Boolean=false) {
			super(type, false);
			this.itemObject = itemObject;
			this.stageX = stageX;
			this.stageY = stageY;
			this.clickCount = clickCount;
			this.rightButton = rightButton;
		}
	}
	
}