package hxunion.engine;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import hxunion.engine.Types;

using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;

class UnionBuilder 
{
	static var count = 0;
	static var cache = new Hash<UnionInfo>();
		
	static public function buildUnion(tp:TypePath, pos):UnionInfo
	{
		if (tp.params.length != 1)
			Context.error(MULTI_ENUM_EXPECTS_TYPE_LIST, pos);

		var types = switch(tp.params[0])
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
		return define(types, pos);
	}
	
	static public function findUnion(name:String, unions:Array<UnionInfo>)
	{
		for (unionInfo in unions)
		{
			switch(unionInfo.cType)
			{
				case TPath(p):
					for (param in p.params)
					{
						switch(param)
						{
							case TPType(p2):
								switch(p2)
								{
									case TPath(p3):
										if (p3.sub == name || p3.sub == null && p3.name == name)
											return toName(p.pack, p.name).asSuccess();
									default:
								}
							default:
						}
					}
				default:
			}
		}
		return "No enum found.".asFailure();
	}
	
	static function define(types:Array<Type>, pos)
	{
		types.sort(function (t1, t2)
		{
			var n1 = getName(t1);
			var n2 = getName(t2);
			if (n1 == n2)
				Context.error("Duplicate type name: " +n1, pos);
			return n1 < n2 ? -1 : 1;
		});	

		var signature = Lambda.fold(types, function(type, r) return r + "$" +type.getID(), "Union");
		if (cache.exists(signature))
			return cache.get(signature);
		var id = count++;
		var name = "Union" +id;
		
		var fields = [];
		var params = [];
		var params2 = [];
		
		for (type in types)
		{
			var complexType = type.toComplex(true);
			fields.push(makeField(getName(type), complexType, pos));
			params.push({name:getName(type), constraints:[]});
			params2.push(TPType(complexType));
		}
		
		Context.defineType( {
			pack: ["hxunion", "types"],
			name: name,
			pos: pos,
			meta: [],
			params: params,
			isExtern: false,
			kind: TDEnum,
			fields: fields
		});

		var cType = TPath({
			name: name,
			pack: ["hxunion", "types"],
			params: params2,
			sub: null
		});

		var typeInfo = { cType: cType, id: id, types: types };
		cache.set(signature, typeInfo);
		return typeInfo;
	}
	
	static function makeField(name:String, type:ComplexType, pos)
	{
		return {
			name: name,
			doc: null,
			access: [APublic, AStatic],
			meta: [],
			pos: pos,
			kind: 
				FFun( {
					ret: null,
					params: [],
					expr: null,
					args: [{
						name: "_",
						opt: false,
						value: null,
						type: type
					}]
				})
		};
	}
		
	static function toName(pack:Array<String>, name:String)
		return pack.length == 0 ? name : pack.join(".") + "." + name
		
	static public function getName(t:Type)
		return switch(t)
		{
			case TInst(i, _): i.get().name;
			case TEnum(i, _): i.get().name;
			case TType(i, _): i.get().name;
			default: Context.error("Could not determine name of " +t, Context.currentPos());
		}
		
	static var MULTI_ENUM_EXPECTS_TYPE_LIST = "Union expects one argument of type [type list].";
}

#end