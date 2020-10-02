
local inspect = require("inspect")

function filter(t, f)
    local res = {}
    for _, v in ipairs(t) do
        if f(v) then
            table.insert(res, v)
        end
    end
    return res
end

string.split = function(haystack, delim_or_pattern, is_regex)
    if not is_regex then
        delim_or_pattern = delim_or_pattern or '%s'
        delim_or_pattern = string.format("([^%s]*)(%s?)", delim_or_pattern, delim_or_pattern)
    end
    local temp = {}
    for field, s in string.gmatch(haystack, delim_or_pattern) do
        table.insert(temp, field)
        if s == "" then
            return temp
        end
    end
    return temp
end

table.copy = function(t)
    local res = {}
    for k, v in pairs(t) do
        res[k] = v
    end
    setmetatable(res, getmetatable(t))
    return res
end

table.join = function(t, sep)
    t = table.copy(t)
    for i = 1, #t do
        t[i] = tostring(t[i])
    end
    return table.concat(t, sep)
end

local class = {
    new = function(classtype, t)
        t.__classtype = classtype
        t.classtype = function(self)
            return self.__classtype
        end
        t.copy = table.copy
        t.new = table.copy
        setmetatable(t, t.mt)
        return t
    end
}

-- -------------------------------------------------------------------------------------------------
-- Code
-- -------------------------------------------------------------------------------------------------

