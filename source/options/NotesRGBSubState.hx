package options;

#if desktop
import Discord.DiscordClient;
#end
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class NotesRGBSubState extends MusicBeatSubstate
{
	public static var curSelected:Int = 0;
	public static var typeSelected:Int = 0;

	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorMask> = [];
	private var defaultColors:Array<Array<Int>> = [[194, 75, 153], [0, 255, 255], [18, 250, 5], [249, 57, 63]];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var posX = 230;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.antialiasing;
		add(bg);

		blackBG = new FlxSprite(posX - 25).makeGraphic(1140, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		for (i in 0...ClientPrefs.arrowRGB.length)
		{
			var yPos:Float = (165 * i) + 35;
			for (j in 0...3)
			{
				var optionText:Alphabet = new Alphabet(0, yPos + 60, Std.string(ClientPrefs.arrowRGB[i][j]), true);
				optionText.x = posX + (225 * j) + 250;
				optionText.ID = i;
				grpNumbers.add(optionText);
				var add = (40 * (optionText.letters.length - 1)) / 2;
				for (letter in optionText.letters)
					letter.offset.x += add;
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas('Notes/NOTE_assets_RGB');
			var animations:Array<String> = ['purple0', 'blue0', 'green0', 'red0'];
			note.animation.addByPrefix('idle', animations[i]);
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.antialiasing;
			note.ID = i;
			grpNotes.add(note);

			var newShader:ColorMask = new ColorMask();
			note.shader = newShader.shader;
			newShader.rCol = FlxColor.fromRGB(ClientPrefs.arrowRGB[i][0], ClientPrefs.arrowRGB[i][1], ClientPrefs.arrowRGB[i][2]);
			newShader.gCol = newShader.rCol.getDarkened(0.6);
			shaderArray.push(newShader);
		}

		hsbText = new Alphabet(posX + 720, 0, Locale.get("rgbNotesText"), false);
		hsbText.scaleX = 0.6;
		hsbText.scaleY = 0.6;
		add(hsbText);

		var descBox:FlxSprite = new FlxSprite(40, 589).makeGraphic(613, 87, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);
		var descText:FlxText = new FlxText(50, 600, 0, "Press Ctrl to alternate RGB/HSV\nPress R to reset the colors", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		descText.screenCenter(Y);
		descText.y += 270;
		add(descText);

		changeSelection();
	}

	var changingNote:Bool = false;

	override function update(elapsed:Float)
	{
		var rownum = 0;
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			var scaledY = FlxMath.remapToRange(item.ID, 0, 1, 0, 1.3);
			item.y = FlxMath.lerp(item.y, (scaledY * 165) + 270 + 60, lerpVal);
			item.x = FlxMath.lerp(item.x, (item.ID * 20) + 90 + posX + (225 * rownum + 250), lerpVal);
			rownum++;
			if (rownum == 3)
				rownum = 0;
		}
		for (i in 0...grpNotes.length)
		{
			var item = grpNotes.members[i];
			var scaledY = FlxMath.remapToRange(item.ID, 0, 1, 0, 1.3);
			item.y = FlxMath.lerp(item.y, (scaledY * 165) + 270, lerpVal);
			item.x = FlxMath.lerp(item.x, (item.ID * 20) + 90, lerpVal);
			if (i == curSelected)
			{
				hsbText.y = item.y - 70;
				blackBG.y = item.y - 20;
				blackBG.x = item.x - 20;
			}
		}

		if (FlxG.keys.justPressed.CONTROL)
		{
			ClientPrefs.useRGB = false;
			OptionsState.autoResetNotes = true;
			close();
		}
		if (changingNote)
		{
			if (holdTime < 0.5)
			{
				if (controls.UI_LEFT_P)
				{
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else if (controls.UI_RIGHT_P)
				{
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else if (controls.RESET)
				{
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
				{
					holdTime = 0;
				}
				else if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
				}
			}
			else
			{
				if (controls.UI_LEFT)
				{
					updateValue(elapsed * -50);
				}
				else if (controls.UI_RIGHT)
				{
					updateValue(elapsed * 50);
				}
				if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		}
		else
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P)
			{
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P)
			{
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.RESET)
			{
				for (i in 0...3)
				{
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length)
				{
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * 3) + typeSelected == i)
					{
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length)
				{
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i)
					{
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT))
		{
			if (!changingNote)
			{
				close();
			}
			else
			{
				changeSelection();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = ClientPrefs.arrowRGB.length - 1;
		if (curSelected >= ClientPrefs.arrowRGB.length)
			curSelected = 0;
		NotesSubState.curSelected = curSelected;

		curValue = ClientPrefs.arrowRGB[curSelected][typeSelected];
		updateValue();
		var bullshit = 0;
		var rownum = 0;
		// var currow;
		var bullshit2 = 0;
		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i)
			{
				item.alpha = 1;
			}
			item.ID = bullshit - curSelected;
			rownum++;
			if (rownum == 3)
			{
				rownum = 0;
				bullshit++;
			}
		}
		for (i in 0...grpNotes.length)
		{
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
			if (curSelected == i)
			{
				item.alpha = 1;
				item.scale.set(1, 1);
				hsbText.y = item.y - 70;
				blackBG.y = item.y - 20;
			}
			item.ID = bullshit2 - curSelected;
			bullshit2++;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0)
	{
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;
		NotesSubState.typeSelected = typeSelected;

		curValue = ClientPrefs.arrowRGB[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i)
			{
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int)
	{
		curValue = 0;
		ClientPrefs.arrowRGB[selected][type] = defaultColors[selected][type];

		shaderArray[selected].rCol = FlxColor.fromRGB(ClientPrefs.arrowRGB[selected][0], ClientPrefs.arrowRGB[selected][1], ClientPrefs.arrowRGB[selected][2]);
		shaderArray[selected].gCol = shaderArray[selected].rCol.getDarkened(0.6);

		var item = grpNumbers.members[(selected * 3) + type];
		item.text = Std.string(ClientPrefs.arrowRGB[selected][type]);

		var add = (40 * (item.letters.length - 1)) / 2;
		for (letter in item.letters)
			letter.offset.x += add;
	}

	function updateValue(change:Float = 0)
	{
		curValue += change;
		var roundedValue:Int = Math.round(curValue);

		if (roundedValue < 0)
			curValue = 0;
		else if (roundedValue > 255)
			curValue = 255;

		roundedValue = Math.round(curValue);
		ClientPrefs.arrowRGB[curSelected][typeSelected] = roundedValue;

		shaderArray[curSelected].rCol = FlxColor.fromRGB(ClientPrefs.arrowRGB[curSelected][0], ClientPrefs.arrowRGB[curSelected][1],
			ClientPrefs.arrowRGB[curSelected][2]);
		shaderArray[curSelected].gCol = shaderArray[curSelected].rCol.getDarkened(0.6);

		var item = grpNumbers.members[(curSelected * 3) + typeSelected];
		item.text = Std.string(roundedValue);

		var add = (40 * (item.letters.length - 1)) / 2;
		for (letter in item.letters)
			letter.offset.x += add;
	}
}