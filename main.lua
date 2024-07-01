-- name: Sonic Character: \\#4084d9\\Rebooted\\#ffffff\\ \\#fd90a7\\v1.2\\#ffffff\\
-- incompatible:
-- description: The Sonic character mod remade with a couple of improvement in controls, as well as new characters.\n\ \n\Credits:\n\Coding and modelling: \\#acfffc\\steven.\\#ffffff\\\n\Ball model: \\#5454a7\\king the memer\\#ffffff\\\n\Sonic VA: \\#ff5c26\\Yuyake Kasarion\\#ffffff\\\n\Voice system: \\#ff6b91\\SMS Alfredo \\#ffffff\\\n\Coolest playtesters: \\#016786\\Asra\\#ffffff\\, \\#99fe02\\MlopsFunny\\#ffffff\\, \\#6a9ac3\\Cooliokid 956\\#ffffff\\, \\#171b73\\Demnyx\\#4b1c75\\Onyxfur\\#ffffff\\, \\#9856ac\\Zerks\\#ffffff\\.

E_MODEL_SONIC = smlua_model_util_get_id("sonic_geo")
E_MODEL_AMY_ROSE = smlua_model_util_get_id("amy_rose_geo")
E_MODEL_AMY_ROSE_WINTER = smlua_model_util_get_id("amy_rose_winter_geo")
E_MODEL_SPINBALL = smlua_model_util_get_id("spinball_geo")

SOUND_SONIC_JUMP = audio_sample_load("SA1-Jump.mp3")
SOUND_SONIC_SPIN = audio_sample_load("SA1-Spin.mp3")
SOUND_SONIC_DASH = audio_sample_load("SA1-Dash.mp3")
SOUND_SONIC_RING = audio_sample_load("SA1-Ring.mp3")
SOUND_AMY_PIKO = audio_sample_load("Piko.mp3")

ACT_SONIC_AIR_HIT_WALL = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)

gMarioStateExtras = {}
for i = 0, (MAX_PLAYERS - 1) do
    gMarioStateExtras[i] = {}
    local m = gMarioStates[i]
    local e = gMarioStateExtras[i]
    
    -- Animations.
    e.rotAngle = 0
    e.animFrame = 0
    e.rotFrames = 0
    e.squishFrame = 0
    e.modelState = 0
    
    -- Moveset related.
    e.lastforwardVel = 0
    e.dashspeed = 0
    e.snapLimit = 0 -- SHADOW THE HEDGEHOG IS A BITCH ASS MOTHE-
    e.airdashed = 0
    e.wallClimbed = 0
    e.ballTimer = 0
    e.moveAngle = 0
    e.spawnDelay = 0
    e.peakHeightDelay = 0
    e.preVel = 0
    
    -- Stats.
    e.movingSpeed = 0
    e.movingSpeedSlow = 0
    e.jumpHeight = 0
    e.jumpHeightMultiplier = 0
    e.walkAction = 0
end

sonicchars = 0

-- General functions.
function current_sonic_char(m)
    if gPlayerSyncTable[m.playerIndex].modelId == E_MODEL_SONIC then
        return 1
    elseif gPlayerSyncTable[m.playerIndex].modelId == E_MODEL_AMY_ROSE 
    or gPlayerSyncTable[m.playerIndex].modelId == E_MODEL_AMY_ROSE_WINTER then
        return 2
    else
        return 0
    end
end

function sonic_air_attacks(m)
    local e = gMarioStateExtras[m.playerIndex]
    if current_sonic_char(m) == 1 then
        if (m.input & INPUT_NONZERO_ANALOG) ~= 0 and e.wallClimbed == 0 then
            m.action = ACT_DROPDASH
            audio_sample_play(SOUND_SONIC_SPIN, m.pos, 1)
        else
            set_mario_action(m, ACT_JUMP_KICK, 0)
        end
    elseif current_sonic_char(m) == 2 then
        set_mario_action(m, ACT_AMY_HAMMER_ATTACK_AIR, 0)
    end
end

function convert_s16(num)
    local min = -32768
    local max = 32767
    while (num < min) do
        num = max + (num - min)
    end
    while (num > max) do
        num = min + (num - max)
    end
    return num
end

