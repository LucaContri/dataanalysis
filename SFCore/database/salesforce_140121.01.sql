# Add column to sf_tables to regulate max sync frequency on a table basis
ALTER TABLE salesforce.sf_tables ADD COLUMN MinSecondsBetweenSyncs INT UNSIGNED NOT NULL DEFAULT 3600;