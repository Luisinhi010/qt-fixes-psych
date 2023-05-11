package lore;

// og https://github.com/sayofthelor/lore-engine/blob/main/source/lore/Locale.hx
import haxe.Json;
#if sys import sys.io.File;
import sys.FileSystem; #end // since haxe hates me
import lime.utils.Assets;

using StringTools;

class Locale
{
	public static final DEFAULT_LANGUAGE:String = 'en-US';
	public static var selectedLocale:String;
	private static var localeObject:Dynamic;

	public static function init():Void
	{
		selectedLocale = DEFAULT_LANGUAGE;
		var exists:Bool = Paths.fileExists('locale/${ClientPrefs.locale}/lang.json', TEXT, true);
		if (Paths.fileExists('locale/list.txt', TEXT, true))
		{
			var list:Array<String> = CoolUtil.coolTextFile(Paths.getPath('locale/list.txt', TEXT));
			if (exists && list.contains(ClientPrefs.locale))
				selectedLocale = ClientPrefs.locale;
		}
		localeObject = Json.parse(Assets.getText(Paths.localeFile(selectedLocale)));
		#if sys
		if (!exists) // this may be usseless
		{
			FileSystem.createDirectory('assets/locale/${ClientPrefs.locale}/');
			File.saveContent('assets/locale/${ClientPrefs.locale}/lang.json', Assets.getText(Paths.localeFile(selectedLocale)));
			trace('Created locale for ${ClientPrefs.locale}');
		}
		#end
	}

	public static function get(key:String):String
	{
		var returnkey:String = Reflect.field(localeObject, key);
		if (returnkey == null)
			returnkey = key;
		else
			for (i in ClientPrefs.keyBinds.keys())
				if (returnkey.contains('%' + i))
					returnkey = returnkey.replace('%' + i, ClientPrefs.getkeys(i));

		return returnkey;
	}
}
