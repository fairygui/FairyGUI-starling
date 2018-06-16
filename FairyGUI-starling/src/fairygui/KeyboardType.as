package fairygui
{
	import flash.text.SoftKeyboardType;
	
	public class KeyboardType
	{
		public function KeyboardType()
		{
		}
		public static function parseType(value:int):String
		{
			try { 
				switch(value)
				{
					case 0://默认键盘
						return SoftKeyboardType.DEFAULT;
					case 1://字母
						return SoftKeyboardType.CONTACT;
					case 2://数字和标点
						return SoftKeyboardType.DECIMAL;
					case 3://URL
						return SoftKeyboardType.URL;
					case 4://数字
						return SoftKeyboardType.NUMBER;
					case 5://电话号码
						return SoftKeyboardType.PHONE;
					case 6://邮件地址
						return SoftKeyboardType.EMAIL;
				}
				return SoftKeyboardType.DEFAULT;
			}catch(errObject:Error) { 
				return SoftKeyboardType.DEFAULT;
			}			
		}
	}
}