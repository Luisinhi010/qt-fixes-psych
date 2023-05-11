package;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class CustomMouse extends FlxSprite
{
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
		FlxG.mouse.visible = false;
		loadGraphic(Paths.image('Default/cursorOG'));
		updateHitbox();
		setGraphicSize(Std.int(width * 0.1));
		antialiasing = ClientPrefs.globalAntialiasing;
		mouseadded = true;
		offset.set(2, 2);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updatemouse(elapsed);
	}

	function updatemouse(elapsed:Float):Void
	{
		if (mouseadded && this != null)
		{
			setPosition(FlxG.mouse.screenX, FlxG.mouse.screenY);
			updateHitbox();
			antialiasing = ClientPrefs.globalAntialiasing;
		}
	}

	public function setcolor(color:FlxColor = FlxColor.WHITE) // the mouse was suposed to have a color animation when left click,
	{
		defaultcolor = color;
		this.color = color;
	}
}