function update_sonic_walking_speed(m)
    local e = gMarioStateExtras[m.playerIndex]
    local maxTargetSpeed = 0
    local targetSpeed = 0

    if (m.floor ~= nil and m.floor.type == SURFACE_SLOW) then
        maxTargetSpeed = e.movingSpeedSlow
    else
        maxTargetSpeed = e.movingSpeed
    end

    if m.intendedMag < 24 then
        targetSpeed = m.intendedMag
    else
        targetSpeed = maxTargetSpeed
    end

    if (m.quicksandDepth > 10.0) then
        targetSpeed = targetSpeed * (6.25 / m.quicksandDepth)
    end

    if (m.forwardVel <= 0.0) then
        m.forwardVel = m.forwardVel + 1.1
    elseif (m.forwardVel <= targetSpeed) then
        m.forwardVel = m.forwardVel + (1.1 - m.forwardVel / targetSpeed)
        --elseif (m.floor ~= nil and m.floor.normal.y >= 0.95) then
        --m.forwardVel = m.forwardVel - 1.0
    end

    if m.forwardVel > 250 then
        m.forwardVel = 250
    end

    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x800, 0x800)

    apply_slope_accel(m)
end

function sonic_update_air(m)
    local e = gMarioStateExtras[m.playerIndex]
    local sidewaysSpeed = 0.0
    local dragThreshold = 0
    local intendedDYaw = 0
    local intendedMag = 0

    if (check_horizontal_wind(m)) == 0 then
        dragThreshold = e.movingSpeed

        if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
            intendedDYaw = m.intendedYaw - m.faceAngle.y
            intendedMag = m.intendedMag / 32.0
            m.forwardVel = m.forwardVel + intendedMag * coss(intendedDYaw) * 1.5
            if m.forwardVel > dragThreshold then
                m.forwardVel = m.forwardVel - 1.5
            end
            sidewaysSpeed = intendedMag * sins(intendedDYaw) * dragThreshold
        else
            m.forwardVel = approach_f32(m.forwardVel, 0.0, 1, 1)
        end

        --! Uncapped air speed. Net positive when moving forward.
        if (m.forwardVel > dragThreshold) then
            m.forwardVel = m.forwardVel
        end
        if (m.forwardVel < -32.0) then
            m.forwardVel = m.forwardVel + 2.0
        end

        m.slideVelX = m.forwardVel * sins(m.faceAngle.y)
        m.slideVelZ = m.forwardVel * coss(m.faceAngle.y)

        m.slideVelX = m.slideVelX + sidewaysSpeed * sins(m.faceAngle.y + 0x4000)
        m.slideVelZ = m.slideVelZ + sidewaysSpeed * coss(m.faceAngle.y + 0x4000)

        m.vel.x = approach_f32(m.vel.x, m.slideVelX, 1, 1)
        m.vel.z = approach_f32(m.vel.z, m.slideVelZ, 1, 1)
    end
end

function sonic_common_air_action_step(m, landAction, animation, stepArg, turning, keepMomentum)
    local e = gMarioStateExtras[m.playerIndex]
    local stepResult = perform_air_step(m, stepArg)

    sonic_update_air(m)
    if turning then
        if math.abs(m.forwardVel) >= 10 then
            m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)
        else
            m.faceAngle.y = m.intendedYaw
        end
        
        if m.faceAngle.y ~= m.intendedYaw and m.forwardVel > 32 then
            mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, m.forwardVel/16, m.forwardVel/16))
        else
            mario_set_forward_vel(m, m.forwardVel)
        end
    end

    if (m.action == ACT_BUBBLED and stepResult == AIR_STEP_HIT_LAVA_WALL) then
        stepResult = AIR_STEP_HIT_WALL
    end

    if stepResult == AIR_STEP_NONE then
        set_mario_animation(m, animation)
    elseif stepResult == AIR_STEP_LANDED then
        if m.vel.x ~= 0 or m.vel.z ~= 0 then
            m.faceAngle.y = atan2s(m.vel.z, m.vel.x)
        end
        if (check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB) == 0) then
            if m.forwardVel ~= 0 and keepMomentum then
                m.marioObj.oMarioWalkingPitch = 0x0000
                set_mario_action(m, e.walkAction, 0)
            else
                set_mario_action(m, landAction, 0)
            end
        end
    elseif stepResult == AIR_STEP_HIT_WALL then
        set_mario_animation(m, animation)

        if (m.forwardVel > 16.0) then
            queue_rumble_data_mario(m, 5, 40)
            mario_bonk_reflection(m, false)
            m.faceAngle.y = m.faceAngle.y + 0x8000

            if (m.wall ~= nil) then
                set_mario_action(m, ACT_SONIC_AIR_HIT_WALL, 0)
            else
                if (m.vel.y > 0.0) then
                    m.vel.y = 0.0
                end

                --! Hands-free holding. Bonking while no wall is referenced
                -- sets Mario's action to a non-holding action without
                -- dropping the object, causing the hands-free holding
                -- glitch. This can be achieved using an exposed ceiling,
                -- out of bounds, grazing the bottom of a wall while
                -- falling such that the final quarter step does not find a
                -- wall collision, or by rising into the top of a wall such
                -- that the final quarter step detects a ledge, but you are
                -- not able to ledge grab it.
                if (m.forwardVel >= 38.0) then
                    set_mario_particle_flags(m, PARTICLE_VERTICAL_STAR, false)
                    set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
                else
                    if (m.forwardVel > 8.0) then
                        mario_set_forward_vel(m, -8.0)
                    end
                    return set_mario_action(m, ACT_SOFT_BONK, 0)
                end
            end
        else
            mario_set_forward_vel(m, 0.0)
        end
    elseif stepResult == AIR_STEP_GRABBED_LEDGE then
        set_mario_animation(m, MARIO_ANIM_IDLE_ON_LEDGE)
        drop_and_set_mario_action(m, ACT_LEDGE_GRAB, 0)
    elseif stepResult == AIR_STEP_GRABBED_CEILING then
        set_mario_action(m, ACT_START_HANGING, 0)
    elseif stepResult == AIR_STEP_HIT_LAVA_WALL then
        lava_boost_on_wall(m)
    end

    return stepResult
