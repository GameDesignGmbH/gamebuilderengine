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
	import com.pblabs.engine.resource.DataResource;
	import com.pblabs.engine.resource.ImageResource;
	import com.pblabs.rendering2D.ITextRenderer;
	
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.text.TextField;
	import starling.utils.HAlign;

	public class UITextRendererComponentG2D extends DisplayObjectRendererG2D implements ITextRenderer
	{
		protected var _fontColor : uint = 0x000000;
		protected var _fontSize : Number = 12;
		protected var _text : String = "[EMPTY]";
		protected var _fontImage : ImageResource;
		protected var _fontData : DataResource;
		
		public function UITextRendererComponentG2D()
		{
			super();
		}
		
		override protected function onAdd():void
		{
			super.onAdd();
			buildG2DObject();
		}
		
		override protected function buildG2DObject():void
		{
			if(!Starling.context){
				InitializationUtilG2D.initializeRenderers.add(buildG2DObject);
				return;
			}

			if(!gpuObject){
				//Create GPU Renderer Object
				gpuObject = new TextField(_size.x, _size.y, _text, "Arial", _fontSize, _fontColor, true);
				(gpuObject as TextField).hAlign = HAlign.LEFT;
			}
			super.buildG2DObject();
		}

		private function updateFontSize():void
		{
			if(!owner || !gpuObject ) return;
			
			var newSize : Point = new Point((gpuObject as TextField).textBounds.width+2, (gpuObject as TextField).textBounds.height+2)
			if(sizeProperty && sizeProperty.property != "")
			{
				size = newSize;
				this.owner.setProperty( sizeProperty, newSize )
			}else{
				size = newSize;
			}
		}

		public function get fontImage():ImageResource{ return _fontImage; }
		public function set fontImage(img : ImageResource):void{
			_fontImage = img;
		}
		
		public function get fontData():DataResource{ return _fontData; }
		public function set fontData(data : DataResource):void{
			_fontData = data;
		}

		public function get fontColor():uint{ return _fontColor; }
		public function set fontColor(val : uint):void{
			_fontColor = val;
			if(!gpuObject) return;
			gpuTextObject.color = _fontColor;			
		}
		
		public function get fontSize():Number{ return _fontSize; }
		public function set fontSize(val : Number):void{
			_fontSize = val;
			if(!gpuObject) return;
			gpuTextObject.fontSize = _fontSize;
			updateFontSize();
		}
		
		public function get text():String{ return _text; }
		public function set text(val : String):void{
			if(val == "") 
				val = "[Empty]";
			_text = val;
			if(!gpuObject) return;
			gpuTextObject.text = _text;
			updateFontSize();
			//gpuTextObject.autoScale = true;
		}
		
		private function get gpuTextObject():TextField{ return gpuObject ? gpuObject as TextField : null; }

		/**
		 * @inheritDoc
		 */
		override public function set size(value:Point):void
		{
			super.size = value;
			
			if(!gpuObject) return;
			gpuObject.width = _size.x;
			gpuObject.height = _size.y;
		}
	}
}