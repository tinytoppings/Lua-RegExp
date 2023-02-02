-- Version: 1.0; Lua RegExp object; Made by: tinytop
-- 1/30/2023 (DD/MM/YYYY)

local function NewRegExp()
    local RegExp = {
        TokenType = {}
    }

    function RegExp:NewTokenType(tokName, tokenPattern)
        self.TokenType[tokName] =
        {
            Type = "Regular",
            Pattern = tokenPattern
        }

        return RegExp
    end
    function RegExp:NewComplexTokenType(tokName, tokenPattern)
        self.TokenType[tokName] =
        {
            Type = "Complex"
        }
        -- EX: "<!playerName><(%b())><?playerSpeed>"

        local finalizedStrings = {}
        local complexPatterns = {}

        for cpat = 1, #tokenPattern do
            finalizedStrings[cpat] = {}
            finalizedStrings[cpat].max = 0

            tokenPattern[cpat]:gsub("(%b<>)", function(x)
                local prefix = x:sub(2,2)
                
                if prefix == '?' then
                    finalizedStrings[cpat].max = finalizedStrings[cpat].max + 1

                    local raw = x:sub(3,-2)
                    local len = #finalizedStrings[cpat] + 1
                    local am = 1

                    for name in string.gmatch(raw, "([^,]+)") do
                        if not self.TokenType[name] then
                            error(("token-type \"%s\" not found within RegExp object."):format(name))
                        end
                        finalizedStrings[cpat][len] = ("`%d~%d~%s`"):format(finalizedStrings[cpat].max, am, name)

                        len = len + 1
                        am = am + 1
                    end

                    return nil
                elseif prefix == '!' then
                    local raw = x:sub(3,-2)
                    local len = #finalizedStrings[cpat] + 1

                    for name in string.gmatch(raw, "([^,]+)") do
                        if not self.TokenType[name] then
                            error(("token-type \"%s\" not found within RegExp object."):format(name))
                        end
                        finalizedStrings[cpat][len] = self.TokenType[name].Pattern[1]

                        len = len + 1
                    end
                    return nil
                end

                finalizedStrings[cpat][#finalizedStrings[cpat] + 1] = x:sub(2,-2)
                return nil
            end)
        end

        for find = 1, #finalizedStrings do
            local dummyPatterns = {}

            local next = 0
            local counter = 1
            local min, max = 0, 0
            local clen = #complexPatterns

            local current = finalizedStrings[find]
            local amax = current.max

            if amax > 0 then
                while (counter <= amax) do
                    local next = '`' .. counter .. "~%d+~([%a_]+[%a%d_]*)`"
                    if max == 0 then
                        local s = table.concat(current)
                        local len = #dummyPatterns + 1

                        for name in string.gmatch(s, next) do
                            for p = 1, #self.TokenType[name].Pattern do
                                dummyPatterns[len] = s:gsub(next, function() return self.TokenType[name].Pattern[p] end, 1):gsub(next,'')
                                len = len + 1
                            end
                        end
                        
                        min = 1
                        max = #dummyPatterns
                    else
                        local len = #dummyPatterns
                        for r = min, max do
                            for name in string.gmatch(dummyPatterns[r], next) do
                                for p = 1, #self.TokenType[name].Pattern do
                                    len = len + 1
                                    dummyPatterns[len] = dummyPatterns[r]:gsub(next, function() return self.TokenType[name].Pattern[p] end, 1):gsub(next, '')
                                end
                            end
                        end
                        min = max + 1
                        max = len
                    end
                    
                    counter = counter + 1
                end
            else
                dummyPatterns[find] = table.concat(current)
            end

            for completed = min, max do
                clen = clen + 1
                complexPatterns[clen] = dummyPatterns[completed]
            end
        end

        self.TokenType[tokName].Pattern = complexPatterns
    end

    function RegExp:RemoveGeneralTokenType(tokName)
        self.TokenType[tokName] = nil
    end

    function RegExp:HookEventToToken(tokName, f)
        if type(f) ~= "function" then
            error("attempted to hook event that is not of type \"function\"")
        end
        if not self.TokenType[tokName] then
            error(("token-type \"%s\" not found within RegExp object."):format(tokName))
        end

        self.TokenType[tokName].Event = f
    end
    function RegExp:UnhookEventToToken(tokName)
        if not self.TokenType[tokName] then
            error(("token-type \"%s\" not found within RegExp object."):format(tokName))
        end

        self.TokenType[tokName].Event = nil
    end
    function RegExp:GetTokenEvent(tokName)
        if not self.TokenType[tokName] then
            error(("token-type \"%s\" not found within RegExp object."):format(tokName))
        end
        if not self.TokenType[tokName].Event then
            error(("token-type \"%s\": no event hooked."):format(tokName))
        end

        return self.TokenType[tokName].Event
    end

    function RegExp:GetTokenType(tokName)
        return (self.TokenType[tokName] or {}).Type
    end
    
    function RegExp:GetTokenFromString(str)
        for t, v in pairs(self.TokenType) do
            for i = 1, #v.Pattern do
                if str:match('^' .. v.Pattern[i]) then
                    if v.Event then
                        local r = {t, str:find('^' .. v.Pattern[i])}

                        if v.Event((unpack or table.unpack)(r, 4)) then
                            return r
                        end
                    else
                        return {t, str:find('^' .. v.Pattern[i])}
                    end
                end
            end
        end
        return nil
    end
    function RegExp:GetRegularTokenFromString(str)
        for t, v in pairs(self.TokenType) do
            if v.Type == "Regular" then
                for i = 1, #v.Pattern do
                    if str:match('^' .. v.Pattern[i]) then
                        if v.Event then
                            local r = {t, str:find('^' .. v.Pattern[i])}

                            if v.Event((unpack or table.unpack)(r, 4)) then
                                return r
                            end
                        else
                            return {t, str:find('^' .. v.Pattern[i])}
                        end
                    end
                end
            end
        end
        return nil
    end
    function RegExp:GetComplexTokenFromString(str)
        for t, v in pairs(self.TokenType) do
            if v.Type == "Complex" then
                for i = 1, #v.Pattern do
                    if str:match('^' .. v.Pattern[i]) then
                        if v.Event then
                            local r = {t, str:find('^' .. v.Pattern[i])}

                            if v.Event((unpack or table.unpack)(r, 4)) then
                                return r
                            end
                        else
                            return {t, str:find('^' .. v.Pattern[i])}
                        end
                    end
                end
            end
        end
        return nil
    end
    function RegExp:GetSpecificTokenFromString(str, tokName)
        if not self.TokenType[tokName] then
            error(("token-type \"%s\" not found within RegExp object."):format(tokName))
        end

        local v = self.TokenType[tokName]
        for i = 1, #v.Pattern do
            if str:match('^' .. v.Pattern[i]) then
                if v.Event then
                    local r = {t, str:find('^' .. v.Pattern[i])}

                    if v.Event((unpack or table.unpack)(r, 4)) then
                        return r
                    end
                else
                    return {t, str:find('^' .. v.Pattern[i])}
                end
            end
        end
    end
    function RegExp:GetAllSpecificTokensFromString(str, tokName)
        if not self.TokenType[tokName] then
            error(("token-type \"%s\" not found within RegExp object."):format(tokName))
        end

        local v = self.TokenType[tokName]
        local c = 1
        local f = true
        local l = #str
        local ret = {tokName, 0, 0}

        local firstNum = false
        local lastNum = 0
        while f and c <= l do
            f = false
            for i = 1, #v.Pattern do
                if str:sub(c):match('^' .. v.Pattern[i]) then
                    local r = {str:sub(c):find('^' .. v.Pattern[i])}
                    if v.Event then
                        if v.Event((unpack or table.unpack)(r, 4)) then
                            c = c + r[2]
                            ret[#ret + 1] = r

                            f = true

                            if not firstNum then
                                firstNum = r[1]
                            end

                            lastNum = c
                        end
                    else
                        r[1] = c
                        c = c + r[2]
                        r[2] = c
                        ret[#ret + 1] = r

                        f = true

                        if not firstNum then
                            firstNum = r[1]
                        end
                        lastNum = c
                    end
                end
            end
        end

        ret[2] = firstNum
        ret[3] = lastNum

        function ret:Join()
            local new = {tokName, firstNum, lastNum}
            
            local len = 3
            for i = 4, #self do
                for x = 3, #self[i] do
                    len = len + 1
                    new[len] = self[i][x]
                end
            end

            return new
        end
        return ret
    end

    function RegExp:StringMatchesToken(str, tokName)
        if not self.TokenType[tokName] then
            error(("token-type \"%s\" not found within RegExp object."):format(tokName))
        end

        local v = self.TokenType[tokName]
        for i = 1, #v.Pattern do
            if str:match('^' .. v.Pattern[i]) then
                if v.Event then
                    local r = {t, str:find('^' .. v.Pattern[i])}

                    if v.Event((unpack or table.unpack)(r, 4)) then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end

    function RegExp:GmatchAllTokens(str)
        local lmax = #str
        local cmax, lower = 1, 0

        return function()
            local b = self:GetTokenFromString(str:sub(cmax))

            if b then
                lower = cmax
                cmax = cmax + b[3]

                return (lower), (cmax), b[1], (table.unpack or unpack)(b, 4)
            end
        end
    end
    function RegExp:GmatchAllComplexTokens(str)
        local lmax = #str
        local cmax, lower = 1, 0

        return function()
            local b = self:GetComplexTokenFromString(str:sub(cmax))

            if b then
                lower = cmax
                cmax = cmax + b[3]
                
                return (lower), (cmax), b[1], (table.unpack or unpack)(b, 4)
            end
        end
    end
    function RegExp:GmatchAllRegularTokens(str)
        local lmax = #str
        local cmax, lower = 1, 0

        return function()
            local b = self:GetRegularTokenFromString(str:sub(cmax))

            if b then
                lower = cmax
                cmax = cmax + b[3]

                return (lower), (cmax), b[1], (table.unpack or unpack)(b, 4)
            end
        end
    end

    function RegExp:Print()
        for k, v in pairs(self.TokenType) do
            print(k .. ":")
            for i = 1, #v.Pattern do
                print("\t" .. v.Pattern[i])
            end

            print("\n")
        end
    end
    function RegExp:ToRawLua()
        local buffer = {}
        local len = #buffer
        for k, v in pairs(self.TokenType) do
            len = len + 1
            buffer[len] = ('\n' .. k) .. (' = { Type = "' .. v.Type .. '", ')

            for _, pat in ipairs(v.Pattern) do
                len = len + 1
                buffer[len] = ('"' .. pat) .. '"'
                len = len + 1
                buffer[len] = ', '
            end

            buffer[len] = ' }'
        end

        return table.concat(buffer)
    end

    return RegExp
end

return NewRegExp
