---Credit: Thanks to plexpt. Code taken from the Big Data string 2 mod.


local function decode(data)
    if type(data) == "string" then
        return data
    end
    local str = {}
    for i = 2, #data do
        str[i - 1] = decode(data[i])
    end
    return table.concat(str, "")
end

local function bigunpack(name)
    assert(type(name) == "string", "missing name!")
    local prototype = assert(prototypes.entity["big-data-" .. name],
            string.format("big data '%s' not defined!", name))
    return decode(prototype.localised_description)
end


-- please cache the result
return bigunpack

