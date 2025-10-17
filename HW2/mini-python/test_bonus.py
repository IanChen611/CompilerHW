# Bonus: Test lexicographic comparison for lists
# In Python: [0, 1, 1] < [1] should be True (lexicographic order)
# In old OCaml: would compare lengths first

print([0, 1, 1] < [1])
print([1] > [0, 1, 1])
print([1, 2] < [1, 3])
print([1, 2] == [1, 2])
