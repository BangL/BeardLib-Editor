---Writes .massunit files (Diesel 3.0, the format of RAID), replacing the MassunitMaker.exe: no external program, so it
---works on every platform the editor does.
---
---Layout (all little endian, 64 bit):
---    u64 type_count, u64 type_count (capacity), u64 offset of the types (0x20), u64 0
---    per type (48 bytes): u64 unit hash, i32 pool size, i32 0, u64 instance_count, u64 instance_count, u64 offset of the instances, u64 0
---    per type, the instances (28 bytes each): float x, y, z (position), float x, y, z, w (rotation)
---    u32 0xCC0BEED1
---Verified against the massunit of a vanilla level, rewriting it gives the same bytes.
---@class MassunitWriter
MassunitWriter = MassunitWriter or {}

local char, concat, floor, frexp = string.char, table.concat, math.floor, math.frexp

local function u32(n)
    return char(n % 256, floor(n / 256) % 256, floor(n / 65536) % 256, floor(n / 16777216) % 256)
end

--- Up to 2^53, plenty for sizes and offsets.
local function u64(n)
    return u32(n % 4294967296) .. u32(floor(n / 4294967296))
end

--- IEEE 754 single precision.
local function f32(x)
    x = tonumber(x) or 0
    if x ~= x then
        x = 0 -- nan
    end
    local sign = 0
    if x < 0 then
        sign = 2147483648
        x = -x
    end
    if x == 0 then
        return u32(sign)
    elseif x == math.huge then
        return u32(sign + 2139095040)
    end
    local m, e = frexp(x) -- x = m * 2^e, 0.5 <= m < 1
    local exponent = e + 126 -- biased exponent of 2 * m * 2^(e - 1)
    local mantissa
    if exponent <= 0 then
        mantissa = floor(x * 2 ^ 149 + 0.5) -- denormal
        exponent = 0
        if mantissa >= 8388608 then
            mantissa, exponent = 0, 1
        end
    else
        mantissa = floor((m * 2 - 1) * 8388608 + 0.5)
        if mantissa >= 8388608 then
            mantissa = 0
            exponent = exponent + 1
        end
        if exponent >= 255 then
            return u32(sign + 2139095040)
        end
    end
    return u32(sign + exponent * 8388608 + mantissa)
end

--- The unit hash as it is stored: the bytes of Idstring:key() in the order of its digits.
local function hash_bytes(key)
    key = tostring(key)
    key = string.rep("0", 16 - #key) .. key
    return (key:gsub("%x%x", function(byte)
        return char(tonumber(byte, 16))
    end))
end

---Builds the content of a massunit file.
---@param units table List of {key = "[idstring key of the unit]", positions = {{x, y, z}, ...}, rotations = {{x, y, z, w}, ...}}
---Entries of the same unit are merged, entries without an instance are left out (the engine crashes on a type without
---instances).
---@return string
function MassunitWriter:Serialize(units)
    local order, by_key = {}, {}
    for _, unit in ipairs(units) do
        local key = tostring(unit.key)
        local entry = by_key[key]
        if not entry then
            entry = {key = key, instances = {}}
            by_key[key] = entry
            table.insert(order, entry)
        end
        local positions, rotations = unit.positions or {}, unit.rotations or {}
        for i, pos in ipairs(positions) do
            local rot = rotations[i] or {0, 0, 0, 1}
            table.insert(entry.instances, f32(pos[1]) .. f32(pos[2]) .. f32(pos[3]) .. f32(rot[1]) .. f32(rot[2]) .. f32(rot[3]) .. f32(rot[4]))
        end
    end
    local types = {}
    for _, entry in ipairs(order) do
        if #entry.instances > 0 then
            table.insert(types, entry)
        end
    end

    local count = #types
    local parts = {u64(count), u64(count), u64(0x20), u64(0)}
    -- the instances follow the types, the data of the first starts there
    local offset = 0x20 + count * 48
    for _, entry in ipairs(types) do
        local n = #entry.instances
        table.insert(parts, hash_bytes(entry.key) .. u32(n) .. u32(0) .. u64(n) .. u64(n) .. u64(offset) .. u64(0))
        offset = offset + n * 28
    end
    for _, entry in ipairs(types) do
        table.insert(parts, concat(entry.instances))
    end
    table.insert(parts, u32(0xCC0BEED1))
    return concat(parts)
end

---Writes a massunit file.
---@param path string
---@param units table See MassunitWriter:Serialize
function MassunitWriter:Write(path, units)
    FileIO:WriteTo(path, self:Serialize(units), "wb")
end
