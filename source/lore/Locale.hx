package lore;

// og https://github.com/sayofthelor/lore-engine/blob/main/source/lore/Locale.hx
import haxe.Json;

class Locale
{
	public static final DEFAULT_LANGUAGE:String = 'en-US';
	public static var selectedLocale:String;
	private static var localeObject:Dynamic;

	public static function init():Void
	{
		selectedLocale = DEFAULT_LANGUAGE;
		if (Paths.fileExists('locale/list.txt', TEXT, true))
		{
			var list:Array<String> = CoolUtil.coolTextFile(Paths.getPath('locale/list.txt', TEXT));
			if (Paths.fileExists('locale/${ClientPrefs.locale}/lang.json', TEXT, true) && list.contains(selectedLocale))
				selectedLocale = ClientPrefs.locale;
		}
		localeObject = Json.parse(lime.utils.Assets.getText(Paths.localeFile(selectedLocale)));
	}

	public static function get(key:String):String
	{
		var returnkey:String = Reflect.field(localeObject, key);
		return returnkey == null ? key : returnkey;
	}
}
