package fairygui
{
	import flash.display.Stage;
	import flash.events.FocusEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import fairygui.utils.FontUtils;
	import fairygui.utils.ToolSet;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class GTextInput extends GTextField
	{
		private var _nativeTextField:TextField;
		private var _editable:Boolean;
		private var _promptText:String;
		private var _password:Boolean;
		
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
			this.addEventListener(Event.REMOVED_FROM_STAGE, __removeFromStage);
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
		
		override public function get text():String
		{
			if(_nativeTextField.parent)
				_text = _nativeTextField.text;
			
			return _text;
		}
		
		override public function set text(value:String):void
		{
			super.text = value;
			
			if(_nativeTextField.parent)
				_nativeTextField.text = _text;
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
		
		public function get promptText():String
		{
			return _promptText;
		}
		
		public function set promptText(value:String):void
		{
			_promptText = value;
			renderNow();
		}
		
		public function get restrict():String
		{
			return _nativeTextField.restrict;
		}
		
		public function set restrict(value:String):void
		{
			_nativeTextField.restrict = value;
		}
		
		public function get password():Boolean
		{
			return _password;
		}
		
		public function set password(val:Boolean):void
		{
			if(_password != val)
			{
				_password = val;
				render();
			}
		}
		
		override protected function handleSizeChanged():void
		{
			super.handleSizeChanged();
			
			_canvas.setCanvasSize(this.width, this.height+_fontAdjustment);
		}
		
		override protected function updateTextFieldText():void
		{
			if(!_text && _promptText)
			{
				renderTextField.htmlText = ToolSet.parseUBB(ToolSet.encodeHTML(_promptText));
			}
			else if(_password)
			{
				var str:String = "";
				var cnt:int = _text.length;
				for(var i:int=0;i<cnt;i++)
					str += "*";
				renderTextField.text = str; 
			}
			else if(_ubbEnabled)
				renderTextField.htmlText = ToolSet.parseUBB(ToolSet.encodeHTML(_text));
			else
				renderTextField.text = _text;
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			_promptText = xml.@prompt;
			var str:String = xml.@maxLength;
			if(str)
				_nativeTextField.maxChars = parseInt(str);
			str = xml.@restrict;
			if(str)
				_nativeTextField.restrict = str;
			_password = xml.@password=="true";
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			if(!_text && _promptText)
				renderNow();
		}
		
		private function __touch(evt:TouchEvent):void
		{
			if(!_editable)
				return;
			
			var touch:Touch = evt.getTouch(displayObject);
			if(touch && touch.phase==TouchPhase.BEGAN)
			{
				startInput();
				evt.stopPropagation();
			}
		}
		
		public function startInput():void
		{
			var textFormat:TextFormat;
			if(_nativeTextField.defaultTextFormat==null)
				textFormat = new TextFormat();
			else
				textFormat = _nativeTextField.defaultTextFormat;
			textFormat.font = _textFormat.font;
			textFormat.align = _textFormat.align;
			textFormat.bold = _textFormat.bold;
			textFormat.color = _textFormat.color;
			textFormat.italic = _textFormat.italic;
			textFormat.leading = int(_textFormat.leading)*GRoot.contentScaleFactor;
			textFormat.letterSpacing = int(_textFormat.letterSpacing)*GRoot.contentScaleFactor;
			textFormat.size = int(_textFormat.size)*GRoot.contentScaleFactor;
			_nativeTextField.embedFonts = FontUtils.isEmbeddedFont(textFormat);
			_nativeTextField.defaultTextFormat = textFormat;
			_nativeTextField.displayAsPassword = _password;
			_nativeTextField.wordWrap = !_singleLine;
			_nativeTextField.multiline = !_singleLine;
			_nativeTextField.text = _text;
			_nativeTextField.setSelection(0, int.MAX_VALUE);
			
			var rect:Rectangle = this.localToGlobalRect(0, -_yOffset-_fontAdjustment, this.width, this.height+_fontAdjustment);
			var stage:Stage = Starling.current.nativeStage;
			_nativeTextField.x = int(rect.x);
			var _hOffset:Number = 0;//(stage.fullScreenHeight - Starling.current.stage.stageHeight) >> 1;
			_nativeTextField.y = int(rect.y) + _hOffset;
			_nativeTextField.width = int(rect.width);
			_nativeTextField.height = int(rect.height);
			stage.addChild(_nativeTextField);
			stage.focus = _nativeTextField;
			
			_canvas.visible = false;
		}
		
		private function __focusOut(evt:FocusEvent):void
		{
			if(_nativeTextField.parent)
			{
				var stage:Stage = Starling.current.nativeStage;
				stage.removeChild(_nativeTextField);
				_canvas.visible = true;
				this.text = _nativeTextField.text;
			}
		}
		
		private function __removeFromStage(evt:Event):void
		{
			if(_nativeTextField.parent)
			{
				var stage:Stage = Starling.current.nativeStage;
				stage.removeChild(_nativeTextField);
				_canvas.visible = true;
			}
		}
	}
}