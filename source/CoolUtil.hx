package;

import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import flixel.system.FlxSound;
import openfl.display.BlendMode;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tweens.FlxTween.FlxTweenType;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

class CoolUtil
{
	public static final defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Hard', 'Harder'];
	public static final defaultDifficulty:String = 'Normal'; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode
	public static var difficulties:Array<String> = [];
	public static var lowerDifficulties(get, null):Array<String>;

	static function get_lowerDifficulties():Array<String>
	{
		var copy:Array<String> = [];
		for (v in difficulties)
			copy.push(v.toLowerCase());
		return copy;
	}

	inline public static function quantize(f:Float, snap:Float):Float
		return Math.fround(f * snap) / snap; // changed so this actually works lol

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	public static function getDifficultyFilePath(num:Null<Int> = null):String
	{
		if (num == null)
			num = PlayState.storyDifficulty;
		var fileSuffix:String = difficulties[num];
		if (fileSuffix != defaultDifficulty)
			fileSuffix = '-' + fileSuffix;
		else
			fileSuffix = '';
		return Paths.formatToSongPath(fileSuffix);
	}

	inline public static function difficultyString():String
	{
		var dumbShit:String = difficulties[PlayState.storyDifficulty].toUpperCase();

		// Scuffed code is my favourite type of code!
		// I mean, trust me, I am professional programmer, I totally know what I am doing.
		// LMFAO
		// ported to psych 0.6.3 cuz yes
		if (PlayState.SONG != null && PlayState.THISISFUCKINGDISGUSTINGPLEASESAVEME)
		{
			switch (PlayState.SONG.song.toLowerCase())
			{
				case "termination":
					dumbShit = (PlayState.storyDifficulty == 2 ? "CLASSIC" : "VERY HARD");
				case "cessation":
					dumbShit = "FUTURE";
				case "interlope":
					dumbShit = "???";
			}
		}
		return dumbShit;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));

	public static function coolTextFile(path:String):Array<String>
	{
		#if sys
		if (FileSystem.exists(path))
			return [for (i in File.getContent(path).trim().split('\n')) i.trim()];
		#else
		if (Assets.exists(path))
			return [for (i in Assets.getText(path).trim().split('\n')) i.trim()];
		#end
		return [];
	}

	inline public static function listFromString(string:String):Array<String>
		return [for (i in string.trim().split('\n')) i.trim()];

	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];

	// uhhhh does this even work at all? i'm starting to doubt
	// yes it does. -Luis
	public static function precacheSound(sound:String, ?library:String = null):Void
		precacheSoundFile(Paths.sound(sound, library));

	public static function precacheMusic(sound:String, ?library:String = null):Void
		precacheSoundFile(Paths.music(sound, library));

	public static function precacheVoices(sound:String, ?library:String = null):Void
		precacheSoundFile(Paths.voices(sound));

	public static function precacheInst(sound:String, ?library:String = null):Void
		precacheSoundFile(Paths.inst(sound));

	public static function precacheImage(image:String, ?library:String = null):Void
		precacheImageFile(Paths.image(image, library));

	private static function precacheSoundFile(file:Dynamic):Void
	{
		if (Assets.exists(file, SOUND) || Assets.exists(file, MUSIC))
			Assets.getSound(file, true);
	}

	private static function precacheImageFile(file:Dynamic):Void
	{
		if (Assets.exists(file, IMAGE))
			LimeAssets.getImage(file, true);
	}

	inline public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	/** Quick Function to Fix Save Files for Flixel 5
		if you are making a mod, you are gonna wanna change "Hazardous industries" to something else
		so Base Psych saves won't conflict with yours
		@BeastlyGabi 
	**/
	public static function getSavePath(folder:String = 'Hazardous industries'):String
	{
		@:privateAccess
		return #if (flixel < "5.0.0") folder #else FlxG.stage.application.meta.get('company')
			+ '/'
			+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}

	public static function returnTweenType(?type:String = ''):FlxTweenType
	{
		switch (type.toLowerCase())
		{
			case 'backward':
				return FlxTweenType.BACKWARD;
			case 'looping':
				return FlxTweenType.LOOPING;
			case 'oneshot':
				return FlxTweenType.ONESHOT;
			case 'persist':
				return FlxTweenType.PERSIST;
			case 'pingpong':
				return FlxTweenType.PINGPONG;
		}
		return FlxTweenType.PERSIST;
	}

	public static function returnBlendMode(str:String):BlendMode
	{
		return switch (str.toLowerCase())
		{
			case "normal": BlendMode.NORMAL;
			case "darken": BlendMode.DARKEN;
			case "multiply": BlendMode.MULTIPLY;
			case "lighten": BlendMode.LIGHTEN;
			case "screen": BlendMode.SCREEN;
			case "overlay": BlendMode.OVERLAY;
			case "hardlight": BlendMode.HARDLIGHT;
			case "difference": BlendMode.DIFFERENCE;
			case "add": BlendMode.ADD;
			case "subtract": BlendMode.SUBTRACT;
			case "invert": BlendMode.INVERT;
			case _: BlendMode.NORMAL;
		}
	}

	public static function setTextAlign(str:String):FlxTextAlign
	{
		return switch (str.toLowerCase())
		{
			case "center": FlxTextAlign.CENTER;
			case "justify": FlxTextAlign.JUSTIFY;
			case "left": FlxTextAlign.LEFT;
			case "right": FlxTextAlign.RIGHT;
			case _: FlxTextAlign.LEFT;
		}
	}

	public static function returnColor(?str:String = ''):FlxColor
	{
		switch (str.toLowerCase())
		{
			case "black":
				return FlxColor.BLACK;
			case "white":
				return FlxColor.WHITE;
			case "blue":
				return FlxColor.BLUE;
			case "brown":
				return FlxColor.BROWN;
			case "cyan":
				return FlxColor.CYAN;
			case "yellow":
				return FlxColor.YELLOW;
			case "gray":
				return FlxColor.GRAY;
			case "green":
				return FlxColor.GREEN;
			case "lime":
				return FlxColor.LIME;
			case "magenta":
				return FlxColor.MAGENTA;
			case "orange":
				return FlxColor.ORANGE;
			case "pink":
				return FlxColor.PINK;
			case "purple":
				return FlxColor.PURPLE;
			case "red":
				return FlxColor.RED;
			case "transparent" | 'trans':
				return FlxColor.TRANSPARENT;
		}
		return FlxColor.WHITE;
	}

	public static function getPoint(point:String):FlxAxes
	{
		switch (point.toLowerCase())
		{
			case 'x':
				return FlxAxes.X;
			case 'y':
				return FlxAxes.Y;
			case 'xy':
				return FlxAxes.XY;
		}
		return FlxAxes.XY;
	}

	public static function fromHSB(hue:Float, sat:Float, brt:Float, alpha:Float):FlxColor
		return FlxColor.fromHSB(hue, sat, brt, alpha);

	public static function fromRGB(red:Int, green:Int, blue:Int, alpha:Int):FlxColor
		return FlxColor.fromRGB(red, green, blue, alpha);

	public static function fromRGBFloat(red:Float, green:Float, blue:Float, alpha:Float):FlxColor
		return FlxColor.fromRGBFloat(red, green, blue, alpha);

	public static function fromInt(value:Int):FlxColor
		return FlxColor.fromInt(value);

	public static function fromString(str:String):FlxColor
		return FlxColor.fromString(str);

	public static function getUsername()
	{
		#if sys
		/*
			var envs = Sys.environment();
			if (envs.exists("USERNAME"))
				return envs["USERNAME"];
			if (envs.exists("USER"))
				return envs["USER"];
		 */
		#end
		return null;
	}

	public static function getUsernameOption()
	{
		#if sys
		if (getUsername() != null)
			return true;
		#end
		return false;
	}

	public static function getFramerate(Int:Int, multiply:Bool = false)
	{
		var frame:Int = Int;
		if (MusicBeatState.multAnims)
			frame = multiply ? Std.int(Int * PlayState.instance.playbackRate) : Std.int(Int / PlayState.instance.playbackRate);
		return frame;
	}

	public static function mashIntoOneLine(a:Array<String>):String
		return a.join('');

	public static function windowsToast(title:String = null,
			text:String = null) // from https://github.com/tposejank/FNF-PsychEngine/blob/jankengine-dev/source/CoolUtil.hx
	{
		#if windows
		if (title == null)
			title = openfl.Lib.application.meta["name"];
		if (text == null)
			text = "Notification";

		var prohibitSymbols:Array<String> = ["'"];

		var commands:Array<String> = [
			"powershell -Command \"",
			"$ErrorActionPreference = 'Stop';",
			"$notificationTitle = '",
			deleteSpecialSymbols(text, prohibitSymbols),
			"';",
			"[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null;",
			"$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01);",
			"$toastXml = [xml]",
			"$template.GetXml();",
			"$toastXml.GetElementsByTagName('text').AppendChild($toastXml.CreateTextNode($notificationTitle)) > $null;",
			"$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;",
			"$xml.LoadXml($toastXml.OuterXml);",
			"$toast = [Windows.UI.Notifications.ToastNotification]::new($xml);",
			"$toast.Tag = 'Test1';",
			"$toast.Group = 'Test2';",
			"$toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(5);",
			"$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('",
			deleteSpecialSymbols(title, prohibitSymbols),
			"');",
			"$notifier.Show($toast);\""
		];

		var toRun:String = mashIntoOneLine(commands);
		Sys.command(toRun);
		#end
	}

	public static function deleteSpecialSymbols(string:String, ?symbols:Array<String> = null)
	{
		var newString:String = "";
		for (i in 0...string.length)
		{
			var char:String = string.charAt(i);

			var dontCheck:Bool = false;
			if (char == ' ')
				dontCheck = true;

			if (symbols != null && !dontCheck)
				if (symbols.contains(char))
					continue;

			if (!isTypeAlphabet(char) && !dontCheck)
				continue;

			newString += char;
		}

		return newString;
	}

	public static function isTypeAlphabet(c:String) // thanks kade
	{
		var ascii = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122) || // A-Z, a-z
			specialCharCheck(c);
	}

	public static function specialCharCheck(c:String):Bool
	{
		switch (c.toLowerCase())
		{
			case 'á' | 'é' | 'í' | 'ó' | 'ú' | 'ñ' | 'ï' | 'õ' | 'ü' | 'ê' | 'ç' | 'ã' | 'â' | 'ô':
				return true;
		}

		return false;
	}
}
