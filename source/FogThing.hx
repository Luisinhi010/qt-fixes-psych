package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class FogThing extends FlxSprite
{
	public var isUpperLayer:Bool = false;
	public var movementSpeed:Int = 2;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		regenerate();
	}

	public function regenerate():Void
	{
		loadGraphic(Paths.imageRandom("hazard/inhuman-port/fogEffectTEST", 1, 3)); // they are test or what? sorry for asking.
		flipX = FlxG.random.bool(50);

		setGraphicSize(Std.int(width * 2));
		scrollFactor.set(0.1, 0.1);
		antialiasing = ClientPrefs.globalAntialiasing;
		movementSpeed = FlxG.random.int(1, 5);
	}
}
