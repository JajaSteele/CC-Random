-- a (de)compression library for non-sparse mc block data, no block state support
-- can use registry keys or resource locations (not implemented)
-- ALL INTS ARE UNSIGNED

-- TinyStructure:
--  0x00-0x0F: Header
--  Pallet
--  BlockData

-- Header: 16 bytes
--  Flags, int12
--  xSize, int16
--  ySize, int12
--  zSize, int16
--  RESERVED: int72 

-- Flags (int12)
--  0x0, usesRegistryKeys: bit

-- Pallet:
--  0x00-0x01, palletLength: int16
--  Flags.usesRegistryKeys ? RegistryPallet[palletLength] : ResourceLocationPallet[palletLength]

-- RegistryPallet:
--  0x0-0x0B, registryId: int16

-- BlockData
-- int(ceil(log_2(Pallet.palletLength)))[ySize][xSize][zSize]

local insert = table.insert
local pack = table.pack
local unpack = table.unpack
local byte = string.byte
local blshift = bit.blshift
local band = bit.band
local bor = bit.bor
local char = string.char

local function find(t,value)
    for k,v in ipairs(t) do
        if v == value then
            return k
        end
    end
    return false
end
---@class BitBuffer
---@field bitsInLast integer
---@field buffer integer[]
local BitBuffer = {}
BitBuffer.__index = BitBuffer

---Creates a new BitBuffer
---@param data string?
---@return BitBuffer
function BitBuffer.new(data)
    local newBitBuffer = {}
    newBitBuffer.buffer = data and pack(byte(data,1,string.len(data))) or {0}
    newBitBuffer.bitsInLast = 0
    setmetatable(newBitBuffer,BitBuffer)
    return newBitBuffer
end
---Pushes a bit
---@param bit integer
function BitBuffer:pushBit(bit)
    local buffer = self.buffer
    local length = #buffer
    local last = buffer[length]
    local bitsInLast = self.bitsInLast
    buffer[length] = bor(last,blshift(bit,bitsInLast))
    self.bitsInLast = bitsInLast + 1
    if bitsInLast == 7 then
        insert(buffer,0)
        self.bitsInLast = 0
    end
end
---Pushes bits
---@param bits integer[]
function BitBuffer:pushBits(bits)
    for k,v in pairs(bits) do
        self:pushBit(v)
    end
end
function BitBuffer:pushInt(int,length)
    for i=0,length-1 do
        self:pushBit(band(int,blshift(1,i)) ~= 0 and 1 or 0)
    end
end
---Reads the bit and increments the pointer
---@param pointer {at:integer}
---@return integer
function BitBuffer:readBit(pointer)
    local pointed = pointer.at
    pointer.at = pointed + 1
    local currentByte = self.buffer[math.floor(pointed/8)+1]
    return band(currentByte,blshift(1,pointed%8)) ~= 0 and 1 or 0
end
---Reads the bit and increments the pointer
---@param pointer {at:integer}
function BitBuffer:readInt(pointer, length)
    local out = 0
    for i=0,length-1 do
        out = out + blshift(self:readBit(pointer), i)
    end
    return out
end
function BitBuffer:toString()
    return char(unpack(self.buffer))
end

---@alias BlockMatrixXYZ string[][][]
---@alias BlockArrayYXZ string[]
---@alias BlockName string

---Turns a 3d XYZ matrix into YXZ array
---@param blockMatrix BlockMatrixXYZ
---@return BlockArrayYXZ 
local function linearizeXYZtoYXZ(blockMatrix, sizeX, sizeY)
    local linearized = {}
    for y=1,sizeY do
        for x=1,sizeX do
            local yArray = blockMatrix[x][y]
            for z,block in ipairs(yArray) do
                insert(linearized, block)
            end
        end
    end
    return linearized
end
---Generates a pallet from the blockArray
---@param blockArray BlockArrayYXZ
local function generatePallet(blockArray)
    local pallet = {}
    local palletArray = {}
    for k, block in pairs(blockArray) do
        if not pallet[block] then
            pallet[block] = true
            insert(palletArray, block)
        end
    end
    return palletArray
end
---Converts a ResourceLocationPallet to a RegistryPallet
---@param resourcePallet string[]
---@param registryData BlockName[]
---@return number[] registryPallet
---@return table<string, number> resourceToPalletMap
local function resourceToRegistryPallet(resourcePallet, registryData)
    local outputPallet = {}
    local resourceToPalletMap = {}
    for k,v in pairs(resourcePallet) do
        local registryId = find(registryData, v)
        if not registryId then
            error("Unknown Block ResourceLocation: '"..v.."'")
        end
        outputPallet[k] = registryId-1
        resourceToPalletMap[v] = k-1
    end
    return outputPallet, resourceToPalletMap
end
local function calculateCubeSize(scanDataArray)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for k,posArray in pairs(scanDataArray) do
        for _, pos in pairs(posArray) do
            local x,y,z = pos.x,pos.y,pos.z
            minX = math.min(minX,x)
            minY = math.min(minY,y)
            minZ = math.min(minZ,z)
            maxX = math.max(maxX,x)
            maxY = math.max(maxY,y)
            maxZ = math.max(maxZ,z)
        end
    end
    return minX, minY, minZ, maxX, maxY, maxZ
