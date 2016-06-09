<%doc>
Copyright (c) 2015 Thomson Reuters

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
</%doc>
<%inherit file="base.mako" />
<%namespace name="base" file="base.mako" />
<%def name='propertyDecl(variableDef)'>\
<%
varType = base.attr.convertType(variableDef)
%>\
    ${varType} ${variableDef.name};\
</%def>\
<%def name='enumDecl(enumDef)'>\
    enum class ${enumDef.name} {
% for v in enumDef.values:
        ${ v[0].title() + v[1:] },
% endfor
    };
    static std::string ${enumDef.plain_name}_to_string(const ${enumDef.name} &val);
    static ${enumDef.name} string_to_${enumDef.plain_name}(const std::string &key);
</%def>\
<%block name="code">
#pragma once

<%
has_optionals = any([v.isOptional for v in classDef.variable_defs])
has_variants = any([v.isVariant for v in classDef.variable_defs])
%>\
% if has_optionals:
#include <boost/optional.hpp>
% endif
% if has_variants:
#include <boost/variant.hpp>
% endif
#include <json11/json11.hpp>
#include <string>
#include <unordered_map>
#include <vector>

% if classDef.dependencies:
% for dep in classDef.dependencies:
#include "${dep}"
% endfor
% endif
% if include_files:
% for include_file in include_files:
#include "${include_file}"
% endfor
% endif

% for ns in namespace.split('::'):
namespace ${ns} {
% endfor
<%
class_name = classDef.name
superClass = classDef.superClasses[0] if len(classDef.superClasses) else None
%>
class ${class_name + ((' : public ' + superClass) if superClass else '')}
{
public:
    ALIAS_PTR_TYPES(${class_name});

    // TODO: We should eventually make the destructor private to ensure we
    //       only allocate instances of this class using std::make_shared().
    ~${class_name}() {}

% for e in classDef.enum_defs:
${enumDecl(e)}
% endfor
% for v in classDef.variable_defs:
${propertyDecl(v)}
% if v.isVariant:
<%
variant_type_return = "boost::optional<std::string>" if v.isOptional and not v.isArray else "std::string"
%>\
% if v.isArray:
    ${variant_type_return} ${v.name}ValueType(const ${base.attr.arrayItemType(v)}& ${v.name}Value) const;
% else:
    ${variant_type_return} ${v.name}Type() const;
% endif
% endif
% endfor

public:
    ${class_name}() = default;
    ${class_name}(const ${class_name} &other) = default;
    ${class_name}(const json11::Json &value);

    /// Returns true if the contents of this object match the schema
    bool is_valid() const;
    /// Throws if the contents of this object do not match the schema
    void check_valid() const;

    json11::Json to_json() const;
% if classDef.has_pattern_properties:
<%
assert(len(classDef.pattern_properties) == 1)
pattern, variableDef = classDef.pattern_properties[0]
varType = base.attr.convertType(variableDef)
acceptsAnyKey = (pattern == '.*')
%>
    // Get or set additional properties. Like std::map, this will
    // insert a default constructed value if no value exists.
% if not acceptsAnyKey:
    // It will also throw if the property key doesn't match the
    // allowed pattern "${pattern}".
% endif
    ${varType}& operator[](const std::string &key);

    // Test to see if the property key value is valid. It must not
    // match the name of an existing property\
% if acceptsAnyKey:
.
% else:
, and must match the pattern "${pattern}".
% endif
    static bool is_valid_key(const std::string &key);

    // Test to see if the property is set.
    bool has_property(const std::string &key) const;

    // Get a property value if set, or return a default value.
% if not acceptsAnyKey:
    // It will return the default value if the property key doesn't
    // match the allowed pattern "${pattern}".
% endif
    const ${varType}& get_property_or(const std::string &key, const ${varType} &defaultValue) const;

    // Get a const ref to the dynamic property map, for iteration.
    // Writes still must go through operator[], so that property patterns can be validated.
    const std::map<std::string, ${varType}>& dynamic_properties() const {
        return _patternProperties;
    }

private:
    static bool is_intrinsic_key(const std::string &key);
    std::map<std::string, ${varType}> _patternProperties;
% endif
}; // class ${class_name}

% for ns in reversed(namespace.split('::')):
} // namespace ${ns}
% endfor
</%block>
