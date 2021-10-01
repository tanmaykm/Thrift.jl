#include <string>
#include <fstream>
#include <iostream>
#include <vector>

#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sstream>
#include <algorithm>
#include "thrift/generate/t_oop_generator.h"
#include "thrift/platform.h"
#include "thrift/version.h"

using std::map;
using std::ofstream;
using std::ostringstream;
using std::string;
using std::stringstream;
using std::vector;

static const string endl = "\n";  // avoid ostream << std::endl flushes

static const char * _julia_keywords[] = {
        "if", "else", "elseif", "while", "for", "begin", "end", "quote",
        "try", "catch", "return", "local", "abstract", "function", "macro",
        "ccall", "finally", "typealias", "break", "continue", "type",
        "global", "module", "using", "import", "export", "const", "let",
        "bitstype", "do", "baremodule", "importall", "immutable", "struct",
        "Type"
};
static const std::vector<string> julia_keywords(_julia_keywords, _julia_keywords + 35);

/**
 * Julia code generator.
 *
 */
class t_jl_generator: public t_generator {
public:
	t_jl_generator(t_program* program,
			__attribute__((unused)) const std::map<std::string, std::string>& parsed_options,
			const std::string& option_string) :
			t_generator(program) {
		(void) option_string;
		std::map<std::string, std::string>::const_iterator iter;
		out_dir_base_ = "gen-jl";
	}

	/**
	 * Init and close methods
	 */
	void init_generator();
	void close_generator();

	/**
	 * Program-level generation functions
	 */
	void generate_typedef(t_typedef* ttypedef);
	void generate_enum(t_enum* tenum);
	void generate_const(t_const* tconst);
	void generate_struct(t_struct* tstruct);
	void generate_xception(t_struct* txception);
	void generate_service(t_service* tservice);

	/**
	 * Helper functions
	 */
	std::string render_const_value(t_type* type, t_const_value* value, bool with_conversion);
	string julia_type(t_type *type);
	void generate_jl_struct(ofstream& out, t_struct* tstruct, bool is_exception, string suffix="");
	std::string jl_autogen_comment();
	std::string jl_imports();
	void generate_module_begin();
	void generate_module_end();
	void generate_service_args_and_returns(t_service* tservice);
	void generate_service_processor(t_service* tservice);
	void generate_service_user_function_comments(t_service* tservice);
	void generate_service_client(t_service* tservice);
	void add_to_module(t_service* tservice);
	bool is_keyword(const string &value);
	string chk_keyword(const string &value);

private:

	/**
	 * File streams
	 */
	std::ofstream f_types_;
	std::ofstream f_consts_;
	std::ofstream f_service_;
	std::ofstream f_module_;

	std::ostringstream module_exports_;
	std::ostringstream module_using_;
	std::ostringstream module_includes_;

	std::string package_dir_;
	std::string program_dir_;
};

/**
 * Prepares for file generation by opening up the necessary file output
 * streams.
 *
 * @param tprogram The program to generate
 */
void t_jl_generator::init_generator() {
	// Make output directory
	package_dir_ = get_out_dir();
	MKDIR(package_dir_.c_str());

	program_dir_ = package_dir_ + "/" + program_name_;
	MKDIR(program_dir_.c_str());

	// Make output file
	string f_types_name = program_dir_ + "/" + program_name_ + "_types.jl";
	f_types_.open(f_types_name.c_str());

	string f_consts_name = program_dir_ + "/" + program_name_ + "_constants.jl";
	f_consts_.open(f_consts_name.c_str());

	string f_mod_name = program_dir_ + "/" + program_name_ + ".jl";
	f_module_.open(f_mod_name.c_str());

	// Print header
	f_types_ << jl_autogen_comment() << endl;
	f_consts_ << jl_autogen_comment() << endl;
	f_module_ << jl_autogen_comment() << endl;
	generate_module_begin();
}

void t_jl_generator::generate_module_begin() {
	f_module_ << endl;
	f_module_ << "module " << program_name_ << endl;
	f_module_ << endl << jl_imports() << endl;
}

void t_jl_generator::generate_module_end() {
	f_module_ << endl << "export meta" << endl;
	f_module_ << module_exports_.str() << endl;

	f_module_ << "include(\"" << program_name_ << "_constants.jl\")" << endl;
	f_module_ << "include(\"" << program_name_ << "_types.jl\")" << endl;
	f_module_ << "include(\"" << program_name_ << "_impl.jl\")  # server methods to be hand coded" << endl;
	f_module_ << module_includes_.str() << endl;

	f_module_ << endl << "end # module " << program_name_ << endl;
}

