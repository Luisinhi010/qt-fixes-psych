package lore;

/*
 *  Btw @see https://github.com/sayofthelor/lore-engine/blob/main/source/lore/FlxSpriteTools.hx
 */
import flixel.FlxSprite;
import flixel.util.FlxAxes;

class FlxSpriteTools
{
	public static function centerOnSprite(s:FlxSprite, t:FlxSprite, ?axes:FlxAxes = FlxAxes.XY):Void
	{
		if (axes == FlxAxes.XY || axes == FlxAxes.X)
			s.x = t.x + (t.width / 2) - (s.width / 2);
		if (axes == FlxAxes.XY || axes == FlxAxes.Y)
			s.y = t.y + (t.height / 2) - (s.height / 2);
	}
}
