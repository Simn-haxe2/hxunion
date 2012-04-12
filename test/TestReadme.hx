package ;
import haxe.unit.TestCase;
import hxmr.MultiReturn;
import hxmr.MultiReturnSupport;

enum MyProblem
{
	CoffeeShortage(amount:Int);
	LessImportant;
}

enum MySuccess
{
	BossDead;
	FoundGold;
}

class TestReadme extends TestCase, implements MultiReturnSupport
{
	public function testBasic()
	{
		switch(doSomething())
		{
			case MySuccess(s):
				switch(s)
				{
					case BossDead:
					case FoundGold:
				}
			case MyProblem(p):
				switch(p)
				{
					case CoffeeShortage(amount):
					case LessImportant:
				}
		}
		assertTrue(true);
	}
	
	public function doSomething():MultiReturn<[MyProblem, MySuccess]>
	{
		var rand = Std.random(4);
		switch(rand)
		{
			case 1: return CoffeeShortage(3);
			case 2: return BossDead;
			case 3: return FoundGold;
			default: return LessImportant;
		}
	}
}