/**
 * Return corresponding Julia type
 */
string t_jl_generator::julia_type(t_type *type) {
	if (type->is_base_type()) {
		t_base_type::t_base tbase = ((t_base_type*) type)->get_base();
		switch (tbase) {
		case t_base_type::TYPE_STRING:
			if (((t_base_type*)type)->is_binary()) {
				return "Vector{UInt8}";
			}
			else {
				return "String";
			}
		case t_base_type::TYPE_BOOL:
			return "Bool";
		case t_base_type::TYPE_I8:
			return "UInt8";
		case t_base_type::TYPE_I16:
			return "Int16";
		case t_base_type::TYPE_I32:
			return "Int32";
		case t_base_type::TYPE_I64:
			return "Int64";
		case t_base_type::TYPE_DOUBLE:
			return "Float64";
		default:
			throw "compiler error: unknown base type " + t_base_type::t_base_name(tbase);
		}
	}
	else if(type->is_list()) {
		t_type *etype = ((t_list*)type)->get_elem_type();
		return ("Vector{" + julia_type(etype) + "}");
	}
	else if(type->is_set()) {
		t_type *etype = ((t_set*)type)->get_elem_type();
		return ("Set{" + julia_type(etype) + "}");
	}
	else if(type->is_map()) {
	    t_type* ktype = ((t_map*)type)->get_key_type();
	    t_type* vtype = ((t_map*)type)->get_val_type();
		return ("Dict{" + julia_type(ktype) + "," + julia_type(vtype) + "}");
	} else if(type->is_enum()) {
		return "Int32";
	}

	return type->get_name();
}

/**
 * Autogen'd comment
 */
string t_jl_generator::jl_autogen_comment() {
	return std::string("#\n") + "# Autogenerated by Thrift Compiler ("
			+ THRIFT_VERSION + ")\n" + "#\n"
			+ "# DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING\n";
}

/**
 * Prints standard thrift imports
 */
string t_jl_generator::jl_imports() {
	std::ostringstream out;

	out << "using Thrift" << endl << "import Thrift.process, Thrift.meta, Thrift.distribute" << endl << endl;

	const vector<t_program*>& includes = program_->get_includes();
	for (size_t i = 0; i < includes.size(); ++i) {
		if(i > 0) (out << ", ");
		else (out << "# import included programs" << endl << "using ");
		out << ".." << includes[i]->get_name();
	}
	out << endl;
	return out.str();
}

/**
 * Closes the type files
 */
void t_jl_generator::close_generator() {
	f_types_.close();
	f_consts_.close();
	generate_module_end();
	f_module_.close();
}

/**
 * Generates a typedef.
 *
 * @param ttypedef The type definition
 */
void t_jl_generator::generate_typedef(t_typedef* ttypedef) {
	f_types_ << indent() << "const " << ttypedef->get_symbolic() << " = ";
	t_type *t = ttypedef->get_type();
	f_types_ << julia_type(t) << endl << endl;

	module_exports_ << "export " << ttypedef->get_symbolic() << " # typealias for " << julia_type(t) << endl;
}

bool t_jl_generator::is_keyword(const string &value) {
	return std::find(julia_keywords.begin(), julia_keywords.end(), value) != julia_keywords.end();
}

string t_jl_generator::chk_keyword(const string &value) {
	if(is_keyword(value) == true) {
		pwarning(0, "Encountered Julia keyword \"%s\" in IDL file. It will be generated as \"_%s\". Consider renaming.", value.c_str(), value.c_str());
		return "_" + value;
	}
	return value;
}

/**
 * Generates code for an enumerated type. Done using a class to scope
 * the values.
 *
 * @param tenum The enumeration
 */
