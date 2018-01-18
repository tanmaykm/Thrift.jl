
include "srvcctrl.thrift"

const list<string> GREETINGS = [
    "Hello",        # English
    "你好",         # Chinese
    "Hola",         # Spanish 
    "Kumusta Ka",   # Filipino 
    "Terve",        # Finnish 
    "Bonjour",      # French 
    "Ciao",         # Italian 
    "Hallo",        # German 
    "Tungjatjeta",  # Albanian 
    "Shalom",       # Hebrew 
    "Sveikas",      # Lithuanian 
    "Haa",          # Comanche 
    "Apa Kabar",    # Bahasa Indonesia 
    "Kako Si",      # Croation 
    "Ahoj",         # Czech 
    "Szvervusz",    # Hungarian 
    "Konnichiwa",   # Japanese 
    "Labdien",      # Latvian 
    "Talofa",       # Samoan 
    "Hujambo"       # Swahili
]

exception InvalidOperation {
  1: string oper
}

enum TestEnum {
    ONE = 1,
    TEN = 10,
    TWO = 2,
    TWENTY = 20
}

struct AllTypesDefault {
    1: optional bool bool_val = true,
    2: optional i8 byte_val = 1,
    3: optional i16 i16_val = 10,
    4: optional i32 i32_val = 20,
    5: optional i64 i64_val = 30,
    6: optional double double_val = 10.10,
    7: optional string string_val = "hello world",
    8: optional map<i32,i16> map_val = {1:10, 2:20},
    9: optional list<i16> list_val = [1,2,3],
    10: optional set<i8> set_val = [3,4,5]
}

struct AllTypes {
    1: bool bool_val,
    2: i8 byte_val,
    3: i16 i16_val,
    4: i32 i32_val,
    5: i64 i64_val,
    6: double double_val,
    7: string string_val,
    8: map<i32,i16> map_val,
    9: list<i16> list_val,
    10: set<i8> set_val
}

service ProtoTests extends srvcctrl.ServiceControl {
    string test_hello(1:string name),
    void test_exception() throws (1:InvalidOperation ouch),
    oneway void test_oneway(),
    void ping(),
    TestEnum test_enum(1:TestEnum enum_val),
    AllTypes test_types(1:AllTypes types),
    AllTypesDefault test_types_default(1:AllTypesDefault types)
}