end

function sonic_walking_door_check(m)
    local e = gMarioStateExtras[m.playerIndex]
    -- Replacin' the walking action while make sure the player can still open doors.
    local dist = 200
    local doorwarp = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoorWarp)
    local door = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoor)
    local stardoor = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvStarDoor)
    
    
    if m.action == ACT_WALKING then
        if
        (dist_between_objects(m.marioObj, doorwarp) > dist and doorwarp ~= nil) or
        (dist_between_objects(m.marioObj, door) > dist and door ~= nil) or
        (dist_between_objects(m.marioObj, stardoor) > dist and stardoor ~= nil)
        then
            return set_mario_action(m, e.walkAction, 0)
        elseif doorwarp == nil and door == nil and stardoor == nil then
            return set_mario_action(m, e.walkAction, 0)
        end
    end

    if m.action == e.walkAction and m.heldObj == nil then
        if
        (dist_between_objects(m.marioObj, doorwarp) < dist and doorwarp ~= nil) or
        (dist_between_objects(m.marioObj, door) < dist and door ~= nil) or
        (dist_between_objects(m.marioObj, stardoor) < dist and stardoor ~= nil)
        then
            return set_mario_action(m, ACT_WALKING, 0)
        end
    end
end

function sonic_check_wall_kick(m)
    if ((m.input & INPUT_A_PRESSED) ~= 0 and m.wallKickTimer ~= 0 and m.prevAction == ACT_SONIC_AIR_HIT_WALL) then
        m.faceAngle.y = m.faceAngle.y + 0x8000
        return set_mario_action(m, ACT_WALL_KICK_AIR, 0)
    end

    return 0
end

function lua_swimming_near_surface(m)
    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        return false
    end

    return (m.waterLevel - 80) - m.pos.y < 400.0
end

function lua_update_swimming_yaw(m)
    local targetYawVel = -convert_s16(10.0 * m.controller.stickX)

    if (targetYawVel > 0) then
        if (m.angleVel.y < 0) then
            m.angleVel.y = m.angleVel.y + 0x40
            if (m.angleVel.y > 0x10) then    
                m.angleVel.y = 0x10
            end
        else
            m.angleVel.y = approach_s32(m.angleVel.y, targetYawVel, 0x10, 0x20)
        end
    elseif (targetYawVel < 0) then
        if (m.angleVel.y > 0) then
            m.angleVel.y = m.angleVel.y - 0x40
            if (m.angleVel.y < -0x10) then
                m.angleVel.y = -0x10
            end
        else
            m.angleVel.y = approach_s32(m.angleVel.y, targetYawVel, 0x20, 0x10)
        end
    else
        m.angleVel.y = approach_s32(m.angleVel.y, 0, 0x40, 0x40)
    end

    m.faceAngle.y = m.faceAngle.y + m.angleVel.y
    m.faceAngle.z = -m.angleVel.y * 8
