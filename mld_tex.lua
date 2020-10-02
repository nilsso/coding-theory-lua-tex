local function filter(t, f)
    local res = {}
    for _, v in ipairs(t) do
        if f(v) then
            table.insert(res, v)
        end
    end
    return res
end

function longtable(data)
    tex.print(string.format([[\begin{longtable}{%s}]], data.cols))
    tex.print(string.format([[%s \endfirsthead]], data.firsthead))
    tex.print(string.format([[%s \endhead]], data.head))
    tex.print(string.format([[%s \endfoot]], data.foot))
    tex.print(string.format([[%s \endlastfoot]], data.lastfoot))
    for _, row in ipairs(data.rows) do
        tex.print(row..[[\\]])
    end
    tex.print(string.format([[\end{longtable}]]))
end

local function print_mld(data)
    local n = #data.code
    for i = 1, #data.corrects do
        local hue = (i - 1) / #data.corrects
        tex.print(string.format([[\definecolor{corrects%s}{hsb}{%.3f,1,0.8}]], i, hue))
    end
    local rows = {}
    for i, row in ipairs(data.rows) do
        local s = ""
        if data.detects:contains(row.w) then
            if data.code:contains(row.w) then
                s = s..string.format([[${\color{blue}%s}^{\phantom{\times}}$]], row.w)
            else
                s = s..string.format([[${%s}^{\phantom{\times}}$]], row.w)
            end
        else
            if data.code:contains(row.w) then
                s = s..string.format([[${\color{blue}%s}^\times$]], row.w)
            else
                s = s..string.format([[${%s}^\times$]], row.w)
            end
        end
        for _, e in ipairs(row.error_patterns) do
            if row.decoded and e:weight() == row.min_weight then
                if data.corrects:contains(e) then
                    local i = data.corrects:find(e)
                    s = s..string.format([[ & {\color{corrects%s}${%s}^\ast$}]], i, e)
                else
                    s = s..string.format([[ & ${%s}^\ast$]], e)
                end
            else
                s = s..string.format([[ & ${%s}^{\phantom\ast}$]], e)
            end
        end
        table.insert(rows, s..string.format([[ & %s]], row.decoded or ""))
    end
    local head = "w"
    for _, v in ipairs(data.code) do
        head = head..string.format(" & %s+w", v)
    end
    head = head..[[ & v \\]]
    longtable({
        cols = string.format("c | *{%d}c | c", n),
        firsthead = [[\toprule ]]..
            string.format([[Received & \multicolumn{%d}{|c|}{Error patterns} & Decoded \\]], n)..
            [[\midrule ]]..
            head..
            [[\midrule]],
        head = [[\toprule ]]..
            head..
            [[\midrule]],
        foot = [[\bottomrule]],
        lastfoot = [[\bottomrule]],
        rows = rows
    })
end

function mld(unparsed_code)
    --tex.print(tostring(Code:of_length(4)))
    print_mld(Code:parse(unparsed_code):mld_data())
end

