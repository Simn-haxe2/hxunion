import hxunion.Union<T>;
import hxunion.UnionSupport;

class MyUsing implements UnionSupport
{
	static public function usingTest(first:hxunion.Union<[Int, String]>):String
	{
		switch(first)
		{
			case Int(i): return Std.string(i * 2);
			case String(s): return s.toUpperCase();
		}
	}
	
	static public function usingTestUnion(first:hxunion.Union<[Int, String]>):hxunion.Union<[Int, String]>
	{
		return switch(first)
		{
			case Int(i): i * 2;
			case String(s): s.toUpperCase();
		}
	}
	
	static public function ifString(arg:Union<[String, Int]>, func:String->Void):hxunion.Union<[Int, String]>
	{
		switch(arg)
		{
			case String(s): func(s);
			default:
		}
		return arg;
	}
	
	static public function getIntOrString(asInt:Bool):hxunion.Union<[Int, String]>
	{
		return asInt ? Int(13) : String("value");
	}	
}