end

function lua_update_swimming_pitch(m)
    local targetPitch = -convert_s16(252.0 * m.controller.stickY)

    local pitchVel
    if (m.faceAngle.x < 0) then
        pitchVel = 0x100
    else
        pitchVel = 0x200
    end

    if (m.faceAngle.x < targetPitch) then
        m.faceAngle.x = m.faceAngle.x + pitchVel
        if (m.faceAngle.x > targetPitch) then
            m.faceAngle.x = targetPitch
        end
    elseif (m.faceAngle.x > targetPitch) then
        m.faceAngle.x = m.faceAngle.x - pitchVel
        if (m.faceAngle.x < targetPitch) then
            m.faceAngle.x = targetPitch
        end
    end
end

function lua_update_water_pitch(m)
    local marioObj = m.marioObj

    if (marioObj.header.gfx.angle.y > 0) then
        marioObj.header.gfx.pos.x = marioObj.header.gfx.pos.x + (60.0 * sins(marioObj.header.gfx.angle.y) * sins(marioObj.header.gfx.angle.y))
    end

    if (marioObj.header.gfx.angle.y < 0) then
        marioObj.header.gfx.angle.y = marioObj.header.gfx.angle.y * 6 / 10
    end

    if (marioObj.header.gfx.angle.y > 0) then
        marioObj.header.gfx.angle.y = marioObj.header.gfx.angle.y * 10 / 8
    end
end

function lua_check_water_jump(m)
    if (m.input & INPUT_A_PRESSED) ~= 0 then
        if (m.pos.y + 1.5 >= m.waterLevel - 80 and m.faceAngle.x >= 0 and m.controller.stickY < -60.0) then
            vec3s_set(m.angleVel, 0, 0, 0)

            m.vel.y = 62.0

            if (m.heldObj == nil) then
                return set_mario_action(m, ACT_WATER_JUMP, 0)
            else
                return set_mario_action(m, ACT_HOLD_WATER_JUMP, 0)
            end
        end
    end
end

function move_with_current(m)
    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        return
    end
    local step = {
            x = 0,
            y = 0,
            z = 0
    }
    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
    
    apply_water_current(m, step)
    
    m.pos.x = m.pos.x + step.x
    m.pos.y = m.pos.y + step.y
    m.pos.z = m.pos.z + step.z
end

function mario_update_local(m)
    local p = gNetworkPlayers[m.playerIndex]
    local e = gMarioStateExtras[m.playerIndex]
    if gPlayerSyncTable[m.playerIndex].marioOverride == true then
        p.overrideModelIndex = 0
    else
        p.overrideModelIndex = p.modelIndex
    end

    if sonicchars == 1 then
        if p.modelIndex == 0 then
            gPlayerSyncTable[0].marioOverride = true
            gPlayerSyncTable[0].modelId = E_MODEL_SONIC
        elseif p.modelIndex == 2 then
            gPlayerSyncTable[0].marioOverride = true
            if ((m.area.terrainType & TERRAIN_MASK) == TERRAIN_SNOW) then
                gPlayerSyncTable[0].modelId = E_MODEL_AMY_ROSE_WINTER
            else
                gPlayerSyncTable[0].modelId = E_MODEL_AMY_ROSE
            end
        else
            gPlayerSyncTable[0].marioOverride = false
            gPlayerSyncTable[0].modelId = nil
        end
    elseif sonicchars == 0 then
        gPlayerSyncTable[0].marioOverride = false
        gPlayerSyncTable[0].modelId = nil
    end

    if e.modelState <= 0 then
        gPlayerSyncTable[0].trueModelId = gPlayerSyncTable[0].modelId
    else
        gPlayerSyncTable[0].trueModelId = E_MODEL_SPINBALL
    end

    if m.action == ACT_SPINDASH then
        spawn_spindust(m)
    end
end

