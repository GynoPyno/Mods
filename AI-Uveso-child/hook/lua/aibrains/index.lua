-- Registrazione delle personality OverwhelmPlus nel keyToBrain di FAF.
-- Usa la nostra subclass che imposta self.Uveso = true anche per personality
-- che non contengono "uveso" nel nome (check in uveso-ai.lua riga 10).
keyToBrain['overwhelmplus']      = import("/mods/AI-Uveso-child/lua/AI/overwhelmplusai.lua").AIBrain
keyToBrain['overwhelmpluscheat'] = import("/mods/AI-Uveso-child/lua/AI/overwhelmplusai.lua").AIBrain
