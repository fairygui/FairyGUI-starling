package fairygui
{
	public class FillType
	{
		public static const FillMethod_None:int = 0;
		public static const FillMethod_Horizontal:int = 1;
		public static const FillMethod_Vertical:int = 2;
		public static const FillMethod_Radial90:int = 3;
		public static const FillMethod_Radial180:int = 4;
		public static const FillMethod_Radial360:int = 5;
		
		public static const OriginHorizontal_Left:int = 0;
		public static const OriginHorizontal_Right:int = 1;
		
		public static const OriginVertical_Top:int = 0;
		public static const OriginVertical_Bottom:int = 1;
		
		public static const Origin90_TopLeft:int = 0;
		public static const Origin90_TopRight:int = 1;
		public static const Origin90_BottomLeft:int = 2;
		public static const Origin90_BottomRight:int = 3;
		
		public static const Origin180_Top:int = 0;
		public static const Origin180_Bottom:int = 1;
		public static const Origin180_Left:int = 2;
		public static const Origin180_Right:int = 3;
		
		public static const Origin360_Top:int = 0;
		public static const Origin360_Bottom:int = 1;
		public static const Origin360_Left:int = 2;
		public static const Origin360_Right:int = 3;
		
		public function FillType()
		{
		}
		
		public static function parseFillMethod(value:String):int
		{
			switch (value)
			{
				case "none":
					return FillMethod_None;
				case "hz":
					return FillMethod_Horizontal;
				case "vt":
					return FillMethod_Vertical;
				case "radial90":
					return FillMethod_Radial90;
				case "radial180":
					return FillMethod_Radial180;
				case "radial360":
					return FillMethod_Radial360;
				default:
					return FillMethod_None;
			}
		}
	}
}