-- data:
local badType = "bad argument #%i to '%s' (%s expected, got %s)"
local badArgument = "bad argument #%i to '%s' (%s)"


-- Connection:
local Connection = {}

-- constructors:
function Connection.new(listener)
	assert(typeof(listener) == "function", badType:format(1, "Connection.new", "function", typeof(listener)))
	local connection = setmetatable({}, {__index = Connection})
	connection.Listener = listener
	return connection
end

-- properties:
Connection.IsConnected = true

-- methods:
function Connection:Disconnect()
	self.IsConnected = false
end


-- Signal:
local Signal = {}

-- constructors:
function Signal.new()
	local signal = setmetatable({}, {__index = Signal})
	signal._Connections = {}
	signal._BindableEvent = Instance.new("BindableEvent")
	return signal
end

-- methods:
function Signal:Connect(listener)
	assert(typeof(listener) == "function", badType:format(1, "Signal:Connect", "function", typeof(listener)))
	local connection = Connection.new(listener)
	table.insert(self._Connections, connection)
	return connection
end

function Signal:Wait()
	local temporaryBindableEvent = Instance.new("BindableEvent")
	local connection
	local results
	connection = self:Connect(function(...)
		connection:Disconnect()
		results = {...}
		temporaryBindableEvent:Fire()
	end)
	temporaryBindableEvent.Event:Wait()
	return unpack(results)
end

function Signal:_Fire(...)
	local connections = self._Connections
	local threads = self._Threads
	-- removing elements from array while iterating over it is dangerous, safe alternative
	local removedConnections = {}
	local bindableEvent = self._BindableEvent
	local bindableSignal = bindableEvent.Event
	-- pack arguments
	local arguments = {...}
	-- iterate over connections, spawning their listener or removing them
	for index, connection in ipairs(connections) do
		if connection.IsConnected then
			-- connect to bindable for preparation of firing
			local bindableConnection
			bindableConnection = bindableSignal:Connect(function()
				bindableConnection:Disconnect()
				connection.Listener(unpack(arguments))
			end)
		else
			-- add to table of connections to be removed
			table.insert(removedConnections, index)
		end
	end
	-- remove connections to be removed
	for _, index in ipairs(removedConnections) do
		table.remove(connections, index)
	end
	-- fire bindable, resuming threads and invoking listeners
	bindableEvent:Fire()
end


-- Event:
local Event = {}

-- constructors:
function Event.new()
	local event = setmetatable({}, {__index = Event})
	event.Signal = Signal.new()
	return event
end

-- methods:
function Event:Fire(...)
	self.Signal:_Fire(...)
end


-- PersistentEvent:
local module = {}

function module.Create()
	return Event.new()
end

return module
