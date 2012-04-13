package ;
import haxe.unit.TestCase;
import hxunion.Union<T>;
import hxunion.UnionSupport;
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

class TestBasic extends TestCase, implements UnionSupport
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
		
		switch(multiClassReturn())
		{
			case String(s):
				assertEquals("Just a string", s);
			case Int(i):
				assertEquals(12, i);
			case Xml(xml):
				assertTrue(false);
		}
	}
	
	public function multiEnumReturn(b:Bool):hxunion.Union<[Enum1, Enum2]>
	{
		if (b)
			return E2a("foo");
		else
			return E2b;
	}
	
	public function multiEnumReturn2(b:Bool):hxunion.Union<[Enum1, Enum2]>
	{
		return if (b)
			E1b("foo");
		else
			E1c(15);
	}	
	
	public function multiEnumReturn3(i:Int):hxunion.Union<[Enum2, Class1]>
	{
		switch(i)
		{
			case 0: return E2a("bla");
			case 1: return new Class1("foobar");
			default: return E2b;
		}
	}
	
	public function multiClassReturn():hxunion.Union<[Int, String, Xml]>
	{
		if (Date.now().getHours() == 23 && Date.now().getMinutes() == 58)
			return Xml.parse("<two minutes='till'>midnight</two>");
		if (Date.now().getMinutes() < 20)
			return 12;
		else
			return "Just a string";
	}
	
	public function unificationProblems():hxunion.Union<[Int, String]>
	{
		return if (true) 12 else "12";
		
		return switch(false)
		{
			case true: 99;
			case false: "99";
		}
		
		return false ? "foo" : 12;
		return 4 + 2;
		
		return ([1, 12])[0];
	}
}