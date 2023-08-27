import CoolUtil;

function create()
{
	MainMenuState.alignment = "right";
	MainMenuState.optionShit = ['story_mode', 'freeplay', 'mods', 'awards', 'credits', 'options'];
	MainMenuState.bgPath = 'menuMain';
}

var iconBG:FlxSprite;
var icon:HealthIcon;
var vignette1:OverlaySprite;
var lastalpha:Float;

function postCreate()
{
	var checker:FlxBackdrop = new FlxBackdrop(Paths.image('luis/qt-fixes/Checker'), 0.2, 0.2, true, true);
	checker.alpha = 0.4;
	MainMenuState.insert(MainMenuState.members.indexOf(MainMenuState.menuItems), checker);
	checker.scrollFactor.set(0, 0.07);
	checker.velocity.x -= 45;
	checker.velocity.y -= 16;

	if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
	{
		iconBG = new FlxSprite().loadGraphic(Paths.image('luis/qt-fixes/iconbackground'));
		iconBG.y = FlxG.height - iconBG.height;
		iconBG.scrollFactor.set();
		iconBG.updateHitbox();
		iconBG.antialiasing = ClientPrefs.antialiasing;
		MainMenuState.add(iconBG);
	}

	icon = new HealthIcon('bf');
	icon.antialiasing = ClientPrefs.antialiasing;
	icon.x = 70;
	icon.y = FlxG.height - 180;
	icon.scrollFactor.set();
	icon.updateHitbox();
	MainMenuState.add(icon);

	MainMenuState.versionShit.screenCenter(FlxAxes.X);
	MainMenuState.versionShit.alignment = "center";
	MainMenuState.versionShitfnf.screenCenter(FlxAxes.X);
	MainMenuState.versionShitfnf.alignment = "center";
	var qtVersion:FlxText = new FlxText(FlxG.width - 270, FlxG.height - 44, 0, "QT Mod Version - v" + qtmodVersion, 12);
	qtVersion.x -= qtVersion.width;
	qtVersion.scrollFactor.set();
	qtVersion.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
	MainMenuState.add(qtVersion);

	var fixesVersion:FlxText = new FlxText(qtVersion.x, FlxG.height - 24, 0,
		"QT Fixes Version - v" + qtfixesVersion /*+ ' (' + MusicBeatState.commitHash + ')'*/, 12);
	fixesVersion.scrollFactor.set();
	fixesVersion.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
	MainMenuState.add(fixesVersion);
	FlxG.mouse.visible = true;
	FlxG.mouse.useSystemCursor = false;

	if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
	{
		vignette1 = new OverlaySprite('luis/qt-fixes/vignettealt');
		vignette1.usewindowscale = false;
		vignette1.alpha = 0;
		MainMenuState.add(vignette1);
	}

	switch (FlxG.random.int(1, 5))
	{
		case 1:
			icon.changeIcon('bf');
			icon.setGraphicSize(Std.int(icon.width * 2));
			if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
				iconBG.color = CoolUtil.returnColor('cyan');
		case 2:
			icon.changeIcon('gf');
			icon.setGraphicSize(Std.int(icon.width * 2));
			if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
				iconBG.color = CoolUtil.returnColor('red');
		case 3:
			icon.changeIcon('kb');
			icon.setGraphicSize(Std.int(icon.width * 1.9));
			if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
				iconBG.color = CoolUtil.returnColor('gray');
			switch (FlxG.random.int(1, 2))
			{
				case 1:
					if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
						vignette1.alpha = 0.5;
					icon.animation.curAnim.curFrame = 0;
				case 2:
					if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
						vignette1.alpha = 0.8;
					icon.animation.curAnim.curFrame = 1;
			}
		case 4:
			icon.changeIcon('qt-menu');
			icon.setGraphicSize(Std.int(icon.width * 1.9));
			if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
				iconBG.color = CoolUtil.returnColor('pink');
			switch (FlxG.random.int(1, 2))
			{
				case 1:
					if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
						vignette1.alpha = 0.1;
					icon.animation.curAnim.curFrame = 0;
				case 2:
					if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
						vignette1.alpha = 0.7;
					icon.animation.curAnim.curFrame = 1;
			}
		case 5:
			icon.changeIcon('qt_annoyed');
			icon.setGraphicSize(Std.int(icon.width * 1.9));
			if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
			{
				iconBG.color = CoolUtil.returnColor('pink');
				vignette1.alpha = 0.7;
			}
	}
	trace(icon.getCharacter());

	if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
	{
		if (checker != null)
			checker.color = iconBG.color;

		lastalpha = vignette1.alpha;
	}
}

function postcloseSubState()
{
	if (!ClientPrefs.lowQuality && !ClientPrefs.optimize)
		vignette1.alpha = lastalpha;
}
/*function beatHit(curBeat)//testing other functions
	{
	MainMenuState.alignment = curBeat % 2 == 0 ? "right" : "left";
}*/
