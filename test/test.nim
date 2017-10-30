#[proc log[T](x:T) {.header:"glue", importc:"log".}

var a = 12.3
proc d*(a:float = 12.0):float =
  var x = [a+12.4, a]
  x[0]

log d()
log a]#
proc log[T](x:T) {.header:"glue", importc:"log".}
proc check[T](x:T) {.header:"glue", importc:"assert".}
var ar  = [0.0'f32,1,2]
var b = 1..12
type R = object
  a: range[1..12]
log ar is array
log ar[1] is float32
log 10 in b
log -1 in b
var r = R(a:3)
log r of R
