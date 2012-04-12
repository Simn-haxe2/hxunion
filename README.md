Haxe multi return
=============

This library allows functions to return multiple types by creating a common enumeration. 

Usage
-------

Simply make classes use `implements hxmr.MultiReturnSupport` and you are good to go. You can list allowed types as your method's return type by using the syntax `hxme.MultiReturn<[Type1, Type2, ..., TypeN]>`. This will create a hidden enum with constructors for `Type1` to `TypeN` that you can switch over.

Assuming you defined two enums:

```

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

```

You can declare a function returning either of these like so:

```

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

```

And you can simply switch over the result of that function:

```
static public function main()
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
}

```