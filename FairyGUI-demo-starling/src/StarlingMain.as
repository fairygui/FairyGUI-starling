package
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import fairygui.GRoot;
	import fairygui.UIConfig;
	import fairygui.UIPackage;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;

	public class StarlingMain extends Sprite
	{
		private var _loader:URLLoader;
		private var _mainPanel:MainPanel;

		public function StarlingMain()
		{
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(evt:starling.events.Event):void
		{
			var path:String = "assets/demo.zip";
			
			_loader = new URLLoader();
			_loader.dataFormat = URLLoaderDataFormat.BINARY;
			_loader.load(new URLRequest(path));
			_loader.addEventListener(flash.events.Event.COMPLETE, onLoadComplete);
		}
		
		private function onLoadComplete(evt:flash.events.Event):void
		{
			UIPackage.addPackage(ByteArray(_loader.data), null);
			
			UIConfig.defaultFont = "Droid Sans Fallback; Droid Sans; SimSun";
			UIConfig.verticalScrollBar = UIPackage.getItemURL("Demo", "ScrollBar_VT");
			UIConfig.horizontalScrollBar = UIPackage.getItemURL("Demo", "ScrollBar_HZ");
			UIConfig.popupMenu = UIPackage.getItemURL("Demo", "PopupMenu");
			UIConfig.defaultScrollBounceEffect = true;
			UIConfig.defaultScrollTouchEffect = true;
			
			//等待图片资源全部解码，也可以选择不等待，这样图片会在用到的时候才解码
			UIPackage.waitToLoadCompleted(continueInit);
		}
		
		private function continueInit():void {
			stage.addChild(new GRoot().displayObject);
			
			//if(Capabilities.isDebugger)
			Starling.current.showStatsAt("left","top");
			
			GRoot.inst.setContentScaleFactor(640, 960);
			
			_mainPanel = new MainPanel();
		}
	}
}