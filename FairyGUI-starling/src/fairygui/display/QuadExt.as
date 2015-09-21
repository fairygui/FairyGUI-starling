package fairygui.display
{
	import flash.geom.Rectangle;
	
	import starling.display.Quad;
	import starling.textures.Texture;
	
	public class QuadExt extends Quad
	{		
		private static var sHelperTexCoords:Vector.<Number> = new Vector.<Number>(8);
		private static var FULL_UV:Array = [0,0,1,0,0,1,1,1];
		
		public function QuadExt()
		{			
			super(1, 1);
		}
		
		public function setPremultipliedAlpha(value:Boolean):void
		{
			mVertexData.setPremultipliedAlpha(value, false);
		}
		
		public function fillVertsByRect(vertRect:Rectangle):void
		{
			mVertexData.setPosition(0, vertRect.x, vertRect.y);
			mVertexData.setPosition(1, vertRect.right, vertRect.y);
			mVertexData.setPosition(2, vertRect.x, vertRect.bottom);
			mVertexData.setPosition(3, vertRect.right, vertRect.bottom); 
		}
		
		public function fillVertsWithScale(x:Number, y:Number, width:Number, height:Number, sx:Number, sy:Number):void
		{
			mVertexData.setPosition(0, x*sx, y*sy);
			mVertexData.setPosition(1, (x+width)*sx, y*sy);
			mVertexData.setPosition(2, x*sx, (y+height)*sy);
			mVertexData.setPosition(3, (x+width)*sx, (y+height)*sy);
		}
		
		public function fillVerts(x:Number, y:Number, width:Number, height:Number):void
		{
			mVertexData.setPosition(0, x, y);
			mVertexData.setPosition(1, x+width, y);
			mVertexData.setPosition(2, x, y+height);
			mVertexData.setPosition(3, x+width, y+height);
		}
		
		public function fillUVByRect(uvRect:Rectangle):void
		{
			mVertexData.setTexCoords(0, uvRect.x, uvRect.y);
			mVertexData.setTexCoords(1, uvRect.right, uvRect.y);
			mVertexData.setTexCoords(2, uvRect.x, uvRect.bottom);
			mVertexData.setTexCoords(3, uvRect.right, uvRect.bottom); 
		}
		
		public function fillUVOfTexture(texture:Texture):void
		{
			for(var i:int=0;i<8;i++)
				sHelperTexCoords[i] = FULL_UV[i];
			texture.adjustTexCoords(sHelperTexCoords);
			for(i=0;i<4;i++)
				mVertexData.setTexCoords(i, sHelperTexCoords[i*2], sHelperTexCoords[i*2+1]);	
		}
		
		public function fillUV(texCoords:Vector.<Number>, texture:Texture):void
		{
			for(var i:int=0;i<8;i++)
				sHelperTexCoords[i] = texCoords[i];
			texture.adjustTexCoords(sHelperTexCoords);
			for(i=0;i<4;i++)
				mVertexData.setTexCoords(i, sHelperTexCoords[i*2], sHelperTexCoords[i*2+1]);	
		}
		
		public function fillUVWithScale(texCoords:Vector.<Number>, texture:Texture, percX:Number, percY:Number):void
		{
			for(var i:int=0;i<8;i++)
				sHelperTexCoords[i] = texCoords[i];
			
			if(sHelperTexCoords[2]>sHelperTexCoords[0])
				sHelperTexCoords[2] = sHelperTexCoords[0] + (sHelperTexCoords[2]-sHelperTexCoords[0])*percX;
			else
				sHelperTexCoords[2] = sHelperTexCoords[2] + (sHelperTexCoords[0]-sHelperTexCoords[2])*(1-percX);
			sHelperTexCoords[6] = sHelperTexCoords[2];
			
			if(sHelperTexCoords[5]>sHelperTexCoords[1])
				sHelperTexCoords[5] = sHelperTexCoords[1] + (sHelperTexCoords[5]-sHelperTexCoords[1])*percY;
			else
				sHelperTexCoords[5] = sHelperTexCoords[5] + (sHelperTexCoords[1]-sHelperTexCoords[5])*(1-percY);
			sHelperTexCoords[7] = sHelperTexCoords[5];

			texture.adjustTexCoords(sHelperTexCoords);
			for(i=0;i<4;i++)
				mVertexData.setTexCoords(i, sHelperTexCoords[i*2], sHelperTexCoords[i*2+1]);	
		}
	}
}