function visual_updates(m)
    local e = gMarioStateExtras[m.playerIndex]

    if m.action == ACT_BOUND_POUND or m.action == ACT_GROUND_POUND_LAND then
        e.modelState = 1
    elseif m.action == ACT_SPINDASH or m.action == ACT_DROPDASH or m.action == ACT_SONIC_WATER_SPINDASH then
        e.modelState = 2
    else
        e.modelState = 0
    end

    if m.action == ACT_BOUND_JUMP then
        if m.actionArg == 0 then
            e.modelState = 0
        elseif m.actionArg == 1 then
            if m.actionTimer < 5 then
                e.modelState = 1
            else
                e.modelState = 0
            end
        end
    end

    if
    m.action == ACT_SONIC_JUMP or m.action == ACT_SONIC_ROLL or
    (m.action == ACT_SONIC_WATER_FALLING and m.actionArg == 2 and m.heldObj == nil) or
    m.action == ACT_SONIC_WATER_ROLLING
    then
        local ballTimerAdd = (m.forwardVel) / 25
        if ballTimerAdd < 0.5 then
            ballTimerAdd = 0.5
        elseif ballTimerAdd > 2.5 then
            ballTimerAdd = 2.5
        end
        
        e.ballTimer = e.ballTimer + ballTimerAdd
        if e.ballTimer >= 4 then
            if e.modelState == 0 then
                e.modelState = 1
            elseif e.modelState == 1 then
                e.modelState = 0
            end
            e.ballTimer = 0
        end
    end

    if m.action == ACT_BOUND_POUND then
        m.marioObj.header.gfx.scale.y = 1.5
        m.marioObj.header.gfx.scale.z = 0.7
        m.marioObj.header.gfx.scale.x = 0.7
    end
    if m.action == ACT_SPINDASH or m.action == ACT_SONIC_WATER_SPINDASH then
        m.marioObj.header.gfx.scale.z = 0.7
        m.marioObj.header.gfx.scale.x = 0.7
        m.marioObj.header.gfx.angle.x = m.marioObj.header.gfx.angle.x + 0x2000
        m.marioObj.header.gfx.pos.y = m.pos.y + 15
    end
end

function do_sonic_jump(m)
    local e = gMarioStateExtras[m.playerIndex]
    set_mario_y_vel_based_on_fspeed(m, e.jumpHeight, e.jumpHeightMultiplier)
    if m.heldObj == nil then
        audio_sample_play(SOUND_SONIC_JUMP, m.pos, 1)
        if current_sonic_char(m) == 1 then
            return set_mario_action(m, ACT_SONIC_JUMP, 0)
        elseif current_sonic_char(m) == 2 then
            return set_mario_action(m, ACT_AMY_JUMP, 0)
        end
    else
        return set_mario_action(m, ACT_SONIC_HOLD_JUMP, 0)
    end
end

function spawn_spindust(m)
    local e = gMarioStateExtras[m.playerIndex]
    if e.spawnDelay > 1 then
        spawn_sync_object(
        id_bhvSpinDust,
        E_MODEL_SMOKE,
        m.pos.x,
        m.pos.y,
        m.pos.z,
        function(o)
            o.oMoveAngleYaw = m.marioObj.header.gfx.angle.y + math.random(-0x1000, 0x1000)
            o.oGraphYOffset = o.oGraphYOffset - math.random(20, 40)
        end
        )
        e.spawnDelay = 0
    end
    e.spawnDelay = e.spawnDelay + 1
    return 0
end

-- Hitting wall patched up to fix bonking.
function act_air_hit_wall(m)


    if (m.heldObj ~= nil) then
        mario_drop_held_object(m)
    end

    if m.actionTimer <= 1 then
        if (m.input & INPUT_A_PRESSED) ~= 0 then
            m.vel.y = 52.0
            m.faceAngle.y = m.faceAngle.y + 0x8000
            return set_mario_action(m, ACT_WALL_KICK_AIR, 0)
        end
    end

    if (m.forwardVel >= 69) then
        set_mario_animation(m, MARIO_ANIM_START_WALLKICK)
        m.wallKickTimer = 5
        if (m.vel.y > 0.0) then
            m.vel.y = 0.0
        end

        set_mario_particle_flags(m, PARTICLE_VERTICAL_STAR, false)
        set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
    else
        m.wallKickTimer = 5
        if (m.vel.y > 0.0) then
            m.vel.y = 0.0
        end

        if (m.forwardVel > 8.0) then
            mario_set_forward_vel(m, -8.0)
        end
        set_mario_action(m, ACT_SOFT_BONK, 0)
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

