# OOP For lua
### How it work?
To create a class, you just need to call the "class" function and pass the constructor function to it. Unlike the standard approach, in your constructor function you only need to register all the fields as if you declare them in global scope. OOP.lua intercepts changes to the global scope and writes them to the prototype of the class
### Examples
#### Simple example
```lua
require "OOP"

local Car = class(function()
    model = "BMW M3"
    local serial_number = 24542
    
    function get_serial()
        return "serial_number: " .. serial_number
    end
end)

local myCar = Car()
print(myCar.model) -- output: "BMW M3"
print(myCar.serial_number) -- output: nil
print(myCar:get_serial()) -- output: "serial_number: 24542"
```
#### Methods
```lua
require "OOP"

local Car = class(function()
    model = "BMW M3"

    function changeModel(newModel)
    	this.model = newModel
    end
end)

local myCar = Car()
print(myCar.model) -- output: "BMW M3"
myCar.changeModel("BMW M4")
print(myCar.model) -- output: "BMW M4"
```
### "New" method
The "new" method is absolutely the same method as all the others. Its main difference is that it is automatically called when a new instance of the class is assembled
```lua
require "OOP"

local Car = class(function()
    function new(carModel)
   	    this.model = carModel
    end
end)

local myCar = Car("BMW M3")
print(myCar.model) -- output: "BMW M3"
```
### Inheritance
The "inherit" function allows you to create a class inherited from another class
```lua
require "OOP"

local A = class(function()
    function parent_func()
        return "called from parent"
    end

    function get_class()
        return "A"
    end
end)

local B = inherit(A)(function()
    function get_class()
        return "B"
    end
end)

local object = B()
print(object:parent_func()) -- output: "called from parent"
print(object:get_class()) -- output: "B"
```
