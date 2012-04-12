Haxe multi return
=============

This library allows functions to return multiple types by creating a common enumeration. 

Usage
-------

Simply make classes use `implements hxmr.MultiReturnSupport` and you are good to go. You can list allowed types as your method's return type by using the syntax `hxmr.MultiReturn<[Type1, Type2, ..., TypeN]>`. This will create a hidden enum with constructors for `Type1` to `TypeN` that you can switch over.

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
	return switch(rand)
	{
		case 1: CoffeeShortage(3);
		case 2: BossDead;
		case 3: FoundGold;
		default: LessImportant;
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

Of course the types must not be enums, you can return different class types as well:

```

public function multiClassReturn():hxmr.MultiReturn<[Int, String, Xml]>
{
	if (Date.now().getHours() == 23 && Date.now().getMinutes() == 58)
		return Xml.parse("<two minutes='till'>midnight</two>");
	if (Date.now().getMinutes() < 20)
		return 12;
	else
		return "Just a string";
}

```