local prevVelY
local prevPosY
-- Hooks.
function mario_update(m)
    local e = gMarioStateExtras[m.playerIndex]
    
    e.lastforwardVel = m.forwardVel

    if m.playerIndex == 0 then
        mario_update_local(m)
    end
	
    if m.vel.y >= 0 then prevPosY = m.pos.y end

    if current_sonic_char(m) == 1 then
        if m.action == ACT_IDLE then
            return set_mario_action(m, ACT_SONIC_IDLE, 0)
        end
        return sonic_update(m)
    elseif current_sonic_char(m) == 2 then
        if m.action == ACT_IDLE then
            return set_mario_action(m, ACT_AMY_IDLE, 0)
        end
        return amy_update(m)
    else
        if m.action == ACT_SONIC_IDLE or m.action == ACT_AMY_IDLE then
            return set_mario_action(m, ACT_IDLE, 0)
        end
    end

    -- 9: smug
    -- 10: shocked
    -- 11: squinted eyes
    -- 12: happy
    -- 13: sad
    -- 14: aah
    -- 15: choo

    --if m.marioObj.header.gfx.disableAutomaticShadowPos then
    --    vec3f_copy(m.marioObj.header.gfx.shadowPos, m.pos)
    --end
end

function mario_on_set_action(m)
    local e = gMarioStateExtras[m.playerIndex]
    if current_sonic_char(m) == 1 then
        return sonic_on_set_action(m)
    elseif current_sonic_char(m) == 2 then
        return amy_on_set_action(m)
    end
end

function sonic_command(msg)
    local m = gMarioStates[0]
    if msg == "on" then
        if sonicchars == 0 then
            audio_sample_play(SOUND_SONIC_RING, m.marioObj.header.gfx.cameraToObject, 1)
            djui_popup_create("\\#4084d9\\Sonic Character\\#ffffff\\ is \\#00C7FF\\on\\#ffffff\\! \nRefer to '/sonic help' for more info.", 1)
            sonicchars = 1
        end

        return true
    elseif msg == "off" then
        if sonicchars == 1 then
            play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
            djui_popup_create("\\#4084d9\\Sonic Character\\#ffffff\\ is \\#A02200\\off\\#ffffff\\!", 1)
            sonicchars = 0
        end

        return true
    elseif msg == "" then
        if sonicchars == 0 then
            audio_sample_play(SOUND_SONIC_RING, m.marioObj.header.gfx.cameraToObject, 1)
            djui_popup_create("\\#4084d9\\Sonic Character\\#ffffff\\ is \\#00C7FF\\on\\#ffffff\\! \nRefer to '/sonic help' for more info.", 1)
            sonicchars = 1
        elseif sonicchars == 1 then
            play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
            djui_popup_create("\\#4084d9\\Sonic Character\\#ffffff\\ is \\#A02200\\off\\#ffffff\\!", 1)
            sonicchars = 0
        end

        return true
    elseif msg == "help" then
        audio_sample_play(SOUND_SONIC_RING, m.marioObj.header.gfx.cameraToObject, 1)
        djui_popup_create("Switch to \\#ff0000\\Mario\\#ffffff\\ to play as \\#4084d9\\Sonic\\#ffffff\\. \n\nSwitch to \\#ff0000\\Toad\\#ffffff\\ to play as \\#fd90a7\\Amy Rose\\#ffffff\\.", 3)

        return true
    end

    return false
end