end
---Converts sparse data grouped by block into a dense matrix
---@param sparsePosMatrix table<BlockName, {x:integer, y:integer, z:integer}[]>
local function convertSparsePosMatrixToDenseMatrix(sparsePosMatrix)
    local minX, minY, minZ, maxX, maxY, maxZ = calculateCubeSize(sparsePosMatrix)
    local sizeX, sizeY, sizeZ = maxX-minX,maxY-minY,maxZ-minZ
    local matrix = {}
    for x=1,sizeX+1 do
        local xArray = {}
        matrix[x] = xArray
        for y=1, sizeY+1 do
            local yArray = {}
            xArray[y] = yArray
            for z=1, sizeZ+1 do
                yArray[z] = "minecraft:air"
            end
        end
    end
    for block,array in pairs(sparsePosMatrix) do
        for k, pos in pairs(array) do
            matrix[pos.x - minX +1][pos.y - minY +1][pos.z - minZ + 1] = block
        end
    end
    return matrix
end
---Converts a XYZ Matrix of block data into sparse data grouped by block
---@param denseMatrix any
---@return table
local function convertDenseMatrixToSparsePosMatrix(denseMatrix)
    local sparse = {}
    for x, xArray in pairs(denseMatrix) do
        for y, yArray in pairs(xArray) do
            for z, block in pairs(yArray) do
                sparse[block] = sparse[block] or {}
                insert(sparse[block], {x=x,y=y,z=z})
            end
        end
    end
    return sparse
end
---Encodes into TinyStructure format
---@param data BlockMatrixXYZ
---@param registryData string[]
local function encode(data, registryData)
    local usesRegistryKeys = registryData and true or false
    if not usesRegistryKeys then
        error("ResourceLocation mode not supported")
    end
    local sizeX = #data
    local sizeY = #data[1]
    local sizeZ = #data[1][1]
    local buffer = BitBuffer.new()
    -- Header
    buffer:pushInt(usesRegistryKeys and 1 or 0, 12)
    buffer:pushInt(sizeX, 16)
    buffer:pushInt(sizeY, 12)
    buffer:pushInt(sizeZ, 16)
    buffer:pushInt(0,72)
    -- Pallet
    local linearized = linearizeXYZtoYXZ(data, sizeX, sizeY)
    local resourcePallet = generatePallet(linearized)
    local palletLength = #resourcePallet
    local palletLog2Ceil = math.max(math.ceil(math.log(palletLength,2)),1)
    buffer:pushInt(palletLength-1,16)
    if usesRegistryKeys then
        --RegistryPallet
        local registryPallet, resourceToPalletMap = resourceToRegistryPallet(resourcePallet, registryData)
        for k,v in pairs(registryPallet) do
            buffer:pushInt(v,16)
        end
        --BlockData
        for k,v in pairs(linearized) do
            buffer:pushInt(resourceToPalletMap[v], palletLog2Ceil)
        end
    end
    return buffer:toString()
end
---Decodes an encoded TinyStructure
---@param data string
---@param registryData BlockName[] A list of blocks sorted by some function that guarantees consistency between restarts / registry updates. (e.g., sorted by raw registry id)
---@return BlockMatrixXYZ
local function decode(data, registryData)
    local buffer = BitBuffer.new(data)
    local pointer = {at=0}
    -- Header
    local usesRegistryKeys = buffer:readBit(pointer)
    if not usesRegistryKeys then
        error("ResourceLocation mode not supported")
    elseif not registryData then
        error("registryData is required for decoding registry pallets")
    end
    buffer:readInt(pointer,11)
    local sizeX = buffer:readInt(pointer, 16)
    local sizeY = buffer:readInt(pointer, 12)
    local sizeZ = buffer:readInt(pointer, 16)
    buffer:readInt(pointer,72)
    -- Pallet
    local palletLength = buffer:readInt(pointer,16)+1
    local palletLog2Ceil = math.max(math.ceil(math.log(palletLength,2)),1)
    if usesRegistryKeys then
        --RegistryPallet
        local registryPallet = {}
        for i=1,palletLength do
            local value = buffer:readInt(pointer,16)+1
            insert(registryPallet, registryData[value])
        end
        --BlockData
        local blockData = {}
        for y = 1, sizeY do
            for x = 1, sizeX do
                blockData[x] = blockData[x] or {}
                local yArray = {}
                blockData[x][y] = yArray
                for z =1, sizeZ do
                    insert(yArray, registryPallet[buffer:readInt(pointer,palletLog2Ceil)+1])
                end
            end
        end
        return blockData
    end
    error("TODO: finish implementing support for resource locations")
end

return {
    encode = encode,
    decode = decode,
    convertSparsePosMatrixToDenseMatrix = convertSparsePosMatrixToDenseMatrix,
    convertDenseMatrixToSparsePosMatrix = convertDenseMatrixToSparsePosMatrix
}
