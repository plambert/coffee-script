# Basic array comprehensions.
nums    = (n * n for n in [1, 2, 3] when n & 1)
results = (n * 2 for n in nums)

ok results.join(',') is '2,18'


# Basic object comprehensions.
obj   = {one: 1, two: 2, three: 3}
names = (prop + '!' for prop of obj)
odds  = (prop + '!' for prop, value of obj when value & 1)

ok names.join(' ') is "one! two! three!"
ok odds.join(' ')  is "one! three!"


# Basic range comprehensions.
nums = (i * 3 for i in [1..3])

negs = (x for x in [-20..-5*2])
negs = negs[0..2]

result = nums.concat(negs).join(', ')

ok result is '3, 6, 9, -20, -19, -18'


# With range comprehensions, you can loop in steps.
results = (x for x in [0...15] by 5)
ok results.join(' ') is '0 5 10'

results = (x for x in [0..100] by 10)
ok results.join(' ') is '0 10 20 30 40 50 60 70 80 90 100'


# And can loop downwards, with a negative step.
results = (x for x in [5..1])

ok results.join(' ') is '5 4 3 2 1'
ok results.join(' ') is [(10-5)..(-2+3)].join(' ')

results = (x for x in [10..1])
ok results.join(' ') is [10..1].join(' ')

results = (x for x in [10...0] by -2)
ok results.join(' ') is [10, 8, 6, 4, 2].join(' ')


# Range comprehension gymnastics.
eq "#{i for i in [5..1]}", '5,4,3,2,1'
eq "#{i for i in [5..-5] by -5}", '5,0,-5'

a = 6
b = 0
c = -2

eq "#{i for i in [a..b]}", '6,5,4,3,2,1,0'
eq "#{i for i in [a..b] by c}", '6,4,2,0'


# Multiline array comprehension with filter.
evens = for num in [1, 2, 3, 4, 5, 6] when not (num & 1)
           num *= -1
           num -= 2
           num * -1
eq evens + '', '4,6,8'


# The in operator still works, standalone.
ok 2 of evens

# all isn't reserved.
all = 1


# Ensure that the closure wrapper preserves local variables.
obj = {}

for method in ['one', 'two', 'three']
  obj[method] = ->
    "I'm " + method

ok obj.one()   is "I'm one"
ok obj.two()   is "I'm two"
ok obj.three() is "I'm three"

i = 0
for i in [1..3]
  -> 'func'
  break if false
ok i is 4


# Ensure that local variables are closed over for range comprehensions.
funcs = for i in [1..3]
  -> -i

ok (func() for func in funcs).join(' ') is '-1 -2 -3'
ok i is 4


# Even when referenced in the filter.
list = ['one', 'two', 'three']

methods = for num, i in list when num isnt 'two' and i isnt 1
  -> num + ' ' + i

ok methods.length is 2
ok methods[0]() is 'one 0'
ok methods[1]() is 'three 2'


# Even a convoluted one.
funcs = []

for i in [1..3]
  x = i * 2
  ((z)->
    funcs.push -> z + ' ' + i
  )(x)

ok (func() for func in funcs).join(', ') is '2 1, 4 2, 6 3'

funcs = []

results = for i in [1..3]
  z = (x * 3 for x in [1..i])
  ((a, b, c) -> [a, b, c].join(' ')).apply this, z

ok results.join(', ') is '3  , 3 6 , 3 6 9'


# Naked ranges are expanded into arrays.
array = [0..10]
ok(num % 2 is 0 for num in array by 2)


# Nested comprehensions.
multiLiner =
  for x in [3..5]
    for y in [3..5]
      [x, y]

singleLiner =
  (([x, y] for y in [3..5]) for x in [3..5])

ok multiLiner.length is singleLiner.length
ok 5 is multiLiner[2][2][1]
ok 5 is singleLiner[2][2][1]


# Comprehensions within parentheses.
result = null
store = (obj) -> result = obj
store (x * 2 for x in [3, 2, 1])

ok result.join(' ') is '6 4 2'


# Closure-wrapped comprehensions that refer to the "arguments" object.
expr = ->
  result = (item * item for item in arguments)

ok expr(2, 4, 8).join(' ') is '4 16 64'


# Fast object comprehensions over all properties, including prototypal ones.
class Cat
  constructor: -> @name = 'Whiskers'
  breed: 'tabby'
  hair:  'cream'

whiskers = new Cat
own = (value for own key, value of whiskers)
all = (value for key, value of whiskers)

ok own.join(' ') is 'Whiskers'
ok all.sort().join(' ') is 'Whiskers cream tabby'


# Optimized range comprehensions.
exxes = ('x' for [0...10])
ok exxes.join(' ') is 'x x x x x x x x x x'


# Comprehensions safely redeclare parameters if they're not present in closest
# scope.
rule = (x) -> x

learn = ->
  rule for rule in [1, 2, 3]

ok learn().join(' ') is '1 2 3'

ok rule(101) is 101

f = -> [-> ok no, 'should cache source']
ok yes for k of [f] = f()


# Lenient on pure statements not trying to reach out of the closure
val = for i in [1]
  for j in [] then break
  i
ok val[0] is i


# Comprehensions only wrap their last line in a closure, allowing other lines
# to have pure expressions in them.
func = -> for i in [1]
  break if i is 2
  j for j in [1]

ok func()[0][0] is 1

i = 6
odds = while i--
  continue unless i & 1
  i

ok odds.join(', ') is '5, 3, 1'


# Nested shared scopes.
foo = ->
  for i in [0..7]
    for j in [0..7]
      -> i + j

eq foo()[3][4](), 7