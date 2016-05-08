package fairygui.event
{
	import starling.events.Event;
	
	public class TextEvent extends Event
	{
		public var _text:String;
		
		public static const LINK:String = "textLink";
		
		public function TextEvent(type:String, bubbles:Boolean, text:String)
		{
			super(type, bubbles);
			
			_text = text;
		}
		
		public function get text():String
		{
			return _text;
		}
	}
}