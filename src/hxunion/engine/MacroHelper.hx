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
			default: Context.error("Could not determine name of " +t, Context.currentPos());
		}
		
	static public function getTypesFromTypePath(tp:TypePath, pos)
	{
		if (tp.params.length != 1)
			Context.error(MULTI_ENUM_EXPECTS_TYPE_LIST, pos);
			
		return switch(tp.params[0])
		{
			case TPExpr(e):
				switch(e.expr)
				{
					case EArrayDecl(exprs):
						var ret = [];
						for (expr in exprs)
						{
							var type = switch(expr.typeof())
							{
								case Success(t):
									switch(t)
									{
										case TInst(_), TEnum(_): t;
										case TType(tt, _): Context.getType(toName(tt.get().pack, tt.get().name.substr(1)));
										default: Context.error("Could not find type: " +t, pos);
									}
								case Failure (e): Context.error("Could not find type: " +e, pos);
							}
							ret.push(type);
						}
						ret;
					default:
						Context.error(MULTI_ENUM_EXPECTS_TYPE_LIST, pos);
				}
			default: Context.error(MULTI_ENUM_EXPECTS_TYPE_LIST, pos);
		}
	}
	
	static public function toName(pack:Array<String>, name:String)
		return pack.length == 0 ? name : pack.join(".") + "." + name
		
	static var MULTI_ENUM_EXPECTS_TYPE_LIST = "Union expects one argument of type [type list].";
}

#end