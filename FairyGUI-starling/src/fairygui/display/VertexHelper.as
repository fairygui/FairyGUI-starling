package fairygui.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import fairygui.FillType;
	import fairygui.FlipType;
	
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.textures.Texture;

	public class VertexHelper
	{
		public static var vertBuffer:Vector.<Point> = new Vector.<Point>();
		public static var uvBuffer:Vector.<Point> = new Vector.<Point>();
		public static var vertCount:int;
		
		private static var helperPoint:Point = new Point();
		private static var helperRect1:Rectangle = new Rectangle();
		private static var helperRect2:Rectangle = new Rectangle();
		private static var helperRect3:Rectangle = new Rectangle();
		private static var helperRect4:Rectangle = new Rectangle();
		
		public function VertexHelper()
		{
			super();
		}
		
		public static function beginFill():void
		{
			vertCount = 0;

			if(vertBuffer.length==0)
				alloc(200);
		}
		
		public static function alloc(capacity:int):void
		{
			var req:int = capacity;
			var cnt:int = vertBuffer.length;
			if(cnt<req)
			{
				vertBuffer.length = req;
				uvBuffer.length = req;
				
				for(var i:int=cnt;i<req;i++)
				{
					vertBuffer[i] = new Point();
					uvBuffer[i] = new Point();
				}
			}
		}
		
		public static function allocMore(space:int):void
		{
			alloc(vertCount + space);
		}
		
		public static function updateVertexData(vertexData:VertexData):void
		{
			if(vertCount==0)
			{
				vertexData.clear();
				return;
			}
			
			vertexData.numVertices = vertCount;
			for(var i:int=0;i<vertCount;i++)
			{
				vertexData.setPoint(i, "position", vertBuffer[i].x, vertBuffer[i].y);
				vertexData.setPoint(i, "texCoords", uvBuffer[i].x, uvBuffer[i].y);
			}
		}
		
		public static function updateIndexData(indexData:IndexData):void
		{
			if(vertCount==0)
			{
				indexData.clear();
				return;
			}

			indexData.numIndices = 0;
			for(var i:int=0;i<vertCount;i+=4)
			{
				indexData.addQuad(i, i+1, i+2, i+3);
			}
		}
		
		public static function updateAll(vertexData:VertexData, indexData:IndexData):void 
		{
			updateVertexData(vertexData);
			updateIndexData(indexData);
		}
		
		public static function addQuad(x:Number, y:Number, width:Number, height:Number):void
		{
			vertBuffer[vertCount].x = x;
			vertBuffer[vertCount].y = y;
			vertBuffer[vertCount+1].x = x+width;
			vertBuffer[vertCount+1].y = y;
			vertBuffer[vertCount+2].x = x;
			vertBuffer[vertCount+2].y = y+height;
			vertBuffer[vertCount+3].x = x+width;
			vertBuffer[vertCount+3].y = y+height;
			vertCount+=4;
		}
		
		public static function addQuad2(vertRect:Rectangle):void
		{
			vertBuffer[vertCount].x = vertRect.x;
			vertBuffer[vertCount].y = vertRect.y;
			vertBuffer[vertCount+1].x = vertRect.right;
			vertBuffer[vertCount+1].y = vertRect.y;
			vertBuffer[vertCount+2].x = vertRect.x;
			vertBuffer[vertCount+2].y = vertRect.bottom;
			vertBuffer[vertCount+3].x = vertRect.right;
			vertBuffer[vertCount+3].y = vertRect.bottom;
			vertCount+=4;
		}
		
		public static function getTextureUV(texture:Texture, rect:Rectangle = null):Rectangle
		{
			if(rect==null)
				rect = new Rectangle();
			texture.localToGlobal(0,0,helperPoint);
			rect.x = helperPoint.x;
			rect.y = helperPoint.y;
			texture.localToGlobal(1,1,helperPoint);
			rect.right = helperPoint.x;
			rect.bottom = helperPoint.y;
			
			return rect;
		}
		
		public static function flipUV(rect:Rectangle, flip:int):void
		{
			var tmp:Number;
			if (flip == FlipType.Horizontal || flip == FlipType.Both)
			{
				tmp = rect.x;
				rect.x = rect.right;
				rect.right = tmp;
			}
			if (flip == FlipType.Vertical || flip == FlipType.Both)
			{
				tmp = rect.y;
				rect.y = rect.bottom;
				rect.bottom = tmp;
			}
		}
		
		public static function fillUV(x:Number, y:Number, width:Number, height:Number):void
		{
			var vertIndex:int = vertCount-4;
			uvBuffer[vertIndex].x = x;
			uvBuffer[vertIndex].y = y;
			uvBuffer[vertIndex+1].x = x+width;
			uvBuffer[vertIndex+1].y = y;
			uvBuffer[vertIndex+2].x = x;
			uvBuffer[vertIndex+2].y = y+height;
			uvBuffer[vertIndex+3].x = x+width;
			uvBuffer[vertIndex+3].y = y+height;
		}
		
		public static function fillUV2(uvRect:Rectangle):void
		{
			var vertIndex:int = vertCount-4;
			uvBuffer[vertIndex].x = uvRect.x;
			uvBuffer[vertIndex].y = uvRect.y;
			uvBuffer[vertIndex+1].x = uvRect.right;
			uvBuffer[vertIndex+1].y = uvRect.y;
			uvBuffer[vertIndex+2].x = uvRect.x;
			uvBuffer[vertIndex+2].y = uvRect.bottom;
			uvBuffer[vertIndex+3].x = uvRect.right;
			uvBuffer[vertIndex+3].y = uvRect.bottom;
		}
		
		public static function fillUV3(uvRect:Rectangle, ratioX:Number, ratioY:Number):void
		{
			var vertIndex:int = vertCount-4;
			uvBuffer[vertIndex].x = uvRect.x;
			uvBuffer[vertIndex].y = uvRect.y;
			uvBuffer[vertIndex+1].x = uvRect.x + uvRect.width*ratioX;
			uvBuffer[vertIndex+1].y = uvRect.y;
			uvBuffer[vertIndex+2].x = uvRect.x;
			uvBuffer[vertIndex+2].y = uvRect.y + uvRect.height*ratioY;
			uvBuffer[vertIndex+3].x = uvBuffer[vertIndex+1].x;
			uvBuffer[vertIndex+3].y = uvBuffer[vertIndex+2].y;
		}
		
		public static function fillUV4(texture:Texture):void
		{
			texture.localToGlobal(0,0,helperPoint);
			var x:Number = helperPoint.x;
			var y:Number = helperPoint.y;
			texture.localToGlobal(1,1,helperPoint);
			var width:Number = helperPoint.x-x;
			var height:Number = helperPoint.y-y;
			
			var vertIndex:int = vertCount-4;
			uvBuffer[vertIndex].x = x;
			uvBuffer[vertIndex].y = y;
			uvBuffer[vertIndex+1].x = x + width;
			uvBuffer[vertIndex+1].y = y;
			uvBuffer[vertIndex+2].x = x;
			uvBuffer[vertIndex+2].y = y + height;
			uvBuffer[vertIndex+3].x = x + width;
			uvBuffer[vertIndex+3].y = y + height;
		}
		
		public static function fillImage(method:int, amount:Number, origin:int, clockwise:Boolean,
									vertRect:Rectangle, uvRect:Rectangle):void
		{
			amount = amount>1?1:(amount<0?0:amount);
			switch(method)
			{
				case FillType.FillMethod_Horizontal:
					fillHorizontal(origin, amount, vertRect, uvRect);
					break;
				
				case FillType.FillMethod_Vertical:
					fillVertical(origin, amount, vertRect, uvRect);
					break;
				
				case FillType.FillMethod_Radial90:
					fillRadial90(origin, amount, clockwise, vertRect, uvRect);
					break;
				
				case FillType.FillMethod_Radial180:
					fillRadial180(origin, amount, clockwise, vertRect, uvRect);
					break;
				
				case FillType.FillMethod_Radial360:
					fillRadial360(origin, amount, clockwise, vertRect, uvRect);
					break;	
			}
		}
		
		public static function fillHorizontal(origin:int, amount:Number, 
					vertRect:Rectangle, uvRect:Rectangle):void
		{
			if (origin == FillType.OriginHorizontal_Left)
			{
				vertRect.width = vertRect.width * amount;
				uvRect.width = uvRect.width * amount;
			}
			else
			{
				vertRect.x += vertRect.width * (1 - amount);
				vertRect.width = vertRect.width * amount;
				uvRect.x += uvRect.width * (1 - amount);
				uvRect.width = uvRect.width * amount;
			}
			
			addQuad2(vertRect);
			fillUV2(uvRect);
		}
		
		public static function fillVertical(origin:int, amount:Number, 
											vertRect:Rectangle, uvRect:Rectangle):void
		{
			if (origin == FillType.OriginVertical_Bottom)
			{
				vertRect.y += vertRect.height * (1 - amount);
				vertRect.height = vertRect.height * amount;
				uvRect.y += uvRect.height*(1-amount);
				uvRect.height = uvRect.height * amount;
			}
			else
			{
				vertRect.height = vertRect.height * amount;
				uvRect.height = uvRect.height * amount;
			}
			
			addQuad2(vertRect);
			fillUV2(uvRect);
		}
		
		public static function fillRadial90(origin:int, amount:Number, clockwise:Boolean, 
											vertRect:Rectangle, uvRect:Rectangle):void
		{			
			if (amount < 0.001)
				return;
			
			addQuad2(vertRect);
			fillUV2(uvRect);
			
			if (amount > 0.999)
				return;
			
			var v:Number, h:Number, ratio:Number;
			switch (origin)
			{
				case FillType.Origin90_BottomLeft:
				{
					if (clockwise)
					{
						v = Math.tan(Math.PI / 2 * (1 - amount));
						h = vertRect.width * v;
						if (h > vertRect.height)
						{
							ratio = (h - vertRect.height) / h;
							vertBuffer[1].x -= vertRect.width * ratio;
							vertBuffer[3].copyFrom(vertBuffer[1]);
							
							uvBuffer[1].x -= uvRect.width * ratio;
							uvBuffer[3].copyFrom(uvBuffer[1]);
						}
						else
						{
							ratio = h / vertRect.height;
							vertBuffer[3].y -= h;
							uvBuffer[3].y -= uvRect.height * ratio;
						}
					}
					else
					{
						v = Math.tan(Math.PI / 2 * amount);
						h = vertRect.width * v;
						if (h > vertRect.height)
						{
							ratio = (h - vertRect.height) / h;
							vertBuffer[0].x += vertRect.width * (1 - ratio);
							uvBuffer[0].x += uvRect.width * (1 - ratio);
						}
						else
						{
							ratio = h / vertRect.height;
							vertBuffer[1].y += vertRect.height * (1 - ratio);
							vertBuffer[0].copyFrom(vertBuffer[1]);
							
							uvBuffer[1].y += uvRect.height * (1 - ratio);
							uvBuffer[0].copyFrom(uvBuffer[1]);
						}
					}
					break;
				}
				
				case FillType.Origin90_BottomRight:
				{
					if (clockwise)
					{
						v = Math.tan(Math.PI / 2 * amount);
						h = vertRect.width * v;
						if (h > vertRect.height)
						{
							ratio = (h - vertRect.height) / h;
							vertBuffer[1].x -= vertRect.width * (1 - ratio);
							uvBuffer[1].x -= uvRect.width * (1 - ratio);
						}
						else
						{
							ratio = h / vertRect.height;
							vertBuffer[0].y += vertRect.height * (1 - ratio);
							vertBuffer[1].copyFrom(vertBuffer[3]);
							
							uvBuffer[0].y += uvRect.height * (1 - ratio);
							uvBuffer[1].copyFrom(uvBuffer[3]);
						}
					}
					else
					{
						v =  Math.tan(Math.PI / 2 * (1 - amount));
						h = vertRect.width * v;
						if (h > vertRect.height)
						{
							ratio = (h - vertRect.height) / h;
							vertBuffer[0].x += vertRect.width * ratio;
							vertBuffer[2].copyFrom(vertBuffer[0]);
							
							uvBuffer[0].x += uvRect.width * ratio;
							uvBuffer[2].copyFrom(uvBuffer[0]);
						}
						else
						{
							ratio = h / vertRect.height;
							vertBuffer[2].y -= h;
							uvBuffer[2].y -= uvRect.height * ratio;
						}
					}
					break;
				}					
				
				case FillType.Origin90_TopLeft:
				{
					if (clockwise)
					{
						v = Math.tan(Math.PI / 2 * amount);
						h = vertRect.width * v;
						if (h > vertRect.height)
						{
							ratio = (h - vertRect.height) / h;
							vertBuffer[2].x += vertRect.width * (1 - ratio);
							uvBuffer[2].x += uvRect.width * (1 - ratio);
						}
						else
						{
							ratio = h / vertRect.height;
							vertBuffer[3].y -= vertRect.height * (1 - ratio);
							vertBuffer[2].copyFrom(vertBuffer[3]);
							
							uvBuffer[3].y -= uvRect.height * (1 - ratio);
							uvBuffer[2].copyFrom(uvBuffer[3]);
						}
					}
					else
					{
						v =  Math.tan(Math.PI / 2 * (1 - amount));
						h = vertRect.width * v;
						if (h > vertRect.height)
						{
							ratio = (h - vertRect.height) / h;
							vertBuffer[3].x -= vertRect.width * ratio;
							vertBuffer[1].copyFrom(vertBuffer[3]);
							uvBuffer[3].x -= uvRect.width * ratio;
							uvBuffer[1].copyFrom(uvBuffer[3]);
						}
						else
						{
							ratio = h / vertRect.height;
							vertBuffer[1].y += h;
							uvBuffer[1].y += uvRect.height * ratio;
						}
					}
					break;
				}					
				
				case FillType.Origin90_TopRight:
				{
					if (clockwise)
					{
						v =  Math.tan(Math.PI / 2 * (1 - amount));
						h = vertRect.width * v;
						if (h > vertRect.height)
						{
							ratio = (h - vertRect.height) / h;
							vertBuffer[2].x += vertRect.width * ratio;
							vertBuffer[0].copyFrom(vertBuffer[1]);
							uvBuffer[2].x += uvRect.width * ratio;
							uvBuffer[0].copyFrom(uvBuffer[1]);
						}
						else
						{
							ratio = h / vertRect.height;
							vertBuffer[0].y += vertRect.height * ratio;
							uvBuffer[0].y += uvRect.height * ratio;
						}
					}
					else
					{
						v = Math.tan(Math.PI / 2 * amount);
						h = vertRect.width * v;
						if (h > vertRect.height)
						{
							ratio = (h - vertRect.height) / h;
							vertBuffer[3].x -= vertRect.width * (1 - ratio);
							uvBuffer[3].x -= uvRect.width * (1 - ratio);
						}
						else
						{
							ratio = h / vertRect.height;
							vertBuffer[2].y -= vertRect.height * (1 - ratio);
							vertBuffer[3].copyFrom(vertBuffer[2]);
							uvBuffer[2].y -= uvRect.height * (1 - ratio);
							uvBuffer[3].copyFrom(uvBuffer[2]);
						}
					}
				}
				break;
			}
		}
		
		public static function fillRadial180(origin:int, amount:Number, clockwise:Boolean, 
											vertRect:Rectangle, uvRect:Rectangle):void
		{			
			if (amount < 0.001)
				return;
			
			if (amount > 0.999)
			{
				addQuad2(vertRect);
				fillUV2(uvRect);
				return;
			}
			
			helperRect1.copyFrom(vertRect);
			helperRect2.copyFrom(uvRect);
			
			vertRect = helperRect1;
			uvRect = helperRect2;
			
			var v:Number, h:Number, ratio:Number;
			switch (origin)
			{
				case FillType.Origin180_Top:
					if (amount <= 0.5)
					{
						vertRect.width /= 2;
						uvRect.width /= 2;
						if (clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						amount = amount / 0.5;
						fillRadial90(clockwise ? FillType.Origin90_TopLeft : FillType.Origin90_TopRight, amount, clockwise, vertRect, uvRect);
					}
					else
					{
						vertRect.width /= 2;
						uvRect.width /= 2;
						if (!clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						amount = (amount - 0.5) / 0.5;
						fillRadial90(clockwise ? FillType.Origin90_TopRight : FillType.Origin90_TopLeft, amount, clockwise, vertRect, uvRect);
						
						if (clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						else
						{
							vertRect.x -= vertRect.width;
							uvRect.x -= uvRect.width;
						}
						addQuad2(vertRect);
						fillUV2(uvRect);
					}
					break;
				
				case FillType.Origin180_Bottom:
					if (amount <= 0.5)
					{
						vertRect.width /= 2;
						uvRect.width /= 2;
						if (!clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						amount = amount / 0.5;
						fillRadial90(clockwise ? FillType.Origin90_BottomRight : FillType.Origin90_BottomLeft, amount, clockwise, vertRect, uvRect);
					}
					else
					{
						vertRect.width /= 2;
						uvRect.width /= 2;
						if (clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						amount = (amount - 0.5) / 0.5;
						fillRadial90(clockwise ? FillType.Origin90_BottomLeft : FillType.Origin90_BottomRight, amount, clockwise, vertRect, uvRect);
						
						if (clockwise)
						{
							vertRect.x -= vertRect.width;
							uvRect.x -= uvRect.width;
						}
						else
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						addQuad2(vertRect);
						fillUV2(uvRect);
					}
					break;
				
				case FillType.Origin180_Left:
					if (amount <= 0.5)
					{
						if (clockwise)
						{
							vertRect.height /= 2;
							uvRect.height /= 2;
						}
						else
						{
							vertRect.height /= 2;
							vertRect.y += vertRect.height;
							uvRect.height /= 2;
							uvRect.y += uvRect.height;
						}
						amount = amount / 0.5;
						fillRadial90(clockwise ? FillType.Origin90_BottomLeft : FillType.Origin90_TopLeft, amount, clockwise, vertRect, uvRect);
					}
					else
					{
						if (clockwise)
						{
							vertRect.height /= 2;
							vertRect.y += vertRect.height;
							uvRect.height /= 2;
							uvRect.y += uvRect.height;
						}
						else
						{
							vertRect.height /= 2;
							uvRect.height /= 2;
						}
						amount = (amount - 0.5) / 0.5;
						fillRadial90(clockwise ? FillType.Origin90_TopLeft : FillType.Origin90_BottomLeft, amount, clockwise, vertRect, uvRect);
						
						if (clockwise)
						{
							vertRect.y -= vertRect.height;
							uvRect.y -= uvRect.height;
						}
						else
						{
							vertRect.y += vertRect.height;
							uvRect.y += uvRect.height;
						}
						addQuad2(vertRect);
						fillUV2(uvRect);
					}
					break;
				
				case FillType.Origin180_Right:
					if (amount <= 0.5)
					{
						if (clockwise)
						{
							vertRect.height /= 2;
							vertRect.y += vertRect.height;
							uvRect.height /= 2;
							uvRect.y += uvRect.height;
						}
						else
						{
							vertRect.height /= 2;
							uvRect.height /= 2;
						}
						amount = amount / 0.5;
						fillRadial90(clockwise ? FillType.Origin90_TopRight : FillType.Origin90_BottomRight, amount, clockwise, vertRect, uvRect);
					}
					else
					{
						if (clockwise)
						{
							vertRect.height /= 2;
							uvRect.height /= 2;
						}
						else
						{
							vertRect.height /= 2;
							vertRect.y += vertRect.height;
							uvRect.height /= 2;					
							uvRect.y += uvRect.height;
						}
						amount = (amount - 0.5) / 0.5;
						fillRadial90(clockwise ? FillType.Origin90_BottomRight : FillType.Origin90_TopRight, amount, clockwise, vertRect, uvRect);
						
						if (clockwise)
						{
							vertRect.y += vertRect.height;
							uvRect.y += uvRect.height;
						}
						else
						{
							vertRect.y -= vertRect.height;
							uvRect.y -= uvRect.height;
						}
						addQuad2(vertRect);
						fillUV2(uvRect);
					}
					break;
			}
		}
		
		public static function fillRadial360(origin:int, amount:Number, clockwise:Boolean, 
											 vertRect:Rectangle, uvRect:Rectangle):void
		{			
			if (amount < 0.001)
				return;
			
			if (amount > 0.999)
			{
				addQuad2(vertRect);
				fillUV2(uvRect);
				return;
			}
			
			helperRect3.copyFrom(vertRect);
			helperRect4.copyFrom(uvRect);
			
			vertRect = helperRect3;
			uvRect = helperRect4;
			
			switch (origin)
			{
				case FillType.Origin360_Top:
					if (amount < 0.5)
					{
						amount = amount / 0.5;
						vertRect.width /= 2;
						uvRect.width /= 2;
						if (clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						fillRadial180(clockwise ? FillType.Origin180_Left : FillType.Origin180_Right, amount, clockwise, vertRect, uvRect);
					}
					else
					{
						vertRect.width /= 2;
						uvRect.width /= 2;
						if (!clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						amount = (amount - 0.5) / 0.5;
						fillRadial180(clockwise ? FillType.Origin180_Right : FillType.Origin180_Left, amount, clockwise, vertRect, uvRect);
						
						if (clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						else
						{
							vertRect.x -= vertRect.width;
							uvRect.x -= uvRect.width;
						}
						addQuad2(vertRect);
						fillUV2(uvRect);
					}
					break;
				
				case FillType.Origin360_Bottom:
					if (amount < 0.5)
					{
						amount = amount / 0.5;
						vertRect.width /= 2;
						uvRect.width /= 2;
						if (!clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						fillRadial180(clockwise ? FillType.Origin180_Right : FillType.Origin180_Left, amount, clockwise, vertRect, uvRect);
					}
					else
					{
						vertRect.width /= 2;
						uvRect.width /= 2;
						if (clockwise)
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						amount = (amount - 0.5) / 0.5;
						fillRadial180(clockwise ? FillType.Origin180_Left : FillType.Origin180_Right, amount, clockwise, vertRect, uvRect);
						
						if (clockwise)
						{
							vertRect.x -= vertRect.width;
							uvRect.x -= uvRect.width;
						}
						else
						{
							vertRect.x += vertRect.width;
							uvRect.x += uvRect.width;
						}
						addQuad2(vertRect);
						fillUV2(uvRect);
					}
					break;
				
				case FillType.Origin360_Left:
					if (amount < 0.5)
					{
						amount = amount / 0.5;
						if (clockwise)
						{
							vertRect.height /= 2;
							uvRect.height /= 2;
						}
						else
						{
							vertRect.height /= 2;
							vertRect.y += vertRect.height;
							uvRect.height /= 2;
							uvRect.y += uvRect.height;
						}
						fillRadial180(clockwise ? FillType.Origin180_Bottom : FillType.Origin180_Top, amount, clockwise, vertRect, uvRect);
					}
					else
					{
						if (clockwise)
						{
							vertRect.height /= 2;
							vertRect.y += vertRect.height;
							uvRect.height /= 2;
							uvRect.y += uvRect.height;
						}
						else
						{
							vertRect.height /= 2;
							uvRect.height /= 2;
						}
						amount = (amount - 0.5) / 0.5;
						fillRadial180(clockwise ? FillType.Origin180_Top : FillType.Origin180_Bottom, amount, clockwise, vertRect, uvRect);
						
						if (clockwise)
						{
							vertRect.y -= vertRect.height;
							uvRect.y -= uvRect.height;
						}
						else
						{
							vertRect.y += vertRect.height;
							uvRect.y += uvRect.height;
						}
						addQuad2(vertRect);
						fillUV2(uvRect);
					}
					break;
				
				case FillType.Origin360_Right:
					if (amount < 0.5)
					{
						if (clockwise)
						{
							vertRect.height /= 2;
							vertRect.y += vertRect.height;
							uvRect.height /= 2;
							uvRect.y += uvRect.height;
						}
						else
						{
							vertRect.height /= 2;
							uvRect.height /= 2;
						}
						amount = amount / 0.5;
						fillRadial180(clockwise ? FillType.Origin180_Top : FillType.Origin180_Bottom, amount, clockwise, vertRect, uvRect);
					}
					else
					{
						if (clockwise)
						{
							vertRect.height /= 2;
							uvRect.height /= 2;
						}
						else
						{
							vertRect.height /= 2;
							vertRect.y += vertRect.height;
							uvRect.height /= 2;
							uvRect.y += uvRect.height;
						}
						
						amount = (amount - 0.5) / 0.5;
						fillRadial180(clockwise ? FillType.Origin180_Bottom : FillType.Origin180_Top, amount, clockwise, vertRect, uvRect);
						
						if (clockwise)
						{
							vertRect.y += vertRect.height;
							uvRect.y += uvRect.height;
						}
						else
						{
							vertRect.y -= vertRect.height;
							uvRect.y -= uvRect.height;
						}
						addQuad2(vertRect);
						fillUV2(uvRect);
					}
					break;
			}
		}
	}
}

