package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 */
class FlxSoundTray extends Sprite
{
	/**
		The sound that'll play when you change volume.
	**/
	public static var volumeChangeSFX:String = null;

	/**
		The sound that'll play when you increase volume.
	**/
	public static var volumeUpChangeSFX:String = "assets/sound/volumeUpSound";

	/**
		The sound that'll play when you decrease volume.
	**/
	public static var volumeDownChangeSFX:String = "assets/sound/volumeDownSound";

	/**
		Whether or not changing the volume should make noise.
	**/
	public static var silent:Bool = false;

	/**
	 * "VOLUME" text.
	 */
	public var text:TextField = new TextField();

	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = 80;

	var _defaultScale:Float = 2.0;

	/**For the Bars Animation**/
	public var barTween:FlxTween;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		var tmp:Bitmap = new Bitmap(new BitmapData(_width, 30, true, 0x7F000000));
		screenCenter();
		addChild(tmp);

		text.width = tmp.width;
		text.height = tmp.height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;

		#if flash
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.NORMAL;
		text.gridFitType = GridFitType.PIXEL;
		#end

		var dtf:TextFormat = new TextFormat(Paths.font("FridayNightFunkin2.ttf"), 10, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = 'Volume';
		text.y = 16;

		var bx:Int = 10;
		var by:Int = 14;
		_bars = new Array();

		for (i in 0...10)
		{
			tmp = new Bitmap(new BitmapData(4, i + 1, false, FlxColor.WHITE));
			tmp.x = bx;
			tmp.y = by;
			addChild(tmp);
			_bars.push(tmp);
			bx += 6;
			by--;
		}

		y = -height;
		visible = false;
	}

	/**
	 * This function just updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
		// Animate stupid sound tray thing
		if (_timer > 0)
		{
			_timer -= MS / 1000;
		}
		else if (y > -height)
		{
			y -= (MS / 1000) * FlxG.height * 2;

			if (y <= -height)
			{
				visible = false;
				active = false;

				// Save sound preferences
				FlxG.save.data.mute = FlxG.sound.muted;
				FlxG.save.data.volume = FlxG.sound.volume;
				FlxG.save.flush();
			}
		}
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public function show(up:Bool = false):Void
	{
		if (!silent)
		{
			var sound = up ? volumeUpChangeSFX : volumeDownChangeSFX;
			if (sound == null)
				sound = volumeChangeSFX;
			FlxG.sound.load(sound).play();
		}

		_timer = 1;
		y = 0;
		visible = true;
		active = true;
		var globalVolume:Int = FlxG.sound.muted ? 0 : Math.round(FlxG.sound.volume * 10);

		text.text = Locale.get("volumeText");

		for (i in 0..._bars.length)
			_bars[i].alpha = (i < globalVolume) ? 1 : 0.5;

		var bar = _bars[globalVolume - 1];

		if (bar != null)
		{
			if (barTween != null)
				barTween.cancel();

			bar.scaleX = up ? 1.075 : 0.925;
			bar.scaleY = up ? 1.075 : 0.925;
			barTween = FlxTween.tween(bar, {"scaleX": 1, "scaleY": 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					barTween = null;
				}
			});
		}
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end
