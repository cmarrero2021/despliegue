-- Add two_factor_enabled to session_settings
ALTER TABLE session_settings ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN DEFAULT TRUE;

-- Add two_factor_enabled to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN DEFAULT TRUE;

-- Update existing records if necessary (though DEFAULT TRUE handles it for new/existing usually, 
-- but explicitly ensuring they are TRUE for existing users)
UPDATE session_settings SET two_factor_enabled = TRUE WHERE two_factor_enabled IS NULL;
UPDATE users SET two_factor_enabled = TRUE WHERE two_factor_enabled IS NULL;
