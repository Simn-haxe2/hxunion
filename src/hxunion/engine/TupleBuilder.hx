package hxunion.engine;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import hxunion.engine.Types;

using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;

class TupleBuilder 
{
	static var count = 0;
	static var cache = new Hash<TypePath>();
	
	static public function buildFromTypePath(tp:TypePath, pos)
	{
		var types = MacroHelper.getTypesFromTypePath(tp, pos);
		return buildFromTypes(types, pos);
	}
	
	static public function buildFromTypes(types:Array<Type>, pos)
	{
		var signature = Lambda.fold(types, function(type, r) return r + "$" +type.getID(), "Union");
		if (cache.exists(signature))
			return cache.get(signature);
		var id = count++;
		var name = "Tuple" +id;
		
		var fields = [];
		var params = [];
		var params2 = [];
		var ctorArgs = [];
		var ctorAssigns = [];
		
		var i = 1;
		for (type in types)
		{
			var complexType = type.toComplex(true);
			var fieldName = "val" +i++;
			fields.push(makeField(fieldName, complexType, pos));
			params.push({name:MacroHelper.getName(type), constraints:[]});
			params2.push(TPType(complexType));
			ctorArgs.push( {
				name: fieldName,
				opt: false,
				type: complexType,
				value: null
			});
			ctorAssigns.push(["this", fieldName].drill().assign(fieldName.resolve()));
		}
		
		fields.push({
			name: "new",
			doc: null,
			access: [APublic],
			meta: [],
			pos: pos,
			kind: FFun( {
					ret: null,
					params: [],
					expr: EBlock(ctorAssigns).at(pos),
					args: ctorArgs
				})
		});
		
		Context.defineType( {
			pack: ["hxunion", "types"],
			name: name,
			pos: pos,
			meta: [],
			params: params,
			isExtern: false,
			kind: TDClass(null, null, null),
			fields: fields
		});

		var path = {
			name: name,
			pack: ["hxunion", "types"],
			params: params2,
			sub: null
		};

		cache.set(signature, path);
		
		return path;
	}
	
	static function makeField(name:String, type:ComplexType, pos)
	{
		return {
			name: name,
			doc: null,
			access: [APublic],
			meta: [],
			pos: pos,
			kind: FVar(type, null)
		};
	}	
}

#end