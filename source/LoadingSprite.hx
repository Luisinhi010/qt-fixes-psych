package;

import sys.FileSystem;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import openfl.Assets;

using StringTools;

class LoadingSprite extends FlxSprite
{
	public var coolColor:FlxColor = FlxColor.PURPLE;

	var name:String;
	var texts:Array<String> = [];

	var updateSize:Bool = true;

	public function new()
	{
		super();
		if (PlayState.SONG != null && PlayState.SONG.song != null)
			name = PlayState.SONG.song.replace(" ", "-").toLowerCase();
		if (FlxG.random.bool(70))
			switch (name)
			{
				case 'carefree' | 'careless' | 'censory-overload' | 'termination':
					loadGraphic(Paths.image('Loading/$name'));
				case 'interlope':
					loadGraphic(Paths.imageRandom('Loading/interlope', 0, 1));
				default:
					defaultsprite();
			}
		else
			defaultsprite();

		antialiasing = ClientPrefs.globalAntialiasing;
		if (this != null)
			coolColor = FlxColor.fromInt(CoolUtil.dominantColor(this));
		if (updateSize)
			setGraphicSize(FlxG.width, FlxG.height);
		updateHitbox();
		screenCenter();
		moves = false;
		active = false;
	}

	function defaultsprite()
	{
		if (FlxG.random.bool(60))
		{
			frames = Paths.getSparrowAtlas('Loading/anim');
			animation.addByPrefix('idle', 'Loading', 24, true);
			animation.play('idle', true, FlxG.random.bool(10));
		}
		else
			loadGraphic(Paths.image('Loading/loading'));
	}
}
