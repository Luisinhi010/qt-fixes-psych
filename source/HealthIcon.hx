package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var canBounce:Bool = false;
	public var hasWinning:Bool = false;

	private var isPlayer:Bool = false;
	private var char:String = '';
	private var index:Int = 2;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		makeGraphic(300, 150, flixel.util.FlxColor.TRANSPARENT);
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);

		if (canBounce)
		{
			var mult:Float = flixel.math.FlxMath.lerp(1, scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			scale.set(mult, mult);
			updateHitbox();
		}
	}

	private var iconOffset:Float = 0; // pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/12648

	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			var name:String = 'icons/' + char;

			if (!Paths.fileExists('images/' + name + '.png', IMAGE))
				name = 'icons/icon-' + char; // Older versions of psych engine's support
			if (!Paths.fileExists('images/' + name + '.png', IMAGE))
				name = 'icons/icon-face'; // Prevents crash from missing icon

			var file:FlxGraphic = Paths.image(name);
			index = Std.int(file.width / file.height);
			if (index >= 3)
				hasWinning = true;
			loadGraphic(file, true, Math.floor(file.width / index), Math.floor(file.height));
			iconOffset = (width - 150) / index;
			offset.set(iconOffset, iconOffset);
			updateHitbox();
			animation.add(char, CoolUtil.numberArray(index), 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			antialiasing = ClientPrefs.antialiasing;
			if (char.endsWith('-pixel'))
				antialiasing = false;
		}
	}

	override function updateHitbox()
	{
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		centerOrigin();
	}

	public function bounce()
	{
		if (canBounce)
		{
			var mult:Float = 1.2;
			scale.set(mult, mult);
			updateHitbox();
		}
	}

	public function getCharacter():String
		return char;

	public function getDiscordCharacter():String
	{
		var thechar:String = char;
		// To avoid having duplicate images in Discord assets
		switch (char)
		{
			case 'kb' | 'kb-404' | 'kb-404-angry' | 'kb-angry':
				thechar = 'kb';
			case 'kb-classic-placeholder' | 'kb-classic-placeholder-404':
				thechar = 'kb-classic';
			case 'bf' | 'bf-404' | 'bf-pixel' | 'bf-invis':
				thechar = 'bf';
			case 'gf' | 'gf-404':
				thechar = 'gf';
			case 'qt' | 'qt-nervous' | 'qt_annoyed' | 'q' | 'qt-classic-placeholder':
				thechar = 'qt';
			case 'qt-kb':
				thechar = 'qt-kb';
			default:
				if (char.startsWith('kb'))
					thechar = 'kb';
				if (char.startsWith('qt'))
					thechar = 'qt';
				if (!char.endsWith('-invis'))
					thechar = 'placeholder';
		}
		return thechar;
	}
}
