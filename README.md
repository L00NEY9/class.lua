# class.lua - OOP For lua
### How it work?
To create a class, you just need to call the "class" function and pass the constructor function to it. Unlike the standard approach, in your constructor function you only need to register all the fields as if you declare them in global scope. Class.lua intercepts changes to the global scope and writes them to the prototype of the class
### Examples
#### Simple example
```lua
require("class")

local Car = class(function()
    model = "BMW M3"
end)

local myCar = Car()
print(myCar.model) -- Expected output "BMW M3"
```
#### Methods
```lua
require("class")

local Car = class(function()
    model = "BMW M3"

    function changeModel(newModel)
    	this.model = newModel
    end
end)

local myCar = Car()
print(myCar.model) -- Expected output "BMW M3"
myCar.changeModel("BMW M4")
print(myCar.model) -- Expected output "BMW M4"
```
### "New" method
The "new" method is absolutely the same method as all the others. Its main difference is that it is automatically called when a new instance of the class is assembled
```lua
require("class")

local Car = class(function()
    function new(carModel)
   	this.model = carModel
    end
end)

local myCar = Car("BMW M3")
print(myCar.model) -- Expected output: "BMW M3"
```
### Decorators
Decorators are also actively used in "class.lua". Decorators are created by the developer himself and can be used for each field in the class. Decorators are ordinary functions, when called, they are added to the decorator stack and when any field has been collected in the global scope, the entire decorator stack is called and it is cleared.

```lua
local RightDirectionDecorator = createDecorator(function(context, fieldName, currentClass)
    context.direction = "right"
end)

local Car = class(function()
    direction = "forward"

    RightDirectionDecorator()
    function drive()
        print("Car is driving to " .. this.direction)
    end
end)

local myCar = Car()
myCar.drive() -- Expected output: "Car is driving to right"
```
Here we have created a simple decorator. Decorators are created by calling the "createDecorator" function. In the arguments we passed the function itself, which will be called to work with a specific field, this function takes:

 1. context - Context of current class (aka "this")
 2. fieldName - Name of field, that was created
 3.  currentClass - It's just a static class table that is created only once, when the "class" function is called. Usually this argument is used to define any static methods of the class.

For a better understanding, see how easily the built-in "Static" decorator is arranged:
```lua
Static = createDecorator(function(context, fieldName, currentClass)
    local temp = context[fieldName]
    context[fieldName] = nil -- Remove field from context
    currentClass[fieldName] = temp -- Add this field to static class table
end)
```
