package fairygui.text {
	import starling.display.DisplayObject;
	
	public interface IRichTextObjectFactory {
		function createObject(src:String, width:int, height:int):DisplayObject;
		function freeObject(obj:DisplayObject):void;
	}
}