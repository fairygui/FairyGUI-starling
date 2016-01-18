package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	
	import starling.core.Starling;
	
	public class Main extends Sprite
	{		
		public function Main()
		{
			stage.frameRate = 60;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.stageFocusRect = false;
			stage.color = 0x9F9F9F;
			
			stage.addEventListener(Event.RESIZE, onResized);
		}
		
		private function onResized(evt:Event):void
		{	
			stage.removeEventListener(Event.RESIZE, onResized);
			
			Starling.handleLostContext = Capabilities.os.slice(0,2).toLowerCase()!="ip";
			
			var starlingInst:Starling = new Starling(StarlingMain, stage);			
			starlingInst.simulateMultitouch = false;
			starlingInst.enableErrorChecking = false;
			
			var w:int, h:int;
			if(Capabilities.os.toLowerCase().slice(0,3)=="win" 
				|| Capabilities.os.toLowerCase().slice(0,3)=="mac")
			{
				w = stage.stageWidth;
				h = stage.stageHeight;
			}
			else
			{
				w = Capabilities.screenResolutionX;
				h = Capabilities.screenResolutionY;
			}

			starlingInst.stage.stageWidth  = w;
			starlingInst.stage.stageHeight = h;
			starlingInst.viewPort = new Rectangle(0,0,w,h);
			starlingInst.start();
		}
	}
}