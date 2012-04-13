package hxunion.engine;

#if macro

typedef UnionInfo =
{
	cType: haxe.macro.Expr.ComplexType,
	types: Array<haxe.macro.Type>,
	id: Int
}

#end