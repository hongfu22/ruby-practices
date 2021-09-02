#!/usr/bin/env ruby

(1..20).each do |x|
  tmp = 
  if x % 3 == 0 && x % 5 == 0
      "FizzBuzz"
  elsif x % 3 == 0
      "Fizz"
  elsif x % 5 == 0
      "Buzz"
  else
      x.to_s
  end
  puts tmp 
end