void t_jl_generator::generate_enum(t_enum* tenum) {
	vector<t_enum_value*> constants = tenum->get_constants();
	string enum_name = chk_keyword(tenum->get_name());

	f_types_ << indent() << "struct " << "_enum_" << enum_name << endl;
	indent_up();
	vector<t_enum_value*>::const_iterator c_iter;
	for (c_iter = constants.begin(); c_iter != constants.end(); ++c_iter) {
		f_types_ << indent() << chk_keyword((*c_iter)->get_name()) << "::Int32" << endl;
	}
	indent_down();
	f_types_ << indent() << "end" << endl;

	// tenum->resolve_values();
	f_types_ << indent() << "const " << enum_name << " = _enum_" << enum_name << "(";
	bool first = true;
	for (c_iter = constants.begin(); c_iter != constants.end(); ++c_iter) {
	    if (first) {
	    	first = false;
	    } else {
	    	f_types_ << ", ";
	    }
		f_types_ << "Int32(" << (*c_iter)->get_value() << ")";
	}
	f_types_ << ")" << endl << endl;

	module_exports_ << "export " << enum_name << " # enum" << endl;
}

/**
 * Generate a constant value
 */
void t_jl_generator::generate_const(t_const* tconst) {
	t_type* type = tconst->get_type();
	string name = chk_keyword(tconst->get_name());
	t_const_value* value = tconst->get_value();

	indent(f_consts_) << "const " << name << " = " << render_const_value(type, value, true);
	f_consts_ << endl;

	module_exports_ << "export " << name << " # const" << endl;
}

/**
 * Prints the value of a constant with the given type. Note that type checking
 * is NOT performed in this function as it is always run beforehand using the
 * validate_types method in main.cc
 */
string t_jl_generator::render_const_value(t_type* type, t_const_value* value, bool with_conversion) {
	type = get_true_type(type);
	std::ostringstream out;

	if (type->is_base_type()) {
		t_base_type::t_base tbase = ((t_base_type*) type)->get_base();
		switch (tbase) {
		case t_base_type::TYPE_STRING:
			if (((t_base_type*)type)->is_binary()) {
				out << "convert(Vector{UInt8}, \"" << get_escaped_string(value) << "\")";
			}
			else {
				out << "\"" << get_escaped_string(value) << "\"";
			}
			break;
		case t_base_type::TYPE_BOOL:
			out << (value->get_integer() > 0 ? "true" : "false");
			break;
		case t_base_type::TYPE_I8:
			if(with_conversion) {
				out << "UInt8(" << value->get_integer() << ")";
			}
			else {
				out << value->get_integer();
			}
			break;
		case t_base_type::TYPE_I16:
			if(with_conversion) {
				out << "Int16(" << value->get_integer() << ")";
			}
			else {
				out << value->get_integer();
			}
			break;
		case t_base_type::TYPE_I32:
			if(with_conversion) {
				out << "Int32(" << value->get_integer() << ")";
			}
			else {
				out << value->get_integer();
			}
			break;
		case t_base_type::TYPE_I64:
			if(with_conversion) {
				out << "Int64(" << value->get_integer() << ")";
			}
			else {
				out << value->get_integer();
			}
			break;
		case t_base_type::TYPE_DOUBLE:
			if(with_conversion) {
				out << "Float64(" << value->get_double() << ")";
			}
			else {
				out << value->get_double();
			}
			break;
		default:
			throw "compiler error: no const of base type " + t_base_type::t_base_name(tbase);
		}
	} else if (type->is_enum()) {
		out << "Int32(" << value->get_integer() << ")";
	} else if (type->is_struct() || type->is_xception()) {
		throw "compiler error: struct constants are not implemented yet";
	} else if (type->is_map()) {
	    t_type* ktype = ((t_map*)type)->get_key_type();
	    t_type* vtype = ((t_map*)type)->get_val_type();
	    out << "Dict(";
	    indent_up();
	    const map<t_const_value*, t_const_value*>& val = value->get_map();
	    map<t_const_value*, t_const_value*>::const_iterator v_iter;
	    bool first = true;
	    for (v_iter = val.begin(); v_iter != val.end(); ++v_iter) {
			if (first) {
		    	first = false;
		    } else {
				out << ", ";
		    }
	    	out << render_const_value(ktype, v_iter->first, true);
	    	out << " => ";
	    	out << render_const_value(vtype, v_iter->second, true);
	    }
	    indent_down();
	    indent(out) << ")";
	} else if (type->is_list() || type->is_set()) {
	    t_type* etype;
	    if (type->is_list()) {
	      etype = ((t_list*)type)->get_elem_type();
	    } else {
	      etype = ((t_set*)type)->get_elem_type();
	    }
	    if (type->is_set()) {
	      out << "union!(Set{" << julia_type(etype) << "}(), ";
	    }
	    out << julia_type(etype) << "[";
	    indent_up();
	    const vector<t_const_value*>& val = value->get_list();
	    vector<t_const_value*>::const_iterator v_iter;
	    bool first = true;
	    for (v_iter = val.begin(); v_iter != val.end(); ++v_iter) {
		    if (first) {
		    	first = false;
		    } else {
		    	out << ", ";
		    }
		    out << render_const_value(etype, *v_iter, false);
	    }
	    indent_down();
	    indent(out) << "]";
	    if (type->is_set()) {
	      out << ")";
	    }
	} else {
		throw "CANNOT GENERATE CONSTANT FOR TYPE: " + type->get_name();
	}

	return out.str();
}

