package fairygui
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Mouse;
	import flash.utils.getTimer;
	
	import fairygui.event.DragEvent;
	import fairygui.event.GTouchEvent;
	import fairygui.utils.GTimers;
	import fairygui.utils.SimpleDispatcher;
	import fairygui.utils.ToolSet;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.ColorMatrixFilter;
	import starling.filters.FragmentFilter;
	import starling.utils.MatrixUtil;
	import starling.utils.deg2rad;
	
	[Event(name = "startDrag", type = "fairygui.event.DragEvent")]
	[Event(name = "endDrag", type = "fairygui.event.DragEvent")]
	[Event(name = "dragMoving", type = "fairygui.event.DragEvent")]
	[Event(name = "beginGTouch", type = "fairygui.event.GTouchEvent")]
	[Event(name = "endGTouch", type = "fairygui.event.GTouchEvent")]
	[Event(name = "dragGTouch", type = "fairygui.event.GTouchEvent")]
	[Event(name = "clickGTouch", type = "fairygui.event.GTouchEvent")]
	[Event(name = "rollOverGTouch", type = "fairygui.event.GTouchEvent")]
	[Event(name = "rollOutGTouch", type = "fairygui.event.GTouchEvent")]
	public class GObject extends EventDispatcher
	{
		public var data:Object;
		public var packageItem:PackageItem;
		public static var draggingObject:GObject;
		
		public var sourceWidth:Number;
		public var sourceHeight:Number;
		public var initWidth:Number;
		public var initHeight:Number;
		public var minWidth:Number;
		public var minHeight:Number;
		public var maxWidth:Number;
		public var maxHeight:Number;
		
		private var _x:Number;
		private var _y:Number;
		private var _alpha:Number;
		private var _rotation:Number;
		private var _visible:Boolean;
		private var _touchable:Boolean;
		private var _grayed:Boolean;
		private var _draggable:Boolean;
		private var _scaleX:Number;
		private var _scaleY:Number;
		private var _skewX:Number;
		private var _skewY:Number;
		private var _pivotX:Number;
		private var _pivotY:Number;
		private var _pivotAsAnchor:Boolean;
		private var _pivotOffsetX:Number;
		private var _pivotOffsetY:Number;
		private var _sortingOrder:int;
		private var _internalVisible:Boolean;
		private var _handlingController:Boolean;
		private var _focusable:Boolean;
		private var _tooltips:String;
		private var _pixelSnapping:Boolean;
		
		private var _relations:Relations;
		private var _group:GGroup;
		private var _gears:Vector.<GearBase>;
		private var _displayObject:DisplayObject;
		private var _dragBounds:Rectangle;
		
		protected var _yOffset:int;
		//Size的实现方式，有两种，0-GObject的w/h等于DisplayObject的w/h。1-GObject的sourceWidth/sourceHeight等于DisplayObject的w/h，剩余部分由scale实现
		protected var _sizeImplType:int;
		
		internal var _parent:GComponent;
		internal var _dispatcher:SimpleDispatcher;
		internal var _width:Number;
		internal var _height:Number;
		internal var _rawWidth:Number;
		internal var _rawHeight:Number;
		internal var _id:String;
		internal var _name:String;
		internal var _underConstruct:Boolean;
		internal var _gearLocked:Boolean;
		internal var _sizePercentInGroup:Number;
		
		internal static var _gInstanceCounter:uint;
		
		internal static const XY_CHANGED:int = 1;
		internal static const SIZE_CHANGED:int = 2;
		internal static const SIZE_DELAY_CHANGE:int = 3;
		
		public function GObject()
		{
			_x = 0;
			_y = 0;
			_width = 0;
			_height = 0;
			_rawWidth = 0;
			_rawHeight = 0;
			sourceWidth = 0;
			sourceHeight = 0;
			initWidth = 0;
			initHeight = 0;
			minWidth = 0;
			minHeight = 0;
			maxWidth = 0;
			maxHeight = 0;
			_id = "_n" + _gInstanceCounter++;
			_name = "";
			_alpha = 1;
			_rotation = 0;
			_visible = true;
			_internalVisible = true;
			_touchable = true;
			_scaleX = 1;
			_scaleY = 1;
			_skewX = 0;
			_skewY = 0;
			_pivotX = 0;
			_pivotY = 0;
			_pivotOffsetX = 0;
			_pivotOffsetY = 0;
			
			createDisplayObject();
			
			_relations = new Relations(this);
			_dispatcher = new SimpleDispatcher();
			_gears = new Vector.<GearBase>(8, true);
		}

		final public function get id():String
		{
			return _id;
		}

		final public function get name():String
		{
			return _name;
		}

		final public function set name(value:String):void
		{
			_name = value;
		}

		final public function get x():Number
		{
			return _x;
		}
		
		final public function set x(value:Number):void
		{
			setXY(value, _y);
		}
		
		final public function get y():Number
		{
			return _y;
		}
		
		final public function set y(value:Number):void
		{
			setXY(_x, value);
		}
		
		final public function setXY(xv:Number, yv:Number):void
		{
			if(_x!=xv || _y!=yv)
			{
				var dx:Number = xv-_x;
				var dy:Number = yv-_y;
				_x = xv;
				_y = yv;
				
				handlePositionChanged();
				if(this is GGroup)
					GGroup(this).moveChildren(dx, dy);
				
				updateGear(1);
				
				if (parent != null && !(parent is GList))
				{
					_parent.setBoundsChangedFlag();
					if (_group != null)
						_group.setBoundsChangedFlag();
					_dispatcher.dispatch(this, XY_CHANGED);
				}
				
				if (draggingObject == this && !sUpdateInDragging)
					this.localToGlobalRect(0,0,this.width,this.height,sGlobalRect);
			}
		}
		
		public function get pixelSnapping():Boolean
		{
			return _pixelSnapping;
		}
		
		public function set pixelSnapping(value:Boolean):void
		{
			if(_pixelSnapping!=value)
			{
				_pixelSnapping = value;
				handlePositionChanged();
			}
		}
		
		public function center(restraint:Boolean=false):void
		{
			var r:GComponent;
			if (parent != null)
				r = parent;
			else
				r = this.root;
			
			this.setXY(int((r.width-this.width)/2), int((r.height-this.height)/2));
			if (restraint)
			{
				this.addRelation(r, RelationType.Center_Center);
				this.addRelation(r, RelationType.Middle_Middle);
			}
		}
		
		final public function get width():Number
		{
			if(!this._underConstruct)
			{
				ensureSizeCorrect();
				if(_relations.sizeDirty)
					_relations.ensureRelationsSizeCorrect();
			}
			return _width;
		}
		
		final public function set width(value:Number):void
		{
			setSize(value, _rawHeight);
		}
		
		final public function get height():Number
		{
			if(!this._underConstruct)
			{
				ensureSizeCorrect();
				if(_relations.sizeDirty)
					_relations.ensureRelationsSizeCorrect();
			}
			return _height;
		}
		
		final public function set height(value:Number):void
		{
			setSize(_rawWidth, value);
		}
		
		public function setSize(wv:Number, hv:Number, ignorePivot:Boolean = false):void
		{
			if(_rawWidth!=wv || _rawHeight!=hv)
			{
				_rawWidth = wv;
				_rawHeight = hv;
				if(wv<minWidth)
					wv = minWidth;
				if(hv<minHeight)
					hv = minHeight;
				if(maxWidth>0 && wv>maxWidth)
					wv = maxWidth;
				if(maxHeight>0 && hv>maxHeight)
					hv = maxHeight;
				var dWidth:Number = wv-_width;
				var dHeight:Number = hv-_height;
				_width = wv;
				_height = hv;
				
				handleSizeChanged();
				if(_pivotX!=0 || _pivotY!=0)
				{
					if(_sizeImplType==0)
					{
						_displayObject.pivotX = _pivotX * _width;
						_displayObject.pivotY = _pivotY * _height;
					}
					if(!_pivotAsAnchor)
					{
						if(!ignorePivot)
							this.setXY(this.x-_pivotX*dWidth, this.y-_pivotY*dHeight);

						updatePivotOffset();
					}
					else
					{
						updatePivotOffset();
						handlePositionChanged();
					}
				}		
				
				if (this is GGroup)
					GGroup(this).resizeChildren(dWidth, dHeight);
				
				updateGear(2);
				
				if(_parent)
				{
					_relations.onOwnerSizeChanged(dWidth, dHeight);
					_parent.setBoundsChangedFlag();
					if (_group != null)
						_group.setBoundsChangedFlag(true);
				}

				_dispatcher.dispatch(this, SIZE_CHANGED);
			}
		}
		
		public function ensureSizeCorrect():void
		{
		}

		final public function get actualWidth():Number
		{
			return this.width*_scaleX;
		}
		
		final public function get actualHeight():Number
		{
			return this.height*_scaleY;
		}
		
		final public function get scaleX():Number
		{
			return _scaleX;
		}
		
		final public function set scaleX(value:Number):void
		{
			setScale(value, _scaleY);
		}
		
		final public function get scaleY():Number
		{
			return _scaleY;
		}
		
		final public function set scaleY(value:Number):void
		{
			setScale(_scaleX, value);
		}
		
		final public function setScale(sx:Number, sy:Number):void
		{
			if(_scaleX!=sx || _scaleY!=sy)
			{
				_scaleX = sx;
				_scaleY = sy;
				handleScaleChanged();
				updatePivotOffset();
				updateGear(2);
			}
		}
		
		final public function get skewX():Number
		{
			return _skewX;
		}
		
		public function set skewX(value:Number):void
		{
			setSkew(value, _skewY);
		}
		
		final public function get skewY():Number
		{
			return _skewY;
		}
		
		public function set skewY(value:Number):void
		{
			setSkew(_skewX, value);
		}
		
		public function setSkew(xv:Number, yv:Number):void
		{
			if(_skewX!=xv || _skewY!=yv)
			{
				_skewX = xv;
				_skewY = yv;
				if(_displayObject!=null)
				{
					_displayObject.skewX = _skewX*Math.PI/180;
					_displayObject.skewY = _skewY*Math.PI/180;
					updatePivotOffset();
				}				
			}
		}
		
		final public function get pivotX():Number
		{
			return _pivotX;
		}
		
		final public function set pivotX(value:Number):void
		{
			setPivot(value, _pivotY);
		}
		
		final public function get pivotY():Number
		{
			return _pivotY;
		}
		
		final public function set pivotY(value:Number):void
		{
			setPivot(_pivotX, value);
		}
		
		final public function setPivot(xv:Number, yv:Number, asAnchor:Boolean=false):void
		{
			if(_pivotX!=xv || _pivotY!=yv || _pivotAsAnchor!=asAnchor)
			{
				_pivotX = xv;
				_pivotY = yv;
				_pivotAsAnchor = asAnchor;
				
				if(_displayObject!=null)
				{				
					if(_sizeImplType==0)
					{
						_displayObject.pivotX = _pivotX * _width;
						_displayObject.pivotY = _pivotY * _height;
					}
					else
					{
						_displayObject.pivotX = _pivotX * sourceWidth;
						_displayObject.pivotY = _pivotY * sourceHeight;
					}
					updatePivotOffset();
					handlePositionChanged();
				}
			}
		}
		
		private function updatePivotOffset():void
		{
			if(_displayObject!=null)
			{
				//GObject的特点是旋转和缩放不影响坐标，所以要有一个GObject坐标和DisplayObject坐标的转换。pivotOffset就是两个坐标的偏移值
				if(_pivotX!=0 || _pivotY!=0)
				{
					var pt:Point = MatrixUtil.transformCoords(_displayObject.transformationMatrix, 
						_displayObject.pivotX, _displayObject.pivotY, sHelperPoint);
					_pivotOffsetX = _pivotX*_width - (pt.x - _displayObject.x);
					_pivotOffsetY = _pivotY*_height - (pt.y - _displayObject.y);
				}
				else					
				{
					_pivotOffsetX = 0;
					_pivotOffsetY = 0;
				}				
			}
		}

		final public function get touchable():Boolean
		{
			return _touchable;
		}
		
		public function set touchable(value:Boolean):void
		{
			if(_touchable!=value)
			{
				_touchable = value;
				updateGear(3);
				
				if((this is GImage) || (this is GMovieClip) 
					|| (this is GTextField) && !(this is GTextInput) && !(this is GRichTextField))
					//Touch is not supported by GImage/GMovieClip/GTextField
					return;
				
				if(_displayObject!=null)
					_displayObject.touchable = _touchable;
			}
		}
		
		final public function get grayed():Boolean
		{
			return _grayed;
		}
		
		public function set grayed(value:Boolean):void
		{
			if(_grayed!=value)
			{
				_grayed = value;
				handleGrayedChanged();
				updateGear(3);
			}
		}
		
		final public function get enabled():Boolean
		{
			return !_grayed && _touchable;
		}
		
		public function set enabled(value:Boolean):void
		{
			this.grayed = !value;
			this.touchable = value; 
		}
		
		final public function get rotation():Number
		{
			return _rotation;
		}
		
		public function set rotation(value:Number):void
		{
			if(_rotation!=value)
			{
				_rotation = value;
				if(_displayObject!=null)
				{
					_displayObject.rotation = deg2rad(this.normalizeRotation);
					updatePivotOffset();
				}
				updateGear(3);
			}
		}
		
		public function get normalizeRotation():Number
		{
			var rot:Number = _rotation%360;
			if(rot>180)
				rot = rot-360;
			else if(rot<-180)
				rot = 360+rot;
			return rot;
		}
		
		final public function get alpha():Number
		{
			return _alpha;
		}
		
		public function set alpha(value:Number):void
		{
			if(_alpha!=value)
			{
				_alpha = value;
				handleAlphaChanged();
				updateGear(3);
			}
		}
		
		final public function get visible():Boolean
		{
			return _visible;
		}
		
		public function set visible(value:Boolean):void
		{
			if(_visible!=value)
			{
				_visible = value;
				handleVisibleChanged();
				if(_parent)
					_parent.setBoundsChangedFlag();
			}
		}
		
		public function get internalVisible():Boolean
		{
			return _internalVisible && (!_group || _group.internalVisible);
		}
		
		public function get internalVisible2():Boolean
		{
			return _visible && (!_group || _group.internalVisible2);
		}
		
		final public function get sortingOrder():int
		{
			return _sortingOrder;
		}
		
		public function set sortingOrder(value:int):void
		{
			if(value<0)
				value = 0;
			if(_sortingOrder!=value)
			{
				var old:int = _sortingOrder;
				_sortingOrder = value;
				if(_parent!=null)
					_parent.childSortingOrderChanged(this, old, _sortingOrder);
			}
		}
		
		final public function get focusable():Boolean
		{
			return _focusable;
		}
		
		public function set focusable(value:Boolean):void
		{
			_focusable = value;
		}
		
		public function get focused():Boolean
		{
			return this.root.focus == this;
		}
		
		public function requestFocus():void
		{
			var p:GObject = this;
			while(p && !p._focusable)
				p = p.parent;
			if(p!=null)
				this.root.focus = p;
		}
		
		final public function get tooltips():String
		{
			return _tooltips;
		}
		
		public function set tooltips(value:String):void
		{
			if(_tooltips && Mouse.supportsCursor)
			{
				this.removeEventListener(GTouchEvent.ROLL_OVER, __rollOver);
				this.removeEventListener(GTouchEvent.ROLL_OUT, __rollOut);
			}
			
			_tooltips = value;
			if(_tooltips && Mouse.supportsCursor)
			{
				this.addEventListener(GTouchEvent.ROLL_OVER, __rollOver);
				this.addEventListener(GTouchEvent.ROLL_OUT, __rollOut);
			}
		}
		
		public function get blendMode():String
		{
			return _displayObject.blendMode;
		}
		
		public function set blendMode(value:String):void
		{
			_displayObject.blendMode = value;
		}
		
		public function get filter():FragmentFilter
		{
			return _displayObject.filter;
		}
		
		public function set filter(value:FragmentFilter):void
		{
			_displayObject.filter = value;
		}
		
		private function __rollOver(evt:GTouchEvent):void
		{
			var r:GRoot = this.root;
			if(r)
				GTimers.inst.callDelay(100, __doShowTooltips);
		}
		
		private function __doShowTooltips(r:GRoot):void
		{
			this.root.showTooltips(_tooltips);
		}
		
		private function __rollOut(evt:GTouchEvent):void
		{
			GTimers.inst.remove(__doShowTooltips);
			this.root.hideTooltips();
		}
		
		final public function get inContainer():Boolean
		{
			return _displayObject!=null && _displayObject.parent!=null;
		}
		
		final public function get onStage():Boolean
		{
			return _displayObject!=null && _displayObject.stage!=null;
		}
		
		final public function get resourceURL():String
		{
			if(packageItem!=null)
				return "ui://"+packageItem.owner.id + packageItem.id;
			else
				return null;
		}
		
		final public function set group(value:GGroup):void
		{
			if (_group != value)
			{
				if (_group != null)
					_group.setBoundsChangedFlag(true);
				_group = value;
				if (_group != null)
					_group.setBoundsChangedFlag(true);
			}
		}
		
		final public function get group():GGroup
		{
			return _group;
		}

		final public function getGear(index:int):GearBase
		{
			var gear:GearBase = _gears[index];
			if (gear == null)
			{
				switch (index)
				{
					case 0:
						gear = new GearDisplay(this);
						break;
					case 1:
						gear = new GearXY(this);
						break;
					case 2:
						gear = new GearSize(this);
						break;
					case 3:
						gear = new GearLook(this);
						break;
					case 4:
						gear = new GearColor(this);
						break;
					case 5:
						gear = new GearAnimation(this);
						break;
					case 6:
						gear = new GearText(this);
						break;
					case 7:
						gear = new GearIcon(this);
						break;
					default:
						throw new Error("FairyGUI: invalid gear index!");
				}
				_gears[index] = gear;
			}
			return gear;
		}
		
		protected function updateGear(index:int):void
		{
			if(_underConstruct || _gearLocked)
				return;
			
			var gear:GearBase = _gears[index];
			if ( gear!= null && gear.controller!=null)
				gear.updateState();
		}
		
		internal function checkGearController(index:int, c:Controller):Boolean
		{
			return _gears[index] != null && _gears[index].controller==c;
		}
		
		internal function updateGearFromRelations(index:int, dx:Number, dy:Number):void
		{
			if (_gears[index] != null)
				_gears[index].updateFromRelations(dx, dy);
		}
		
		internal function addDisplayLock():uint
		{
			var gearDisplay:GearDisplay = GearDisplay(_gears[0]);
			if(gearDisplay && gearDisplay.controller)
			{
				var ret:uint = gearDisplay.addLock();
				checkGearDisplay();
				
				return ret;
			}
			else
				return 0;
		}
		
		internal function releaseDisplayLock(token:uint):void
		{
			var gearDisplay:GearDisplay = GearDisplay(_gears[0]);
			if(gearDisplay && gearDisplay.controller)
			{
				gearDisplay.releaseLock(token);
				checkGearDisplay();
			}
		}
		
		private function checkGearDisplay():void
		{
			if(_handlingController)
				return;
			
			var connected:Boolean = _gears[0]==null || GearDisplay(_gears[0]).connected;
			if(connected!=_internalVisible)
			{
				_internalVisible = connected;
				if(_parent)
					_parent.childStateChanged(this);
			}
		}
		
		final public function get gearXY():GearXY
		{
			return GearXY(getGear(1));
		}
		
		final public function get gearSize():GearSize
		{
			return GearSize(getGear(2));
		}
		
		final public function get gearLook():GearLook
		{
			return GearLook(getGear(3));
		}
		
		final public function get relations():Relations
		{
			return _relations;
		}
		
		final public function addRelation(target:GObject, relationType:int, usePercent:Boolean = false):void
		{
			_relations.add(target, relationType, usePercent);
		}
	
		final public function removeRelation(target:GObject, relationType:int):void
		{
			_relations.remove(target, relationType);
		}
		
		final public function get displayObject():DisplayObject
		{
			return _displayObject;
		}
		
		final protected function setDisplayObject(value:DisplayObject):void
		{
			_displayObject = value;
		}
		
		final public function get parent():GComponent
		{
			return _parent;
		}
		
		final public function set parent(val:GComponent):void
		{
			_parent = val;
		}
		
		final public function removeFromParent():void
		{
			if(_parent)
				_parent.removeChild(this);
		}
		
		public function get root():GRoot
		{
			if(this is GRoot)
				return GRoot(this);
			
			var p:GObject = _parent;
			while(p)
			{
				if(p is GRoot)
					return GRoot(p);
				p = p.parent;
			}
			return GRoot.inst;
		}
		
		final public function get asCom():GComponent
		{
			return this as GComponent;
		}
		
		final public function get asButton():GButton
		{
			return this as GButton;
		}
		
		final public function get asLabel():GLabel
		{
			return this as GLabel;
		}
		
		final public function get asProgress():GProgressBar
		{
			return this as GProgressBar;
		}
		
		final public function get asTextField():GTextField
		{
			return this as GTextField;
		}
		
		final public function get asRichTextField():GRichTextField
		{
			return this as GRichTextField;
		}
		
		final public function get asTextInput():GTextInput
		{
			return this as GTextInput;
		}
		
		final public function get asLoader():GLoader
		{
			return this as GLoader;
		}
		
		final public function get asList():GList
		{
			return this as GList;
		}
		
		final public function get asGraph():GGraph
		{
			return this as GGraph;
		}
		
		final public function get asGroup():GGroup
		{
			return this as GGroup;
		}
		
		final public function get asSlider():GSlider
		{
			return this as GSlider;
		}
		
		final public function get asComboBox():GComboBox
		{
			return this as GComboBox;
		}
		
		final public function get asImage():GImage
		{
			return this as GImage;
		}
		
		final public function get asMovieClip():GMovieClip
		{
			return this as GMovieClip;
		}
		
		public function get text():String
		{
			return null;
		}
		
		public function set text(value:String):void
		{
		}
		
		public function get icon():String
		{
			return null;
		}
		
		public function set icon(value:String):void
		{
		}
		
		public function dispose():void
		{
			removeFromParent();
			_relations.dispose();
			if(_displayObject!=null)
			{
				_displayObject.dispose();
				_displayObject = null;
			}
		}

		public function addClickListener(listener:Function):void
		{
			addEventListener(GTouchEvent.CLICK, listener);
		}
		
		public function removeClickListener(listener:Function):void
		{
			removeEventListener(GTouchEvent.CLICK, listener);	
		}
		
		public function hasClickListener():Boolean
		{
			return hasEventListener(GTouchEvent.CLICK);
		}
		
		public function addXYChangeCallback(listener:Function):void
		{
			_dispatcher.addListener(XY_CHANGED, listener);
		}
		
		public function addSizeChangeCallback(listener:Function):void
		{
			_dispatcher.addListener(SIZE_CHANGED, listener);
		}
		
		internal function addSizeDelayChangeCallback(listener:Function):void
		{
			_dispatcher.addListener(SIZE_DELAY_CHANGE, listener);
		}
		
		public function removeXYChangeCallback(listener:Function):void
		{
			_dispatcher.removeListener(XY_CHANGED, listener);
		}
		
		public function removeSizeChangeCallback(listener:Function):void
		{
			_dispatcher.removeListener(SIZE_CHANGED, listener);
		}
		
		internal function removeSizeDelayChangeCallback(listener:Function):void
		{
			_dispatcher.removeListener(SIZE_DELAY_CHANGE, listener);
		}
		
		override public function addEventListener(type:String, listener:Function):void
		{
			super.addEventListener(type, listener);
			
			if(_displayObject!=null)
			{
				if(MTOUCH_EVENTS.indexOf(type)!=-1)
					initMTouch();
				else
					_displayObject.addEventListener(type, _reDispatch);
			}
		}
		
		override public function removeEventListener(type:String, listener:Function):void
		{
			super.removeEventListener(type, listener);

			if(_displayObject!=null && !this.hasEventListener(type))
			{
				_displayObject.removeEventListener(type, _reDispatch);
			}
		}
		
		private function _reDispatch(evt:Event):void
		{
			this.dispatchEvent(evt);
		}
		
		final public function get draggable():Boolean
		{
			return _draggable;
		}
		
		final public function set draggable(value:Boolean):void
		{
			if (_draggable != value)
			{
				_draggable = value;
				initDrag();
			}
		}
		
		final public function get dragBounds():Rectangle
		{
			return _dragBounds;
		}
		
		final public function set dragBounds(value:Rectangle):void
		{
			_dragBounds = value;
		}
		
		public function startDrag(touchPointID:int=-1):void
		{
			if (_displayObject.stage==null)
				return;
			
			dragBegin(null);
			triggerDown(touchPointID);
		}
		
		public function stopDrag():void
		{
			dragEnd();
		}
		
		public function get dragging():Boolean
		{
			return draggingObject==this;
		}
		
		public function localToGlobal(ax:Number=0, ay:Number=0, resultPonit:Point=null):Point
		{
			if(_pivotAsAnchor)
			{
				ax += _pivotX*_width;
				ay += _pivotY*_height;
			}
			sHelperPoint.x = ax;
			sHelperPoint.y = ay;
			return _displayObject.localToGlobal(sHelperPoint, resultPonit);
		}
		
		public function globalToLocal(ax:Number=0, ay:Number=0, resultPonit:Point=null):Point
		{
			sHelperPoint.x = ax;
			sHelperPoint.y = ay;
			var pt:Point = _displayObject.globalToLocal(sHelperPoint, resultPonit);
			if(_pivotAsAnchor)
			{
				pt.x -= _pivotX*_width;
				pt.y -= _pivotY*_height;
			}
			return pt;
		}
		
		public function localToRoot(ax:Number=0, ay:Number=0, resultPoint:Point=null):Point
		{
			if(_pivotAsAnchor)
			{
				ax += _pivotX*_width;
				ay += _pivotY*_height;
			}
			
			sHelperPoint.x = ax;
			sHelperPoint.y = ay;
			var pt:Point = _displayObject.localToGlobal(sHelperPoint, resultPoint);
			pt.x /= GRoot.contentScaleFactor;
			pt.y /= GRoot.contentScaleFactor;
			return pt;
		}
		
		public function rootToLocal(ax:Number=0, ay:Number=0, resultPoint:Point=null):Point
		{
			sHelperPoint.x = ax;
			sHelperPoint.y = ay;
			sHelperPoint.x *= GRoot.contentScaleFactor;
			sHelperPoint.y *= GRoot.contentScaleFactor;
			var pt:Point = _displayObject.globalToLocal(sHelperPoint, resultPoint);
			if(_pivotAsAnchor)
			{
				pt.x -= _pivotX*_width;
				pt.y -= _pivotY*_height;
			}
			return pt;
		}
		
		public function localToGlobalRect(ax:Number=0, ay:Number=0, aWidth:Number=0, aHeight:Number=0, 
										  resultRect:Rectangle = null):Rectangle
		{
			if(resultRect==null)
				resultRect = new Rectangle();
			var pt:Point = this.localToGlobal(ax, ay);
			resultRect.x = pt.x;
			resultRect.y = pt.y;
			pt = this.localToGlobal(ax+aWidth, ay+aHeight);
			resultRect.right = pt.x;
			resultRect.bottom = pt.y;
			return resultRect;
		}
		
		public function globalToLocalRect(ax:Number=0, ay:Number=0, aWidth:Number=0, aHeight:Number=0, 
										  resultRect:Rectangle = null):Rectangle
		{
			if(resultRect==null)
				resultRect = new Rectangle();
			var pt:Point = this.globalToLocal(ax, ay);
			resultRect.x = pt.x;
			resultRect.y = pt.y;
			pt = this.globalToLocal(ax+aWidth, ay+aHeight);
			resultRect.right = pt.x;
			resultRect.bottom = pt.y;
			return resultRect;
		}
		
		protected function createDisplayObject():void
		{
			
		}

		protected function handlePositionChanged():void
		{
			if(_displayObject)
			{
				var xv:Number = _x;
				var yv:Number = _y+_yOffset;
				if(_pivotAsAnchor)
				{					
					xv -= _pivotX*_width;
					yv -= _pivotY*_height;
				}
				if(_pixelSnapping)
				{
					xv = Math.round(xv);
					yv = Math.round(yv);
				}
				_displayObject.x = xv+_pivotOffsetX;
				_displayObject.y = yv+_pivotOffsetY;
			}
		}
		
		protected function handleSizeChanged():void
		{
			if(_displayObject!=null && _sizeImplType==1 && sourceWidth!=0 && sourceHeight!=0)
			{
				_displayObject.scaleX = _width/sourceWidth*_scaleX;
				_displayObject.scaleY = _height/sourceHeight*_scaleY;
			}
		}
		
		protected function handleScaleChanged():void
		{
			if(_displayObject!=null)
			{
				if( _sizeImplType==0 || sourceWidth==0 || sourceHeight==0)
				{
					_displayObject.scaleX = _scaleX;
					_displayObject.scaleY = _scaleY;
				}
				else
				{
					_displayObject.scaleX = _width/sourceWidth*_scaleX;
					_displayObject.scaleY = _height/sourceHeight*_scaleY;
				}
			}
		}
		
		public function handleControllerChanged(c:Controller):void
		{
			_handlingController = true;
			for (var i:int = 0; i < 8; i++)
			{
				var gear:GearBase = _gears[i];
				if (gear != null && gear.controller == c)
					gear.apply();
			}
			_handlingController = false;
			
			checkGearDisplay();
		}
		
		protected function handleGrayedChanged():void
		{
			if(_displayObject)
			{
				if(_displayObject.filter!=null)
					_displayObject.filter.dispose();
				
				if(_grayed)
					_displayObject.filter = new ColorMatrixFilter(ToolSet.GRAY_FILTERS_MATRIX);
				else
					_displayObject.filter = null;
			}	
		}
		
		protected function handleAlphaChanged():void
		{
			if(_displayObject)
				_displayObject.alpha = _alpha;
		}
		
		internal function handleVisibleChanged():void
		{
			if(_displayObject)
				_displayObject.visible = internalVisible2;
		}
		
		public function constructFromResource():void
		{
		}

		public function setup_beforeAdd(xml:XML):void
		{
			var str:String;
			var arr:Array;
			
			_id = xml.@id;
			_name = xml.@name;
			
			str = xml.@xy;
			arr = str.split(",");
			this.setXY(parseInt(arr[0]), parseInt(arr[1]));
			
			str = xml.@size;
			if(str)
			{
				arr = str.split(",");
				initWidth = parseInt(arr[0]);
				initHeight = parseInt(arr[1]);
				setSize(initWidth,initHeight,true);
			}
			
			str = xml.@restrictSize;
			if(str)
			{
				arr = str.split(",");
				minWidth = parseInt(arr[0]);
				maxWidth = parseInt(arr[1]);
				minHeight = parseInt(arr[2]);
				maxHeight= parseInt(arr[3]);
			}
			
			str = xml.@scale;
			if(str)
			{
				arr = str.split(",");
				setScale(parseFloat(arr[0]), parseFloat(arr[1]));
			}
			
			str = xml.@skew;
			if(str)
			{
				arr = str.split(",");
				setSkew(parseFloat(arr[0]),parseFloat(arr[1]));
			}
			
			str = xml.@rotation;
			if(str)
				this.rotation = parseInt(str);
			
			str = xml.@alpha;
			if(str)
				this.alpha = parseFloat(str);
			
			str = xml.@pivot;
			if(str)
			{
				arr = str.split(",");
				str = xml.@anchor;
				this.setPivot(parseFloat(arr[0]), parseFloat(arr[1]), str=="true");
			}
			
			if(xml.@touchable=="false")
				this.touchable = false;
			if(xml.@visible=="false")
				this.visible = false;
			if(xml.@grayed=="true")
				this.grayed = true;
			this.tooltips = xml.@tooltips;
			
			str = xml.@blend;
			if (str)
				this.blendMode = str;
			
			str = xml.@filter;
			if (str)
			{
				switch (str)
				{
					case "color":
						var cf:ColorMatrixFilter = new ColorMatrixFilter();
						str = xml.@filterData;
						arr = str.split(",");
						cf.adjustBrightness(parseFloat(arr[0]));
						cf.adjustContrast(parseFloat(arr[1]));
						cf.adjustSaturation(parseFloat(arr[2]));
						cf.adjustHue(parseFloat(arr[3]));
						this.filter = cf;
						break;
				}
			}
		}
		
		private static var GearXMLKeys:Object = {
			"gearDisplay":0,
			"gearXY":1,
			"gearSize":2,
			"gearLook":3,
			"gearColor":4,
			"gearAni":5,
			"gearText":6,
			"gearIcon":7
		};
		
		public function setup_afterAdd(xml:XML):void
		{
			var s:String = xml.@group;
			if(s)
				_group = _parent.getChildById(s) as GGroup;
			
			var col:Object = xml.elements();
			for each(var cxml:XML in col)
			{
				var index:* = GearXMLKeys[cxml.name().localName];
				if(index!=undefined)
					getGear(int(index)).setup(cxml);
			}
		}
		
		//touch support
		//-------------------------------------------------------------------
		private var _touchPointId:int;
		private var _lastClick:int;
		private var _buttonStatus:int;
		private var _rollOver:Boolean;
		private var _touchDownPoint:Point;
		private static var sHelperPoint:Point = new Point();
		private static const MTOUCH_EVENTS:Array = 
			[GTouchEvent.BEGIN, GTouchEvent.DRAG, GTouchEvent.END, GTouchEvent.CLICK,
			GTouchEvent.ROLL_OVER, GTouchEvent.ROLL_OUT];
		
		public function get isDown():Boolean
		{
			return _buttonStatus==1;
		}
		
		public function triggerDown(touchPointID:int=-1):void
		{
			var st:Stage = _displayObject.stage;
			if(st!=null)
			{
				_buttonStatus = 1;
				_touchPointId = touchPointID;
			
				_displayObject.stage.addEventListener(TouchEvent.TOUCH, __stageTouch);
			}
		}
		
		private function initMTouch():void
		{
			_displayObject.addEventListener(TouchEvent.TOUCH, __touch);
		}

		private function __stageTouch(evt:TouchEvent):void
		{
			var st:Stage = _displayObject?_displayObject.stage:null;
			if(st==null) { //maybe remove from stage, or disposed
				evt.currentTarget.removeEventListener(TouchEvent.TOUCH, __stageTouch);
				return;
			}
			
			var touch:Touch = evt.getTouch(st);
			if(touch)
			{
				if(touch.phase==TouchPhase.MOVED)
				{
					if(_buttonStatus==0
						|| GRoot.touchPointInput && _touchPointId!=touch.id)
						return;
					
					var sensitivity:int;
					if(GRoot.touchScreen)
						sensitivity = UIConfig.touchDragSensitivity;
					else
						sensitivity = UIConfig.clickDragSensitivity;
					if(_touchDownPoint!=null 
						&& Math.abs(_touchDownPoint.x - touch.globalX) < sensitivity
							&& Math.abs(_touchDownPoint.y - touch.globalY) < sensitivity)
							return;
						
					var devt:GTouchEvent = new GTouchEvent(GTouchEvent.DRAG);
					devt.copyFrom(evt, touch);
					this.dispatchEvent(devt);
					if(devt.isPropagationStop)
						evt.stopPropagation();
				}
				else if(touch.phase==TouchPhase.ENDED)
				{
					_displayObject.stage.removeEventListener(TouchEvent.TOUCH, __stageTouch);
					handleEnded(evt, touch);
				}
			}
		}
		
		private function __touch(evt:TouchEvent):void
		{
			var touch:Touch = evt.getTouch(displayObject);
			if(!touch)
			{
				if(_rollOver)
				{
					_rollOver = false;
					var devt:GTouchEvent = new GTouchEvent(GTouchEvent.ROLL_OUT);
					devt.copyFrom(evt, touch);
					this.dispatchEvent(devt);
				}
			}
			else if(touch.phase==TouchPhase.BEGAN) 
			{
				devt = new GTouchEvent(GTouchEvent.BEGIN);
				devt.copyFrom(evt, touch);
				this.dispatchEvent(devt);
				if(devt.isPropagationStop)
					evt.stopPropagation();
				
				if(_touchDownPoint==null)
					_touchDownPoint = new Point();
				_touchDownPoint.x = touch.globalX;
				_touchDownPoint.y = touch.globalY;
				
				triggerDown(touch.id);
			}
			else if(touch.phase==TouchPhase.ENDED)
			{
				handleEnded(evt, touch);
			}
			else if(touch.phase==TouchPhase.HOVER)
			{
				if(!_rollOver)
				{
					_rollOver = true;
					devt = new GTouchEvent(GTouchEvent.ROLL_OVER);
					devt.copyFrom(evt, touch);
					this.dispatchEvent(devt);
				}
			}
		}
		
		private function handleEnded(evt:TouchEvent, touch:Touch):void
		{
			if(_buttonStatus==0
				|| GRoot.touchPointInput && _touchPointId!=touch.id)
				return;
			
			if(_buttonStatus==1)
			{
				var cc:int = 1;
				var now:int = getTimer();
				if(now-_lastClick<500)
				{
					cc = 2;
					_lastClick = 0;
				}
				else
					_lastClick = now;				
				
				globalToLocal(touch.globalX, touch.globalY, sHelperPoint);
				var isWithinBounds:Boolean = 
					sHelperPoint.x >= 0 && sHelperPoint.x <= width && sHelperPoint.y >= 0 && sHelperPoint.y <= height;
				if (isWithinBounds)
				{
					var devt:GTouchEvent = new GTouchEvent(GTouchEvent.CLICK);
					devt.copyFrom(evt, touch, cc);
					
					this.dispatchEvent(devt);
				}
				
				if(_rollOver && (!isWithinBounds || !evt.interactsWith(_displayObject)))
				{
					_rollOver = false;
					devt = new GTouchEvent(GTouchEvent.ROLL_OUT);
					devt.copyFrom(evt, touch);
					this.dispatchEvent(devt);
				}
			}
			else if(_buttonStatus==2) //cancelled 
			{
				if(_rollOver)
				{
					globalToLocal(touch.globalX, touch.globalY, sHelperPoint);
					isWithinBounds = sHelperPoint.x >= 0 && sHelperPoint.x <= width && sHelperPoint.y >= 0 && sHelperPoint.y <= height;
					
					if(!isWithinBounds) 
					{
						_rollOver = false;
						devt = new GTouchEvent(GTouchEvent.ROLL_OUT);
						devt.copyFrom(evt, touch);
						this.dispatchEvent(devt);
					}
				}
			}
			_buttonStatus = 0;
			
			devt = new GTouchEvent(GTouchEvent.END);
			devt.copyFrom(evt, touch);
			this.dispatchEvent(devt);
		}
		
		public function cancelClick():void
		{
			var cnt:int = GComponent(this).numChildren;
			for(var i:int=0;i<cnt;i++)
			{
				var child:GObject = GComponent(this).getChildAt(i);
				child._buttonStatus = 2;
				if(child is GComponent)
					child.cancelClick();
			}
		}
		//-------------------------------------------------------------------
		
		//drag support
		//-------------------------------------------------------------------
		private static var sGlobalDragStart:Point = new Point();
		private static var sGlobalRect:Rectangle = new Rectangle();
		private static var sDragHelperPoint:Point = new Point();
		private static var sDragHelperRect:Rectangle = new Rectangle();
		private static var sUpdateInDragging:Boolean;
		
		private function initDrag():void
		{
			if(_draggable)
				addEventListener(GTouchEvent.BEGIN, __begin);
			else
				removeEventListener(GTouchEvent.BEGIN, __begin);
		}
		
		private function dragBegin(evt:GTouchEvent):void
		{
			if(draggingObject!=null)
			{
				draggingObject.stopDrag();
				draggingObject = null;
			}
			
			if(evt!=null)
			{
				sGlobalDragStart.x = evt.stageX;
				sGlobalDragStart.y = evt.stageY;
			}
			else
			{
				sGlobalDragStart.x = Starling.current.nativeStage.mouseX;
				sGlobalDragStart.y = Starling.current.nativeStage.mouseY;
			}
			this.localToGlobalRect(0,0,this.width,this.height,sGlobalRect);
			draggingObject = this;
			
			addEventListener(GTouchEvent.DRAG, __dragging);
			addEventListener(GTouchEvent.END, __dragEnd);
		}
		
		private function dragEnd():void
		{
			if (draggingObject==this)
			{
				removeEventListener(GTouchEvent.DRAG, __dragStart);
				removeEventListener(GTouchEvent.END, __dragEnd);
				removeEventListener(GTouchEvent.DRAG, __dragging);
				draggingObject = null;
			}
		}
		
		private function __begin(evt:GTouchEvent):void
		{
			if((evt.realTarget is TextField) && TextField(evt.realTarget).type==TextFieldType.INPUT)
				return;
			
			addEventListener(GTouchEvent.DRAG, __dragStart);
		}
		
		private function __dragStart(evt:GTouchEvent):void
		{
			removeEventListener(GTouchEvent.DRAG, __dragStart);
			
			if((evt.realTarget is TextField) && TextField(evt.realTarget).type==TextFieldType.INPUT)
				return;
			
			var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_START);
			dragEvent.stageX = evt.stageX;
			dragEvent.stageY = evt.stageY;
			dragEvent.touchPointID = evt.touchPointID;
			dispatchEvent(dragEvent);
			
			if (!dragEvent.isDefaultPrevented())
				dragBegin(evt);
		}
		
		private function __dragging(evt:GTouchEvent):void
		{				
			if(this.parent==null)
				return;
			
			var xx:Number = evt.stageX - sGlobalDragStart.x + sGlobalRect.x;
			var yy:Number = evt.stageY - sGlobalDragStart.y　+ sGlobalRect.y;
			
			if (_dragBounds!=null)
			{
				var rect:Rectangle = GRoot.inst.localToGlobalRect(_dragBounds.x, _dragBounds.y,
					_dragBounds.width,_dragBounds.height, sDragHelperRect);
				if (xx < rect.x)
					xx = rect.x;
				else if(xx + sGlobalRect.width > rect.right)
				{
					xx = rect.right - sGlobalRect.width;
					if (xx < rect.x)
						xx = rect.x;
				}
				
				if(yy < rect.y)
					yy = rect.y;
				else if(yy + sGlobalRect.height > rect.bottom)
				{
					yy = rect.bottom - sGlobalRect.height;
					if(yy < rect.y)
						yy = rect.y;
				}
			}
			
			sUpdateInDragging = true;
			var pt:Point = this.parent.globalToLocal(xx, yy, sDragHelperPoint);
			this.setXY(Math.round(pt.x), Math.round(pt.y));
			sUpdateInDragging = false;
			
			var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_MOVING);
			dragEvent.stageX = evt.stageX;
			dragEvent.stageY = evt.stageY;
			dragEvent.touchPointID = evt.touchPointID;
			dispatchEvent(dragEvent);
		}
		
		private function __dragEnd(evt:GTouchEvent):void
		{
			if (draggingObject==this)
			{
				stopDrag();
				
				var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_END);
				dragEvent.stageX = evt.stageX;
				dragEvent.stageY = evt.stageY;
				dragEvent.touchPointID = evt.touchPointID;
				dispatchEvent(dragEvent);
			}
		}
		//-------------------------------------------------------------------
	}
}
