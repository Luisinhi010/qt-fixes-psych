import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;

using StringTools;

class ConfirmUserOption extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;
	var selectedSomethin = false;

	public function new()
	{
		super();
		bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var textstring:String = 'would you let this mod\nuse your computer\'s\nusername?';

		var tipTextArray:Array<String> = textstring.split('\n');
		for (i in 0...tipTextArray.length)
		{
			var text:Alphabet = new Alphabet(0, 160, tipTextArray[i], true);
			text.y += i * 80;
			text.screenCenter(X);
			alphabetArray.push(text);
			text.alpha = 0;
			text.scrollFactor.set();
			add(text);
		}

		yesText = new Alphabet(0, 490, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 150;
		yesText.scrollFactor.set();
		add(yesText);
		noText = new Alphabet(0, 490, 'No', true);
		noText.screenCenter(X);
		noText.x += 150;
		noText.scrollFactor.set();
		add(noText);
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6)
			bg.alpha = 0.6;

		for (i in 0...alphabetArray.length)
		{
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}

		if (!selectedSomethin)
		{
			if (FlxG.mouse.overlaps(yesText) && !onYes)
				updateselection(true);

			if (FlxG.mouse.overlaps(noText) && onYes)
				updateselection(false);

			if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
				updateselection(!onYes);
			else if (controls.ACCEPT || (FlxG.mouse.justPressed && (FlxG.mouse.overlaps(noText) || FlxG.mouse.overlaps(yesText))))
				accepted();
		}
		super.update(elapsed);
	}

	function updateOptions()
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
	}

	function updateselection(onYes:Bool)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 1);
		this.onYes = onYes;
		updateOptions();
	}

	function accepted()
	{
		selectedSomethin = true;
		ClientPrefs.usePlayerUsername = FlxG.save.data.usePlayerUsername = onYes;
		FlxG.sound.play(Paths.sound(onYes ? 'confirmMenu' : 'cancelMenu'), 1);
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			close();
		});
	}
}