/**
 * Generates a Julia type
 */
void t_jl_generator::generate_struct(t_struct* tstruct) {
	generate_jl_struct(f_types_, tstruct, false);
	module_exports_ << "export " << chk_keyword(tstruct->get_name()) << " # struct" << endl;
}

/**
 * Generates a struct definition for a thrift exception. Basically the same
 * as a struct but extends the Exception class.
 *
 * @param txception The struct definition
 */
void t_jl_generator::generate_xception(t_struct* txception) {
	generate_jl_struct(f_types_, txception, true);
	module_exports_ << "export " << chk_keyword(txception->get_name()) << " # exception" << endl;
}

/**
 * Generates a Julia composite type or exception type
 */
void t_jl_generator::generate_jl_struct(ofstream& out, t_struct* tstruct, bool is_exception, string suffix /*=""*/) {
	const vector<t_field*>& members = tstruct->get_members();
	vector<t_field*>::const_iterator m_iter;
	string struct_name = chk_keyword(tstruct->get_name()) + suffix;

	indent(out) << endl << "mutable struct " << struct_name;

	out << " <: Thrift.TMsg";
	if (is_exception) {
		out << " # Exception";
	}
	out << endl;
	indent_up();

	indent(out) << "meta::ThriftMeta" << endl;
	indent(out) << "values::Dict{Symbol,Any}" << endl;
	indent(out) << endl;
	indent(out) << "function " << struct_name << "(; kwargs...)" << endl;
	indent_up();
	indent(out) << "obj = new(__meta__" << struct_name << ", Dict{Symbol,Any}())" << endl;
	indent(out) << "values = obj.values" << endl;
	indent(out) << "symdict = obj.meta.symdict" << endl;
	indent(out) << "for nv in kwargs" << endl;
	indent_up();
	indent(out) << "fldname, fldval = nv" << endl;
	indent(out) << "fldtype = symdict[fldname].jtype" << endl;
	indent(out) << "(fldname in keys(symdict)) || error(string(typeof(obj), \" has no field with name \", fldname))" << endl;
	indent(out) << "values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)" << endl;
	indent_down();
	indent(out) << "end" << endl;
	indent(out) << "Thrift.setdefaultproperties!(obj)" << endl;
	indent(out) << "obj" << endl;
	indent_down();
	indent(out) << "end" << endl;
	indent_down();
	out << "end # mutable struct " << struct_name << endl;

	std::ostringstream fldall;
	std::ostringstream fldalltypes;
	std::ostringstream fldoptional;
	std::ostringstream fldnums;
	std::ostringstream flddefaults;
	std::ostringstream getconditions;
	bool need_fldnums = false;
	int default_fld_num = 1;
	for (m_iter = members.begin(); m_iter != members.end(); ++m_iter) {
		t_field* fld= (*m_iter);
		string fld_name = chk_keyword(fld->get_name());
		string fld_type = julia_type(fld->get_type());

		if(!fldall.str().empty()) (fldall << ",");
		fldall << ":" << fld_name;

		if(!fldalltypes.str().empty()) (fldalltypes << ",");
		fldalltypes << fld_type;

		if(getconditions.str().empty()) {
			getconditions << "  if name === ";
		}
		else {
			getconditions << "  elseif name === ";
		}
		getconditions << ":" << fld_name << endl << "    return (obj.values[name])::" << fld_type << endl;

		if (fld->get_req() == t_field::T_OPTIONAL) {
			if(!fldoptional.str().empty()) (fldoptional << ",");
			fldoptional << ":" << fld_name;
		}

		if(fld->get_key() != default_fld_num) {
			need_fldnums = true;
		}
		if(!fldnums.str().empty()) (fldnums << ",");
		fldnums << fld->get_key();

		if(fld->get_value() != NULL) {
			t_type* type = get_true_type(fld->get_type());
			if(!flddefaults.str().empty()) (flddefaults << ", ");
			flddefaults << ":" << fld_name << " => " << render_const_value(type, fld->get_value(), true);
		}
		default_fld_num++;
	}

	string fldns = need_fldnums ? fldnums.str() : "";
	out << endl << "const __meta__" << struct_name << " = meta(" << struct_name << "," << endl;
	indent_up();
	indent(out) << "Symbol[" << fldall.str() << "]," << endl;
	indent(out) << "Type[" << fldalltypes.str() << "]," << endl;
	indent(out) << "Symbol[" << fldoptional.str() << "]," << endl;
	indent(out) << "Int[" << fldns << "]," << endl;
	indent(out) << "Dict{Symbol,Any}(" << flddefaults.str() << ")" << endl;
	indent_down();
	out << ")" << endl;

	if(!getconditions.str().empty()) {
		getconditions << "  else" << endl << "    getfield(obj, name)" << endl << "  end";
		out << endl << "function Base.getproperty(obj::" << struct_name << ", name::Symbol)" << endl << getconditions.str() << endl << "end" << endl;
	}

	out << endl << "meta(::Type{" << struct_name << "}) = __meta__" << struct_name << endl << endl;
}

