select* from users;

-- merge into alternative
INSERT INTO users (id, username, email)
    VALUES (1, 'Claire Scarlett', '"cscarlett13@yb.com"')
    ON CONFLICT (id)
    DO
	-- NOTHING
	UPDATE SET username = EXCLUDED.username, email = EXCLUDED.email
;
