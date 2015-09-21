package fairygui.event
{
	import starling.events.Event;
	
	public class StateChangeEvent extends Event 
	{
		public static const CHANGED:String = "___stateChanged";

		public function StateChangeEvent(type:String) 
		{
			super(type, false);
		}
	}
	
}