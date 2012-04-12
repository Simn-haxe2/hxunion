package ;
import haxe.unit.TestCase;
import hxmr.MultiReturn<T>;
import hxmr.MultiReturnSupport;
import sub.Enum3;

enum Enum1
{
	E1a;
	E1b(v:String);
	E1c(c:Int);
}

enum Enum2
{
	E2a(v:String);
	E2b;
	E2c;
}

class Class1
{
	public var value:String;
	public function new(v:String)
	{
		value = v;
	}
}

class TestBasic extends TestCase, implements MultiReturnSupport
{
	public function testBasic()
	{
		switch(multiEnumReturn(false))
		{
			case Enum1(e):
				assertFalse(true);
			case Enum2(e):
				assertEquals(E2b, e);
		}
		
		switch(multiEnumReturn2(true))
		{
			case Enum1(e):
				switch(e)
				{
					case E1a: assertFalse(true);
					case E1b(v): assertEquals("foo", v);
					case E1c(s): assertFalse(true);
				}
			case Enum2(e):
				assertFalse(true);
		}	
		
		switch(multiEnumReturn3(0))
		{
			case Enum2(e):
				switch(e)
				{
					case E2a(v): assertEquals("bla", v);
					default: assertFalse(true);
				}
			case Class1(v): assertFalse(true);
		}
		
		switch(multiEnumReturn3(1))
		{
			case Enum2(e):
				assertFalse(true);
			case Class1(v):
				assertTrue(Std.is(v, Class1));
				assertEquals("foobar", v.value);
		}		
	}
	
	public function multiEnumReturn(b:Bool):hxmr.MultiReturn<[Enum1, Enum2]>
	{
		if (b)
			return E2a("foo");
		else
			return E2b;
	}
	
	public function multiEnumReturn2(b:Bool):hxmr.MultiReturn<[Enum1, Enum2]>
	{
		return if (b)
			E1b("foo");
		else
			E1c(15);
	}	
	
	public function multiEnumReturn3(i:Int):hxmr.MultiReturn<[Enum2, Class1]>
	{
		switch(i)
		{
			case 0: return E2a("bla");
			case 1: return new Class1("foobar");
			default: return E2b;
		}
	}
}