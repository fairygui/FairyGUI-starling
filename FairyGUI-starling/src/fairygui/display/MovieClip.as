package fairygui.display
{
	import flash.geom.Rectangle;
	
	import fairygui.utils.GTimers;
	
	import starling.core.RenderSupport;
	import starling.display.QuadBatch;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	
	public class MovieClip extends FixedSizeObject
	{
		public var interval:int;
		public var swing:Boolean;
		public var repeatDelay:int;
		
		private var _texture:Texture;
		private var _batch:QuadBatch;
		private var _frameRect:Rectangle;
		private var _smoothing:String;
		
		private var _playing:Boolean;
		private var _playState:PlayState;
		private var _frameCount:int;
		private var _frames:Vector.<Frame>;
		private var _currentFrame:int;
		private var _boundsRect:Rectangle;
		private var _start:int;
		private var _end:int;
		private var _times:int;
		private var _endAt:int;
		private var _status:int; //0-none, 1-next loop, 2-ending, 3-ended
		private var _callback:Function;
		
		public function MovieClip()
		{
			//MovieClip is by default touchable
			this.touchable = false;
			
			_playState = new PlayState();
			_playing = true;
			_smoothing = TextureSmoothing.BILINEAR;
			
			_batch = new QuadBatch();
			_batch.capacity = 1;
			
			setPlaySettings();
		}
		
		public function get playState():PlayState
		{
			return _playState;
		}
		
		public function set playState(value:PlayState):void
		{
			_playState = value;
		}
		
		override public function dispose():void
		{
			_batch.dispose();
			
			super.dispose();
		}
		
		public function get smoothing():String
		{
			return _smoothing;
		}
		
		public function set smoothing(value:String):void
		{
			if(_smoothing != value)
			{
				_smoothing = value;
				_needRebuild = true;
			}
		}
		
		override public function set blendMode(value:String):void
		{
			super.blendMode = value;
			_batch.blendMode = value;
		}

		public function get frames():Vector.<Frame>
		{
			return _frames;
		}
		
		public function set frames(value:Vector.<Frame>):void
		{
			_frames = value;
			if(_frames!=null)
				_frameCount = _frames.length;
			else
				_frameCount = 0;
			
			if(_end==-1 || _end>_frameCount - 1)
				_end = _frameCount - 1;
			if(_endAt==-1 || _endAt>_frameCount - 1)
				_endAt = _frameCount - 1;
			
			if(_currentFrame<0 || _currentFrame>_frameCount - 1)
				_currentFrame = _frameCount - 1;
		}
		
		public function get frameCount():int
		{
			return _frameCount;
		}
		
		public function get boundsRect():Rectangle
		{
			return _boundsRect;
		}
		
		public function set boundsRect(value:Rectangle):void
		{
			_boundsRect = value;
			this.setSize(_boundsRect.right, _boundsRect.bottom);
		}
		
		public function get currentFrame():int
		{
			return _currentFrame;
		}
		
		public function set currentFrame(value:int):void
		{
			if (_currentFrame != value)
			{
				_currentFrame = value;
				_playState.currentFrame = value;
				setFrame(_currentFrame<_frameCount?_frames[_currentFrame]:null);
			}
		}
		
		public function get playing():Boolean
		{
			return _playing;
		}
		
		public function set playing(value:Boolean):void
		{
			_playing = value;
		}
		
		//从start帧开始，播放到end帧（-1表示结尾），重复times次（0表示无限循环），循环结束后，停止在endAt帧（-1表示参数end）
		public function setPlaySettings(start:int = 0, end:int = -1, 
										times:int = 0, endAt:int = -1, 
										endCallback:Function = null):void
		{
			_start = start;
			_end = end;
			if(_end==-1 || _end>_frameCount - 1)
				_end = _frameCount - 1;
			_times = times;
			_endAt = endAt;
			if (_endAt == -1)
				_endAt = _end;
			_status = 0;
			_callback = endCallback;			
			this.currentFrame = start;
		}
		
		private function update():void
		{
			if (_playing && _frameCount != 0 && _status != 3)
			{
				_playState.update(this);
				if (_currentFrame != _playState.currentFrame)
				{
					if (_status == 1)
					{
						_currentFrame = _start;
						_playState.currentFrame = _currentFrame;
						_status = 0;
					}
					else if (_status == 2)
					{
						_currentFrame = _endAt;
						_playState.currentFrame = _currentFrame;
						_status = 3;
						
						//play end
						if(_callback!=null)
							GTimers.inst.callLater(__playEnd);
					}
					else
					{
						_currentFrame = _playState.currentFrame;
						if (_currentFrame == _end)
						{
							if (_times > 0)
							{
								_times--;
								if (_times == 0)
									_status = 2;
								else
									_status = 1;
							}
						}
					}
					
					//draw
					setFrame(_frames[_currentFrame]);
				}
			}
			else
				setFrame(null);
		}
		
		private function __playEnd():void
		{
			if(_callback!=null)
			{
				var f:Function = _callback;
				_callback = null;
				if(f.length == 1)
					f(this);
				else
					f();
			}
		}
		
		private function setFrame(frame:Frame):void
		{
			if(frame==null)
			{
				if(_texture!=null)
				{
					_texture = null;
					_needRebuild = true;
				}
			}
			else if(_texture != frame.texture)
			{
				_texture = frame.texture;
				_frameRect = frame.rect;
				_needRebuild = true;
			}
		}
		
		private static var sHelperQuad:QuadExt;
		override public function render(support:RenderSupport, parentAlpha:Number):void
		{
			this.update();
			
			if(_needRebuild)
			{
				_needRebuild = false;
				
				if(sHelperQuad==null)
					sHelperQuad = new QuadExt();
			
				_batch.reset();
				if(_texture!=null)
				{
					sHelperQuad.setPremultipliedAlpha(_texture.premultipliedAlpha);
					sHelperQuad.fillVertsWithScale(_frameRect.x, _frameRect.y, _texture.width, _texture.height, 
						_scaleX, _scaleY);
					sHelperQuad.fillUVOfTexture(_texture);
					_batch.addQuad(sHelperQuad, 1.0, _texture, _smoothing);
					
					_batch.blendMode = this.blendMode;
				}
			}
			
			if(_batch.numQuads>0)
				support.batchQuadBatch(_batch, this.alpha*parentAlpha);
		}
	}
}