function allow_interact(m, o, intType)
    -- Properly grab stuff. (Bit taken from Sharen's Pasta Castle)
    local grabActions = {
        [ACT_SPINDASH] = true,
        [ACT_SONIC_ROLL] = true,
        [ACT_AMY_HAMMER_ATTACK] = true,
        [ACT_AMY_FACE_PLANT] = true,
        [ACT_AMY_FACE_PLANT_SLIDE] = true,
        [ACT_SONIC_WATER_SPINDASH] = true,
        [ACT_SONIC_WATER_ROLLING] = true
    }
    
    -- Unimplemented slide boost mode.
    -- local faceplanting = {
    --    [ACT_AMY_FACE_PLANT] = true,
    --    [ACT_AMY_FACE_PLANT_SLIDE] = true
    --}
    
    if grabActions[m.action] then -- or (faceplanting[m.action] and m.forwardVel < 125) 
        if (intType & (INTERACT_GRABBABLE) ~= 0) and o.oInteractionSubtype & (INT_SUBTYPE_NOT_GRABBABLE) == 0 then
            m.interactObj = o
            m.input = m.input | INPUT_INTERACT_OBJ_GRABBABLE
            if o.oSyncID ~= 0 then
                network_send_object(o, true)
            end
        end
    end
    
    -- Do not grab those poles.
    if intType == INTERACT_POLE then
        if m.action == ACT_SONIC_EAGLE or (m.action == ACT_SONIC_JUMP and m.heldObj ~= nil) then
            return false
        end
    end

    -- Hacky way to make warps work with Sonic's idle action.
    if (m.action == ACT_SONIC_IDLE or m.action == ACT_AMY_IDLE) and o.behavior == get_behavior_from_id(id_bhvFadingWarp) then
        return set_mario_action(m, ACT_IDLE, 0)
    end
    
    if obj_has_behavior_id(o, id_bhvChainChomp) ~= 0 
    and ((m.action == ACT_AMY_HAMMER_ATTACK_AIR and m.actionArg == 1) 
    or m.action == ACT_AMY_HAMMER_HIT
    or m.action == ACT_AMY_HAMMER_SPIN
    or m.action == ACT_AMY_HAMMER_SPIN_AIR) then
        -- Chomp knockback.
        o.oSubAction = CHAIN_CHOMP_SUB_ACT_LUNGE
        o.oForwardVel = 150
        o.oVelY = 100
        o.oGravity = 0
        
        if (m.action == ACT_AMY_HAMMER_ATTACK_AIR and m.actionArg == 1) 
        or m.action == ACT_AMY_HAMMER_HIT then
            o.oMoveAngleYaw = m.faceAngle.y
            
        elseif m.action == ACT_AMY_HAMMER_SPIN
        or m.action == ACT_AMY_HAMMER_SPIN_AIR then
            m.faceAngle.y = 0 - o.oMoveAngleYaw
            o.oMoveAngleYaw = 0 - o.oMoveAngleYaw
            
        end
        
        -- Player knockback.
        mario_set_forward_vel(m, -48.0)
        set_camera_shake_from_hit(SHAKE_ATTACK)
        m.particleFlags = m.particleFlags | 0x00040000
        play_sound(SOUND_ACTION_HIT_2, m.marioObj.header.gfx.cameraToObject)
        
        return false
    end
    
end

function on_interact(m, o, intType)
    local damagableTypes = (INTERACT_BOUNCE_TOP | INTERACT_BOUNCE_TOP2 | INTERACT_HIT_FROM_BELOW | 2097152 | INTERACT_KOOPA | 
    INTERACT_BREAKABLE | INTERACT_GRABBABLE | INTERACT_BULLY)

    local bounceTypes = (INTERACT_BOUNCE_TOP | INTERACT_BOUNCE_TOP2 | INTERACT_KOOPA)
    
    -- damage stuff if running
    -- Unimplemented slide boost mode.
    -- if ((m.action == ACT_AMY_FACE_PLANT_SLIDE 
    -- or m.action == ACT_AMY_FACE_PLANT)
    -- and m.forwardVel >= 125)

    if m.action == ACT_AIRDASH
    and (intType & damagableTypes) ~= 0 then
        o.oInteractStatus = ATTACK_KICK_OR_TRIP + (INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED)
        play_sound(SOUND_ACTION_HIT, m.marioObj.header.gfx.cameraToObject)
        return false
    end

	if (intType & bounceTypes) ~= 0 and (o.oInteractionSubtype & INT_SUBTYPE_TWIRL_BOUNCE) == 0 and m.action == ACT_BOUND_POUND then
        o.oInteractStatus = ATTACK_GROUND_POUND_OR_TWIRL + (INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED)
        return set_mario_action(m, ACT_BOUND_JUMP, 0)
    end
end 

function set_mario_model(o)
    if obj_has_behavior_id(o, id_bhvMario) ~= 0 then
        local i = network_local_index_from_global(o.globalPlayerIndex)
        if gPlayerSyncTable[i].modelId ~= nil and obj_has_model_extended(o, gPlayerSyncTable[i].trueModelId) == 0 then
            obj_set_model_extended(o, gPlayerSyncTable[i].trueModelId)
        end
    end
end

hook_event(HOOK_ON_SET_MARIO_ACTION, mario_on_set_action)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ALLOW_INTERACT, allow_interact)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_OBJECT_SET_MODEL, set_mario_model)

hook_mario_action(ACT_SONIC_AIR_HIT_WALL, act_air_hit_wall)

hook_chat_command(
"sonic",
"[\\#00C7FF\\on\\#ffffff\\|\\#A02200\\off\\#ffffff\\] turn \\#4084d9\\Sonic \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off",
sonic_command
)
