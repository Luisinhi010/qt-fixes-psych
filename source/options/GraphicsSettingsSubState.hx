package options;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; // for Discord Rich Presence

		// I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', // Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', // Description
			'lowQuality', // Save data variable name
			'bool', // Variable type
			false); // Default value
		option.onChange = function()
		{
			if (!ClientPrefs.lowQuality)
				ClientPrefs.optimize = false;
		};
		addOption(option);

		var option:Option = new Option('Optimize',
			"If checked, Removes almost everything from the stage, \nBoosting FPS For Low-End PCS \nit uses stage's color when possible", 'optimize', 'bool',
			false);
		option.onChange = function()
		{
			if (ClientPrefs.optimize)
			{
				ClientPrefs.lowQuality = true;
				ClientPrefs.globalAntialiasing = false;
				onChangeAntiAliasing();
				ClientPrefs.persistentCaching = false;
			}
		};
		addOption(option);

		var option:Option = new Option('Shaders', // Name
			'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU/GPU intensive for weaker PCs.', 'shaders', 'bool', true);
		option.showBoyfriend = true;
		option.showfuckingchaders = true;
		option.onChange = function() censoryCustomChroma.shader.enabled.value = [ClientPrefs.shaders];
		addOption(option);

		var option:Option = new Option('Characters Shaders', 'Same as above, but for the characters', 'charactershaders', 'bool', true);
		option.showBoyfriend = true;
		option.showBfsshaders = true;
		option.onChange = function() boyfriend.blueshader.shader.enabled.value = [ClientPrefs.charactershaders];
		addOption(option);

		var option:Option = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing', 'bool', true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; // Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Persistent Caching',
			'If checked, graphics will continue to be cached in memory after they are loaded, making reload times basically instant.\nWARNING: This uses a lot of memory!',
			'persistentCaching', 'bool', false);
		addOption(option);

		#if desktop
		/*#if !debug
			{
				var option:Option = new Option('Image Chaching', // Name
					'If checked, the game will Pre-Cache images.', // Description
					'precache', // Save data variable name
					'bool', // Variable type
					false); // Default value
				option.onChange = onChangeCache; // Changing onChange is only needed if you want to make a special interaction after it changes the value
				addOption(option);
			}
			#end */

		var option:Option = new Option('GPU Rendering', // Name //taken from Forever engine Underscore: https://github.com/BeastlyGhost/Forever-Engine-Underscore //i recommend testing it out, its a awesome engine made by a awesome progammer.
			'If checked the game will use your GPU to render images. [EXPERIMENTAL, takes effect after restart]', // Description
			'gpurendering', // Save data variable name
			'bool', // Variable type
			false); // Default value
		addOption(option);
		#end

		#if !html5 // Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate', "Pretty self explanatory, isn't it?", 'framerate', 'int', 60);
		addOption(option);

		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		#if desktop // no need for this at other platforms cuz only desktop has fullscreen as false by default
		var option:Option = new Option('Screen Resolution', 'Choose your preferred screen resolution.', 'screenRes', 'string', '1280x720', [
			'640x360', '852x480', '960x540', '1280x720', '1680x720', '2560x720', '1920x1080', '2560x1080', '3840x1080', '3840x2160'
		]); // https://calculateaspectratio.com/ chad
		addOption(option);
		option.onChange = onChangeScreenRes;

		var option:Option = new Option('Fullscreen', 'Should the game be maximized?', 'fullscreen', 'bool', false);
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
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
		}

	#if PRELOAD_ALL
	function onChangeCache()
		if (!Cache.loaded)
		{
			if (!ClientPrefs.persistentCaching)
				Paths.clearUnusedMemory();
			Cache.tosettings = true;
			MusicBeatState.switchState(new Cache());
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
