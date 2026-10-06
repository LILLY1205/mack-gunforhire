--[[
    Locale System for mack-gunforhire
    Provides translation functionality with fallback to English
]]

Locales = {}

-- Get translation with fallback
function _L(key, ...)
    local locale = Config.Locale or 'en'
    local translation = nil
    
    -- Try to get from current locale
    if Locales[locale] and Locales[locale][key] then
        translation = Locales[locale][key]
    -- Fallback to English
    elseif Locales['en'] and Locales['en'][key] then
        translation = Locales['en'][key]
    -- Return key if not found
    else
        return key
    end
    
    -- Handle format arguments
    local args = {...}
    if #args > 0 then
        return string.format(translation, table.unpack(args))
    end
    
    return translation
end

-- Alias for compatibility
Lang = _L
