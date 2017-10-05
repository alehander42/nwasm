import wasmast, wasmleb128
from math import ceil,log2

proc newWANode*(op:WasmOpKind):WasmNode =
  WasmNode(kind:op, sons: newSeq[WasmNode]())

proc newUnaryOp*(op:WasmOpKind,a:WasmNode):WasmNode =
  # assert op.kind == unaryOp
  result = newWANode(op)
  result.a = a

proc newBinaryOp*(op:WasmOpKind,a,b:WasmNode):WasmNode =
  assert(op in BinaryOp, $op)
  result = newWANode(op)
  result.a = a
  result.b = b

proc newCall*(idx:int,args:varargs[WasmNode], isImport: bool = false):WasmNode =
  result = newWANode(woCall)
  result.funcIndex = idx
  result.isImport = isImport
  result.sons = @args

proc newLoad*(op:WasmOpKind, offset, alignment: Natural=1,idx:WasmNode):WasmNode =
  assert op in MemLoad
  result = newWANode(op)
  result.align = ceil(log2(abs(alignment).float)).int
  result.offset = offset
  result.a = idx

proc newGet*(op:WasmOpKind,idx:int):WasmNode =
  assert op in {woGetGlobal,woGetLocal}
  result = newWANode(op)
  result.index = idx
proc newSet*(op:WasmOpKind,idx:int, what:WasmNode):WasmNode =
  assert op in {woSetLocal,woSetGlobal}
  result = newWANode(op)
  result.index = idx
  result.a = what

proc newReturn*(what:WasmNode): WasmNode {.inline.}=
  newUnaryOp(woReturn, what)

proc newConst*[T:int32|int64|float32|float64](val:T):WasmNode =
  when T is int32 or T is int:
    result = newWANode(constI32)
    result.intVal = val
  elif T is int64:
    result = newWANode(constI64)
    result.intVal = val
  elif T is float32:
    result = newWANode(constF32)
    result.floatVal = val
  elif T is float64:
    result = newWANode(constF64)
    result.floatVal = val
  else:
    # other branches shouldn't be possible
    assert(false,"Impossible type")

  #[when T is SomeUnsignedInt:
    result.value = val.int32.unsignedLeb128
  elif T is SomeSignedInt:
    result.value = val.int32.signedLeb128
  elif T is bytes:
    result.value = val
  else:
    result.value = toBytes(val)
  ]#

proc newStore*(kind:WasmOpKind, what: varargs[WasmNode],offset: int32,index:WasmNode=newConst(0'i32)): WasmNode =
  assert kind in MemStore, $kind
  result = newWANode(kind)
  result.sons.add( index )
  result.sons.add( what ) 
  #align: ceil(log2(align.float)).int,
  result.offset = offset

proc newEnd*():WasmNode {.inline.} = newWANode(woEnd) 

proc newWhileLoop*(cond:WasmNode, inner:WasmNode):WasmNode =
  # https://github.com/rhmoller/wasm-by-hand/blob/master/src/controlflow.wat
  result = newWANode(woBlock)
  result.sig = vtNone
  var 
    brkcond = newWANode(woBrIf)  
    brret = newWANode(woBr)
    loop = newWANode(woLoop)
  
  brkcond.sons.add(newUnaryOp(itEqz32, cond))
  brkcond.relativeDepth = 1

  brret.relativeDepth = 0

  loop.sig = ltPseudo
  loop.sons.add( [brkcond, inner, brret, newEnd()] )

  result.sons.add([loop,newEnd()])

proc newElse*(then:WasmNode):WasmNode =
  result = newWANode(woElse)
  result.a = then
  
proc newIf*(cond:WasmNode, then:WasmNode #[, other:WasmNode=nil]#):WasmNode =
  result = newWANode(woIf)
  result.sig = ltPseudo
  result.a = cond
  result.b = then
  #ifstmt.sons.add(then)
  #if other!=nil: # else block
  #  ifstmt.sons.add(newElse(other))
  #ifstmt.sons.add(newEnd())
  #result.sons.add(ifstmt)
