function code_as_matrix(code)
    tex.print([[\begin{bmatrix}]])
    for _, word in ipairs(code) do
        tex.print(tostring(word)..[[\\]])
    end
    tex.print([[\end{bmatrix}]])
end

function check_code_is_linear(unparsed_code)
    local code = Code:parse(unparsed_code)
    local zero = code[1] + code[1]
    if not code:contains(zero) then
        tex.print([[Since $C$ does not contain the zero pattern, it is not a linear code.]])
        return
    end
    if #code == 2 then
        local v = code[1]
        local u = code[2]
        tex.print(string.format([[Since for the only pair $%s+%s=%s\in C$, $C$ is a linear code.]], v, u, u))
        return
    end
    local v_fails, u_fails, w_fails
    local lines = {}
    tex.print([[Checking the sum of each pair of non-zero $v,u\in C$ distinct:]])
    for i = 1, #code do
        local v = code[i]
        if not v:is_zero() then
            for j = i + 1, #code do
                local u = code[j]
                local w = v + u
                if code:contains(w) then
                    table.insert(lines, string.format([[%s+%s=%s\in C]], v, u, w))
                else
                    table.insert(lines, string.format([[%s+%s=%s\notin C]], v, u, w))
                    v_fails = v
                    u_fails = u
                    w_fails = w
                    goto done
                end
            end
        end
    end
    ::done::
    tex.print([[\begin{gather*}]])
    tex.print(table.concat(lines, [[\\]]))
    tex.print([[\end{gather*}]])
    if v_fails then
        tex.print(string.format([[Since $%s+%s=%s\notin C$, we conclude that $C$ is not a linear code.]], v_fails, u_fails, w_fails))
    else
        tex.print([[And we conclude that $C$ is a linear code.]])
    end
end

function generate_linear_code(unparse_words)
    local S = Code:parse(unparse_words)
    local zero = S[1] + S[1]
    local coefficients = Code:of_length(#S)

    local lines = {}
    for _, v in ipairs(coefficients) do
        local sum = zero:copy()
        local parts = {}
        for i = 1, #v do
            local c = v[i]
            local w = S[i]
            sum = sum + c * w
            parts[i] = string.format([[%d(%s)]], c, w)
        end
        table.insert(lines, "&"..table.concat(parts, "+").."="..tostring(sum))
    end
    tex.print(
        [[\begin{align*}]]..
        [[C=\langle S\rangle=\{\ ]]..
        table.concat(lines, [[,\\]])..
        [[\ \} \end{align*}]]
    )
end

function check_set_is_linear(unparsed_words)
    local words = Code:parse(unparsed_words)
    local coefficients = filter(Code:of_length(#words), function(w)
        return w:weight() >= 2
    end)
    tex.print(tostring(coefficients))
end

