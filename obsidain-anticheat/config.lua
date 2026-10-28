Config = {}
-- Enable only after testing your resource integrations on a staging server.
Config.AutoBan = false
Config.AdminAce = 'obsidain.admin'
Config.Rules = {
    purchase = { limit = 10, window = 10 },
    inventory = { limit = 20, window = 10 }
}
