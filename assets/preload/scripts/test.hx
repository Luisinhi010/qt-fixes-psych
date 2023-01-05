import MainMenuState;

function createPost()
{
	var versionTxt:FlxText = new FlxText(0, 0, 0, 'QT Fixes Version - v' + MainMenuState.qtfixesVersion);
	versionTxt.setFormat(Paths.font("vcr.ttf"), 18, 0xffffffff);
	versionTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xff000000, 2);
	versionTxt.setPosition(FlxG.width - (versionTxt.width + 5), 5);
	versionTxt.antialiasing = true;
	versionTxt.cameras = [game.camHUD];
	game.add(versionTxt);
}
