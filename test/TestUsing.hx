package ;
import haxe.unit.TestCase;

using MyUsing;

class TestUsing extends TestCase
{
	public function testUsing()
	{
		var c = MyUsing.getIntOrString(true);
		assertEquals("26", c.usingTest());

		var c2 = MyUsing.getIntOrString(false);
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
		
		var c3 = MyUsing.getIntOrString(false);
		c3.ifString(function(s) assertEquals("value", s));
	}	
}