local TableUtil = require(script:WaitForChild("TableUtil"))

local function clone(value)
    if typeof(value) == "table" then
        return TableUtil.clone(value)
    else
        return value
    end
end

local EventUtil = require(script:WaitForChild("EventUtil"))

local Object = require(script:WaitForChild("Object"))

local OOPService = {}
OOPService.__index = OOPService
setmetatable(OOPService, {
    __call = function(cls, ...) 
        return cls.new()
    end
})


--[[**
    <description>
    Run this once to create a new instance of OOPService that will be
    used throughout your entire game.
    </description>

    <returns>
    New metatable of OOPService.
    </returns>
**]]--
function OOPService.new()
    local self = setmetatable({}, OOPService)

    self.classTypes = {}
    self.objectList = {}


    --[[**
        <description>
        Sets up a class to create Objects from.
        </description>

        <parameter name = "className">
        Name of the class.
        </parameter>

        <parameter name = "template">
        Table of key,value pairs that will be the starting data for the objects created from this class.
        Can store any type in value, but try to use a string for the key.
        </parameter>
    **]]--
    function self:CreateClass(className, template, inheritance)
        assert(typeof(className) == "string", (":CreateClass expected {string className}, got {%s}"):format(typeof(className)))
		
        if not self.classTypes[className] then
			if inheritance then
				assert(typeof(inheritance) == "string", (":CreateClass expected {string inheritance}, got {%s}"):format(typeof(inheritance)))
				assert(self.classTypes[inheritance] ~= nil, ("Could not find class {%s} to inherit from"):format(inheritance))
				
				local newTemplate = clone(self.classTypes[inheritance].temp)
				
				for i,v in pairs(template) do
					newTemplate[i] = v
				end
				
				self.classTypes[className] = {obj = Object.new(className, template), temp = newTemplate}
            	self.objectList[className] = {}
			else
				if not template then
					template = {}
				end
				self.classTypes[className] = {obj = Object.new(className, template), temp = template}
            	self.objectList[className] = {}
			end
        else
            error(("Class type \"%s\" already exists!"):format(className))
        end
    end

    --[[**
        <description>
        Initializes and returns a new Object from specified class.
        </description>

        <parameter name = "className">
        Name of the class the object will be templated from.
        </parameter>

        <parameter name = "ID">
        Identifier used to identify this Object from others of the same class.
        Optional.
        If not provided, one will be generated.
        </parameter>

        <parameter name = "data">
        Table of variable to setup for the Object.
        </parameter>

        <returns>
        A new Object of type className, with ID given or generated.
        </returns>
    **]]--
    function self:CreateObject(className, ID, data)
        assert(typeof(className) == "string", (":CreateObject expected {string className}, got {%s}"):format(typeof(className)))
        assert(self.classTypes[className] ~= nil, ("Could not locate Class: %s"):format(className))

        if not ID then
            local index = #self.objectList[className] + 1
            while not ID do
                if self.objectList[className][tostring(index)] == nil then
                    ID = tostring(index)
                    break
                end

                index = index + 1
            end
        end

		local template = self.classTypes[className].temp
		pcall(function()
			for i,v in pairs(data) do
				template[i] = v
			end
		end)
			
        local newObj = self.classTypes[className].obj.Create(ID, template)
        self.objectList[className][ID] = newObj

        return newObj,ID
    end

    --[[**
        <description>
        Gets table of all objects of specified class.
        </description>

        <parameter name = "className">
        Name of the class function will look for.
        </parameter>

        <returns>
        Table of objects.
        </returns>
    **]]--
    function self:GetClassObjects(className)
        assert(typeof(className) == "string", (":GetClassObjects expected {string className}, got {%s}"):format(typeof(className)))
        assert(self.classTypes[className] ~= nil and self.objectList[className] ~= nil, ("Could not locate Class: %s"):format(className))

        return self.objectList[className]
    end
	--[[**
        <description>
		A yieldable function.
        Gets a specified object from a specified class type.
		If the object is not found, it will return a Wait() event that yeilds code until the event is fired
        </description>

        <parameter name = "className">
        Name of the class function will look for.
        </parameter>
		
		<parameter name = "objectID">
		Name of the object function will look for.
		</parameter>

        <returns>
        Object or an event that is called when the object is found.
        </returns>
    **]]--
	function self:GetObject(className, objectID)
		objectID = tostring(objectID)
		
		assert(typeof(className) == "string", (":GetObject expected {string className}, got {%s}"):format(typeof(className)))
		assert(typeof(objectID) == "string", (":GetObject expected {string objectID}, got {%s}"):format(typeof(className)))	
		
		if self.classTypes[className] and self.objectList[className] and self.objectList[className][objectID] then
			return self.objectList[className][objectID]
		end
		
		local foundEvent = EventUtil.Create()
		local co = coroutine.create(function()
			while not self.classTypes[className] or not self.objectList[className] or not self.objectList[className][objectID] do wait() end
			foundEvent:Fire(self.objectList[className][objectID])
		end)
			
		coroutine.resume(co)
		return foundEvent.Signal:Wait()
	end

    return self
end

-- Creates one instance of OOPService to use throughout the whole game.
local m = OOPService.new()
return m
