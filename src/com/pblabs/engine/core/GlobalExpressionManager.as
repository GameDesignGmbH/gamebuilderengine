package com.pblabs.engine.core
{
	import com.pblabs.engine.PBE;
	import com.pblabs.engine.components.DataComponent;
	import com.pblabs.engine.entity.IEntity;
	
	import flash.display.Stage;
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.StageOrientationEvent;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;

	public final class GlobalExpressionManager implements ITickedObject
	{
		public var screenScale : Number = 1;
		public var screenLayout : String = "Portrait";
		public var screenOrientation : String = "Portrait";
		public var globalExpressionEntity : IEntity;
		
		private var objectContext : Object;
		
		public function GlobalExpressionManager(clazz : Privatizer)
		{
			initialize();
		}
		
		/**
		 * Singleton pattern to retrieve this class
		 **/
		private static var _instance : GlobalExpressionManager;
		public static function get instance():GlobalExpressionManager
		{
			if(!_instance){
				_instance = new GlobalExpressionManager(new Privatizer());
			}
			return _instance
		}

		private var _ignoreTimeScale : Boolean = true;
		/**
		 * @inheritDoc
		 */
		public function get ignoreTimeScale():Boolean { return _ignoreTimeScale; }
		public function set ignoreTimeScale(val:Boolean):void
		{
			_ignoreTimeScale = val;
		}

		public function onTick(deltaTime:Number):void
		{
			var processManager : ProcessManager = PBE.processManager;
			var levelManager : LevelManager = PBE.levelManager;
			var inputManager : InputManager = PBE.inputManager;
			
			//Update mouse position for globally for expressions
			objectContext.Game.Mouse.x = inputManager.stageMouseX;
			objectContext.Game.Mouse.y = inputManager.stageMouseY;

			for(var i : int = 1; i < 11; i++)
			{
				if(!objectContext.Game.Touch["TouchPoint"+i]) 
					objectContext.Game.Touch["TouchPoint"+i] = new Object();
				var touchData : InputState = PBE.inputManager.getKeyData(InputKey["TOUCH_"+i].keyCode);
				if(touchData)
				{
					objectContext.Game.Touch["TouchPoint"+i].isTouching = touchData.value;
					objectContext.Game.Touch["TouchPoint"+i].x = touchData.stageX;
					objectContext.Game.Touch["TouchPoint"+i].y = touchData.stageY;
					objectContext.Game.Touch["TouchPoint"+i].pressure = touchData.pressure;
				}
			}

			objectContext.Game.Time.virtualTime = processManager.virtualTime;
			objectContext.Game.Time.timeScale = processManager.timeScale;
			objectContext.Game.Time.gameTime = processManager.platformTime;
			objectContext.Game.Time.deltaTime = deltaTime;

			objectContext.Game.Screen.screenOrientation = screenOrientation;

			objectContext.Game.Level.currentLevel = levelManager.currentLevel;
			objectContext.Game.Level.levelCount = levelManager.levelCount;
		}

		private function initialize():void
		{
			if(!PBE.mainStage)
				throw new Error("Game engine has to be started first!");
			
			PBE.mainStage.addEventListener(Event.RESIZE, onScreenResize);
			if(ApplicationDomain.currentDomain.hasDefinition("flash.events.StageOrientationEvent")){
				if(Stage.supportsOrientationChange)
					PBE.mainStage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, orientationChange);
			}
			
			objectContext = PBE.GLOBAL_DYNAMIC_OBJECT;
			if(!objectContext.Game) objectContext.Game = new Object();
			if(!objectContext.Game.Mouse) objectContext.Game.Mouse = new DataComponent();
			if(!objectContext.Game.Time) objectContext.Game.Time = new DataComponent();
			if(!objectContext.Game.Screen) objectContext.Game.Screen = new DataComponent();
			if(!objectContext.Game.Level) objectContext.Game.Level = new DataComponent();
			if(!objectContext.Game.Touch) objectContext.Game.Touch = new DataComponent();

			calculateScreenSize();
			
			objectContext.Game.Level.currentLevel = PBE.levelManager.currentLevel;
			calculateScreenSize();
			screenOrientation = "right-sideup";
			
			globalExpressionEntity = PBE.allocateEntity();
			globalExpressionEntity.initialize("Game");
			globalExpressionEntity.addComponent(objectContext.Game.Mouse, "Mouse");
			globalExpressionEntity.addComponent(objectContext.Game.Time, "Time");
			globalExpressionEntity.addComponent(objectContext.Game.Screen, "Screen");
			globalExpressionEntity.addComponent(objectContext.Game.Level, "Level");
			globalExpressionEntity.addComponent(objectContext.Game.Touch, "Touch");
		}
		
		private function calculateScreenSize():void
		{
			if(objectContext){
				objectContext.Game.Screen.screenResolutionX = Capabilities.screenResolutionX;
				objectContext.Game.Screen.screenResolutionY = Capabilities.screenResolutionY;
				objectContext.Game.Screen.fullScreenWidth = PBE.mainStage.fullScreenWidth;
				objectContext.Game.Screen.fullScreenHeight = PBE.mainStage.fullScreenHeight;
				objectContext.Game.Screen.width = PBE.mainStage.stageWidth;
				objectContext.Game.Screen.height = PBE.mainStage.stageHeight;
			}

			var screenSize:Rectangle = new Rectangle(0, 0, PBE.mainStage.stageWidth, PBE.mainStage.stageHeight);
			var deviceSize:Rectangle = new Rectangle(0, 0,
				Math.max(PBE.mainStage.fullScreenWidth, PBE.mainStage.fullScreenHeight),
				Math.min(PBE.mainStage.fullScreenWidth, PBE.mainStage.fullScreenHeight));
			
			var appSize:Rectangle = screenSize.clone();
			
			// if device is wider than GUI's aspect ratio, height determines scale
			if ((deviceSize.width/deviceSize.height) > (screenSize.width/screenSize.height)) {
				screenScale = deviceSize.height / screenSize.height;
			} 
				// if device is taller than GUI's aspect ratio, width determines scale
			else {
				screenScale = deviceSize.width / screenSize.width;
			}
			if(deviceSize.width > deviceSize.height)
				screenLayout = "landscape";
			if(deviceSize.height > deviceSize.width)
				screenLayout = "portrait";
			
			if(objectContext){
				//Screen Size
				objectContext.Game.Screen.fullScreenScale = screenScale;
				if(screenLayout == "landscape")
					objectContext.Game.Screen.isLandscapeLayout = true;
				else
					objectContext.Game.Screen.isLandscapeLayout = false;
				
				if(screenLayout == "portrait")
					objectContext.Game.Screen.isPortraitLayout = true;
				else
					objectContext.Game.Screen.isPortraitLayout = false;
			}
			
		}
		
		private function onScreenResize(event : Event):void
		{
			calculateScreenSize();	
		}
		
		private function orientationChange(event : Event):void
		{
			switch ((event as StageOrientationEvent).afterOrientation) { 
				case StageOrientation.DEFAULT: 
					// re-orient display objects based on 
					// the default (right-sideup) orientation. 
					objectContext.Game.Screen.screenOrientation = "right-sideup";
					break; 
				case StageOrientation.ROTATED_RIGHT: 
					// Re-orient display objects based on 
					// right-hand orientation. 
					objectContext.Game.Screen.screenOrientation = "right-hand";
					break; 
				case StageOrientation.ROTATED_LEFT: 
					// Re-orient display objects based on 
					// left-hand orientation. 
					objectContext.Game.Screen.screenOrientation = "left-hand";
					break; 
				case StageOrientation.UPSIDE_DOWN: 
					// Re-orient display objects based on 
					// upside-down orientation. 
					objectContext.Game.Screen.screenOrientation = "upside-down";
					break;
				default: 
					// Re-orient display objects based on 
					// upside-down orientation. 
					objectContext.Game.Screen.screenOrientation = "right-sideup";
					break;
			}
		}
	}
}
class Privatizer{}