void t_jl_generator::add_to_module(t_service* tservice) {
	string f_service_name = program_dir_ + "/" + service_name_ + ".jl";

	module_includes_ << "include(\"" << service_name_ << ".jl\")" << endl;

	module_exports_ << "export " << service_name_ << "Processor, " << service_name_ << "Client, " << service_name_ << "ClientBase";
	vector<t_function*> functions = tservice->get_functions();
	vector<t_function*>::iterator f_iter;
	for (f_iter = functions.begin(); f_iter != functions.end(); ++f_iter) {
		module_exports_ << ", " << chk_keyword((*f_iter)->get_name());
	}
	module_exports_ << " # service " << service_name_ << endl;
}

void t_jl_generator::generate_service_processor(t_service* tservice) {
	indent(f_service_) << "# Processor for " << service_name_ << " service (to be used in server implementation)" << endl;
	f_service_ << "mutable struct " << service_name_ << "Processor <: TProcessor" << endl;
	indent_up();
	indent(f_service_) << "tp::ThriftProcessor" << endl;
	indent(f_service_) << "function " << service_name_ << "Processor()" << endl;
	indent_up();
	indent(f_service_) << "p = new(ThriftProcessor())" << endl;

	vector<t_function*> functions = tservice->get_functions();
	vector<t_function*>::iterator f_iter;
	for (f_iter = functions.begin(); f_iter != functions.end(); ++f_iter) {
		t_function* tfunction = (*f_iter);
		string fname = chk_keyword(tfunction->get_name());
		string result_type = tfunction->is_oneway() ? "Nothing" : (fname + "_result_" + service_name_);
		string args_type = (fname + "_args_" + service_name_);

		indent(f_service_) << "handle(p.tp, ThriftHandler(\"" << fname << "\", _" << fname << ", " << args_type << ", " << result_type << "))" << endl;
	}

	t_service* extends_service = tservice->get_extends();
	if (extends_service != NULL) {
		string extends_service_name = chk_keyword(extends_service->get_name());
		indent(f_service_) << "extend(p.tp, " << extends_service_name << "Processor().tp) # using " << extends_service_name << endl;
	}

	indent(f_service_) << "p" << endl;
	indent_down();
	indent(f_service_) << "end" << endl;
	indent_down();
	f_service_ << "end # mutable struct " << service_name_ << "Processor" << endl;

	for (f_iter = functions.begin(); f_iter != functions.end(); ++f_iter) {
		t_function* tfunction = (*f_iter);
		t_struct* arglist = tfunction->get_arglist();
		string fname = chk_keyword(tfunction->get_name());
		t_type* ttype = tfunction->get_returntype();
		t_struct* xceptions = tfunction->get_xceptions();
		bool has_xceptions = !xceptions->get_members().empty();
		bool oneway = tfunction->is_oneway();
		string args_type = (fname + "_args_" + service_name_);
		string result_type = tfunction->is_oneway() ? "Nothing" : (fname + "_result_" + service_name_);

		if(has_xceptions) {
			indent(f_service_) << "function _" << fname << "(inp::" << args_type << ")" << endl;
			indent_up();
			indent(f_service_) << "try" << endl;
			indent_up();

			if(!ttype->is_void()) {
				indent(f_service_) << "result = " << fname << "(";
			}
			else {
				indent(f_service_) << fname << "(";
			}

			const vector<t_field*>& members = arglist->get_members();
			vector<t_field*>::const_iterator m_iter;
			bool first = true;
			for (m_iter = members.begin(); m_iter != members.end(); ++m_iter) {
				if (first) {
					first = false;
				} else {
					f_service_ << ", ";
				}
				t_field* fld= (*m_iter);
				f_service_ << "inp." << chk_keyword(fld->get_name());
			}
			f_service_ << ")" << endl;
			if(oneway) {
				indent(f_service_) << "return" << endl;
			}
			else if(!ttype->is_void()) {
				indent(f_service_) << "return " << result_type << "(;success=result)" << endl;
			}
			else {
				indent(f_service_) << "return " << result_type << "()" << endl;
			}
			indent_down();
			indent(f_service_) << "catch ex" << endl;
			indent_up();

			if(oneway) {
				indent(f_service_) << "// ignore exceptions in oneway functions" << endl;
			}
			else {
				indent(f_service_) << "exret = " << result_type << "()" << endl;

				const vector<t_field*>& xmembers = xceptions->get_members();
				vector<t_field*>::const_iterator x_iter;
				for (x_iter = xmembers.begin(); x_iter != xmembers.end(); ++x_iter) {
					t_field* fld= (*x_iter);
					indent(f_service_) << "isa(ex, " << julia_type(fld->get_type()) << ") && (exret." << chk_keyword(fld->get_name()) << " = ex; return exret)" << endl;
				}

				indent(f_service_) << "rethrow()" << endl;
			}
			indent_down();
			indent(f_service_) << "end # try" << endl;
			indent_down();
			indent(f_service_) << "end #function _" << fname << endl;
		}
		else if(!ttype->is_void() && !oneway) {
			indent(f_service_) << "_" << fname << "(inp::" << args_type << ") = " << result_type << "(; success=" << fname << "(";

			const vector<t_field*>& members = arglist->get_members();
			vector<t_field*>::const_iterator m_iter;
			bool first = true;
			for (m_iter = members.begin(); m_iter != members.end(); ++m_iter) {
				if (first) {
					first = false;
				} else {
					f_service_ << ", ";
				}
				t_field* fld= (*m_iter);
				f_service_ << "inp." << chk_keyword(fld->get_name());
			}
			f_service_ << "))" << endl;
		}
		else if(!ttype->is_void() && oneway) {
			indent(f_service_) << "_" << fname << "(inp::" << args_type << ") = (" << fname << "(";

			const vector<t_field*>& members = arglist->get_members();
			vector<t_field*>::const_iterator m_iter;
			bool first = true;
			for (m_iter = members.begin(); m_iter != members.end(); ++m_iter) {
				if (first) {
					first = false;
				} else {
					f_service_ << ", ";
				}
				t_field* fld= (*m_iter);
				f_service_ << "inp." << chk_keyword(fld->get_name());
			}
			f_service_ << "); nothing)" << endl;
		}
		else {
			if(oneway) {
				indent(f_service_) << "_" << fname << "(inp::" << args_type << ") = (" << fname << "(); " << "nothing)" << endl;
			}
			else {
				indent(f_service_) << "_" << fname << "(inp::" << args_type << ") = (" << fname << "(); " << result_type << "())" << endl;
			}
		}
	}

	f_service_ << "process(p::" << service_name_ << "Processor, inp::TProtocol, outp::TProtocol) = process(p.tp, inp, outp)" << endl;
	f_service_ << "distribute(p::" << service_name_ << "Processor) = distribute(p.tp)" << endl;
}

