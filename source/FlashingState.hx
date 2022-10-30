package; // reused this state to precache warning LMFAO

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;
	#if sys
	public static var leftstateprecache:Bool = false;
	public static var precachewarning:Bool = false;
	#end

	var warnText:FlxText;
	var transGradient:FlxSprite;

	var zoom:Float = 0.0;
	var width:Int = 0;
	var height:Int = 0;
	var text:String = '';

	override function create()
	{
		super.create();

		zoom = CoolUtil.boundTo(FlxG.camera.zoom, 0.05, 1);
		width = Std.int(FlxG.width / zoom);
		height = Std.int(FlxG.height / zoom);

		var bg:FlxSprite = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		add(bg);

		#if sys
		if (!precachewarning)
		{
		#end
			transGradient = FlxGradient.createGradientFlxSprite(width, height, [0x0, FlxColor.WHITE], 1);
			transGradient.scrollFactor.set();
			transGradient.x -= (width - FlxG.width) / 2;
			transGradient.y = (height - transGradient.height) + 100;
			add(transGradient);
			text = "Hey, watch out!\n
			This Mod contains some minor flashing lights!\n
			Press ESCAPE to disable them now or go to Options Menu.\n
			Press ENTER to ignore this message.\n
			Yo've been warned!";
		#if sys
		}
		else
		{
			var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('modbanner'));
			menuBG.screenCenter();
			add(menuBG);
			text = "Hey\n
			Do you want to Enable the Caching?\n
			Press ESCAPE to not enable Caching\n
			Press Enter to enable it.\n";
		}
		#end

		warnText = new FlxText(0, 0, #if sys precachewarning ? 0 : #end FlxG.width, text, 32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warnText.borderSize = 2;
		warnText.screenCenter();
		#if sys
		if (precachewarning)
		{
			var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(warnText.width) + 10, Std.int(warnText.height) + 10, FlxColor.BLACK);
			bg.screenCenter();
			bg.y -= 18;
			bg.alpha = 0.5;
			add(bg);
		}
		#end
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		if ((#if sys !precachewarning && #end!leftState) #if sys || (precachewarning && !leftstateprecache) #end)
		{
			var back:Bool = controls.BACK;
			if (controls.ACCEPT || back)
			{
				#if sys
				if (!precachewarning)
				{
				#end
					leftState = true;
					FlxTween.tween(transGradient, {alpha: 0}, 1);
				#if sys
				}
				else
					leftstateprecache = true;
				#end
				if (!back)
					accept();
				else
					cancel();
			}
		}
		super.update(elapsed);
	}

	function accept()
	{
		#if sys
		if (!precachewarning)
		#end
		ClientPrefs.flashing = true;
		#if sys
		else
		{
			ClientPrefs.precache = true;
			FlxG.save.data.precache = true;
		}
		#end
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('confirmMenu'));
		FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker)
		{
			new FlxTimer().start(0.5, function(tmr:FlxTimer)
			{
				fu();
			});
		});
	}

	function cancel()
	{
		#if sys
		if (!precachewarning)
		#end
		ClientPrefs.flashing = false;
		#if sys
		else
		{
			ClientPrefs.precache = false;
			FlxG.save.data.precache = false;
		}
		#end
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		FlxTween.tween(warnText, {alpha: 0}, 1, {
			onComplete: function(twn:FlxTween)
			{
				fu();
			}
		});
	}

	function fu()
	{
		#if sys
		if (!precachewarning)
		#end
		MusicBeatState.switchState(new TitleState());
		#if sys
		else
			MusicBeatState.switchState(new Cache());
		#end
	}
}
