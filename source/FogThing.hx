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
		switch (FlxG.random.int(1, 3))
		{
			case 2:
				loadGraphic(Paths.image("hazard/inhuman-port/fogEffectTEST2"));
			case 3:
				loadGraphic(Paths.image("hazard/inhuman-port/fogEffectTEST3"));
			default:
				loadGraphic(Paths.image("hazard/inhuman-port/fogEffectTEST1")); // they are test or what? sorry for asking.
		}
		if (FlxG.random.bool(50))
		{
			this.flipX = true;
		}
		setGraphicSize(Std.int(this.width * 2));
		scrollFactor.set(0.1, 0.1);
		antialiasing = ClientPrefs.globalAntialiasing;
		movementSpeed = FlxG.random.int(1, 5);
	}
}
