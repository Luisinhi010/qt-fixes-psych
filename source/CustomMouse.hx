package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class CustomMouse extends FlxSprite
{
	// public var mousecursor:FlxSprite;
	public var mouseadded:Bool = false;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		setupmousecustom();
	}

	public function setupmousecustom():Void
	{
		#if web
		FlxG.mouse.visible = true;
		#else
		FlxG.mouse.visible = false;
		loadGraphic(Paths.image('Default/cursor'));
		updateHitbox();
		setGraphicSize(Std.int(width * 0.1));
		antialiasing = ClientPrefs.globalAntialiasing;
		mouseadded = true;
		offset.set(1, 1);
		trace('good. ' + mouseadded);
		trace(this);
		#end
	}

	public function updatemouse():Void
	{
		#if !web
		if (mouseadded && this != null)
		{
			setPosition(FlxG.mouse.x, FlxG.mouse.y);
			updateHitbox();
			antialiasing = ClientPrefs.globalAntialiasing;
		}
		#end
	}
}
