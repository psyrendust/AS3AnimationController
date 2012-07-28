package com.psyrendust.control{	import com.psyrendust.control.types.AnimationControllerType;	import com.psyrendust.control.events.AnimationControllerEvent;	import com.psyrendust.control.events.AnimationControllerListenerEvent;	import com.psyrendust.managers.CallbackManager;			import flash.display.MovieClip;		import flash.display.FrameLabel;		import flash.events.TimerEvent;		import flash.utils.Timer;		import flash.events.Event;	/**	 * The AnimationController class decorates any movie clip	 * or loaded SWF with logic for controlling their playback. 	 * The animation of the decorated item is not controlled by 	 * the default <code>onEnterFrame</code> command; the decorator 	 * controls the timeline through timer events and has the 	 * ability to dynamically adjust frame rate, speed, and direction.	 * 	 * <p>Labeled key frames may be placed in the timeline of 	 * the decorated object to denote stopping points to the 	 * AnimationController when the <code>stopAtLabel</code> parameter is 	 * set to <code>true</code>. This feature can ideally be used to control 	 * scripted simulation based scenarios.</p>	 * 	 * @example Using AnimationController in a class.	 * <listing>	 * import com.psyrendust.control.AnimationController;	 * import com.psyrendust.control.types.AnimationControllerType;	 * import flash.display.MovieClip;	 * 	 * public class Main extends MovieClip	 * {	 *    private var ac:AnimationController;	 *    	 *    public function Main()	 *    {	 *       super();	 *       var mc:MovieClip = new MovieClip();	 *       mc.graphics.beginFill(0xFF0066);	 *       mc.graphics.drawCircle(200,200,100);	 *       mc.graphics.endFill();	 *       ac = new AnimationController(mc, new AnimationControllerType());	 *       addChild(ac.mc);	 *       ac.play();	 *    }	 * }	 * </listing>	 * 	 * @author lgordon@psyrendust.com	 */	public class AnimationController 	{		private var _version:String="1.0.22";		private var movieClip:MovieClip;		private var dir:String;		private var timer:Timer;		private var _labels:Array;		private var _labelNamesHash:Array;		private var _labelFramesHash:Array;		private var _labelNames:Array;		private var _labelFrames:Array;		private var _frameRate:int;		private var _totalFrames:int;		private var _labelsIndex:int;		private var _labelsTotal:int;		private var _currentFrame:Number;		private var _stopAtLabel:Boolean;		private var _isPlaying:Boolean;		private var callbackManager:CallbackManager;		/**		 * Constructor for AnimationController instances.		 * 		 * @param decorate The MovieClip to decorate.		 * @param params An object to define the default parameters.		 */		public function AnimationController(decorate:*, params:AnimationControllerType)		{			trace("--\\\\\\ com.psyrendust.control.AnimationController ver" + _version + " ///--");			if(!decorate) throwCustomError("Property {decorate} cannot be null.");			init(decorate as MovieClip, params);		}		/* ************************************************		 * Init and dispose methods		 */		private function init(decorate:MovieClip, params:AnimationControllerType):void		{			this.movieClip=decorate;			timer = new Timer(params.timerDelay);			timer.addEventListener(TimerEvent.TIMER,onTimer,false,0,true);			_frameRate=params.frameRate;			direction=params.direction;			stopAtLabel=params.stopAtLabel;			_currentFrame=1;			_isPlaying = false;			_labelsIndex = 0;			_labels = this.movieClip.currentLabels;			_totalFrames = this.movieClip.totalFrames;			_labelNamesHash = new Array();			_labelFramesHash = new Array();			_labelNames = new Array();			_labelFrames = new Array();			_labelsTotal = _labels.length;			for(var i:int=0;i<_labelsTotal;i++)			{				var label:FrameLabel = _labels[i];				_labelNamesHash[label.name] = i;				_labelFramesHash[label.frame] = i;				_labelNames[i] = label.name;				_labelFrames[i] = label.frame;			}			callbackManager=new CallbackManager();			calculateCurrentLabelIndex();			if(params.stopAtFirstFrame) this.movieClip.gotoAndStop(1);			this.movieClip.addEventListener(Event.ADDED_TO_STAGE,addedToStage,false,0,true);			this.movieClip.addEventListener(Event.REMOVED_FROM_STAGE,removedFromStage,false,0,true);		}		/**		 * Dispose of this AnimationController.		 */		public function dispose():void		{			timer.removeEventListener(TimerEvent.TIMER,onTimer);			removeListeners();			dir=null;			timer=null;			_labels=null;			_labelNamesHash=null;			_labelFramesHash=null;			_labelNames=null;			_labelFrames=null;			_frameRate=NaN;			_totalFrames=NaN;			_labelsIndex=NaN;			_labelsTotal=NaN;			_currentFrame=NaN;			_stopAtLabel=undefined;			_isPlaying=undefined;			if(!this.movieClip) return;			this.movieClip.removeEventListener(Event.ADDED_TO_STAGE,addedToStage);			this.movieClip.removeEventListener(Event.REMOVED_FROM_STAGE,removedFromStage);			this.movieClip=null;		}		private function addedToStage(e:Event):void		{			callbackManager.callListeners(AnimationControllerEvent.ADDED_TO_STAGE, AnimationControllerEvent.ADDED_TO_STAGE);		}		private function removedFromStage(e:Event):void		{			callbackManager.callListeners(AnimationControllerEvent.REMOVED_FROM_STAGE,AnimationControllerEvent.REMOVED_FROM_STAGE);		}		private function onTimer(e:TimerEvent):void		{			advanceFrame();		}		/**		 * Get the display object that is being decorated by this AnimationController.		 * 		 * <p>The returned display object is cast as a MovieClip.</p>		 */		public function get mc():MovieClip		{			return this.movieClip;		}		/**		 * Gets or sets the direction of the current playhead animation.		 * 		 * <p>To set values for this property, use the following string values:</p>		 * 		 * <table class="innertable" >		 *    <tr>		 *       <th>String value</th>		 *       <th>Description</th>		 *    </tr>		 *    <tr>		 *       <td><code>com.psyrendust.control.events.AnimationControllerEvent.FORWARD</code></td>		 *       <td>Sets the direction of the playhead animation forward.</td>		 *    </tr>		 *    <tr>		 *       <td><code>com.psyrendust.control.events.AnimationControllerEvent.REVERSE</code></td>		 *       <td>Sets the direction of the playhead animation in reverse.</td>		 *    </tr>		 * </table>		 * 		 * @see com.psyrendust.control.events.AnimationControllerEvent AnimationControllerEvent		 */		public function get direction():String		{			return dir;		}		/**		 * @private		 */		public function set direction(d:String):void		{			var playingNow:Boolean = this.isPlaying;			if(playingNow) stop();			var _d:String = d.toLowerCase();			if(_d=="forward"||_d=="fwd") dir=AnimationControllerEvent.FORWARD;			else if(_d=="reverse"||_d=="rev") dir=AnimationControllerEvent.REVERSE;			calculateCurrentLabelIndex();			if(playingNow) play();		}		/**		 * Get or sets a Boolean value that indicates whether 		 * the AnimationController stops the playhead when it 		 * encounters a labeled key frame. A value of true indicates 		 * that the AnimationController will stop when it encounters		 * a labeled key frame; a value of false indicates that it 		 * will not.		 */		public function get stopAtLabel():Boolean		{			return _stopAtLabel;		}		/**		 * @private		 */		public function set stopAtLabel(b:Boolean):void		{			_stopAtLabel = b;			if(b) calculateCurrentLabelIndex();		}		/**		 * Gets or sets the frame rate of the animation playhead. The		 * playhead of the decorated object will advance <code>n</code> 		 * frames for every tic of the Timer (defined by timerDelay); 		 * where <code>n</code> equals <code>frameRate</code>.		 * 		 * @see #timerDelay		 */		public function get frameRate():int		{			return _frameRate;		}		/**		 * @private		 */		public function set frameRate(n:int):void		{			_frameRate = n;		}		/**		 * A Boolean value that is <code>true</code> if the AnimationController is playing.		 */		public function get isPlaying():Boolean		{			return timer.running;		}		/**		 * Returns an array of label names from the current scene of the decorated object.		 */		public function labels():Array		{			return _labelNames;		}		/**		 * The delay, in milliseconds, between timer events. Each timer 		 * event advances the playhead of the decorated object <code>n</code> frames; where 		 * <code>n</code> equals <code>frameRate</code>.		 * 		 * @see #frameRate		 */		public function get timerDelay():Number		{			return timer.delay;		}		/**		 * @private		 */		public function set timerDelay(n:Number):void		{			timer.delay = n;		}		/**		 * The total number of frames in the decorated object.		 */		public function get totalFrames():int		{			return _totalFrames;		}		/**		 * Specifies the number of the frame in which the playhead 		 * is located in the timeline of the decorated object.		 */		public function get currentFrame():int		{			return Math.floor(_currentFrame);		}		/**		 * The current label in which the playhead is located in 		 * the timeline of the decorated object.		 */		public function get currentLabel():String		{			return _labelNames[_labelFramesHash[currentFrame]];		}		/**		 * Causes the AnimationController to play.		 */		public function play():void		{			timer.start();		}		/**		 * Stops AnimationController playback.		 */		public function stop():void		{			timer.stop();		}		/**		 * Pauses AnimationController playback. 		 */		public function pause():void		{			_isPlaying=isPlaying;			stop();		}		/**		 * Resumes AnimationController playback if it was previously paused.		 */		public function resume():void		{			if(_isPlaying) play();		}		/**		 * Brings the playhead to the specified frame of the movie clip and stops it there.		 * 		 * @param _frame A number representing the frame number, or a string representing 		 * the label of the frame, to which the playhead is sent. If you specify a number, 		 * it is relative to the scene you specify. If you do not specify a scene, the 		 * current scene determines the global frame number at which to go to and stop. 		 * If you do specify a scene, the playhead goes to the frame number in the specified 		 * scene and stops.		 * @param _scene The name of the scene. This parameter is optional.		 */		public function gotoAndStop(_frame:Object, _scene:String=null):void		{			stop();			this.movieClip.gotoAndStop(_frame, _scene);			updateCurrentFrame();			calculateCurrentLabelIndex();			var index:int = _labelFramesHash[_currentFrame];			//callbackManager.callListeners(AnimationControllerEvent.STOPPED_AT_LABEL,new AnimationControllerListenerEvent(_labelFrames[index], _labelNames[index]));		}		/**		 * Starts playing the decorated object at the specified frame. To specify a scene 		 * as well as a frame, specify a value for the scene parameter.		 * 		 * @param _frame A number representing the frame number, or a string representing 		 * the label of the frame, to which the playhead is sent. If you specify a number, 		 * it is relative to the scene you specify. If you do not specify a scene, the 		 * current scene determines the global frame number to play. If you do specify a 		 * scene, the playhead jumps to the frame number in the specified scene.		 * @param _scene The name of the scene to play. This parameter is optional.		 */		public function gotoAndPlay(_frame:Object, _scene:String=null):void		{			stop();			this.movieClip.gotoAndStop(_frame, _scene);			updateCurrentFrame();			calculateCurrentLabelIndex();			play();		}		/**		 * Brings the playhead to the specified labeled frame and stops it there.		 * 		 * @param l The name of the label to which the playhead is sent.		 * @throws CustomError If the label specified does not exhist in the current timeline.		 */		public function gotoLabelAndStop(labelName:String):void		{			if(checkLabel(labelName))			{				stop();				this.movieClip.gotoAndStop(getFrame(labelName));				updateCurrentFrame();				calculateCurrentLabelIndex();				var index:int = _labelFramesHash[_currentFrame];				//callbackManager.callListeners(AnimationControllerEvent.STOPPED_AT_LABEL,new AnimationControllerListenerEvent(_labelFrames[index], _labelNames[index]));			}			else			{				throwCustomError('"'+labelName+'" does not exist.');			}		}		/**		 * Starts playing the decorated object at the specified label.		 * 		 * @param l The name of the label to which the playhead is sent.		 * @throws CustomError If the label specified does not exhist in the current timeline.		 */		public function gotoLabelAndPlay(labelName:String):void		{			if(checkLabel(labelName))			{				stop();				this.movieClip.gotoAndStop(getFrame(labelName));				updateCurrentFrame();				calculateCurrentLabelIndex();				play();			}			else			{				throwCustomError('"'+labelName+'" does not exist.');			}		}		/**		 * Toggles the direction of the animations playhead.		 */		public function toggleDirection():void		{			if(direction==AnimationControllerEvent.FORWARD) direction=AnimationControllerEvent.REVERSE;			else direction=AnimationControllerEvent.FORWARD;		}		/**		 * Add a listener to this AnimationController object.		 * 		 * @param type The type of event to be added.		 * @param callbackDelegate The scope that contains the callback function.		 * @param callbackFunction The name of the function that gets called by the event.		 */		public function addListener(type:String, callbackDelegate:*, callbackFunction:String):void		{			callbackManager.addListener(type, callbackDelegate, callbackFunction);		}		/**		 * Remove a listener from this AnimationController object. 		 * If there are no matching listeners registered with 		 * the AnimationController object, a call to this method 		 * has no effect.		 * 		 * @param type The type of event to be removed.		 * @param callbackDelegate The scope that contains the callback function.		 * @param callbackFunction The name of the function to be removed.		 */		public function removeListener(type:String, callbackDelegate:*, callbackFunction:String):void		{			callbackManager.removeListener(type, callbackDelegate, callbackFunction);		}		/**		 * Remove all listeners from this AnimationController object.		 */		public function removeListeners():void		{			callbackManager.removeListeners();		}		/* ************************************************		 * Logic methods		 */		private function updateCurrentFrame():void		{			_currentFrame=this.movieClip.currentFrame;		}		private function getFrame(l:String):Number		{			return _labelFrames[_labelNamesHash[l]];		}		private function checkLabel(l:String):Boolean		{			return (_labelNamesHash[l]==undefined)?false:true;		}		private function calculateCurrentLabelIndex():void		{			var currFrame:int = _currentFrame;			var i:int;			var frame:int;			if(dir==AnimationControllerEvent.FORWARD)			{				for(i=0;i<_labelsTotal;i++)				{					frame = _labelFrames[i];					if(currFrame<frame)					{						_labelsIndex = i;						break;					}					else if(currFrame==frame)					{						_labelsIndex = (i+1);						if(_labelsIndex>=_labelsTotal) _labelsIndex=0;						break;					}				}			}			else			{				for(i=_labelsTotal-1;i>=0;i--)				{					frame = _labelFrames[i];					if(currFrame>frame)					{						_labelsIndex = i;						break;					}					else if(currFrame==frame)					{						_labelsIndex = (i-1);						if(_labelsIndex<0) _labelsIndex=(_labelsTotal-1);						break;					}				}			}		}		private function advanceFrame():void		{			if(dir==AnimationControllerEvent.FORWARD)			{				_currentFrame += _frameRate;				if(Math.floor(_currentFrame)>_totalFrames)				{					_currentFrame = Math.floor(_currentFrame)-_totalFrames;				}			}			else if(dir==AnimationControllerEvent.REVERSE)			{				_currentFrame -= _frameRate;				if(Math.floor(_currentFrame)<1)				{					_currentFrame = _totalFrames-(1-Math.floor(_currentFrame));				}			}			var nextFrame:int = Math.floor(_currentFrame);			if(stopAtLabel)			{				var index:int;				var nextStopFrame:int;				var labelFramesLength:int = _labelsTotal-1;				if(dir==AnimationControllerEvent.FORWARD)				{					if(_labelsIndex>labelFramesLength)					{						_labelsIndex=0;   /* if greater than total frames then start at 0 */					}					nextStopFrame = _labelFrames[_labelsIndex];          /* get next labeled frame */					if(nextFrame>_labelFrames[labelFramesLength]&&_labelsIndex==0)					{						// increment to next frame					}					else if(nextFrame>=nextStopFrame)					{						_currentFrame=nextFrame=nextStopFrame;     /* if current frame is past next labeled frame then set to next labeled frame */						_labelsIndex+=1;						stop();						index = _labelFramesHash[_currentFrame];						callbackManager.callListeners(AnimationControllerEvent.STOPPED_AT_LABEL,new AnimationControllerListenerEvent(_labelFrames[index], _labelNames[index]));					}				}				else				{					if(_labelsIndex<0)					{						_labelsIndex=labelFramesLength; /* if less than 0 then start at end of labels */					}					nextStopFrame = _labelFrames[_labelsIndex];   /* get next labeled frame */					if(nextFrame>_labelFrames[labelFramesLength]&&_labelsIndex==labelFramesLength)					{						// decrement to next frame					}					else if(nextFrame>_labelFrames[labelFramesLength]&&_labelsIndex==0)					{						_currentFrame=nextFrame=nextStopFrame;      /* if current frame is past next labeled frame then set to next labeled frame */						_labelsIndex-=1;						stop();						index = _labelFramesHash[_currentFrame];						callbackManager.callListeners(AnimationControllerEvent.STOPPED_AT_LABEL,new AnimationControllerListenerEvent(_labelFrames[index], _labelNames[index]));					}					else if(nextFrame<=nextStopFrame)					{						_currentFrame=nextFrame=nextStopFrame;      /* if current frame is past next labeled frame then set to next labeled frame */						_labelsIndex-=1;						stop();						index = _labelFramesHash[_currentFrame];						callbackManager.callListeners(AnimationControllerEvent.STOPPED_AT_LABEL,new AnimationControllerListenerEvent(_labelFrames[index], _labelNames[index]));					}				}			}			this.movieClip.gotoAndStop(nextFrame);		}		/* ************************************************		 * Custom Error		 */		private function throwCustomError(l:String):void		{			throw new Error(l); 		}	}}