void t_jl_generator::generate_service_user_function_comments(t_service* tservice) {
	f_service_ << "# Server side methods to be defined by user:" << endl;
	vector<t_function*> functions = tservice->get_functions();
	vector<t_function*>::iterator f_iter;
	for (f_iter = functions.begin(); f_iter != functions.end(); ++f_iter) {
		t_function* tfunction = (*f_iter);
		t_type* ttype = tfunction->get_returntype();
		t_struct* arglist = tfunction->get_arglist();
		string fname = chk_keyword(tfunction->get_name());
		t_struct* xceptions = tfunction->get_xceptions();
		bool has_xceptions = !xceptions->get_members().empty();

		f_service_ << "# function " << fname << "(";

		const vector<t_field*>& members = arglist->get_members();
		vector<t_field*>::const_iterator m_iter;
		bool first = true;
		for (m_iter = members.begin(); m_iter != members.end(); ++m_iter) {
			if (first) {
				first = false;
			} else {
				f_service_ << ", ";
			}
			t_field* fld= (*m_iter);
			f_service_ << chk_keyword(fld->get_name()) << "::" << julia_type(fld->get_type());
		}
		f_service_ << ")" << endl;
		f_service_ << "#     # returns " << (ttype->is_void() ? "nothing" : julia_type(ttype)) << endl;
		if(has_xceptions) {
			const vector<t_field*>& xmembers = xceptions->get_members();
			vector<t_field*>::const_iterator x_iter;
			for (x_iter = xmembers.begin(); x_iter != xmembers.end(); ++x_iter) {
				t_field* fld= (*x_iter);
				f_service_ << "#     # throws " << chk_keyword(fld->get_name()) << "::" << julia_type(fld->get_type()) << endl;
			}
		}
	}
}

