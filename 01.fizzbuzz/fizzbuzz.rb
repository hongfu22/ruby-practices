#!/usr/bin/env ruby

(1..20).each do |x|
  tmp = ""
  if x % 3 == 0 && x % 5 == 0
      tmp = "FizzBuzz"
  elsif x % 3 == 0
      tmp = "Fizz"
  elsif x % 5 == 0
      tmp = "Buzz"
  else
      tmp = x.to_s
  end
  puts tmp 
end
