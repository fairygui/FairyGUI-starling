package fairygui.display
{
	import fairygui.GObject;
	
	public class UIImage extends ImageExt implements UIDisplayObject 
	{
		private var _owner:GObject;

		public function UIImage(owner:GObject)
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

