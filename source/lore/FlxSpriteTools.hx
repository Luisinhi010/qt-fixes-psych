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

	public static function exactSetGraphicSize(obj:FlxSprite, width:Float, height:Float)
	{
		obj.scale.set(Math.abs(((obj.width - width) / obj.width) - 1), Math.abs(((obj.height - height) / obj.height) - 1));
		obj.updateHitbox();
	}
}
