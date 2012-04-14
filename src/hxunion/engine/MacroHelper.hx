package hxunion.engine;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;

class MacroHelper 
{
	static public function getMembers(cls:ClassType, ctx:Array<tink.macro.tools.ExprTools.VarDecl>)
	{
		for (field in cls.fields.get())
			ctx.push( { name:field.name, type:null, expr: null } );
		if (cls.superClass != null)
			getMembers(cls.superClass.t.get(), ctx);
	}
	
	static public function getName(t:Type)
		return switch(t)
		{
			case TInst(i, _): i.get().name;
			case TEnum(i, _): i.get().name;
			case TType(i, _): i.get().name;
			case TMono(_): "mono";
			default: Context.error("Could not determine name of " +t, Context.currentPos());
		}
		
	static public function getTypesFromTypePath(tp:TypePath, monos, pos)
	{
		if (tp.params.length != 1)
			Context.error(TYPE_LIST_EXPECTS_TYPE_LIST, pos);
			
		return switch(tp.params[0])
		{
			case TPExpr(e):
				switch(e.expr)
				{
					case EArrayDecl(exprs):
						var ret = [];
						for (expr in exprs)
						{
							switch(expr.getName())
							{
								case Success(name):
									if (monos.exists(name))
									{
										ret.push(monos.get(name));
										continue;
									}
								case Failure(_):
							}
							
							var type = switch(expr.typeof())
							{
								case Success(t):
									switch(t)
									{
										case TInst(_), TEnum(_): t;
										case TType(tt, _): Context.getType(toName(tt.get().pack, tt.get().name.substr(1)));
										default: Context.error(NO_SUCH_TYPE +t, pos);
									}
								case Failure(e):
									Context.error(NO_SUCH_TYPE +expr + ": " +e, pos);
							}
							ret.push(type);
						}
						ret;
					default:
						Context.error(TYPE_LIST_EXPECTS_TYPE_LIST, pos);
				}
			default: Context.error(TYPE_LIST_EXPECTS_TYPE_LIST, pos);
		}
	}

	static public function monofy(type:ComplexType, monos:Hash<Type>):ComplexType
	{
		return switch(type)
		{
			case TPath(path):
				if (path.pack.length == 0 && monos.exists(path.name))
					monos.get(path.name).toComplex();
				else
					TPath(monofyParams(path, monos));
			default:
				type;
		}
	}
	
	static public function monofyParams(tp:TypePath, monos:Hash<Type>)
	{
		var newParams = [];
		for (param in tp.params)
		{
			switch(param)
			{
				case TPType(ct):
					newParams.push(TPType(monofy(ct, monos)));
				default:
					newParams.push(param);
			}
		}
		return { name:tp.name, pack:tp.pack, sub:tp.sub, params:newParams };
	}
	
	static public function makeMono()
	{
		return "null".resolve().typeof().sure();
	}
	
	static public function makeMonoHash(names:Iterable<String>)
	{
		var hash = new Hash();
		for (name in names)
			hash.set(name, makeMono());
		return hash;
	}

	static public function toName(pack:Array<String>, name:String)
		return pack.length == 0 ? name : pack.join(".") + "." + name
		
	static var NO_SUCH_TYPE = "Could not find type: ";
	static var TYPE_LIST_EXPECTS_TYPE_LIST = "Union expects one argument of type [type list].";
}

#end