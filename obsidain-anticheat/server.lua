local resource = GetCurrentResourceName()
local bans, buckets, incidents = {}, {}, {}
local raw = LoadResourceFile(resource, 'bans.json')
if raw then
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then error('Obsidain: invalid bans.json; restore it before starting') end
    bans = decoded
end
local function licenseOf(player)
    for _, identifier in ipairs(GetPlayerIdentifiers(player)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
end
local function persist()
    return SaveResourceFile(resource, 'bans.json', json.encode(bans), -1)
end
local function report(player, rule, reason)
    incidents[#incidents + 1] = { player = player, rule = rule, reason = reason, time = os.time() }
    if #incidents > 500 then table.remove(incidents, 1) end
    print(('[Obsidain] player=%s rule=%s reason=%s'):format(player, rule, reason))
end
local function ban(player, reason, actor)
    local identifier = licenseOf(player)
    if not identifier then return false, 'Player has no license identifier' end
    local previous = bans[identifier]
    bans[identifier] = { reason = tostring(reason):sub(1, 250), actor = actor, time = os.time() }
    if not persist() then bans[identifier] = previous; return false, 'Ban storage failed' end
    DropPlayer(player, 'Obsidain: ' .. bans[identifier].reason)
    return true
end
-- Server-only export. Call BEFORE any sensitive side effect. Never expose an
-- event accepting a client-provided player ID, verdict, rule name or ban reason.
exports('ValidateAction', function(player, ruleName, valid)
    player = tonumber(player)
    if not player or not GetPlayerName(player) then return false end
    local rule = Config.Rules[ruleName]
    if not rule then return false end
    local key, now = player .. ':' .. ruleName, os.time()
    local bucket = buckets[key]
    if not bucket or now - bucket.started >= rule.window then
        bucket = { started = now, count = 0 }; buckets[key] = bucket
    end
    bucket.count = bucket.count + 1
    if valid ~= true or bucket.count > rule.limit then
        local reason = valid ~= true and 'Server validation failed' or 'Rate limit exceeded'
        report(player, ruleName, reason)
        -- Rate limiting alone never bans: legitimate bursts can occur.
        if Config.AutoBan and valid ~= true then ban(player, ruleName .. ': ' .. reason, 'server') end
        return false
    end
    return true
end)
AddEventHandler('playerConnecting', function(_, _, deferrals)
    local player = source
    deferrals.defer(); Wait(0)
    local identifier = licenseOf(player)
    local entry = identifier and bans[identifier]
    if entry then deferrals.done('Obsidain: ' .. entry.reason) else deferrals.done() end
end)
AddEventHandler('playerDropped', function()
    local prefix = source .. ':'
    for key in pairs(buckets) do if key:sub(1, #prefix) == prefix then buckets[key] = nil end end
end)
local function allowed(player)
    return player == 0 or IsPlayerAceAllowed(player, Config.AdminAce)
end
RegisterCommand('obsidain-ban', function(player, args)
    if not allowed(player) then return end
    local target = tonumber(args[1]); local reason = table.concat(args, ' ', 2)
    if not target or not GetPlayerName(target) or reason == '' then print('Usage: obsidain-ban <server ID> <reason>'); return end
    local ok, err = ban(target, reason, tostring(player))
    if not ok then print('Obsidain: ' .. err) end
end, false)
RegisterCommand('obsidain-unban', function(player, args)
    if not allowed(player) then return end
    local identifier = args[1]
    if not identifier or not bans[identifier] then return end
    local previous = bans[identifier]; bans[identifier] = nil
    if not persist() then bans[identifier] = previous; print('Obsidain: failed to persist unban') end
end, false)
exports('GetIncidents', function() return json.decode(json.encode(incidents)) end)
