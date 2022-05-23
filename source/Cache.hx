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

	override function create()
	{
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
		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/characters")))
		{
			if (!i.endsWith(".png"))
				continue;
			images.push(i);
		}
		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/hazard/qt-port")))
		{
			if (!i.endsWith(".png"))
				continue;
			images1.push(i);
		}
		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/hazard/qt-port/stage")))
		{
			if (!i.endsWith(".png"))
				continue;
			images2.push(i);
		}
		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/luis/qt-fixes")))
		{
			if (!i.endsWith(".png"))
				continue;
			images3.push(i);
		}
		#end

		toBeDone = Lambda.count(images) + Lambda.count(images1) + Lambda.count(images2) + Lambda.count(images3);

		bar = new FlxBar(10, FlxG.height - 50, FlxBarFillDirection.LEFT_TO_RIGHT, FlxG.width - 20, 40, this, 'donefloat', 0, toBeDone);
		bar.createFilledBar(FlxColor.BLACK, FlxColor.PURPLE, true);
		bar.numDivisions = 800;
		add(bar);
		text = new FlxText(0, bar.y + 2, 0, "Loading...", 34);
		text.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.screenCenter(X);
		text.x -= 90;
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
		playsound('termination', 'inst');
		playsound('termination', 'voice');
		playsound('termination', 'voice-classic');
		playsound('termination', 'inst-old');
		playsound('termination', 'voice-old');
		playsound('censory-overload', 'inst');
		playsound('censory-overload', 'voice');
		playsound('censory-overload', 'voice-classic');
		playsound('careless', 'inst');
		playsound('careless', 'voice');
		playsound('careless', 'voice-classic'); // this is fucking lame -Luis
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
		for (i in images)
		{
			var replaced = i.replace(".png", "");
			var data:BitmapData = BitmapData.fromFile("assets/shared/images/characters/" + i);
			var graph = FlxGraphic.fromBitmapData(data);
			graph.persist = true;
			graph.destroyOnNoUse = false;
			bitmapData.set(replaced, graph);
			done++;
			createtxt(i + ' loaded part 1');
		}
		for (i in images1)
		{
			var replaced = i.replace(".png", "");
			var data:BitmapData = BitmapData.fromFile("assets/shared/images/hazard/qt-port/" + i);
			var graph = FlxGraphic.fromBitmapData(data);
			graph.persist = true;
			graph.destroyOnNoUse = false;
			bitmapData2.set(replaced, graph);
			done++;
			createtxt(i + ' loaded part 2');
		}
		for (i in images2)
		{
			var replaced = i.replace(".png", "");
			var data:BitmapData = BitmapData.fromFile("assets/shared/images/hazard/qt-port/stage/" + i);
			var graph = FlxGraphic.fromBitmapData(data);
			graph.persist = true;
			graph.destroyOnNoUse = false;
			bitmapData3.set(replaced, graph);
			done++;
			createtxt(i + ' loaded part 3');
		}
		for (i in images3)
		{
			var replaced = i.replace(".png", "");
			var data:BitmapData = BitmapData.fromFile("assets/shared/images/luis/qt-fixes/" + i);
			var graph = FlxGraphic.fromBitmapData(data);
			graph.persist = true;
			graph.destroyOnNoUse = false;
			bitmapData3.set(replaced, graph);
			done++;
			createtxt(i + ' loaded part 4');
		} // 4 parts

		trace("Finished caching...");
		// text.text = "Loading... (" + done + "/" + toBeDone + ")";

		loaded = true;
		#end
		// FlxG.switchState(new TitleState());
		MusicBeatState.switchState(new TitleState());
	}

	function createtxt(text:String)
	{
		FlxTween.tween(this, {donefloat: done}, 0.1, {ease: FlxEase.cubeOut});
		trace(text);
		var txt:FlxText = new FlxText(20, FlxG.height - 60, 400, text, 32);
		txt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(txt);
		FlxTween.tween(txt, {y: txt.y - 40, alpha: 0}, 2, {
			ease: FlxEase.circOut,
			onComplete: function(twn:FlxTween)
			{
				txt.kill();
			}
		});
	}

	/*public static*/
	function playsound(song:String, whattype:String) // :Void
	{
		var sound:FlxSound;
		switch (whattype.toLowerCase())
		{
			case 'inst':
				sound = new FlxSound().loadEmbedded(Paths.inst(song));
			case 'inst-old':
				sound = new FlxSound().loadEmbedded(Paths.instOLD(song));
			case 'voice':
				sound = new FlxSound().loadEmbedded(Paths.voices(song));
			case 'voice-classic':
				sound = new FlxSound().loadEmbedded(Paths.voicesCLASSIC(song));
			case 'voice-old':
				sound = new FlxSound().loadEmbedded(Paths.voicesOLD(song));
			default:
				sound = new FlxSound().loadEmbedded(Paths.music(song));
		}
		sound.play();
		sound.volume = 0.00001;
		FlxG.sound.list.add(sound);
	}
}
#end
