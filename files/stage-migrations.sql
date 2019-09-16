#Queries for stage environnement

#add /stage to base_path
UPDATE s_core_shops SET base_path = IF(s_core_shops.base_path IS NULL, '/stage', CONCAT(s_core_shops.base_path, '/stage'));

#enable maintance mode
UPDATE s_core_config_elements SET value = 'b:1;' WHERE name='setoffline';

#set metarobots to noindex/nofollow
UPDATE s_core_snippets SET value = 'noindex,nofollow' WHERE name='IndexMetaRobots';
