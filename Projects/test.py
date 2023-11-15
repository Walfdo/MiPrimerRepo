my_dict = {"key1": "value1", "key2": "value2"}

default_value = my_dict.get("default")

if default_value is not None:
  print(default_value)
else:
  print("The key 'default' does not exist in the dictionary, or its value is None.")