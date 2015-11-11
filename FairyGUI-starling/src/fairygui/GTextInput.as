package fairygui
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	
	import starling.core.Starling;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class GTextInput extends GTextField
	{
		private var _nativeTextField:TextField;
		private var _editable:Boolean;
		
		public function GTextInput()
		{
			super();
			
			this.focusable = true;
			_editable = true;
			_canvas.touchable = true;
			_nativeTextField = new TextField();
			_nativeTextField.type = TextFieldType.INPUT;
			_nativeTextField.addEventListener(FocusEvent.FOCUS_OUT, __focusOut);
			
			this.addEventListener(TouchEvent.TOUCH, __touch);
		}
		
		override public function dispose():void
		{
			if(_nativeTextField.parent)
			{
				var stage:Stage = Starling.current.nativeStage;
				stage.removeChild(_nativeTextField);
			}
			super.dispose();
		}
		
		public function get nativeTextField():TextField
		{
			return _nativeTextField;
		}
		
		public function set editable(val:Boolean):void
		{
			_editable = val;
		}
		
		public function get editable():Boolean
		{
			return _editable;
		}
		
		public function set maxLength(val:int):void
		{
			_nativeTextField.maxChars = val;
		}
		
		public function get maxLength():int
		{
			return _nativeTextField.maxChars;
		}
		
		override protected function handleSizeChanged():void
		{
			super.handleSizeChanged();
			
			_canvas.width = this.width*GRoot.contentScaleFactor;
			_canvas.height = this.height*GRoot.contentScaleFactor+_fontAdjustment;
		}
		
		private function __touch(evt:TouchEvent):void
		{
			if(!_editable)
				return;
			
			var touch:Touch = evt.getTouch(displayObject);
			if(touch && touch.phase==TouchPhase.BEGAN)
			{
				_nativeTextField.defaultTextFormat = _textFormat;
				_nativeTextField.displayAsPassword = this.displayAsPassword;
				_nativeTextField.wordWrap = !_singleLine;
				_nativeTextField.multiline = !_singleLine;
				_nativeTextField.text = _text;
				_nativeTextField.setSelection(0, int.MAX_VALUE);
				
				var pt:Point = this.localToGlobal();
				pt.x*=GRoot.contentScaleFactor;
				pt.y*=GRoot.contentScaleFactor;
				pt.y = pt.y-_yOffset-_fontAdjustment;
				var stage:Stage = Starling.current.nativeStage;
				_nativeTextField.x = pt.x;
				_nativeTextField.y = pt.y;
				_nativeTextField.width = this.width*GRoot.contentScaleFactor;
				_nativeTextField.height = this.height*GRoot.contentScaleFactor+_fontAdjustment;
				stage.addChild(_nativeTextField);
				stage.focus = _nativeTextField;
				
				_canvas.visible = false;
			}
		}
		
		private function __focusOut(evt:Event):void
		{
			if(_nativeTextField.parent)
			{
				var stage:Stage = Starling.current.nativeStage;
				stage.removeChild(_nativeTextField);
				_canvas.visible = true;
				this.text = _nativeTextField.text;
			}
		}
	}
}