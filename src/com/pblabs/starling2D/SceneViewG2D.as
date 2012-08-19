/*******************************************************************************
 * GameBuilder Studio
 * Copyright (C) 2012 GameBuilder Inc.
 * For more information see http://www.gamebuilderstudio.com
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.starling2D
{
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.core.IAnimatedObject;
    import com.pblabs.rendering2D.ui.IUITarget;
    
    import flash.events.Event;
    import flash.geom.Rectangle;
    
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Sprite;
    
    /**
     * This class can be set as the SceneView on the BaseSceneComponent class and is used
     * as the canvas to draw the objects that make up the scene. It defaults to the size
     * of the stage.
     * 
     * <p>Currently this is just a stub, and exists for clarity and potential expandability in
     * the future.</p>
     */
    public class SceneViewG2D extends SceneViewG2DSprite implements IUITarget, IAnimatedObject
    {
		private var _starlingInstance : Starling;
		private var _gpuCanvasContainer : Sprite;
		
		private var _delayedCalls : Vector.<Object> = new Vector.<Object>();
		
		public function SceneViewG2D()
		{
			if(PBE.mainStage)
			{
				/*if(!PBE.mainClass.contains(this))
					PBE.mainClass.addChildAt(this, 0);*/
				
				// Intelligent default size.
				_width = PBE.mainStage.stage.stageWidth;
				_height = PBE.mainStage.stage.stageHeight;
				name = "SceneView";

				Starling.handleLostContext = true;
				_starlingInstance = new Starling(Sprite, PBE.mainStage.stage, new Rectangle(0,0, width, height));
				_starlingInstance.simulateMultitouch = true;
				_starlingInstance.enableErrorChecking = false;
				_starlingInstance.addEventListener("context3DCreate", onContextCreated);
				_starlingInstance.addEventListener("rootCreated", onRootInitialized);
				if(!PBE.IS_SHIPPING_BUILD)
					_starlingInstance.enableErrorChecking = true;
				//_starlingInstance.start();
				PBE.processManager.addAnimatedObject(this);
			}
			
			this.addEventListener("removedFromStage", onRemoved);
			PBE.mainStage.stage.addEventListener(Event.DEACTIVATE, stage_deactivateHandler, false, 0, true);
		}
		
		public function onFrame(deltaTime:Number):void
		{
			if(Starling.context && _starlingInstance)
			{
				_starlingInstance.nextFrame();
			}
		}
		
		public function addDisplayObject(dObj:Object):void
		{
			if(!_gpuCanvasContainer){
				_delayedCalls.push( {func : addDisplayObject, params: [dObj] } );
				return;
			}
				
			_gpuCanvasContainer.addChild( dObj as DisplayObject );
		}
		
		public function clearDisplayObjects():void
		{
			if(!_gpuCanvasContainer){
				_delayedCalls.push( {func : clearDisplayObjects, params: null } );
				return;
			}

			_gpuCanvasContainer.removeChildren(0);
		}
		
		public function removeDisplayObject(dObj:Object):void
		{
			if(!_gpuCanvasContainer){
				_delayedCalls.push( {func : removeDisplayObject, params: [dObj] } );
				return;
			}

			if(_gpuCanvasContainer.contains(dObj as DisplayObject))
				_gpuCanvasContainer.removeChild( dObj as DisplayObject );
		}
		
		public function setDisplayObjectIndex(dObj:Object, index:int):void
		{
			if(!_gpuCanvasContainer){
				_delayedCalls.push( {func : setDisplayObjectIndex, params: [dObj, index] } );
				return;
			}
			_gpuCanvasContainer.addChildAt( dObj as DisplayObject, index);
		}

		private function onRemoved(event : *):void
		{
			_starlingInstance.dispose();
			_starlingInstance = null;
			_gpuCanvasContainer = null;
		}
		
		private function onRootInitialized(event : * ):void{
			_gpuCanvasContainer = event.data as Sprite;
			for each(var calls : Object in _delayedCalls)
			{
				(calls.func as Function).apply(this, calls.params);
			}
		}
		
		private function onContextCreated(event : *):void{
			InitializationUtilG2D.initializeRenderers.dispatch();
		}
		
		private function stage_deactivateHandler(event:Event):void
		{
			//this._starlingInstance.stop();
			PBE.processManager.stop();
			PBE.mainStage.stage.addEventListener(Event.ACTIVATE, stage_activateHandler, false, 0, true);
		}
		
		private function stage_activateHandler(event:Event):void
		{
			PBE.mainStage.stage.removeEventListener(Event.ACTIVATE, stage_activateHandler);
			//this._starlingInstance.start();
			PBE.processManager.start();
		}
		
		override public function get width():Number
        {
            return _width;
        }
        
        override public function set width(value:Number):void
        {
            _width = value;
			var newViewPort : Rectangle = _starlingInstance.viewPort;
			newViewPort.width = _width;
			_starlingInstance.viewPort = newViewPort;
        }
        
        override public function get height():Number
        {
            return _height;
        }
        
        override public function set height(value:Number):void
        {
            _height = value;
			var newViewPort : Rectangle = _starlingInstance.viewPort;
			newViewPort.height = _height;
			_starlingInstance.viewPort = newViewPort;
        }
        
		public function get canvasContainerG2D():DisplayObjectContainer{ return _gpuCanvasContainer; }
		public function get starlingInstance():Starling { return _starlingInstance; }
        
        private var _width:Number = 0;
        private var _height:Number = 0;
    }
}
