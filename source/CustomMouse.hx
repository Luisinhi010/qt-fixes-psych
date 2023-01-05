package;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class CustomMouse extends FlxSprite
{
	// public var mousecursor:FlxSprite;
	public var mouseadded:Bool = false;
	public var defaultcolor:FlxColor = FlxColor.WHITE;
	public var pressedcolor:FlxColor = 0xFF1414AA;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		setupmousecustom();
	}

	public function setupmousecustom():Void
	{
		#if html5
		FlxG.mouse.visible = true;
		#else
		FlxG.mouse.visible = false;
		loadGraphic(Paths.image('Default/cursor'));
		updateHitbox();
		setGraphicSize(Std.int(width * 0.1));
		antialiasing = ClientPrefs.globalAntialiasing;
		mouseadded = true;
		offset.set(2, 2);
		#end
	}

	override function update(elapsed:Float)
	{
		#if !html5
		super.update(elapsed);
		updatemouse(elapsed);
		#end
	}

	function updatemouse(elapsed:Float):Void
	{
		#if !html5
		if (mouseadded && this != null)
		{
			setPosition(FlxG.mouse.x, FlxG.mouse.y);
			updateHitbox();
			antialiasing = ClientPrefs.globalAntialiasing;

			var pressed:Bool = FlxG.mouse.justPressed;
		}
		#end
	}

	public function setcolor(color:FlxColor = FlxColor.WHITE) // the mouse was suposed to have a color animation when left click,
	{
		#if !html5
		defaultcolor = color;
		this.color = color;
		#end
	}
}
