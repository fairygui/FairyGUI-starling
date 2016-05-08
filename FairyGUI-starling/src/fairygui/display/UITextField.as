package fairygui.display
{
	import fairygui.GObject;
	
	public class UITextField extends TextCanvas implements UIDisplayObject 
	{
		private var _owner:GObject;
		
		public function UITextField(owner:GObject)
		{
			super();
			_owner = owner;
		}
		
		public function get owner():GObject
		{
			return _owner;
		}
	}
}