Word = class.new("word", {
    -- METATABLE
    mt = {
        __add = function(a, b)
            if b.classtype then
                if b:classtype() == "word" then
                    assert(#a == #b)
                    local res = a:new()
                    for i = 1, #a do
                        res[i] = math.floor((a[i] + b[i]) % 2)
                        --res[i] = 0
                    end
                    return res
                --elseif b:classtype() == "code" then
                    --return b + a
                end
            end
            assert(false, "Invalid operator arguments")
        end,

        __mul = function(a, x)
            if type(a) == "number" then
                a, x = x, a
            end
            assert(a.classtype and a:classtype() == "word" and type(x) == "number")
            local res = a:copy()
            for i = 1, #res do
                res[i] = res[i] * x
            end
            return res
        end,

        __eq = function(a, b)
            if not b.classtype and b:classtype() ~= "word" then
                return false
            end
            if #a ~= #b then
                return false
            end
            for i = 1, #a do
                if a[i] ~= b[i] then
                    return false
                end
            end
            return true
        end,

        __lt = function(a, b)
            if not b.classtype and b:classtype() ~= "word" then
                return false
            end
            if #a > #b then
                return false
            end
            for i = 1, #a do
                if a[i] ~= b[i] then
                    return a[i] < b[i]
                end
            end
            return false
        end,

        __tostring = function(self)
            return self:hash()
        end
    },

    -- ---------------------------------------------------------------------------------------------
    -- STATIC METHODS
    -- ---------------------------------------------------------------------------------------------

    from = function(Word, ...)
        local res = Word:new()
        for i = 1, select("#", ...) do
            res[i] = select(i, ...)
        end
        return res
    end,

    parse = function(Word, unparsed)
        local bits = {}
        for i = 1, #unparsed do
            local b = unparsed:byte(i)
            assert(b == 48 or b == 49)
            bits[i] = b - 48
        end
        return Word:from(table.unpack(bits))
    end,

    -- ---------------------------------------------------------------------------------------------
    -- INSTANCE METHODS
    -- ---------------------------------------------------------------------------------------------

    hash = function(self)
        return table.join(self)
    end,

    is_zero = function(self)
        for _, b in ipairs(self) do
            if b ~= 0 then
                return false
            end
        end
        return true
    end,

    slice = function(self, start, stop)
        local res = Word:new()
        for i = (start and start or 1), (stop and stop or #self) do
            table.insert(res, self[i])
        end
        return res
    end,

    weight = function(self)
        local weight = 0
        for _, b in ipairs(self) do
            weight = weight + b
        end
        return weight
    end,

    likeliness = function(self, v, p)
        local w = (self + v):weight()
        return p^(#self - w)*(1-p)^(w)
    end,

    dot = function(self, other)
        assert(other.classtype and other:classtype() == "word" and #self == #other)
        local res = 0
        for i = 1, #self do
            res = (res + self[i] * other[i]) % 2
        end
        return res
    end,
})

-- -------------------------------------------------------------------------------------------------
-- Code
-- -------------------------------------------------------------------------------------------------

Code = class.new("code", {
    -- METATABLE
    mt = {
        __add = function(self, other)
            if other.classtype then
                if other:classtype() == "word" then
                    local res = self:new()
                    for i, v in ipairs(self) do
                        res[i] = v + word
                    end
                    return res
                end
            end
            assert(false, "Invalid operator arguments")
        end,

        __eq = function(self, other)
            if other.classtype then
                if other:classtype() == "code" then
                    assert(#self == #other)
                    local a = self:copy()
                    local b = self:copy()
                    table.sort(a)
                    table.sort(b)
                    for i = 1, #a do
                        if a[i] ~= b[i] then
                            return false
                        end
                    end
                    return true
                end
            end
            assert(false, "Invalid type for comparison")
        end,

        __tostring = function(self)
            return "["..table.join(self, ",").."]"
        end
    },

    -- ---------------------------------------------------------------------------------------------
    -- STATIC METHODS
    -- ---------------------------------------------------------------------------------------------

    from = function(Code, ...)
        local res = Code:new()
        for i = 1, select("#", ...) do
            res[i] = select(i, ...)
        end
        return res
    end,

    parse = function(Code, unparsed_words)
        local words = {}
        for i, unparsed_word in ipairs(string.split(unparsed_words, ",")) do
            words[i] = Word:parse(unparsed_word)
        end
        return Code:from(table.unpack(words))
    end,

    -- Return code with all possible words of length n
    of_length = function(Code, n)
        if n > 1 then
            local res = Code:new()
            local subs = Code:of_length(n - 1)
            for _, b in ipairs({ 0, 1 }) do
                for _, sub in ipairs(subs) do
                    table.insert(res, Word:from(b, table.unpack(sub)))
                end
            end
            return res
        else
            return Code:from(Word:from(0), Word:from(1))
        end
    end,

    -- ---------------------------------------------------------------------------------------------
    -- INSTANCE METHODS
    -- ---------------------------------------------------------------------------------------------

    contains = function(self, word)
        for _, v in ipairs(self) do
            if word == v then
                return true
            end
        end
        return false
    end,

    contains_zero = function(self)
        local zero = self[1] + self[1]
        return self:contains(zero)
    end,

    -- Find index of a word in the code
    find = function(self, word)
        for i, v in ipairs(self) do
            if word == v then
                return i
            end
        end
        return false
    end,

    -- Return a copy of the code with the words of another code removed
    remove = function(self, other)
        local res = self:copy()
        for _, w in ipairs(other) do
            local i = res:find(w)
            if i then
                table.remove(res, i)
            end
        end
        return res
    end,

    distance = function(self)
        local min_weight = 999
        for i = 1, #self do
            for j = i + 1, #self do
                local a = self[i]
                local b = self[j]
                local w = (a + b):weight()
                min_weight = w < min_weight and w or min_weight
            end
        end
        return min_weight
    end,

    is_linear = function(self)
        if not self:contains_zero() then
            return false
        end
        local zero = self[1] + self[1]
        for i = 1, #self do
            local v = self[i]
            for j = i + 1, #self do
                local u = self[i]
                if not self:contains(v + u) then
                    return false
                end
            end
        end
        return true
    end,

    mld_data = function(self)
        local n = #self[1]
        local words = Code:of_length(n)
        local rows = {}
        for i, w in ipairs(words) do
            local error_patterns = Code:new()
            local weights = {}
            -- Compile error codes and their weights
            for j, v in ipairs(self) do
                local e = v + w
                error_patterns[j] = e
                weights[j] = e:weight()
            end
            -- Determine indices of patterns with minimum weight
            local min_weight = math.min(table.unpack(weights))
            local min_indices = Code:new()
            for j = 1, #self do
                local e = error_patterns[j]
                if e:weight() == min_weight then
                    table.insert(min_indices, j)
                end
            end
            local decoded = (#min_indices == 1 and self[min_indices[1]] or nil)
            -- Assemble row data
            rows[i] = {
                w = w,
                error_patterns = error_patterns,
                min_weight = min_weight,
                decoded = decoded
            }
        end
        -- Determine all detected error patterns
        -- "A code C detects the error pattern e if and only if v+e is not a codeword, for every v
        -- in C. The set of all error patterns that are undetected by C is the set of all words that
        -- can be written as the sum of two codewords; thus this set removed from all the words with
        -- length of C is the set of detected error patterns."
        -- (Actually starting with all undetected, then removing from all words)
        local detects = Code:new()
        for i = 1, #self do
            for j = i, #self do
                local e = self[i] + self[j]
                if not detects:contains(e) then
                    table.insert(detects, e)
                end
            end
        end
        detects = words:remove(detects)
        -- Determine all corrected error patterns
        -- "A code C corrects the error pattern e if, for all v in C, v+e is closer to v than any
        -- other word in C. An error pattern e is corrected if an asterisk is placed beside e for
        -- every column of the IMLD table."
        local corrects = Code:new()
        for _, word in ipairs(words) do
            corrects[word:hash()] = true
        end
        for c = 1, #self do
            for i, row in ipairs(rows) do
                local e = row.error_patterns[c]
                local hash = e:hash()
                if corrects[hash] then
                    corrects[hash] = row.decoded ~= nil and e == row.w + row.decoded
                end
            end
        end
        for _, e in ipairs(words) do
            if corrects[e:hash()] then
                table.insert(corrects, e)
            end
        end
        print(corrects)
        -- Determine set of words closest to a code word v
        local closest = {}
        for _, row in ipairs(rows) do
            local decoded = row.decoded
            if decoded then
                local hash = decoded:hash()
                closest[hash] = closest[hash] or Code:new()
                table.insert(closest[hash], row.w)
            end
        end
        return {
            code = self,
            rows = rows,
            detects = detects,
            corrects = corrects,
            closest = closest
        }
    end,

    generates = function(S)
        local C = Code:new()
        local zero = S[1] + S[1]
        local coefficients = Code:of_length(#S)
        for i, coefs in ipairs(coefficients) do
            local u = zero:copy()
            for j = 1, #coefs do
                local c = coefs[j]
                local v = S[j]
                u = u + c * v
            end
            C[i] = u
        end
        return C
    end,

    dual = function(S)
        local D = Code:new()
        local words = Code:of_length(#S[1])
        for _, u in ipairs(words) do
            for _, v in ipairs(S) do
                if u:dot(v) > 0 then
                    goto skip
                end
            end
            table.insert(D, u)
            ::skip::
        end
        return D
    end,

    -- Find index of first word with 1 in the c'th bit
    find_any_to_c = function (self, c, start)
        for r = (start and start or 1), #self do
            if self[r][c] == 1 then
                return r
            end
        end
        return false
    end,

    -- Find index of first word with 1 in the c'th bit but all zeros prior
    find_zero_to_c = function(self, c, start)
        for r = (start and start or 1), #self do
            if self[r][c] == 1 and self[r]:slice(1, c - 1):is_zero() then
                return r
            end
        end
        return false
    end,

    ref = function(self)
        local C = self:copy()
        local m = #C
        local n = #C[1]
        -- Shift rows
        local q = 1
        for c = 1, n do
            local r = C:find_any_to_c(c, q)
            if r then
                local temp = C[q]
                C[q] = C[r]
                C[r] = temp
                q = q + 1
            end
        end
        -- Add rows
        for c = 1, n do
            local r = C:find_zero_to_c(c)
            if r then
                for i = r + 1, m do
                    if C[i][c] == 1 then
                        C[i] = C[r] + C[i]
                    end
                end
            end
        end
        -- Post sort
        table.sort(C, function(a, b) return a > b end)
        return C
    end,

    rref = function(self)
        local C = self:ref()
        local m = #C
        local n = #C[1]
        for c = 1, n do
            local r = C:find_zero_to_c(c)
            if r then
                for i = 1, r - 1 do
                    if C[i][c] == 1 then
                        C[i] = C[r] + C[i]
                    end
                end
            end
        end
        return C
    end
})

