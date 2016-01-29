package fairygui.event
{
	import fairygui.GObject;
	
	import starling.events.Event;
	
	public class FocusChangeEvent extends Event 
	{
		public static const CHANGED:String = "focusChanged";
		
		private var _oldFocusedObject:GObject;
		private var _newFocusedObject:GObject;
		
		public function FocusChangeEvent(type:String, oldObject:GObject, newObject:GObject) 
		{
			super(type, false);
			_oldFocusedObject = oldObject;
			_newFocusedObject = newObject;
		}
		
		final public function get oldFocusedObject():GObject
		{
			return _oldFocusedObject;
		}
		
		final public function get newFocusedObject():GObject
		{
			return _newFocusedObject;
		}
	}
}

