#if PRELOAD_ALL
package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.system.FlxSound;
#if windows
#end
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
#if cpp
import sys.FileSystem;
#end

using StringTools;

class Cache extends MusicBeatState
{
	var toBeDone = 0;
	var done = 0;
	var donefloat:Float = 0;

	var bar:FlxBar;

	public static var loaded:Bool = false;
	public static var tosettings:Bool = false;
	public static var cachedAssets:Array<String> = [];

	var images = [];
	var images1 = [];
	var images2 = [];
	var images3 = [];

	var cachefolders:Array<String> = [
		"assets/shared/images/characters",
		"assets/shared/images/hazard/qt-port",
		"assets/shared/images/hazard/qt-port/stage",
		"assets/shared/images/luis/qt-fixes"
	];

	var thevars = [];

	public static var coolsounds:Array<String> = [
		'missnote1', 'missnote2', 'missnote3', 'hazard/alert', 'hazard/alertDouble', 'hazard/alertTriple', 'hazard/alertQuadruple', 'hazard/attack',
		'hazard/attack-double', 'hazard/attack-triple', 'hazard/attack-quadruple',
	];

	public static var dialoguesounds:Array<String> = [
		'dialogue/dialogue',
		'dialogue/generic',
		'dialogue/qt',
		'dialogue/qt_error',
		'dialogue/kb',
		'dialogue/gf',
		'dialogue/bf',
		'dialogue/dialogueClose'
	];

	public static var songs:Array<String> = [
		'carefree',
		'careless',
		'censory-overload',
		'termination',
		'cessation',
		'interlope'
	];

	override function create()
	{
		if (!loaded)
		{
			Paths.clearStoredMemory();
			FlxG.autoPause = false;
			thevars = [images, images1, images2, images3];

			FlxG.worldBounds.set(0, 0);
			FlxG.mouse.visible = false;

			var menuBG:FlxSprite;
			if (FlxG.random.bool(60))
			{
				menuBG = new FlxSprite();
				menuBG.frames = Paths.getSparrowAtlas('Loading-Anim');
				menuBG.animation.addByPrefix('idle', 'Loading', 24, true);
				menuBG.animation.play('idle', true, FlxG.random.bool(10));
			}
			else
				menuBG = new FlxSprite().loadGraphic(Paths.image('modbanner'));

			menuBG.screenCenter();
			add(menuBG);

			#if cpp
			for (o in 0...thevars.length)
			{
				for (i in FileSystem.readDirectory(FileSystem.absolutePath(cachefolders[o])))
				{
					if (!i.endsWith(".png"))
						continue;
					thevars[o].push(i);
				}
				toBeDone += Lambda.count(thevars[o]); // now i'm doing the right way
			}
			#end

			for (i in 0...cachefolders.length)
				cachefolders[i] += '/';

			for (o in 0...thevars.length)
				for (i in thevars[o])
				{
					var replaced:String = cachefolders[o].replace('assets/shared/images/', '')
						+ i.replace("/qt-port", "/qt-port/")
							.replace("/stage", "/stage/")
							.replace("/qt-fixes", "/qt-fixes/")
							.replace(".png", "");
					CoolUtil.precacheImage(replaced);
					Paths.excludeAsset(replaced); // just to be sure you know?//that's dumb
				}

			bar = new FlxBar(10, FlxG.height - 50, FlxBarFillDirection.HORIZONTAL_INSIDE_OUT, FlxG.width - 20, 40, this, 'donefloat', 0, toBeDone);
			bar.createFilledBar(FlxColor.BLACK, FlxColor.PURPLE, true);
			bar.numDivisions = 800;
			add(bar);
			var text:FlxText = new FlxText(0, bar.y + 2, 0, "Loading...", 34);
			text.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.screenCenter(X);
			add(text);

			if (ClientPrefs.gpurendering)
			{
				var text:FlxText = new FlxText(1, 1, 0, 'GPU Rendering is enabled', 24);
				text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(text);
				var gputext:FlxText = new FlxText(1, text.y + text.height - 2, 0, 'be aware that it is VERY experimental!', 24);
				gputext.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(gputext);
				Main.fpsVar.y += gputext.y + gputext.height - 2;
			}

			Paths.clearUnusedMemory();
			// cache thread
			sys.thread.Thread.create(() ->
			{
				cache();
			});
		}
		else
			fu(false); // update to work with the new interlope "crash"

		super.create();
	}

	override function update(elapsed)
	{
		super.update(elapsed);
	}

	function cache()
	{
		preCacheThesounds('all');
		#if !linux
		for (o in 0...thevars.length)
		{
			for (i in thevars[o])
			{
				var key:String = i;
				var replaced:String = key.replace(".png", "");
				var data:BitmapData = BitmapData.fromFile(cachefolders[o] + key);
				var graph:FlxGraphic;
				if (ClientPrefs.gpurendering)
				{
					data.lock();
					var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(data.width, data.height, BGRA, true);
					texture.uploadFromBitmapData(data);
					Paths.currentTrackedTextures.set(key, texture);
					data.dispose();
					data.disposeImage();
					data = null;
					graph = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				}
				else
					graph = FlxGraphic.fromBitmapData(data, false, key, false);
				graph.persist = true;
				graph.destroyOnNoUse = false;

				cachedAssets.push(key);
				Paths.currentTrackedAssets.set(key, graph);
				done++;
				createtxt(replaced + ' cached' /*+ " " + ClientPrefs.gpurendering*/);
			}
		}

		trace("Finished caching...");

		loaded = true;
		#end
		FlxG.autoPause = ClientPrefs.autoPause;
		fu(true);
	}

	public static function preCacheThesounds(duh:String = 'all')
	{
		if (duh == 'all' || duh == 'dialogue')
			for (i in 0...dialoguesounds.length)
				CoolUtil.precacheSound(dialoguesounds[i]);
		if (duh == 'all' || duh == 'game')
			for (i in 0...coolsounds.length)
				CoolUtil.precacheSound(coolsounds[i]);
		if (duh == 'all' || duh == 'inst' || duh == 'songs')
			for (i in 0...songs.length)
				CoolUtil.precacheInst(songs[i]);
		if (duh == 'all' || duh == 'vocals' || duh == 'songs')
			for (i in 0...songs.length)
				CoolUtil.precacheVoices(songs[i]);

		trace('Pre cached sounds: ' + duh);
	}

	function createtxt(text:String)
	{
		FlxTween.tween(this, {donefloat: done}, 0.1, {ease: FlxEase.cubeOut});
		trace(text);
		/*var txt:FlxText = new FlxText(FlxG.random.int(18, 25), FlxG.height - FlxG.random.int(56, 65), 400, text, 32);
			txt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(txt);
			FlxTween.tween(txt, {y: txt.y - FlxG.random.int(36, 46), x: txt.y + FlxG.random.int(-26, 36), alpha: 0}, FlxG.random.float(1.6, 3), {
				ease: FlxEase.circOut,
				onComplete: function(twn:FlxTween)
				{
					txt.kill();
				}
		});*/
	}

	function fu /*ck*/ (trans:Bool = true)
	{
		if (!tosettings)
			if (trans)
				MusicBeatState.justswitchState(new TitleState());
			else
				MusicBeatState.switchState(new TitleState());
		else
			LoadingState.loadAndSwitchState(new options.OptionsState(), false, trans);

		tosettings = false;
	}
}
#end
