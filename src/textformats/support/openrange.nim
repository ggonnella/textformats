##
## Range of integer, in which one of the two ends
## can be undefined, with the meaning +/- Infinite
##

#from options import is_some, unsafe_get, is_none, Option, none, some
import options
export options
import strformat

const
  OpenrangeInfStr* = "Inf"
  OpenrangeNegInfStr* = "-Inf"

type
  MemberT = Natural or int64 or uint64
  OpenRange*[T: MemberT] = object
    rmin*: Option[T]
    rmax*: Option[T]

#
# the nim `$` method applied to uint options seems to be buggy, therefore the
# minstr/maxstr methods currently convert to int (where maxstr will of course
# fail for an uint value > int.high)
#

proc lowstr*[T: MemberT](o: OpenRange[T]): string {.inline.} =
  if o.rmin.is_some:
    let val = o.rmin.unsafe_get
    result = $(val.int64)
  else:
    if o.low == 0: result = "0"
    else: result = OpenrangeNegInfStr

proc highstr*[T: MemberT](o: OpenRange[T]): string {.inline.} =
  if is_some[T](o.rmax):
    let val = o.rmax.unsafe_get
    result = $(val.int64)
  else: result = OpenrangeInfStr

proc `$`*[T: MemberT](o: OpenRange[T]): string =
  "[" & lowstr(o) & ", " & highstr(o) & "]"

proc safe_inc_min*[T](r: var OpenRange[T]) =
  if r.rmin.is_some and r.rmin.unsafe_get < T.high:
    r.rmin = (r.rmin.unsafe_get + 1.T).T.some

proc safe_dec_max*[T](r: var OpenRange[T]) =
  if r.rmax.is_some and r.rmax.unsafe_get > T.low:
    r.rmax = (r.rmax.unsafe_get - 1.T).T.some

proc low*[T](o: OpenRange[T]): T =
  if o.rmin.is_some: o.rmin.unsafe_get
  else: T.low

proc has_low*[T: MemberT](o: OpenRange[T]): bool =
  o.rmin.is_some

proc high*[T](o: OpenRange[T]): T =
  if o.rmax.is_some: o.rmax.unsafe_get
  else:
    when T is uint64: int64.high.uint64
    else: T.high

proc has_high*[T](o: OpenRange[T]): bool =
  o.rmax.is_some

template `<=`[T](i: T, rrmax: Option[T]): bool =
  (rrmax.is_none or i <= rrmax.unsafe_get)

template `>=`[T](i: T, rrmin: Option[T]): bool =
  (rrmin.is_none or i >= rrmin.unsafe_get)

proc contains*[T](r: OpenRange[T], i: T): bool =
  i >= r.rmin and i <= r.rmax

proc contains*(r: OpenRange[uint64], i: int64): bool =
  i.uint64 >= r.rmin and i.uint64 <= r.rmax

proc valid_min*[T](i: T, r: OpenRange[T]): bool=
  (r.rmin.is_none or i >= r.rmin.unsafe_get)

proc valid_max*[T](i: T, r: OpenRange[T]): bool =
  (r.rmax.is_none or i <= r.rmax.unsafe_get)

proc validate*(self: OpenRange) =
  if self.rmin.is_some and self.rmax.is_some and
      self.rmax.unsafe_get < self.rmin.unsafe_get:
    raise newException(ValueError,
            "Invalid range definition: 'max' value < 'min' value.\n" &
            &"- min: {self.lowstr}\n" &
            &"- max: {self.highstr}\n")

converter to_opt*[T: MemberT](i: T): Option[T] =
  i.some

converter to_openrange*[T: MemberT](
            r: tuple[rmin: T or Option[T],
                     rmax: T or Option[T]]): OpenRange[T] =
  when r.rmin is T: result.rmin = r.rmin.some
  else: result.rmin = r.rmin
  when r.rmax is T: result.rmax = r.rmax.some
  else: result.rmax = r.rmax

