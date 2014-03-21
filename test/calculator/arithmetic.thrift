
include "floatops.thrift"

const list<string> OPS = ["+", "-", "*", "^"]

exception InvalidOperation {
  1: string oper
}

service Calc extends floatops.FloatCalc {
    i32 calculate(1:string oper, 2:i32 p1, 3:i32 p2) throws (1:InvalidOperation ouch)
}

