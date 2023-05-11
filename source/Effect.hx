package;

import FlxFixedShader;
import codename.FlxFixedShader;

// this helps stable the FlxFixedShader code
class Effect
{
	public function setValue(shader:FlxFixedShader, variable:String, value:Float)
	{
		Reflect.setProperty(Reflect.getProperty(shader, 'variable'), 'value', [value]);
	}
}
