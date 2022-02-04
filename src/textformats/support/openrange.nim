##
## Range of integer, in which one of the two ends
## can be undefined, with the meaning +/- Infinite
##

import strformat
import options

const
  OpenrangeInfStr* = "Inf"
  OpenrangeNegInfStr* = "-Inf"

type
  MemberT = Natural or int64 or uint64
  OpenRange*[T: MemberT] = object
    l: T
    h: T
    has_low*: bool
    has_high*: bool

proc newOpenRange*[T: MemberT](l: Option[T] or T,
                               h: Option[T] or T): OpenRange[T] =
  when l is T:
    result.l = l
    result.has_low = true
  else:
    if l.is_some:
      result.l = l.unsafe_get
      result.has_low = true
    else:
      result.has_low = false
  when h is T:
    result.h = h
    result.has_high = true
  else:
    if h.is_some:
      result.h = h.unsafe_get
      result.has_high = true
    else:
      result.has_high = false

#
# note on converted to_openrage:
# using "T or Option[T]" in the converter tuple elements type does not work
#

converter to_openrange*[T: MemberT](r: tuple[l: T, h: T]):
  OpenRange[T] = newOpenRange(r.l, r.h)

converter to_openrange*[T: MemberT](r: tuple[l: Option[T], h: T]):
  OpenRange[T] = newOpenRange(r.l, r.h)

converter to_openrange*[T: MemberT](r: tuple[l: T, h: Option[T]]):
  OpenRange[T] = newOpenRange(r.l, r.h)

converter to_openrange*[T: MemberT](r: tuple[l: Option[T], h: Option[T]]):
  OpenRange[T] = newOpenRange(r.l, r.h)

proc low*[T](self: OpenRange[T]): T =
  if self.has_low: self.l else: T.low

proc high*[T](self: OpenRange[T]): T =
  if self.has_high: self.h else: T.high

proc `low=`*[T](self: var OpenRange[T], i: T) =
  self.has_low = true
  self.l = i

proc `low=`*[T](self: var OpenRange[T], i: Option[T]) =
  if i.is_none:
    self.has_low = false
  else:
    self.has_low = true
    self.l = i.unsafe_get

proc `high=`*[T](self: var OpenRange[T], i: T) =
  self.has_high = true
  self.h = i

proc `high=`*[T](self: var OpenRange[T], i: Option[T]) =
  if i.is_none:
    self.has_high = false
  else:
    self.has_high = true
    self.h = i.unsafe_get

proc lowstr*[T: MemberT](self: OpenRange[T]): string {.inline.} =
  if self.has_low: result = $self.l
  elif T.low == 0: result = "0"
  else: result = OpenrangeNegInfStr

proc highstr*[T: MemberT](self: OpenRange[T]): string {.inline.} =
  if self.has_high: result = $self.h
  else: result = OpenrangeInfStr

proc `$`*[T: MemberT](self: OpenRange[T]): string =
  "[" & self.lowstr() & ", " & self.highstr() & "]"

proc safe_inc_min*[T](self: var OpenRange[T]) =
  if self.has_low and self.l < T.high:
    self.l += 1.T

proc safe_dec_max*[T](self: var OpenRange[T]) =
  if self.has_high and self.h > T.low:
    self.h -= 1.T

proc contains*[T](self: OpenRange[T], i: T): bool =
  (not self.has_low or i >= self.l) and
  (not self.has_high or i <= self.h)

proc valid_min*[T](i: T, self: OpenRange[T]): bool =
  (not self.has_low or i >= self.l)

proc valid_max*[T](i: T, self: OpenRange[T]): bool =
  (not self.has_high or i <= self.h)

proc validate*(self: OpenRange) =
  if self.has_low and self.has_high and self.h < self.l:
    raise newException(ValueError,
            "Invalid range definition: 'low' value < 'high' value.\n" &
            &"- low: {self.lowstr}\n" &
            &"- high: {self.highstr}\n")

