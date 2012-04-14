package ;
import haxe.unit.TestCase;
import hxunion.Tuple;
import hxunion.TupleSupport;

class TestParam<T> extends TestCase, implements TupleSupport
{
	public function new(t:T)
	{
		super();
	}
	
	public function doSomething(input:Tuple<[Int, String]>):T
	{
		return null;
	}
	
	static public function swap<T>(input:Tuple<[T, String]>):Tuple<[String, T]>
	{
		return ([input.val2, input.val1]);
	}
}

class TestTuple extends TestCase, implements TupleSupport
{
	public function testBasic()
	{
		var c1 = (["Hello", 122]);
		assertEquals("Hello", c1.val1);
		assertEquals(122, c1.val2);
		
		var c2 = createTuple();
		assertEquals(42, c2.val1);
		assertEquals("South", c2.val2);
		assertEquals(false, c2.val3);
		
		var c3 = (["Hello", 122]);
		assertTrue(Std.string(Type.typeof(c1)) == Std.string(Type.typeof(c3)));
		
		takeTuple(([1902, "foo"]));
		
		var c4 = returnTypedTuple();
		assertEquals(true, c4.val1);
		assertTrue(Std.is(c4.val2, Date));
		
		var c5 = returnParamTuple();
		assertEquals(false, c5.val1);
		assertEquals(3, c5.val2.length);
		assertEquals(66, c5.val3);
		
		var c6 = takeAndReturnTuple(([12, 66]));
		assertEquals("12", c6.val1);
		assertEquals("66", c6.val2);
		
		var c7 = takeAndReturnTuple(([12, 66]));
		assertEquals("12", c7.val1);
		assertEquals("66", c7.val2);
		
		var c8 = takeWithParams("foo", ([9, 2, "bar"]));
		assertEquals("barfoo", c8[0]);
		
		var t1 = new TestParam(5.2);
		t1.doSomething(([12, "hello"]));
		
		var c9 = TestParam.swap(([1, "2"]));
		assertEquals("2", c9.val1);
		assertEquals(1, c9.val2);
	}
	
	public function createTuple()
	{
		return ([42, "South", false]);
	}
	
	public function takeTuple(a:Tuple<[Int, String]>):Void
	{
		assertEquals(1902, a.val1);
	}
	
	public function returnTypedTuple():Tuple<[Bool, Date]>
	{
		return ([true, Date.now()]);
	}
	
	public function returnParamTuple():Tuple<[Bool, new Array<String>(), Int]>
	{
		return ([false, ["array", "of", "strings"], 66]);
	}
	
	public function takeAndReturnTuple(input:Tuple<[Int, Int]>):Tuple<[String, String]>
	{
		return ([Std.string(input.val1), Std.string(input.val2)]);
	}
	
	public function takeAndReturnTuple2(input)
	{
		return ([Std.string(input.val1), Std.string(input.val2)]);
	}
	
	static public function takeWithParams<S>(s:S, input:Tuple<[Int, Int, S]>):Array<S>
	{
		return [input.val3 + s];
	}
}