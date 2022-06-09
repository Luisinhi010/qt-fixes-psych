package;

import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];

	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			var name:String = 'icons/' + char;
			if (!Paths.fileExists('images/' + name + '.png', IMAGE))
				name = 'icons/icon-' + char; // Older versions of psych engine's support
			if (!Paths.fileExists('images/' + name + '.png', IMAGE))
				name = 'icons/icon-face'; // Prevents crash from missing icon
			var file:Dynamic = Paths.image(name);

			loadGraphic(file); // Load stupidly first for getting the file size
			loadGraphic(file, true, Math.floor(width / 2), Math.floor(height)); // Then load it fr
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (width - 150) / 2;
			updateHitbox();

			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			antialiasing = ClientPrefs.globalAntialiasing;
			antialiasing = !char.endsWith('-pixel');
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String
	{
		return char;
	}

	public function getDiscordCharacter():String
	{
		var thechar:String = char;
		// To avoid having duplicate images in Discord assets
		switch (char)
		{
			case 'kb' | 'kb-404' | 'kb-404-angry' | 'kb-angry' | 'kb-classic-placeholder' | 'kb-classic-placeholder-404':
				if (char.contains('classic-placeholder'))
					thechar = 'kb-classic';
				else
					thechar = 'kb';
			case 'bf' | 'bf-404' | 'bf-invis':
				thechar = 'bf';
			case 'gf' | 'gf-404':
				thechar = 'gf';
			case 'qt' | 'qt-nervous' | 'q':
				thechar = 'qt';
			case 'qt-kb':
				thechar = 'qt-kb';
		}
		return thechar == null ? 'placeholder' : thechar;
	}
}