void t_jl_generator::generate_service_client(t_service* tservice) {
	f_service_ << "# Client implementation for " << service_name_ << " service" << endl;
	string service_name_client = (service_name_ + "Client");

	t_service* extends_service = tservice->get_extends();
	if (extends_service == NULL) {
		f_types_ << endl << "abstract type " << service_name_client << "Base end" << endl;
	}
	else {
		f_types_ << endl << "const " << service_name_client << "Base = " << chk_keyword(extends_service->get_name()) << "ClientBase" << endl;
	}

	f_service_ << "mutable struct " << service_name_client << " <: " << service_name_client << "Base" << endl;
	indent_up();
	indent(f_service_) << "p::TProtocol" << endl;
	indent(f_service_) << "seqid::Int32" << endl;
	indent(f_service_) << service_name_client << "(p::TProtocol) = new(p, 0)" << endl;
	indent_down();
	f_service_ << "end # mutable struct " << service_name_client << endl << endl;

	vector<t_function*> functions = tservice->get_functions();
	vector<t_function*>::iterator f_iter;
	for (f_iter = functions.begin(); f_iter != functions.end(); ++f_iter) {
		t_function* tfunction = (*f_iter);
		bool oneway = tfunction->is_oneway();
		t_type* ttype = tfunction->get_returntype();
		t_struct* arglist = tfunction->get_arglist();
		string fname = chk_keyword(tfunction->get_name());
		t_struct* xceptions = tfunction->get_xceptions();
		bool has_xceptions = !xceptions->get_members().empty();
		string args_type = (fname + "_args_" + service_name_);
		string result_type = (fname + "_result_" + service_name_);

		f_service_ << "# Client callable method for " << fname << endl;
		f_service_ << "function " << fname << "(c::" << service_name_client << "Base";

		const vector<t_field*>& members = arglist->get_members();
		vector<t_field*>::const_iterator m_iter;
		for (m_iter = members.begin(); m_iter != members.end(); ++m_iter) {
			t_field* fld= (*m_iter);
			f_service_ << ", " << chk_keyword(fld->get_name()) << "::" << julia_type(fld->get_type());
		}
		f_service_ << ")" << endl;
		indent_up();

		indent(f_service_) << "p = c.p" << endl;
		indent(f_service_) << "c.seqid = (c.seqid < (2^31-1)) ? (c.seqid+1) : 0" << endl;
		indent(f_service_) << "Thrift.writeMessageBegin(p, \"" << fname << "\", Thrift.MessageType." << (oneway ? "ONEWAY" : "CALL") << ", c.seqid)" << endl;
		indent(f_service_) << "inp = " << args_type << "()" << endl;

		for (m_iter = members.begin(); m_iter != members.end(); ++m_iter) {
			t_field* fld= (*m_iter);
			string fld_name = chk_keyword(fld->get_name());
			indent(f_service_) << "inp." << fld_name << " = " << fld_name << endl;
		}

		indent(f_service_) << "Thrift.write(p, inp)" << endl;
		indent(f_service_) << "Thrift.writeMessageEnd(p)" << endl;
		indent(f_service_) << "Thrift.flush(p.t)" << endl;
		indent(f_service_) << endl;

		if(!oneway) {
			indent(f_service_) << "(fname, mtype, rseqid) = Thrift.readMessageBegin(p)" << endl;
			indent(f_service_) << "(mtype == Thrift.MessageType.EXCEPTION) && throw(Thrift.read(p, Thrift.TApplicationException()))" << endl;
			indent(f_service_) << "outp = Thrift.read(p, " << result_type << "())" << endl;
			indent(f_service_) << "Thrift.readMessageEnd(p)" << endl;
			indent(f_service_) << "(rseqid != c.seqid) && throw(Thrift.TApplicationException(; typ=ApplicationExceptionType.BAD_SEQUENCE_ID, message=\"response sequence id $rseqid did not match request ($(c.seqid))\"))" << endl;

			if(has_xceptions) {
				const vector<t_field*>& xmembers = xceptions->get_members();
				vector<t_field*>::const_iterator x_iter;
				for (x_iter = xmembers.begin(); x_iter != xmembers.end(); ++x_iter) {
					t_field* fld= (*x_iter);
					string fld_name = chk_keyword(fld->get_name());
					indent(f_service_) << "hasproperty(outp, :" << fld_name << ") && throw(outp." << fld_name << ")" << endl;
				}
			}
		}

		if (ttype->is_void()) {
			indent(f_service_) << "nothing" << endl;
		}
		else {
			indent(f_service_) << "hasproperty(outp, :success) && (return outp.success)" << endl;
			indent(f_service_) << "throw(Thrift.TApplicationException(; typ=Thrift.ApplicationExceptionType.MISSING_RESULT, message=\"retrieve failed: unknown result\"))" << endl;
		}
		indent_down();
		f_service_ << "end # function " << fname << endl << endl;
	}
}