function detects(unparsed_error_pattern, unparsed_code)
    local e = Word:parse(unparsed_error_pattern)
    local code = Code:parse(unparsed_code)
    assert(#e == #code[1])
    local rows = {}
    for i, v in ipairs(code) do
        local w = e + v
        rows[i] = string.format([[$%s$ & $%s%s$]], v, w, code:contains(w) and [[\in C]] or [[\notin C]])
    end
    local head = string.format([[\toprule $v$ & $v+%s$\\ \midrule]], e)
    longtable({
        cols = "*2c",
        firsthead = head,
        head = head,
        foot = [[\bottomrule]],
        lastfoot = [[\bottomrule]],
        rows = rows
    })
end

function corrects(unparsed_error_pattern, unparsed_code)
    local e = Word:parse(unparsed_error_pattern)
    local code = Code:parse(unparsed_code)
    assert(#e == #code[1])
    local data = code:mld_data()
    data.rows = filter(data.rows, function(row)
        return row.error_patterns:contains(e)
    end)
    print_mld(data)
end

function corrects_list(unparsed_code)
    local corrects = Code:parse(unparsed_code):mld_data().corrects
    tex.sprint(string.format("$%s$", corrects[1]))
    for i = 2, #corrects do
        tex.sprint(string.format(", $%s$", corrects[i]))
    end
end

function distance(unparsed_code)
    local code = Code:parse(unparsed_code)
    tex.print(code:distance())
end

function correcting_limit(unparsed_code)
    local code = Code:parse(unparsed_code)
    tex.print(tostring(math.floor((code:distance() - 1) / 2)))
end

function find_distance(unparsed_code)
    local code = Code:parse(unparsed_code)
    local rows = {}
    for i = 1, #code do
        for j = i + 1, #code do
            local a = code[i]
            local b = code[j]
            local c = a + b
            local w = c:weight()
            local s = string.format([[$%s$ & $%s$ & $%s$ & $%d$]], a, b, c, w)
            table.insert(rows, s)
        end
    end
    local head = [[\toprule $v$ & $u$ & $v+u$ & $\weight(v,u)$\\ \midrule]]
    longtable({
        cols = "*4c",
        firsthead = head,
        head = head,
        foot = [[\bottomrule]],
        lastfoot = [[\bottomrule]],
        rows = rows
    })
end

function find_detected(unparsed_code)
    local code = Code:parse(unparsed_code)
    local n = #code[1]
    local undetected = Code:new(code[1] + code[1])
    tex.print([[\begin{gather*} ]])
    tex.print([[\begin{aligned} ]])
    tex.print(string.format([[ v + v &= %s\\ ]], code[1] + code[1]))
    for i = 1, #code do
        for j = i + 1, #code do
            local a = code[i]
            local b = code[j]
            local c = a + b
            if not undetected:contains(c) then
                table.insert(undetected, c)
            end
            tex.print(string.format([[ %s + %s &= %s\\ ]], a, b, c))
        end
    end
    local detected = Code:of_length(n):remove(undetected)
    tex.print([[\end{aligned}\\ ]])
    tex.print([[\begin{aligned} ]])
    tex.print(string.format([[\text{Undetected} &= \{%s\}\\ ]], undetected))
    tex.print(string.format([[\text{Detected} &= K^%d\setminus\text{Undetected}]], n))
    tex.print([[\end{aligned}]])
    tex.print([[\end{gather*} ]])
end

local function calc_likeliness(p, u, v)
    return p^(#u - (u + v):weight()) * (1 - p)^(u + v):weight()
end

local function likeliness_definition(p, v, u)
    return string.format([[\phi_{%s}(%s,%s)]], p, v, u)
end

local function likeliness_expanded(p, v, u)
    local e = v + u
    local w = e:weight()
    if w == 0 then
        return string.format([[{(%s)}^{%s}]], p, #v - w)
    elseif w ==#v then
        return string.format([[{(%s)}^{%s}]], 1 - p, w)
    else
        return string.format([[{(%s)}^{%s}{(%s)}^{%s}]], p, #v - w, 1 - p, w)
    end
end

function likeliness(p, unparsed_v, unparsed_u)
    local v = Word:parse(unparsed_v)
    local u = Word:parse(unparsed_u)
    tex.print([[\[ ]])
    tex.sprint(string.format([[\phi_{%s}(%s,%s)]], p, v, u))
    tex.sprint("="..likeliness_definition(p, v, u))
    tex.sprint("="..likeliness_expanded(p, v, u))
    tex.sprint("="..tostring(v:likeliness(u, p)))
    tex.print([[\] ]])
end

local function find_likeliness_helper(p, v, data)
    local closest = data.closest[v:hash()]
    local total = 0
    tex.print([[\begin{align*}]])
    tex.sprint(string.format([[\theta_{%s}(C,%s)]], p, v))
    if closest and #closest > 0 then
        total = total + v:likeliness(closest[1], p)
        local a = likeliness_definition(p, v, closest[1])
        local b = likeliness_expanded(p, v, closest[1])
        tex.sprint([[= &\phantom{{}+{}} (]]..a.."="..b..")")
        for i = 2, #closest do
            total = total + v:likeliness(closest[i], p)
            local a = likeliness_definition(p, v, closest[i])
            local b = likeliness_expanded(p, v, closest[i])
            tex.sprint([[\\ &+ (]]..a.."="..b..")")
        end
        tex.print(string.format([[\\ &= %s]], total))
        --
    end
    tex.print([[\end{align*}]])
end

function find_likeliness(p, unparsed_code, unparsed_word)
    local code = Code:parse(unparsed_code)
    local data = code:mld_data()
    if unparsed_word then
        local word = Word:parse(unparsed_word)
        find_likeliness_helper(p, word, data)
    else
        for _, v in ipairs(code) do
            find_likeliness_helper(p, v, data)
        end
    end
end
