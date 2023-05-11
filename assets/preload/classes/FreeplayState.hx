import CoolUtil;

public var qt_gas:FlxSprite;

function create()
{
	FreeplayState.bgPath = 'menuFreePlay';
	FreeplayState.scorecolorDifficulty.set('CLASSIC', CoolUtil.returnColor('red'));
	FreeplayState.scorecolorDifficulty.set('VERY HARD', CoolUtil.returnColor('red'));
	FreeplayState.scorecolorDifficulty.set('FUTURE', CoolUtil.returnColor('cyan'));
	FreeplayState.scorecolorDifficulty.set('', CoolUtil.returnColor('transparent'));
	FreeplayState.scorecolorDifficulty.set('???', CoolUtil.returnColor('red'));
}

function postCreate()
{
	if (!ClientPrefs.lowQuality)
	{
		qt_gas = new FlxSprite();
		qt_gas.frames = Paths.getSparrowAtlas('hazard/qt-port/stage/Gas_Release', 'shared'); // for some reason this is returning null?
		qt_gas.animation.addByPrefix('burst', 'Gas_Release', 38, false);
		qt_gas.animation.addByPrefix('burstALT', 'Gas_Release', 49, false);
		qt_gas.animation.addByPrefix('burstFAST', 'Gas_Release', 76, false);
		qt_gas.animation.addByIndices('burstLoop', 'Gas_Release', [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23], "", 38, true);
		qt_gas.setGraphicSize(Std.int(qt_gas.width * 1.8));
		qt_gas.antialiasing = ClientPrefs.globalAntialiasing;
		qt_gas.scrollFactor.set();
		qt_gas.alpha = 0.63;
		qt_gas.setPosition(450, 0);
		FreeplayState.insert(FreeplayState.members.indexOf(FreeplayState.scoreText), qt_gas);
	}
	FlxG.camera.zoom = 1.1;
}

function beatHit(curBeat)
{
	if (FreeplayState.amountToTakeAway < 1)
	{
		switch (FreeplayState.instPlayingtxt.toLowerCase())
		{
			case 'termination':
				if (curBeat % 4 != 0)
				{
					if (curBeat >= 192 && curBeat <= 320) // 1st drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
					else if (curBeat >= 512 && curBeat <= 640) // 1st drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
					else if (curBeat >= 832 && curBeat <= 1088) // last drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
				}
			case 'censory-overload':
				if (curBeat == 241 || curBeat == 249 || curBeat == 257 || curBeat == 265 || curBeat == 273 || curBeat == 281 || curBeat == 289
					|| curBeat == 293 || curBeat == 297 || curBeat == 301 || curBeat == 497 || curBeat == 505 || curBeat == 513 || curBeat == 521
					|| curBeat == 529 || curBeat == 537 || curBeat == 545 || curBeat == 549 || curBeat == 553 || curBeat == 557)
				{
					if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
						FlxG.camera.zoom += 0.0075;
				}
				if (curBeat >= 80 && curBeat <= 208) // first drop
				{
					if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
						FlxG.camera.zoom += 0.0075;
					if (curBeat % 16 == 0)
						Gas_Release('burst');
				}
				else if (curBeat >= 304 && curBeat <= 432) // second drop
				{
					if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
						FlxG.camera.zoom += 0.0075;

					// Gas Release effect
					if (curBeat % 8 == 0)
						Gas_Release('burstALT');
				}
				else if (curBeat >= 560 && curBeat <= 688)
				{ // third drop
					if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
						FlxG.camera.zoom += 0.0075;

					// Gas Release effect
					if (curBeat % 4 == 0)
						Gas_Release('burstFAST');
				}
				else if (curBeat == 702)
					Gas_Release('burst');
				else if (curBeat >= 832 && curBeat <= 960)
				{ // final drop
					if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
						FlxG.camera.zoom += 0.0075;

					// Gas Release effect
					if (curBeat % 4 == 2)
						Gas_Release('burstFAST');
				}
		}
	}
}

function stepHit(curStep)
{
	if (FreeplayState.amountToTakeAway < 1)
	{
		if (FreeplayState.instPlayingtxt.toLowerCase() == "termination")
		{
			switch (curStep)
			{
				case 1:
					FlxG.camera.shake(0.002, 1);
				case 32:
					FlxG.camera.shake(0.002, 1);
				case 64:
					FlxG.camera.shake(0.002, 1);
				case 96:
					FlxG.camera.shake(0.002, 2);
				case 2808:
					FlxG.camera.shake(0.0075, 0.675);
			}
		}
	}
}

function Gas_Release(anim:String = 'burst')
{
	if (!ClientPrefs.lowQuality)
		if (qt_gas != null)
			qt_gas.animation.play(anim);
}
