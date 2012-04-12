import haxe.unit.TestRunner;

class TestMain
{
	static public function main() 
	{
		var r = new TestRunner();
		r.add(new TestBasic());
		r.run();
	}
}