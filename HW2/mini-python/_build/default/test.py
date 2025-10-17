# Question 4
def fact(n):
    if n <= 1: return 1
    return n * fact(n-1)

# Question 5 functions
def fibaux(a, b, k):
    if k == 0:
        return a
    else:
        return fibaux(b, a+b, k-1)

def fib(n):
    return fibaux(0, 1, n)

# Question 1
print(1+2*3)
print((3*3 +4*4)//5)
print(10-3-4)
print("----------")

# Question 2
print(not True and 1//0==0)
print(1<2)
if False or True:
    print("ok")
else:
    print("oups")
print("----------")

# Question 3
x = 41
x = x+1
print(x)
b = True and False
print(b)
s = "hello" + " world!"
print(s)
print("----------")

# Question 4
print(fact(10))
print("----------")

# Question 5 - Lists

numbers = [1, 2, 3, 4, 5]
print(numbers)          # [1, 2, 3, 4, 5]
print(len(numbers))     # 5
print(numbers[0])       # 1
print(numbers[2])       # 3
print(numbers[4])       # 5

a = [1, 2, 3]           
b = [4, 5, 6]
c = a + b               # c = [1, 2, 3, 4, 5, 6]
print(c)                # [1, 2, 3, 4, 5, 6]
print(len(c))           # 6

r = list(range(10))
print(r)                # [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
print(len(r))           # 10

nums = [10, 20, 30]     
nums[1] = 99
print(nums)             # [10, 99, 30]

print("For loop test:")
for x in [1, 2, 3, 4, 5]:
    print(x)                
# 1 2 3 4 5
print("a few values of the Fibonacci sequence:")
for n in [0, 1, 11, 42]:
    print(fib(n))
# 0
# 1
# 89
# 267914296
print("----------")
