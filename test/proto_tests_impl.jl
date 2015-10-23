
function test_hello(name::AbstractString)
    num_greetings = length(GREETINGS)
    rand_greeting = floor(Int, (num_greetings-1)*rand()) + 1
    string(GREETINGS[rand_greeting], " ", name)
end

function test_exception()
    ex = thriftbuild(InvalidOperation, Dict(:oper => "test_exception"))
    throw(ex)
end

function test_oneway()
    println("server received oneway method call")
end

function ping()
    println("server received ping method call")
end

function test_enum(enum_val::Int32)
    if enum_val == TestEnum.ONE
        return TestEnum.TEN
    elseif enum_val == TestEnum.TWO
        return TestEnum.TWENTY
    end
    ex = thriftbuild(InvalidOperation, Dict(:oper => "test_enum"))
    throw(ex)
end

function _test_types(types)
    set_field!(types, :bool_val,     !get_field(types, :bool_val))
    set_field!(types, :byte_val,     UInt8(get_field(types, :byte_val) + 1))
    set_field!(types, :i16_val,      Int16(get_field(types, :i16_val) + 1))
    set_field!(types, :i32_val,      Int32(get_field(types, :i32_val) + 1))
    set_field!(types, :i64_val,      Int64(get_field(types, :i64_val) + 1))
    set_field!(types, :double_val,   -(get_field(types, :double_val)))
    set_field!(types, :string_val,   uppercase(get_field(types, :string_val)))

    d = Dict{Int32,Int16}()
    for (k,v) in get_field(types, :map_val)
        d[k] = Int16(2*v)
    end
    set_field!(types, :map_val, d)

    l = Int16[]
    for v in get_field(types, :list_val)
        push!(l, Int16(v+10))
    end
    set_field!(types, :list_val, l)

    s = Set{UInt8}()
    for v in get_field(types, :set_val)
        push!(s, UInt8(v+10))
    end
    set_field!(types, :set_val, s)
    types
end

test_types(types::AllTypes) = _test_types(types)
test_types_default(types::AllTypesDefault) = _test_types(types)

