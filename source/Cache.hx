#if sys
package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.system.FlxSound;
#if windows
#end
import openfl.display.BitmapData;
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

	var loaded = false;
	var text:FlxText;

	public static var bitmapData:Map<String, FlxGraphic>;
	public static var bitmapData2:Map<String, FlxGraphic>;
	public static var bitmapData3:Map<String, FlxGraphic>;

	var images = [];
	var images1 = [];
	var images2 = [];
	var images3 = [];

	var cachefolders:Array<String> = [];

	var thevars = [];

	override function create()
	{
		cachefolders = [
			"assets/shared/images/characters",
			"assets/shared/images/hazard/qt-port",
			"assets/shared/images/hazard/qt-port/stage",
			"assets/shared/images/luis/qt-fixes"
		];
		thevars = [images, images1, images2, images3];
		FlxG.worldBounds.set(0, 0);
		FlxG.mouse.visible = false;

		bitmapData = new Map<String, FlxGraphic>();
		bitmapData2 = new Map<String, FlxGraphic>();
		bitmapData3 = new Map<String, FlxGraphic>();

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

		bar = new FlxBar(10, FlxG.height - 50, FlxBarFillDirection.HORIZONTAL_INSIDE_OUT, FlxG.width - 20, 40, this, 'donefloat', 0, toBeDone);
		bar.createFilledBar(FlxColor.BLACK, FlxColor.PURPLE, true);
		bar.numDivisions = 800;
		add(bar);
		text = new FlxText(0, bar.y + 2, 0, "Loading...", 34);
		text.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.screenCenter(X);
		add(text);

		// cache thread
		sys.thread.Thread.create(() ->
		{
			cache();
		});

		super.create();
	}

	override function update(elapsed)
	{
		super.update(elapsed);
	}

	function cache()
	{
		#if !linux
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');
		CoolUtil.precacheSound('hazard/alert');
		CoolUtil.precacheSound('hazard/alertDouble');
		CoolUtil.precacheSound('hazard/alertTriple');
		CoolUtil.precacheSound('hazard/alertQuadruple');
		CoolUtil.precacheSound('hazard/attack');
		CoolUtil.precacheSound('hazard/attack-double');
		CoolUtil.precacheSound('hazard/attack-triple');
		CoolUtil.precacheSound('hazard/attack-quadruple');
		for (o in 0...thevars.length)
		{
			for (i in thevars[o])
			{
				var replaced = i.replace(".png", "");
				var data:BitmapData = BitmapData.fromFile(cachefolders[o] + i);
				var graph = FlxGraphic.fromBitmapData(data);
				graph.persist = true;
				graph.destroyOnNoUse = false;
				bitmapData.set(replaced, graph);
				done++;
				createtxt(i + ' cached');
			}
		}

		trace("Finished caching...");

		loaded = true;
		#end
		// FlxG.switchState(new TitleState());
		MusicBeatState.switchState(new TitleState());
	}

	function createtxt(text:String)
	{
		FlxTween.tween(this, {donefloat: done}, 0.1, {ease: FlxEase.cubeOut});
		trace(text);
		var txt:FlxText = new FlxText(FlxG.random.int(18, 25), FlxG.height - FlxG.random.int(56, 65), 400, text, 32);
		txt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(txt);
		FlxTween.tween(txt, {y: txt.y - FlxG.random.int(36, 46), x: txt.y + FlxG.random.int(-26, 36), alpha: 0}, FlxG.random.float(1.6, 3), {
			ease: FlxEase.circOut,
			onComplete: function(twn:FlxTween)
			{
				txt.kill();
			}
		});
	}
}
#end
