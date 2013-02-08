BEGIN;

SELECT no_plan();
SELECT tables_are(
       ARRAY[
             -- Authz's "things"
             'container',
             'auth_actor',
             'auth_group',
             'auth_object',

             -- Permission tables
             'object_acl_group',
             'object_acl_actor',
             'actor_acl_group',
             'actor_acl_actor',
             'group_acl_group',
             'group_acl_actor',
             'container_acl_group',
             'container_acl_actor',

             -- Group membership tables
             'group_group_relations',
             'group_actor_relations'
         ]);

SELECT enums_are(ARRAY['auth_permission']);

-- All authz_id columns should be unique and non-NULL
SELECT col_is_unique('container', 'authz_id');
SELECT col_is_unique('auth_actor', 'authz_id');
SELECT col_is_unique('auth_group', 'authz_id');
SELECT col_is_unique('auth_object', 'authz_id');

SELECT col_not_null('container', 'authz_id');
SELECT col_not_null('auth_actor', 'authz_id');
SELECT col_not_null('auth_group', 'authz_id');
SELECT col_not_null('auth_object', 'authz_id');

-- But the 'id' column is the real PK
SELECT col_is_pk('container', ARRAY['id']);
SELECT col_is_pk('auth_actor', ARRAY['id']);
SELECT col_is_pk('auth_group', ARRAY['id']);
SELECT col_is_pk('auth_object', ARRAY['id']);

SELECT col_type_is('container','id','bigint');
SELECT col_type_is('auth_actor','id','bigint');
SELECT col_type_is('auth_group','id','bigint');
SELECT col_type_is('auth_object','id','bigint');

SELECT col_type_is('container', 'name', 'text');

-- All permission tables have the exact same columns, and all create the PKs
SELECT columns_are('object_acl_group', ARRAY['target', 'authorizee', 'permission']);
SELECT columns_are('object_acl_actor', ARRAY['target', 'authorizee', 'permission']);
SELECT columns_are('actor_acl_group', ARRAY['target', 'authorizee', 'permission']);
SELECT columns_are('actor_acl_actor', ARRAY['target', 'authorizee', 'permission']);
SELECT columns_are('group_acl_group', ARRAY['target', 'authorizee', 'permission']);
SELECT columns_are('group_acl_actor', ARRAY['target', 'authorizee', 'permission']);
SELECT columns_are('container_acl_group', ARRAY['target', 'authorizee', 'permission']);
SELECT columns_are('container_acl_actor', ARRAY['target', 'authorizee', 'permission']);

SELECT col_is_pk('object_acl_group', ARRAY['target', 'authorizee', 'permission']);
SELECT col_is_pk('object_acl_actor', ARRAY['target', 'authorizee', 'permission']);
SELECT col_is_pk('actor_acl_group', ARRAY['target', 'authorizee', 'permission']);
SELECT col_is_pk('actor_acl_actor', ARRAY['target', 'authorizee', 'permission']);
SELECT col_is_pk('group_acl_group', ARRAY['target', 'authorizee', 'permission']);
SELECT col_is_pk('group_acl_actor', ARRAY['target', 'authorizee', 'permission']);
SELECT col_is_pk('container_acl_group', ARRAY['target', 'authorizee', 'permission']);
SELECT col_is_pk('container_acl_actor', ARRAY['target', 'authorizee', 'permission']);

-- The group membership tables also have the same columns, and all of them make up the PKs
SELECT columns_are('group_group_relations', ARRAY['parent','child']);
SELECT columns_are('group_actor_relations', ARRAY['parent','child']);

SELECT col_is_pk('group_group_relations', ARRAY['parent','child']);
SELECT col_is_pk('group_actor_relations', ARRAY['parent','child']);

-- Test the FKs now
SELECT fk_ok('group_acl_actor', 'target', 'auth_group', 'id');
SELECT fk_ok('group_acl_actor', 'authorizee', 'auth_actor', 'id');
SELECT fk_ok('group_acl_group', 'target', 'auth_group', 'id');
SELECT fk_ok('group_acl_group', 'authorizee', 'auth_group', 'id');

SELECT fk_ok('object_acl_actor', 'target', 'auth_object', 'id');
SELECT fk_ok('object_acl_actor', 'authorizee', 'auth_actor', 'id');
SELECT fk_ok('object_acl_group', 'target', 'auth_object', 'id');
SELECT fk_ok('object_acl_group', 'authorizee', 'auth_group', 'id');

SELECT fk_ok('actor_acl_actor', 'target', 'auth_actor', 'id');
SELECT fk_ok('actor_acl_actor', 'authorizee', 'auth_actor', 'id');
SELECT fk_ok('actor_acl_group', 'target', 'auth_actor', 'id');
SELECT fk_ok('actor_acl_group', 'authorizee', 'auth_group', 'id');

SELECT fk_ok('container_acl_actor', 'target', 'container', 'id');
SELECT fk_ok('container_acl_actor', 'authorizee', 'auth_actor', 'id');
SELECT fk_ok('container_acl_group', 'target', 'container', 'id');
SELECT fk_ok('container_acl_group', 'authorizee', 'auth_group', 'id');

SELECT finish();
ROLLBACK;
