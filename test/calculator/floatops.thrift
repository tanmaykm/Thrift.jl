
const list<string> FLOAT_OPS = ["+", "-", "*"]

exception InvalidFloatOperation {
  1: string oper
}

service FloatCalc {
    double float_calculate(1:string oper, 2:double p1, 3:double p2) throws (1:InvalidFloatOperation ouch)
}

