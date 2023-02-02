-- This is to help get a general understanding of what its purpose is.
-- This demonstration is pretty janky, but it should give you a rough idea on how to use this object.

-- Target: Create a simple unethical language that takes in input, stores it within an array, and outputs on command.
local NewRegExp = require(".\\RegExp")

-- Example:
SOURCE =
[[

    input 50, 60, 70;

    output 0, 1, 2;

    remove 0, 1;
    remove 2;
]]

local RegExp = NewRegExp()

RegExp:NewTokenType("Null", {''}) -- Temporary so we don't catch blank strings later on.

RegExp:NewTokenType("W1", {"%s+"})
RegExp:NewTokenType("W2", {"%s*"})

RegExp:NewTokenType("Keyword", {"([%a_]+[%a%d_]*)"})
RegExp:NewTokenType("Number", {"(%d+%.%d+)", "(%.%d+)", "(%d+)"}) -- Floats before integers
RegExp:NewTokenType("EndExpr", {"(;)"})
RegExp:NewTokenType("Sep", {"(,)"})

RegExp:NewComplexTokenType("ListArgs", {"<!W2><?Sep,Null><!W2><?Number><!W2>"})
RegExp:NewComplexTokenType("KeywordExpr", {"<?Keyword><!W1><?ListArgs><!W2><!EndExpr>"})

-- Now remove possibly blank tokens
RegExp:RemoveGeneralTokenType("Null")
RegExp:RemoveGeneralTokenType("W2")

-- Hook listen events and get correct keywords.
RegExp:HookEventToToken("Keyword", function(RESULT)
    return (RESULT == "input") or (RESULT == "output") or (RESULT == "remove")
end)
--

function Interpret(SOURCE)
    local validTokens = {}
    local luaBuffer = {
        "ALLOCATOR = {};\nLENGTH = 0;\n\n", 
        "function INPUT(...) for _, v in ipairs({...}) do LENGTH = LENGTH + 1; ALLOCATOR[LENGTH] = v; end end\n",
        "function OUTPUT(...) for _, v in ipairs({...}) do if (not ALLOCATOR[v + 1]) then return print(\"\\nerror: value not found at position \" .. v); end; print(ALLOCATOR[v + 1]); end end\n",
        "function REMOVE(...) for _, v in ipairs({...}) do ALLOCATOR[v + 1] = nil; end end\n\n"
    }

    local tokTableLen = 0
    local buffLen = 4

    local i = 1
    local l = #SOURCE

    while (i <= l) do
        for minPos, maxPos, tokType, tokStr in RegExp:GmatchAllRegularTokens(SOURCE) do
            if (tokType ~= "W1" and i <= maxPos) then
                local reference = {tokType, minPos, maxPos, tokStr}

                if (tokType == "Number") then
                    local convertToListArgs = RegExp:GetAllSpecificTokensFromString(SOURCE:sub(minPos), "ListArgs"):Join() -- basically recurses and gets every possible argument for us.
                    if (convertToListArgs) then
                        maxPos = (minPos + convertToListArgs[3]) -- remember we used sub here ^
                        reference = convertToListArgs
                    end
                    
                    if (tokTableLen > 0) then
                        if (validTokens[tokTableLen][1] == "Keyword" and tokType == "Number") then
                            table.insert(reference, 4, validTokens[tokTableLen][4])
                            reference[1] = "KeywordExpr"

                            tokTableLen = tokTableLen - 1
                        end
                    end
                end

                if (tokTableLen > 0) then
                    if (validTokens[tokTableLen][1] == "KeywordExpr" and tokType == "EndExpr") then
                        table.insert(validTokens[tokTableLen], ';')
                        reference = nil
                    end
                end

                if reference then
                    tokTableLen = tokTableLen + 1
                    validTokens[tokTableLen] = reference -- this is how its arranged [TYPE, MIN, MAX, ...]
                end

                i = maxPos
            end
            if (maxPos > i) then
                i = maxPos
            end
        end

        if (i <= l) then
            print("\nerror: unexpected token?: '" .. SOURCE:sub(i - 1, i - 1) .. "', near token '" .. (validTokens[tokTableLen] or {"undefined"})[1] .. '\'')
            return ''
        end
    end

    for x, token in ipairs(validTokens) do
        local toktype = token[1]
        local start = 4

        if (toktype == "KeywordExpr") then
            local keytype = token[4]
            start = 5

            buffLen = buffLen + 1

            if keytype == "input" then 
                luaBuffer[buffLen] = "INPUT("
            elseif keytype == "output" then
                luaBuffer[buffLen] = "OUTPUT("
            elseif keytype == "remove" then
                luaBuffer[buffLen] = "REMOVE("
            end

            for i = start, #token do
                buffLen = buffLen + 1
                luaBuffer[buffLen] = token[i]
            end
            if luaBuffer[buffLen] == ';' then
                luaBuffer[buffLen] = ');\n' -- override last semicolon e.e
            else
                buffLen = buffLen + 1
                luaBuffer[buffLen] = ');\n'
            end
        else
            print("\nerror: no complete expression: ? found " .. toktype .. " token '" .. token[4] .. '\'');
            return ''
        end
    end

    return table.concat(luaBuffer)
end

lua = Interpret(SOURCE);

-- test run now shall we?
(loadstring or load)(lua)();
