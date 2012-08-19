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
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.rendering2D.BitmapRenderer;
	
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.textures.Texture;
	
	public class BitmapRendererG2D extends BitmapRenderer
	{
		public function BitmapRendererG2D()
		{
			super();
		}
		
		override public function pointOccupied(worldPosition:Point, mask:ObjectType):Boolean
		{
			if (!gpuObject || !scene)
				return false;
			
			// This is the generic version, which uses hitTestPoint. hitTestPoint
			// takes a coordinate in screen space, so do that.
			worldPosition = scene.transformWorldToScreen(worldPosition);
			
			return gpuObject.hitTest(worldPosition) ? true : false;
		}

		override protected function buildG2DObject():void
		{
			if(!Starling.context){
				InitializationUtilG2D.initializeRenderers.add(buildG2DObject);
				return;
			}
			//TODO: Get texture from the resource manager for similar bitmaps so that the memory could be re-used.
			
			if(!gpuObject){
				//Create GPU Renderer Object
				gpuObject = Image.fromBitmap( this.bitmap );
			}else{
				if(( gpuObject as Image).texture)
					( gpuObject as Image).texture.dispose();
				( gpuObject as Image).texture = Texture.fromBitmap( this.bitmap );
			}
			super.buildG2DObject();
		}
		
		protected function modifyTexture(data:Texture):Texture
		{
			return data;            
		}

		override public function set mouseEnabled(value:Boolean):void
		{
			_mouseEnabled = value;
			
			if(!gpuObject) return;
			gpuObject.touchable = _mouseEnabled;
		}

		override public function set bitmapData(value:BitmapData):void
		{
			if (value === bitmap.bitmapData)
				return;
			
			// store orginal BitmapData so that modifiers can be re-implemented 
			// when assigned modifiers attribute later on.
			originalBitmapData = value;
			
			// check if we should do modification
			/*
			if (modifiers.length>0)
			{
				// apply all bitmapData modifiers
				bitmap.bitmapData = modify(originalBitmapData.clone());
				dataModified();			
			}	
			else	
			*/					
				bitmap.bitmapData = value;
			
			// Due to a bug, this has to be reset after setting bitmapData.
			smoothing = _smoothing;
			
			buildG2DObject();
			
			_transformDirty = true;
		}
	}
}