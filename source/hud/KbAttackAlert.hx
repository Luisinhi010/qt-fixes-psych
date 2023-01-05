package hud;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxBasic;
import flixel.graphics.frames.FlxFrame;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import lime.app.Application;

using StringTools;

class KbAttackAlert extends FlxTypedGroup<FlxBasic>
{
	public var alert:FlxSprite;
	public var tipTxt:FlxText;
	public var newalert:Bool = false;
	public var lastPlayedAnim:String; // may be usefull
	public var multiplier:Float = 1;

	var alertAdded:Bool = false;

	public var alpha(default, set):Float = 1;

	function set_alpha(value:Float):Float
	{
		alpha = value;
		if (alertAdded)
		{
			if (newalert && alert != null && alert.visible)
				alert.alpha = alpha;
			if (tipTxt != null && tipTxt.visible)
				tipTxt.alpha = alpha;
		}

		return alpha;
	}

	public var x(default, set):Float = 0;

	function set_x(value:Float):Float
	{
		x = value;
		if (alertAdded)
		{
			alert.y = value + pos[0];
			tipTxt.y = value + pos[2];
		}

		return x;
	}

	public var y(default, set):Float = 0;

	function set_y(value:Float):Float
	{
		y = value;
		if (alertAdded)
		{
			alert.y = value + pos[1];
			tipTxt.y = value + pos[3];
		}

		return y;
	}

	private var pos:Array<Float> = [];

	public function new()
	{
		super();
		create();
	}

	public function create():Void
	{
		// Alert!
		if (!alertAdded)
		{
			alert = new FlxSprite();
			alert.frames = Paths.getSparrowAtlas('hazard/qt-port/attack_alert_NEW', 'shared', ClientPrefs.gpurendering);
			alert.antialiasing = ClientPrefs.globalAntialiasing;
			alert.setGraphicSize(Std.int(alert.width * 1.5));

			var animFrames:Array<FlxFrame> = [];
			@:privateAccess {
				alert.animation.findByPrefix(animFrames, "Alert-Single");
				alert.animation.findByPrefix(animFrames, "Alert-Double");
				alert.animation.findByPrefix(animFrames, "Alert-Triple");
				alert.animation.findByPrefix(animFrames, "Alert-Quad");
			}

			trace(animFrames.length);

			if (animFrames.length > 0)
			{
				newalert = true;

				alert.animation.addByPrefix('alert', 'Alert-Single', 0);
				alert.animation.addByPrefix('alertDOUBLE', 'Alert-Double', 0);
				alert.animation.addByPrefix('alertTRIPLE', 'Alert-Triple', 0);
				alert.animation.addByPrefix('alertQUAD', 'Alert-Quad', 0);
			}
			else
			{
				newalert = false;

				alert.animation.addByPrefix('alert', 'kb_attack_animation_alert-single', 24, false);
				alert.animation.addByPrefix('alertDOUBLE', 'kb_attack_animation_alert-double', 24, false);
				alert.animation.addByPrefix('alertTRIPLE', 'kb_attack_animation_alert-triple', 24, false);
				alert.animation.addByPrefix('alertQUAD', 'kb_attack_animation_alert-quad', 24, false);
			}
			trace("newalert " + newalert);

			alert.screenCenter(X);
			alert.x += alert.width / 4; // wtf? haz?
			if (PlayState.instance.forceMiddleScroll || !ClientPrefs.opponentStrums)
				alert.x -= alert.width / (PlayState.instance.forceMiddleScroll ? 2 : 3);
			alert.y = 205 + (ClientPrefs.downScroll ? 20 : 0);
			alert.visible = false;
			add(alert);

			var dodgeKey:String = ClientPrefs.getkeys('qt_dodge');
			tipTxt = new FlxText(0, ClientPrefs.downScroll ? alert.y - 66 : alert.y + alert.height + 36, 0, "Press $" + dodgeKey + "$ to dodge!", 25);
			tipTxt.applyMarkup("Press $" + dodgeKey + "$ to dodge!", [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED), "$")]);
			tipTxt.setFormat(Paths.font("vcr.ttf"), 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			tipTxt.antialiasing = ClientPrefs.globalAntialiasing;
			tipTxt.borderSize = 1.1;
			tipTxt.screenCenter(X);
			if (PlayState.instance.forceMiddleScroll || !ClientPrefs.opponentStrums)
				tipTxt.x -= tipTxt.width / (PlayState.instance.forceMiddleScroll ? 2 : 3);
			tipTxt.visible = false;
			add(tipTxt);

			for (i in [alert.x, alert.y, tipTxt.x, tipTxt.y])
				pos.push(i);
			trace(pos);

			alertAdded = true;
			multiplier = MusicBeatState.multAnims ? PlayState.instance.playbackRate : 1;
		}
	}

	public function playAnim(Anim:String)
	{
		if (alertAdded)
		{
			alert.visible = true;
			tipTxt.visible = true;
			lastPlayedAnim = Anim;
			alert.animation.play(Anim, true);
			switch (Anim)
			{
				default:
					alert.offset.set(0, 0);
				case "alertQUAD":
					alert.offset.set(152, 38);
				case "alertTRIPLE":
					alert.offset.set(150, 56);
				case "alertDOUBLE":
					alert.offset.set(70, 5);
			}
			alpha = 1;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (alpha > 0)
			alpha -= 3.2 * multiplier * elapsed;
	}
}