void t_jl_generator::generate_service_args_and_returns(t_service* tservice) {
	vector<t_function*> functions = tservice->get_functions();
	vector<t_function*>::iterator f_iter;
	for (f_iter = functions.begin(); f_iter != functions.end(); ++f_iter) {
		t_function* tfunction = (*f_iter);
		string function_name = chk_keyword(tfunction->get_name());
		t_type* ttype = tfunction->get_returntype();
		t_struct* arglist = tfunction->get_arglist();
		t_struct* xceptions = tfunction->get_xceptions();
		bool has_xceptions = !xceptions->get_members().empty();

		indent(f_service_) << "# types encapsulating arguments and return values of method " << function_name << endl;
		generate_jl_struct(f_service_, arglist, false, "_" + service_name_);
		f_service_ << endl;

		if(tfunction->is_oneway()) {
			continue;
		}

		t_struct* result_success = new t_struct(program_, function_name + "_result");
		t_field* success_field = NULL;
		if(!ttype->is_void()) {
			success_field = new t_field(ttype, "success");
			result_success->append(success_field);
		}
		if(has_xceptions) {
			const vector<t_field*>& xmembers = xceptions->get_members();
			vector<t_field*>::const_iterator x_iter;
			int xid = 1;
			for (x_iter = xmembers.begin(); x_iter != xmembers.end(); ++x_iter) {
				t_field* fld = (*x_iter);
				result_success->append(fld);
			}
		}
		generate_jl_struct(f_service_, result_success, false, "_" + service_name_);
		f_service_ << endl;
		if(success_field != NULL) {
			free(success_field);
		}
		free(result_success);
	}
}

/**
 * Generates a thrift service.
 *
 * @param tservice The service definition
 */
void t_jl_generator::generate_service(t_service* tservice) {
	string f_service_name = program_dir_ + "/" + service_name_ + ".jl";

	f_service_.open(f_service_name.c_str());
	f_service_ << jl_autogen_comment() << endl;

	t_service* extends_service = tservice->get_extends();
	if (extends_service != NULL) {
		f_service_ << "# service extends " << chk_keyword(extends_service->get_name()) << endl;
	}

	f_service_ << endl << endl;
	generate_service_args_and_returns(tservice);
	f_service_ << endl << endl;
	generate_service_processor(tservice);
	f_service_ << endl << endl;
	generate_service_user_function_comments(tservice);
	f_service_ << endl << endl;
	generate_service_client(tservice);

	// accumulate exports and includes for module file
	add_to_module(tservice);

	// Close service file
	f_service_.close();
}

THRIFT_REGISTER_GENERATOR(jl, "Julia", "")
