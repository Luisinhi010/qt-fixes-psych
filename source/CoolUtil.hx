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
#if cpp import sys.FileSystem; #else import js.html.FileSystem; #end
#else
import openfl.utils.Assets;
#end

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Hard', 'Harder'];
	public static var defaultDifficulty:String = 'Normal'; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	inline public static function quantize(f:Float, snap:Float)
	{
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	public static function getDifficultyFilePath(num:Null<Int> = null)
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
			if (PlayState.SONG.song.toLowerCase() == "termination")
			{
				if (PlayState.storyDifficulty == 2)
					dumbShit = "CLASSIC";
				else
					dumbShit = "VERY HARD";
			}
			else if (PlayState.SONG.song.toLowerCase() == "cessation")
				dumbShit = "FUTURE";
			else if (PlayState.SONG.song.toLowerCase() == "interlope")
				dumbShit = "???";
		}
		return dumbShit;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

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

	public static inline function exactSetGraphicSize(obj:Dynamic, width:Float, height:Float)
		obj.scale.set(Math.abs(((obj.width - width) / obj.width) - 1), Math.abs(((obj.height - height) / obj.height) - 1));

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
		return switch (str)
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
		return switch (str)
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
}
