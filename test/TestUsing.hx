package ;
import haxe.unit.TestCase;
import hxunion.UnionSupport;

using MyUsing;

class TestUsing extends TestCase, implements UnionSupport
{
	static function getIntOrString(asInt:Bool):hxunion.Union<[Int, String]>
	{
		return asInt ? Int(13) : String("value");
	}
	
	public function testUsing()
	{
		var c = getIntOrString(true);
		assertEquals("26", c.usingTest());

		var c2 = getIntOrString(false);
		assertEquals("VALUE", c2.usingTest());
		
		switch(c.usingTestUnion())
		{
			case Int(i):
				assertEquals(26, i);
			case String(s):
				assertTrue(false);
		}
		
		switch(c2.usingTestUnion())
		{
			case Int(i):
				assertTrue(false);
			case String(s):
				assertEquals("VALUE", s);
		}
		
		var c3 = getIntOrString(false);
		c3.ifString(function(s) assertEquals("value", s));
	}	
}