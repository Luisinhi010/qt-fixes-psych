package options;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Locale.get("graphicsOption");
		rpcTitle = 'Graphics Settings Menu'; // for Discord Rich Presence

		// I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option(Locale.get("lowQualityGraphicsText"), // Name
			Locale.get("lowQualityGraphicsDesc"), // Description
			'lowQuality', // Save data variable name
			'bool', // Variable type
			false); // Default value
		option.onChange = function()
		{
			if (!ClientPrefs.lowQuality)
				ClientPrefs.optimize = false;
		};
		addOption(option);

		var option:Option = new Option(Locale.get("optimizeGraphicsText"), Locale.get("optimizeGraphicsDesc"), 'optimize', 'bool', false);
		option.onChange = function()
		{
			if (ClientPrefs.optimize)
			{
				ClientPrefs.lowQuality = true;
				ClientPrefs.antialiasing = false;
				onChangeAntiAliasing();
				ClientPrefs.persistentCaching = false;
			}
		};
		addOption(option);

		var option:Option = new Option(Locale.get("shadersGraphicsText"), Locale.get("shadersGraphicsDesc"), 'shaders', 'bool', true);
		option.showBoyfriend = true;
		option.showfuckingchaders = true;
		option.onChange = function() censoryCustomChroma.shader.enabled.value = [ClientPrefs.shaders];
		addOption(option);

		var option:Option = new Option(Locale.get("charactershadersGraphicsText"), Locale.get("charactershadersGraphicsDesc"), 'charactershaders', 'bool',
			true);
		option.showBoyfriend = true;
		option.showBfsshaders = true;
		option.onChange = function() boyfriend.blueshader.shader.enabled.value = [ClientPrefs.charactershaders];
		addOption(option);

		var option:Option = new Option(Locale.get("antialiasingGraphicsText"), Locale.get("antialiasingGraphicsDesc"), 'antialiasing', 'bool', true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing;
		addOption(option);

		var option:Option = new Option(Locale.get("persistentCachingGraphicsText"), Locale.get("persistentCachingGraphicsDesc"), 'persistentCaching', 'bool',
			false);
		addOption(option);

		#if desktop
		/*#if !debug
			{
				var option:Option = new Option('Locale.get("precacheGraphicsText"),
					Locale.get("precacheGraphicsDesc"),
					'precache',
					'bool',
					false);
				option.onChange = onChangeCache;
				addOption(option);
			}
			#end */

		var option:Option = new Option(Locale.get("gpurenderingGraphicsText"), Locale.get("gpurenderingGraphicsDesc"), 'gpurendering', 'bool', false);
		addOption(option);
		#end

		#if !html5 // Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option(Locale.get("framerateGraphicsText"), Locale.get("framerateGraphicsDesc"), 'framerate', 'int', 60);
		addOption(option);

		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		#if desktop // no need for this at other platforms cuz only desktop has fullscreen as false by default
		var option:Option = new Option(Locale.get("screenResGraphicsText"), Locale.get("screenResGraphicsDesc"), 'screenRes', 'string', '1280x720', [
			'640x360', '852x480', '960x540', '1280x720', '1680x720', '2560x720', '1920x1080', '2560x1080', '3840x1080', '3840x2160'
		]); // https://calculateaspectratio.com/ chad
		addOption(option);
		option.onChange = onChangeScreenRes;

		var option:Option = new Option(Locale.get("fullscreenGraphicsText"), Locale.get("fullscreenGraphicsDesc"), 'fullscreen', 'bool', false);
		addOption(option);
		option.onChange = function() FlxG.fullscreen = ClientPrefs.fullscreen;
		#end

		super();
	}

	function onChangeAntiAliasing()
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; // Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; // Don't judge me ok
			if (sprite != null && (sprite is FlxSprite) && !((sprite is FlxText) || (sprite is FlxText)))
				sprite.antialiasing = ClientPrefs.antialiasing;
		}

	#if PRELOAD_ALL
	function onChangeCache()
		if (!CachingState.loaded)
		{
			if (!ClientPrefs.persistentCaching)
				Paths.clearUnusedMemory();
			CachingState.tosettings = true;
			MusicBeatState.switchState(new CachingState());
		}
	#end

	function onChangeFramerate()
	{
		if (ClientPrefs.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.framerate;
			FlxG.drawFramerate = ClientPrefs.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.framerate;
			FlxG.updateFramerate = ClientPrefs.framerate;
		}
	}

	#if desktop
	function onChangeScreenRes()
	{
		FlxG.fullscreen = ClientPrefs.fullscreen;
		MusicBeatState.updatewindowres();
	}
	#end
}
