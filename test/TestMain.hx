import haxe.unit.TestRunner;

class TestMain
{
	static public function main() 
	{
		var r = new TestRunner();
		r.add(new TestBasic());
		r.add(new TestReadme());
		r.add(new TestUsing());
		r.add(new TestTuple());
		r.run();
	}
}