env.info( "[JTF-1] mission_files" )
--
-- CORE MODULES ADMIN (must include mission_init_data)
--
__JTFLoader.Include( 'lib/Moose.lua' )                          -- library file
__JTFLoader.Include( 'lib/skynet-iads-compiled.lua' )           -- library file
__JTFLoader.Include( 'core/mission_init.lua' )                  -- core file
__JTFLoader.Include( 'mission_init_data.lua' )          
__JTFLoader.Include( 'core/devcheck.lua' )                      -- core file
__JTFLoader.Include( 'core/missionsrs.lua' )                    -- core file
--__JTFLoader.Include( 'core/adminmenu.lua' )                     -- core file
__JTFLoader.Include( 'core/mission_menu.lua' )                  -- core file
__JTFLoader.Include( 'core/missiontimer.lua' )                  -- core file
__JTFLoader.Include( 'core/supportaircraft.lua' )               -- core file
__JTFLoader.Include( 'core/staticranges.lua' )                  -- core file
__JTFLoader.Include( 'core/activeranges.lua' )                  -- core file
__JTFLoader.Include( 'core/missiletrainer.lua' )                -- core file
__JTFLoader.Include( 'core/markspawn.lua' )                     -- core file
__JTFLoader.Include( 'core/bfmacm.lua' )                        -- core file
__JTFLoader.Include( 'core/Hercules_Cargo.lua' )                -- core file
--
-- TEMPLATES
--
__JTFLoader.Include( 'core/spawntemplates.lua' )                -- core file
--__JTFLoader.Include( 'core/supportaircraft_templates.lua' )     -- core file

--
-- LOCAL MODULES
--
__JTFLoader.Include( 'disableai.lua' )
__JTFLoader.Include( 'movingtargets.lua' )
__JTFLoader.Include( 'ecs.lua' )
__JTFLoader.Include( 'bvrgci.lua' )
--
-- DATA
--
__JTFLoader.Include( 'missionsrs_data.lua' )            
--__JTFLoader.Include( 'adminmenu_data.lua' )             
__JTFLoader.Include( 'missiontimer_data.lua' )
__JTFLoader.Include( 'supportaircraft_data.lua' )
__JTFLoader.Include( 'staticranges_data.lua' )
__JTFLoader.Include( 'activeranges_data.lua' )
__JTFLoader.Include( 'markspawn_data.lua' )
__JTFLoader.Include( 'missiletrainer_data.lua' )
__JTFLoader.Include( 'bfmacm_data.lua' )
--
-- JTF END
--
__JTFLoader.Include( 'core/mission_end.lua' )                   -- core file
--
-- LEGACY SCRIPTS
--