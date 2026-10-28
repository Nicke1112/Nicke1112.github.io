# obsidain-anticheat

React security dashboard and a framework independent FiveM server validation resource.

## Dashboard

`npm install`, then `npm run dev` (port 5173). `npm run build` generates `dist/` for static hosting. The dashboard is an interactive **demo**, not a connected administration service. Search, category filters, details, report download and session-only manual bans work with sample data. Protection switches change preview state only. Period selection uses sample aggregates. Refresh resets changes. The dashboard is not bundled as FiveM NUI and does not send administration commands.

## FiveM installation

Copy `obsidain-anticheat/` into your server resources folder. Make it writable for persistent `bans.json`. Back up that file. Add to server.cfg:

```cfg
ensure obsidain-anticheat
add_ace group.admin obsidain.admin allow
# Assign your administrators to group.admin using your existing ACE setup.
```

Console / authorized administrators:

- `obsidain-ban <server ID> <reason>` persists a license ban and disconnects the player.
- `obsidain-unban <license:identifier>` removes a ban.

## Integrate each sensitive resource

There is no ESX/QBCore dependency. Framework-specific actions still need integration in their own server handlers. Always derive player identity from FiveM's `source`. Validate ownership, inventory, money, position and permissions using server-owned data before side effects. Example inside an existing server event:

```lua
local player = source
-- This must come from your own SERVER checks; never take it from event arguments.
local valid = serverVerifiedOwnershipAndBalance(player)
if not exports['obsidain-anticheat']:ValidateAction(player, 'purchase', valid) then
    return
end
-- Perform the authorized transaction here, atomically in your framework.
```

Configure rate limits in config.lua. Unknown rules fail closed. Automatic bans are OFF by default. Rate limits block actions and log incidents, but do not automatically ban. Only enable AutoBan after ensuring failed validation proves abuse, rather than normal invalid requests. Incidents are bounded to the latest 500 and held in memory; bans are persisted. A server-only GetIncidents export allows a future authenticated admin integration.

## Limits and verification

React does not conceal source code or prevent copying. Client-side resource dumping cannot be reliably detected by a generic script. The resource does not implement dumper, movement, weapon or injection detection; those categories in the dashboard are illustrative. It protects only actions whose handlers invoke the server export. Do not treat this starter resource as comprehensive anticheat or universal automatic protection for arbitrary third-party scripts.

No live FiveM server is included in this environment. Test event integration, connection rejection, ACE access, persistence and restart on a staging server before production. A web deployment requires a separately authenticated backend before it can administer real bans.
