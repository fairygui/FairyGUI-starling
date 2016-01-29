package fairygui.event
{
	import starling.events.Event;
	
	public class StateChangeEvent extends Event 
	{
		public static const CHANGED:String = "stateChanged";

		public function StateChangeEvent(type:String) 
		{
			super(type, false);
		}
	}
	
}