-- name: Sonic Character: \\#4084d9\\Rebooted
-- incompatible:
-- description: The Sonic character mod remade with a couple of improvement in controls.\n\ \n\Credits:\n\Coding and modelling: \\#acfffc\\steven.\\#ffffff\\\n\Ball model: \\#5454a7\\king the memer\\#ffffff\\\n\Sonic VA: \\#ff5c26\\Yuyake Kasarion\\#ffffff\\\n\Voice system: \\#ff6b91\\SMS Alfredo \\#ffffff\\\n\Coolest playtesters: \\#016786\\Asra\\#ffffff\\, \\#99fe02\\MlopsFunny\\#ffffff\\, \\#6a9ac3\\Cooliokid 956\\#ffffff\\, \\#171b73\\Demnyx\\#4b1c75\\Onyxfur\\#ffffff\\, \\#9856ac\\Zerks\\#ffffff\\.

E_MODEL_SONIC = smlua_model_util_get_id("sonic_geo")
E_MODEL_SPINBALL = smlua_model_util_get_id("spinball_geo")

SOUND_SONIC_JUMP = audio_sample_load("SA1-Jump.mp3")
SOUND_SONIC_SPIN = audio_sample_load("SA1-Spin.mp3")
SOUND_SONIC_DASH = audio_sample_load("SA1-Dash.mp3")
SOUND_SONIC_RING = audio_sample_load("SA1-Ring.mp3")

gMarioStateExtras = {}
for i = 0, (MAX_PLAYERS - 1) do
    gMarioStateExtras[i] = {}
    local m = gMarioStates[i]
    local e = gMarioStateExtras[i]
    e.rotAngle = 0
    e.dashspeed = 0
    e.animFrame = 0
    e.lastforwardVel = 0
    e.squishFrame = 0
    e.snapLimit = 0
    e.airdashed = 0
    e.wallClimbed = 0
    e.modelState = 0
    e.ballTimer = 0
    e.moveAngle = 0
    e.spawnDelay = 0
    e.peakHeightDelay = 0
end

sonicchars = 0

ACT_SPINDASH =
allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_ATTACKING | ACT_FLAG_INVULNERABLE | ACT_FLAG_SHORT_HITBOX)
ACT_SONIC_ROLL =
allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_BUTT_OR_STOMACH_SLIDE | ACT_FLAG_SHORT_HITBOX)
ACT_SONIC_JUMP =
allocate_mario_action(
ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_AIR | ACT_FLAG_CONTROL_JUMP_HEIGHT |
ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_SHORT_HITBOX)
ACT_SONIC_HOLD_JUMP =
allocate_mario_action(
ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR | ACT_FLAG_CONTROL_JUMP_HEIGHT)
ACT_SONIC_IDLE =
allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_IDLE | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_SONIC_LYING_DOWN =
allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_SONIC_FREEFALL =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_SONIC_EAGLE =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_DROPDASH =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_SHORT_HITBOX)
ACT_AIRDASH = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_SHORT_HITBOX)
ACT_SONIC_WALKING = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING)
ACT_BOUND_JUMP =
allocate_mario_action(
ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_AIR |
ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_SHORT_HITBOX)
ACT_BOUND_POUND =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_SONIC_AIR_HIT_WALL =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)

-- Misc functions

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

function sonic_air_attacks(m)
    local e = gMarioStateExtras[m.playerIndex]
    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 and e.wallClimbed == 0 then
        m.action = ACT_DROPDASH
        audio_sample_play(SOUND_SONIC_SPIN, m.pos, 1)
    else
        set_mario_action(m, ACT_JUMP_KICK, 0)
    end
end

function update_sonic_walking_speed(m)
    local maxTargetSpeed = 0
    local targetSpeed = 0

    if (m.floor ~= nil and m.floor.type == SURFACE_SLOW) then
        maxTargetSpeed = 48.0
    else
        maxTargetSpeed = 64.0
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

function sonic_anim_and_audio_for_walk(m)
    local val14 = 0
    local marioObj = m.marioObj
    local val0C = true
    local targetPitch = 0
    local val04 = 4.0

    if val14 < 4 then
        val14 = 4
    end

    if m.forwardVel > 2 then
        val04 = math.abs(m.forwardVel)
    else
        val04 = 5
    end

    if (m.quicksandDepth > 50.0) then
        val14 = (val04 / 4.0 * 0x10000)
        set_mario_anim_with_accel(m, MARIO_ANIM_MOVE_IN_QUICKSAND, val14)
        play_step_sound(m, 19, 93)
        m.actionTimer = 0
    else
        if val0C == true then
            if m.actionTimer == 0 then
                if (val04 > 8.0) then
                    m.actionTimer = 2
                else
                    --(Speed Crash) If Mario's speed is more than 2^17.
                    if (val14 < 0x1000) then
                        val14 = 0x1000
                    else
                        val14 = (val04 / 4.0 * 0x10000)
                    end
                    set_mario_animation(m, MARIO_ANIM_START_TIPTOE)
                    play_step_sound(m, 7, 22)
                    if (is_anim_past_frame(m, 23)) then
                        m.actionTimer = 2
                    end

                    val0C = false
                end
            elseif m.actionTimer == 1 then
                if (val04 > 8.0) or m.intendedMag > 8.0 then
                    m.actionTimer = 2
                else
                    -- (Speed Crash) If Mario's speed is more than 2^17.
                    if (val14 < 0x1000) then
                        val14 = 0x1000
                    else
                        val14 = (val04 / 4.0 * 0x10000)
                    end
                    set_mario_animation(m, MARIO_ANIM_TIPTOE)
                    play_step_sound(m, 14, 72)

                    val0C = false
                end
            elseif m.actionTimer == 2 then
                if (val04 < 5.0) then
                    m.actionTimer = 1
                elseif (val04 > 22.0) then
                    m.actionTimer = 3
                else
                    -- (Speed Crash) If Mario's speed is more than 2^17.
                    val14 = (val04 / 4.0 * 0x10000)
                    set_mario_anim_with_accel(m, MARIO_ANIM_WALKING, val14)
                    play_step_sound(m, 10, 49)

                    val0C = false
                end
            elseif m.actionTimer == 3 then
                if (val04 < 18.0) then
                    m.actionTimer = 2
                else
                    -- (Speed Crash) If Mario's speed is more than 2^17.
                    val14 = (val04 / 4.0 * 0x10000)
                    if m.forwardVel > 40 then
                        smlua_anim_util_set_animation(marioObj, "SONIC_RUNNING")
                        set_mario_anim_with_accel(m, MARIO_ANIM_RUNNING_UNUSED, val14)
                    else
                        set_mario_anim_with_accel(m, MARIO_ANIM_RUNNING, val14)
                    end
                    play_step_sound(m, 9, 45)
                    targetPitch = tilt_body_running(m)

                    val0C = false
                end
            end
        end
    end

    marioObj.oMarioWalkingPitch = convert_s16(approach_s32(marioObj.oMarioWalkingPitch, find_floor_slope(m, 0x8000), 0x800, 0x800))
    marioObj.header.gfx.angle.x = marioObj.oMarioWalkingPitch
end

function sonic_update_air(m)
    local sidewaysSpeed = 0.0
    local dragThreshold = 0
    local intendedDYaw = 0
    local intendedMag = 0

    if (check_horizontal_wind(m)) == 0 then
        dragThreshold = 64.0

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
    local stepResult = perform_air_step(m, stepArg)

    sonic_update_air(m)
    if turning then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)
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
        m.marioObj.oMarioWalkingPitch = 0x0000
        if (check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB) == 0) then
            if m.forwardVel ~= 0 and keepMomentum then
                set_mario_action(m, ACT_SONIC_WALKING, 0)
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
    --replacin' the walking action while make sure the player can still open doors
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
            return set_mario_action(m, ACT_SONIC_WALKING, 0)
        elseif doorwarp == nil and door == nil and stardoor == nil then
            return set_mario_action(m, ACT_SONIC_WALKING, 0)
        end
    end

    if m.action == ACT_SONIC_WALKING and m.heldObj == nil then
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
        e.ballTimer = e.ballTimer + 1
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
    set_mario_y_vel_based_on_fspeed(m, 40, 0.2)
    if m.heldObj == nil then
        audio_sample_play(SOUND_SONIC_JUMP, m.pos, 1)
        return set_mario_action(m, ACT_SONIC_JUMP, 0)
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

-- Action functions

function act_spindash(m)
    local e = gMarioStateExtras[m.playerIndex]
    local slopeAngle = atan2s(m.floor.normal.z, m.floor.normal.x)
    local MAXDASH = 15
    local MINDASH = 8

    -- Spindash revving.
    if m.actionTimer == 0 then
        play_character_sound(m, CHAR_SOUND_YAH_WAH_HOO)
        audio_sample_play(SOUND_SONIC_SPIN, m.pos, 1)
        e.dashspeed = 0
        e.moveAngle = m.faceAngle.y
    end

    -- Direction changing.
    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
        e.moveAngle = m.intendedYaw
    end

    -- Dash limit.
    if e.dashspeed < MINDASH then
        e.dashspeed = MINDASH
    elseif e.dashspeed > MAXDASH then
        e.dashspeed = MAXDASH
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    end

    -- Animations.
    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)
    set_anim_to_frame(m, e.animFrame)

    if e.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd then
        e.animFrame = e.animFrame - m.marioObj.header.gfx.animInfo.curAnim.loopEnd
    end

    -- Dash release.
    if (m.controller.buttonDown & B_BUTTON) == 0 then
        m.faceAngle.y = e.moveAngle
        if m.forwardVel < 60 then
            mario_set_forward_vel(m, e.dashspeed * 8)
        elseif m.forwardVel < 140 then
            mario_set_forward_vel(m, m.forwardVel + e.dashspeed * 2)
        else
            mario_set_forward_vel(m, m.forwardVel + 1)
        end
        audio_sample_play(SOUND_SONIC_DASH, m.pos, 1)
        return set_mario_action(m, ACT_SONIC_ROLL, 0)
    elseif (m.controller.buttonDown & A_BUTTON) ~= 0 then
        return set_mario_action(m, ACT_JUMP, 0)
    end

    -- Physics 'n stuff
    if m.playerIndex == 0 then
        if mario_check_object_grab(m) ~= 0 then
            return true
        end
    end

    local stepResult = perform_ground_step(m)
    if stepResult == GROUND_STEP_LEFT_GROUND then
        return set_mario_action(m, ACT_FREEFALL, 0)
    end
    apply_slope_decel(m, 0.5)

    if m.vel.x ~= 0 or m.vel.z ~= 0 then
        m.faceAngle.y = atan2s(m.vel.z, m.vel.x)
    elseif m.vel.x == 0 and m.vel.z == 0 then
        m.faceAngle.y = e.moveAngle
    end

    e.animFrame = e.animFrame + (e.dashspeed / 4)
    m.actionTimer = m.actionTimer + 1
    e.dashspeed = e.dashspeed + 0.5
    m.marioObj.header.gfx.angle.y = e.moveAngle
    return 0
end

function act_sonic_roll(m)
    local e = gMarioStateExtras[m.playerIndex]
    if m.actionTimer == 0 then
        e.rotAngle = 0x000
    end
    if (m.input & INPUT_A_PRESSED) ~= 0 then
        return do_sonic_jump(m)
    end

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        set_mario_action(m, ACT_SONIC_WALKING, 0)
    end

    if m.playerIndex == 0 then
        if mario_check_object_grab(m) ~= 0 then
            mario_grab_used_object(m)
            if m.interactObj.behavior == get_behavior_from_id(id_bhvBowser) then
                m.marioBodyState.grabPos = GRAB_POS_BOWSER
                return 1
            elseif m.interactObj.oInteractionSubtype & INT_SUBTYPE_GRABS_MARIO ~= 0 then
                return 0
            else
                set_mario_action(m, ACT_HOLD_BUTT_SLIDE, 0)
                m.marioBodyState.grabPos = GRAB_POS_LIGHT_OBJ
                return 1
            end
        end
    end

    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)

    local stepResult = perform_ground_step(m)
    if stepResult == GROUND_STEP_NONE then
        if mario_floor_is_slope(m) ~= 0 or mario_floor_is_steep(m) ~= 0 then
            apply_slope_accel(m)
        else
            mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 1, 1))
        end
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)
    elseif stepResult == GROUND_STEP_HIT_WALL then
        mario_set_forward_vel(m, -16.0)

        m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
        return set_mario_action(m, ACT_GROUND_BONK, 0)
    elseif stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_SONIC_JUMP, 0)
    end

    if math.abs(m.forwardVel) < 10 then
        set_mario_action(m, ACT_WALKING, 0)
    end
    e.rotAngle = e.rotAngle + (0x50 * m.forwardVel)
    if e.rotAngle > 0x9000 then
        e.rotAngle = e.rotAngle - 0x9000
    end
    set_anim_to_frame(m, 10 * e.rotAngle / 0x9000)

    m.actionTimer = m.actionTimer + 1

    return 0
end

function act_sonic_jump(m)
    local e = gMarioStateExtras[m.playerIndex]
    local spinSpeed = 0
    if m.actionTimer == 0 then
        e.rotAngle = 0x000
    end

    if m.actionTimer == 0 then
        play_character_sound_if_no_flag(m, CHAR_SOUND_YAH_WAH_HOO, MARIO_ACTION_SOUND_PLAYED)
    end

    local stepResult =
    sonic_common_air_action_step(
    m,
    ACT_FREEFALL_LAND,
    MARIO_ANIM_FORWARD_SPINNING,
    AIR_STEP_CHECK_LEDGE_GRAB | AIR_STEP_CHECK_HANG,
    true,
    true
    )

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        return sonic_air_attacks(m)
    end
    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_BOUND_POUND, 0)
    end

    if m.forwardVel > 50 then
        spinSpeed = m.forwardVel
    else
        spinSpeed = 50
    end

    e.rotAngle = e.rotAngle + (0x50 * spinSpeed)
    if e.rotAngle > 0x9000 then
        e.rotAngle = e.rotAngle - 0x9000
    end
    set_anim_to_frame(m, 10 * e.rotAngle / 0x9000)

    m.actionTimer = m.actionTimer + 1
end


function act_sonic_hold_jump(m)
    if (m.marioObj.oInteractStatus & INT_STATUS_MARIO_DROP_OBJECT) ~= 0 then
        return drop_and_set_mario_action(m, ACT_FREEFALL, 0)
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 and m.heldObj ~= nil and (m.heldObj.oInteractionSubtype & INT_SUBTYPE_HOLDABLE_NPC) == 0 then
        return set_mario_action(m, ACT_AIR_THROW, 0)
    end

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return drop_and_set_mario_action(m, ACT_BOUND_POUND, 0)
    end

    play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, 0)
    sonic_common_air_action_step(m, ACT_HOLD_JUMP_LAND, MARIO_ANIM_JUMP_WITH_LIGHT_OBJ,
    AIR_STEP_CHECK_LEDGE_GRAB, true, true)
    return 0
end

function act_dropdash(m)
    local e = gMarioStateExtras[m.playerIndex]
    if m.actionTimer == 0 then
        e.animFrame = 0
        e.dashspeed = 6
    end

    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)
    e.animFrame = e.animFrame + 3
    if e.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd then
        e.animFrame = e.animFrame - m.marioObj.header.gfx.animInfo.curAnim.loopEnd
    end
    set_anim_to_frame(m, e.animFrame)

    local stepResult =
    sonic_common_air_action_step(
    m,
    ACT_SONIC_ROLL,
    MARIO_ANIM_FORWARD_SPINNING,
    AIR_STEP_CHECK_LEDGE_GRAB,
    true,
    false
    )
    if stepResult == AIR_STEP_LANDED then
        audio_sample_play(SOUND_SONIC_DASH, m.pos, 1)
        spawn_non_sync_object(
        id_bhvSpinDust,
        E_MODEL_SMOKE,
        m.pos.x,
        m.pos.y,
        m.pos.z,
        function(o)
        end
        )
        mario_set_forward_vel(m, m.forwardVel + 30)
    elseif stepResult == AIR_STEP_HIT_WALL then
        e.wallClimbed = 1
        mario_set_forward_vel(m, 0)
        m.particleFlags = m.particleFlags | PARTICLE_DUST
        set_mario_action(m, ACT_TRIPLE_JUMP, 0)

        if e.lastforwardVel < 70 then
            m.vel.y = 70
        elseif e.lastforwardVel > 120 then
            m.vel.y = 120
        else
            m.vel.y = e.lastforwardVel
        end
    end

    if (m.controller.buttonDown & B_BUTTON) == 0 then
        if e.airdashed == 0 then
            play_sound(SOUND_ACTION_FLYING_FAST, m.marioObj.header.gfx.cameraToObject)
            play_character_sound(m, CHAR_SOUND_YAHOO_WAHA_YIPPEE)
            set_mario_action(m, ACT_AIRDASH, 0)
        else
            m.action = ACT_SONIC_JUMP
        end
    end

    if m.forwardVel > 50 then
        spinSpeed = m.forwardVel
    else
        spinSpeed = 50
    end
    m.actionTimer = m.actionTimer + 1
end

function act_airdash(m)
    local e = gMarioStateExtras[m.playerIndex]

    e.airdashed = 1

    if m.actionTimer > 10 then
        if (m.flags & MARIO_WING_CAP) ~= 0 then
            return set_mario_action(m, ACT_FLYING, 1)
        else
            return set_mario_action(m, ACT_FREEFALL, 0)
        end
    else
        set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)
        set_anim_to_frame(m, e.animFrame)
        if m.forwardVel < 75 then
            mario_set_forward_vel(m, 75)
        else
            mario_set_forward_vel(m, m.forwardVel)
        end

        if e.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd then
            e.animFrame = e.animFrame - m.marioObj.header.gfx.animInfo.curAnim.loopEnd
        end

        if m.action ~= ACT_FLYING then
            m.vel.y = 0
        end

        e.animFrame = e.animFrame + 2
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    end

    stepResult = perform_air_step(m, 0)

    if stepResult == AIR_STEP_HIT_WALL then
        mario_set_forward_vel(m, -16.0)
        m.vel.y = 40

        m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
        set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
    elseif stepResult == AIR_STEP_LANDED then
        return set_mario_action(m, ACT_WALKING, 0)
    end
    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_sonic_walking(m)
    local e = gMarioStateExtras[m.playerIndex]
    local startYaw = m.faceAngle.x

    m.actionState = 0
    update_sonic_walking_speed(m)
    local stepResult = perform_ground_step(m)

    if stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_FREEFALL, 0)
        set_mario_animation(m, MARIO_ANIM_GENERAL_FALL)
    elseif stepResult == GROUND_STEP_NONE then
        if m.heldObj ~= nil then
            set_mario_anim_with_accel(m, MARIO_ANIM_WALK_WITH_LIGHT_OBJ, m.forwardVel * 0x4000)
            play_step_sound(m, 12, 62)
        else
            sonic_anim_and_audio_for_walk(m)
        end
        if (m.intendedMag - m.forwardVel) > 16 then
            set_mario_particle_flags(m, PARTICLE_DUST, false)
        end
    elseif stepResult == GROUND_STEP_HIT_WALL then
        if m.heldObj == nil then
            push_or_sidle_wall(m, m.pos)
        else
            if m.forwardVel > 5 then mario_set_forward_vel(m, 5) end
        end
        m.actionTimer = 0
    end

    check_ledge_climb_down(m)
    tilt_body_walking(m, startYaw)

    if should_begin_sliding(m) ~= 0 then
        if m.heldObj == nil then
            return set_mario_action(m, ACT_BEGIN_SLIDING, 0)
        else
            return set_mario_action(m, ACT_HOLD_BEGIN_SLIDING, 0)
        end
    end

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return drop_and_set_mario_action(m, ACT_CROUCH_SLIDE, 0)
    end

    if (m.input & INPUT_FIRST_PERSON) ~= 0 then
        return begin_braking_action(m)
    end

    if (m.input & INPUT_A_PRESSED) ~= 0 then
        return do_sonic_jump(m)
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        if m.heldObj ~= nil then
            set_mario_action(m, ACT_THROWING, 0)
        else
            if (m.controller.buttonDown & A_BUTTON) ~= 0 then
                set_mario_action(m, ACT_JUMP_KICK, 0)
            else
                e.moveAngle = m.faceAngle.y
                return set_mario_action(m, ACT_SPINDASH, 0)
            end
        end
    end

    if (m.input & INPUT_ZERO_MOVEMENT) ~= 0 then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 3, 3))
        if math.abs(m.forwardVel) < 2 then
            if m.heldObj ~= nil then
                return set_mario_action(m, ACT_HOLD_IDLE, 0)
            else
                return set_mario_action(m, ACT_IDLE, 0)
            end
        end
    end

    if analog_stick_held_back(m) ~= 0 and m.heldObj == nil then
        m.faceAngle.y = m.intendedYaw + 0x8000
        return set_mario_action(m, ACT_TURNING_AROUND, 0)
    end
    return 0
end

function act_bound_jump(m)
    local e = gMarioStateExtras[m.playerIndex]

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_BOUND_POUND, 0)
    end
    if (m.input & INPUT_B_PRESSED) ~= 0 then
        sonic_air_attacks(m)
    end

    sonic_common_air_action_step(m, ACT_TRIPLE_JUMP_LAND, MARIO_ANIM_FORWARD_SPINNING, AIR_STEP_CHECK_HANG, false, true)
    set_anim_to_frame(m, e.animFrame)
    if e.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd then
        e.animFrame = e.animFrame - m.marioObj.header.gfx.animInfo.curAnim.loopEnd
    end
    e.animFrame = e.animFrame + 1
    m.actionTimer = m.actionTimer + 1

    return 0
end

function act_bound_pound(m)
    local e = gMarioStateExtras[m.playerIndex]
    local soundRng = math.random(1,2)
    if soundRng == 1 then
        play_character_sound_if_no_flag(m, CHAR_SOUND_YAH_WAH_HOO, MARIO_ACTION_SOUND_PLAYED)
    else
        play_character_sound_if_no_flag(m, CHAR_SOUND_HOOHOO, MARIO_ACTION_SOUND_PLAYED)
    end

    m.vel.y = -100.0
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)
    set_anim_to_frame(m, e.animFrame)

    if e.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd then
        e.animFrame = e.animFrame - m.marioObj.header.gfx.animInfo.curAnim.loopEnd
    end
    e.animFrame = e.animFrame + 2

    local stepResult = perform_air_step(m, 0)

    if stepResult == AIR_STEP_LANDED then
        m.vel.y = -100
        m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE | PARTICLE_HORIZONTAL_STAR
        play_sound(SOUND_GENERAL_SHORT_POUND3, m.marioObj.header.gfx.cameraToObject)
        m.squishTimer = 5
        set_mario_action(m, ACT_GROUND_POUND_LAND, 0)
    end
    m.peakHeight = m.pos.y
    m.actionTimer = m.actionTimer + 1

    return 0
end

function act_sonic_freefall(m)
    local animation = 0
    local landAction = 0

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        sonic_air_attacks(m)
    end

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return drop_and_set_mario_action(m, ACT_BOUND_POUND, 0)
    end
    if m.heldObj == nil then
        if m.actionArg == 0 then
            animation = MARIO_ANIM_GENERAL_FALL
        elseif m.actionArg == 1 then
            animation = MARIO_ANIM_FALL_FROM_SLIDE
        elseif m.actionArg == 2 then
            animation = MARIO_ANIM_FALL_FROM_SLIDE_KICK
        end
        landAction = ACT_FREEFALL_LAND
    else
        animation = MARIO_ANIM_FALL_WITH_LIGHT_OBJ
        landAction = ACT_HOLD_FREEFALL_LAND
    end

    sonic_common_air_action_step(m, landAction, animation, AIR_STEP_CHECK_LEDGE_GRAB, true, true)
    return 0
end

function act_sonic_idle(m)
    stationary_ground_step(m)
    if (m.quicksandDepth > 30.0) then
        return set_mario_action(m, ACT_IN_QUICKSAND, 0)
    end

    if (m.input & INPUT_IN_POISON_GAS) ~= 0 then
        return set_mario_action(m, ACT_COUGHING, 0)
    end

    if ((m.actionArg & 1) == 0 and m.health < 0x300) then
        return set_mario_action(m, ACT_PANTING, 0)
    end

    if check_common_idle_cancels(m) ~= 0 then
        return 1
    end

    if (m.actionArg & 1) ~= 0 then
        set_mario_animation(m, MARIO_ANIM_STAND_AGAINST_WALL)
    else
        if m.actionState == 0 then
            set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_LEFT)
            if is_anim_at_end(m) ~= 0 then
                m.actionState = m.actionState + 1
            end
        elseif m.actionState == 1 then
            set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_RIGHT)
            if is_anim_at_end(m) ~= 0 then
                m.actionState = m.actionState + 1
            end
        elseif m.actionState == 2 then
            set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_CENTER)
            if is_anim_at_end(m) ~= 0 then
                if m.actionTimer > math.random(10, 15) * 30 then
                    m.actionTimer = 0
                    if ((m.area.terrainType & TERRAIN_MASK) == TERRAIN_SNOW) then
                        m.actionState = 5
                    else
                        m.actionState = 3
                    end
                else
                    m.actionState = 0
                end
            end
        elseif m.actionState == 3 then
            set_mario_animation(m, MARIO_ANIM_START_SLEEP_IDLE)
            smlua_anim_util_set_animation(m.marioObj, "SONIC_IMPATIENT_START")
            if is_anim_past_end(m) ~= 0 then
                m.actionState = 4
            end
        elseif m.actionState == 4 then
            set_mario_animation(m, MARIO_ANIM_START_SLEEP_SCRATCH)
            m.marioBodyState.eyeState = 18
            smlua_anim_util_set_animation(m.marioObj, "SONIC_IMPATIENT")
            play_step_sound(m, 15, 15)
            if is_anim_past_frame(m, 20) ~= 0 then
                if m.actionTimer > math.random(20, 30) * 30 then
                    m.actionState = 6
                end
            end
        elseif m.actionState == 5 then
            set_mario_animation(m, MARIO_ANIM_START_SLEEP_YAWN)
            smlua_anim_util_set_animation(m.marioObj, "SONIC_SNEEZE")
            if m.marioObj.header.gfx.animInfo.animFrame < 8 then
                m.marioBodyState.eyeState = 14
            elseif m.marioObj.header.gfx.animInfo.animFrame < 12 then
                m.marioBodyState.eyeState = 15
            else
                m.marioBodyState.eyeState = 13
            end
            if is_anim_past_end(m) ~= 0 then
                m.actionState = 0
            end
        elseif m.actionState == 6 then
            set_mario_animation(m, MARIO_ANIM_START_SLEEP_SITTING)
            m.marioBodyState.eyeState = 18
            smlua_anim_util_set_animation(m.marioObj, "SONIC_IMPATIENT2_START")
            if is_anim_past_end(m) ~= 0 then
                set_mario_action(m, ACT_SONIC_LYING_DOWN, 0)
            end
        end
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_sonic_lying_down(m)
    local e = gMarioStateExtras[m.playerIndex]
    local animFrame = m.marioObj.header.gfx.animInfo.animFrame
    stationary_ground_step(m)
    if (m.quicksandDepth > 30.0) then
        return set_mario_action(m, ACT_IN_QUICKSAND, 0)
    end

    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
        m.actionState = 1
    end

    if (m.input & INPUT_A_PRESSED) ~= 0 then
        return do_sonic_jump(m)
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        if (m.input & INPUT_A_DOWN) ~= 0 then
            set_mario_action(m, ACT_JUMP_KICK, 0)
        else
            e.moveAngle = m.faceAngle.y
            return set_mario_action(m, ACT_SPINDASH, 0)
        end
    end

    if m.actionState == 0 then
        m.marioBodyState.eyeState = 18
        set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_LEFT)
        smlua_anim_util_set_animation(m.marioObj, "SONIC_IMPATIENT2")
        play_step_sound(m, 15, 15)
    elseif m.actionState == 1 then
        set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_RIGHT)
        smlua_anim_util_set_animation(m.marioObj, "SONIC_IMPATIENT2_END")
        m.isSnoring = false
        if (is_anim_past_frame(m, 9) ~= 0 and (m.input & INPUT_NONZERO_ANALOG) ~= 0)
        or is_anim_past_end(m) ~= 0 then
            set_mario_action(m, ACT_SONIC_IDLE, 0)
        end
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_sonic_eagle(m)
    local animFrame = m.marioObj.header.gfx.animInfo.animFrame

    if (m.actionState == 0) then
        play_character_sound_if_no_flag(m, CHAR_SOUND_PUNCH_HOO, MARIO_ACTION_SOUND_PLAYED)
        m.marioObj.header.gfx.animInfo.animID = -1
        set_mario_animation(m, MARIO_ANIM_AIR_KICK)
        smlua_anim_util_set_animation(m.marioObj, "SONIC_EAGLE")
        m.actionState = 1
    end

    if (m.controller.buttonPressed & Z_TRIG) ~= 0 and m.actionTimer > 4 then
        set_mario_action(m, ACT_BOUND_POUND, 0)
    end

    if (animFrame == 0) then
        m.marioBodyState.punchState = (2 << 6) | 6
    end
    if (animFrame >= 0 and animFrame < 8) then
        m.flags = m.flags | MARIO_KICKING
    end

    sonic_update_air(m)
    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)

    if m.faceAngle.y ~= m.intendedYaw and m.forwardVel > 32 then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, m.forwardVel/16, m.forwardVel/16))
    else
        mario_set_forward_vel(m, m.forwardVel)
    end

    local stepResult =  perform_air_step(m, 0)

    if stepResult == AIR_STEP_LANDED then
        if check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB) == 0 then
            if m.forwardVel ~= 0 then
                set_mario_action(m, ACT_SONIC_WALKING, 0)
            else
                set_mario_action(m, ACT_FREEFALL_LAND, 0)
            end
        end
    elseif stepResult == AIR_STEP_HIT_WALL then
        mario_set_forward_vel(m, 0.0)
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

-- Hitting wall patched up to fix Sonic's bonking.
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

-- Hooks 'n stuff.

function sonic_on_set_action(m)
    local e = gMarioStateExtras[m.playerIndex]
    if (m.action == ACT_PUNCHING and m.actionArg ~= 9) or m.action == ACT_MOVE_PUNCHING then
        m.vel.y = 0
        if (m.input & INPUT_A_DOWN) ~= 0 then
            set_mario_action(m, ACT_JUMP_KICK, 0)
        else
            e.moveAngle = m.faceAngle.y
            set_mario_action(m, ACT_SPINDASH, 0)
        end
    end

    if m.action == ACT_HOLD_WALKING then
        m.action = ACT_SONIC_WALKING
    end

    if m.action == ACT_DIVE then
        return sonic_air_attacks(m)
    end

    if m.action == ACT_FREEFALL_LAND then
        return set_mario_action(m, ACT_DOUBLE_JUMP_LAND, 0)
    end

    if m.action == ACT_FREEFALL then
        m.action = ACT_SONIC_FREEFALL
    end

    if m.action == ACT_JUMP_KICK then
        m.action = ACT_SONIC_EAGLE
    end

    local jumpActions = {
        [ACT_JUMP] = true,
        [ACT_DOUBLE_JUMP] = true,
        [ACT_FLYING_TRIPLE_JUMP] = true,
        [ACT_HOLD_JUMP] = true,
        [ACT_STEEP_JUMP] = true
    }

    if jumpActions[m.action] then
        return do_sonic_jump(m)
    end

    if m.action == ACT_GROUND_POUND then
        return set_mario_action(m, ACT_BOUND_POUND, 0)
    end
end

function sonic_update(m)
    local e = gMarioStateExtras[m.playerIndex]

    sonic_walking_door_check(m)
    sonic_check_wall_kick(m)

    local reloadActions = {
        [ACT_CLIMBING_POLE] = true,
        [ACT_WALL_KICK_AIR] = true
    }

    if m.pos.y == m.floorHeight or reloadActions[m.action] then
        e.airdashed = 0
        e.wallClimbed = 0
    end

    -- Basically delays Sonic fall damage.

    if m.pos.y == m.floorHeight or m.vel.y >= -5 then
        e.peakHeightDelay = 0
    end

    if e.peakHeightDelay < 30 then
        m.peakHeight = m.pos.y
        e.peakHeightDelay = e.peakHeightDelay + 1
    end

    if m.action == ACT_GROUND_POUND_LAND or m.action == ACT_SOFT_BONK then
        m.actionTimer = m.actionTimer + 1
    end


    if m.action == ACT_GROUND_POUND_LAND then
        if m.actionTimer > 2 then
            m.vel.y = 65.0
            set_mario_action(m, ACT_BOUND_JUMP, 1)
            mario_set_forward_vel(m, e.lastforwardVel)
        elseif m.actionTimer < 1 then
            set_mario_action(m, ACT_GROUND_POUND_LAND, 99)
        end
    end

    if m.action ~= ACT_GROUND_POUND_LAND then
        e.lastforwardVel = m.forwardVel
    end

    --if m.marioObj.header.gfx.animInfo.animID == 79 then
    --	m.marioObj.header.gfx.disableAutomaticShadowPos = true
    --end

    -- Animations 'n stuff.

    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        m.marioBodyState.eyeState = 1
    end

    if m.action == ACT_PANTING then
        m.marioBodyState.eyeState = 17
    end

    if m.marioObj.header.gfx.animInfo.animID == 205 then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_STAR_DANCE")
        if m.marioObj.header.gfx.animInfo.animFrame < 18 then
            m.marioBodyState.eyeState = 12
        elseif m.marioObj.header.gfx.animInfo.animFrame < 46 then
            m.marioBodyState.eyeState = 11
        else
            m.marioBodyState.eyeState = 9
        end
    end

    if m.marioObj.header.gfx.animInfo.animID == 15 then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SKID")
    end

    if m.marioObj.header.gfx.animInfo.animID == 16 then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SKID_STOP")
    end

    if m.marioObj.header.gfx.animInfo.animID == 188 then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SKID")
    end

    if m.marioObj.header.gfx.animInfo.animID == 189 then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SKID_TURN")
    end

    if m.action == ACT_DEATH_EXIT_LAND then
        if m.marioObj.header.gfx.animInfo.animFrame < 45 then
            m.marioBodyState.eyeState = 8
        else
            m.marioBodyState.eyeState = 13
        end
    end

    if
    m.action == ACT_QUICKSAND_DEATH or m.action == ACT_GRABBED or m.action == ACT_GETTING_BLOWN or
    m.action == ACT_HARD_BACKWARD_AIR_KB or
    m.action == ACT_BACKWARD_AIR_KB or
    m.action == ACT_SOFT_BACKWARD_GROUND_KB or
    m.action == ACT_HARD_FORWARD_AIR_KB or
    m.action == ACT_FORWARD_AIR_KB or
    m.action == ACT_SOFT_FORWARD_GROUND_KB or
    m.action == ACT_THROWN_FORWARD or
    m.action == ACT_THROWN_BACKWARD or
    m.action == ACT_DEATH_EXIT
    then
        m.marioBodyState.eyeState = 10
    end

    if
    m.action == ACT_HARD_BACKWARD_GROUND_KB or m.action == ACT_BACKWARD_GROUND_KB or
    m.action == ACT_HARD_FORWARD_GROUND_KB or
    m.action == ACT_FORWARD_GROUND_KB or
    m.action == ACT_FORWARD_WATER_KB or
    m.action == ACT_BACKWARD_WATER_KB or
    m.action == ACT_GROUND_BONK
    then
        m.marioBodyState.eyeState = 8
    end

    if m.action == ACT_DROWNING then
        if m.actionState == 0 then
            m.marioBodyState.eyeState = 14
        elseif m.actionState == 1 then
            if m.marioObj.header.gfx.animInfo.animFrame < 40 then
                m.marioBodyState.eyeState = 17
            else
                m.marioBodyState.eyeState = 16
            end
        end
    end
    if e.modelState == 2 and (m.flags & MARIO_METAL_CAP) == 0 then
        m.marioBodyState.capState = 1
    end

    if m.action == ACT_SOFT_BONK and (m.controller.buttonPressed & Z_TRIG) ~= 0 and m.prevAction ~= ACT_HOLDING_POLE then
        set_mario_action(m, ACT_BOUND_POUND, 0)
    end
	
    if (m.action == ACT_TURNING_AROUND and (m.input & INPUT_B_PRESSED) ~= 0) then
        m.vel.y = 0
        if (m.input & INPUT_A_DOWN) ~= 0 then
            set_mario_action(m, ACT_JUMP_KICK, 0)
        else
            e.moveAngle = m.faceAngle.y
            set_mario_action(m, ACT_SPINDASH, 0)
        end
    end
	
    visual_updates(m)
    return 0
end

-- This is where the actual hook functions are.
function mario_update(m)
    local e = gMarioStateExtras[m.playerIndex]
    if gPlayerSyncTable[m.playerIndex].modelId ~= nil then
        obj_set_model_extended(m.marioObj, gPlayerSyncTable[m.playerIndex].trueModelId)
    end

    if m.playerIndex == 0 then
        mario_update_local(m)
    end

    if gPlayerSyncTable[m.playerIndex].modelId == E_MODEL_SONIC then
        if m.action == ACT_IDLE then
            return set_mario_action(m, ACT_SONIC_IDLE, 0)
        end
        return sonic_update(m)
    else
        if m.action == ACT_SONIC_IDLE then
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
    --	vec3f_copy(m.marioObj.header.gfx.shadowPos, m.pos)
    --end
end

function mario_on_set_action(m)
    local e = gMarioStateExtras[m.playerIndex]
    if gPlayerSyncTable[0].modelId == E_MODEL_SONIC then
        return sonic_on_set_action(m)
    end
end

function sonic_command(msg)
    local m = gMarioStates[0]
    if msg == "on" then
        if sonicchars == 0 then
            audio_sample_play(SOUND_SONIC_RING, m.marioObj.header.gfx.cameraToObject, 1)
            djui_popup_create("\\#4084d9\\Sonic\\#ffffff\\ is \\#00C7FF\\on\\#ffffff\\! Switch to \\#ff0000\\Mario\\#ffffff\\ to play as \n\\#4084d9\\Sonic\\#ffffff\\.", 1)
            sonicchars = 1
        end
        return true
    elseif msg == "off" then
        if sonicchars == 1 then
            play_sound(SOUND_GENERAL_COIN, m.marioObj.header.gfx.cameraToObject)
            djui_popup_create("\\#4084d9\\Sonic\\#ffffff\\ is \\#A02200\\off\\#ffffff\\!", 1)
            sonicchars = 0
        end
        return true
    end
    return false
end

function on_interact(m, o, intType)
    -- Properly grab stuff. (Bit taken from Sharen's Pasta Castle)
    local spinActions = {
        [ACT_SPINDASH] = true,
        [ACT_SONIC_ROLL] = true,
        [ACT_SONIC_WATER_SPINDASH] = true,
        [ACT_SONIC_WATER_ROLLING] = true
    }
    if spinActions[m.action] then
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
    if m.action == ACT_SONIC_IDLE and o.behavior == get_behavior_from_id(id_bhvFadingWarp) then
        return set_mario_action(m, ACT_IDLE, 0)
    end
end

hook_event(HOOK_ON_SET_MARIO_ACTION, mario_on_set_action)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ALLOW_INTERACT, on_interact)

hook_mario_action(ACT_SPINDASH, act_spindash)
hook_mario_action(ACT_SONIC_ROLL, act_sonic_roll, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_SONIC_JUMP, act_sonic_jump)
hook_mario_action(ACT_SONIC_HOLD_JUMP, act_sonic_hold_jump)
hook_mario_action(ACT_SONIC_IDLE, act_sonic_idle)
hook_mario_action(ACT_SONIC_LYING_DOWN, act_sonic_lying_down)
hook_mario_action(ACT_SONIC_EAGLE, act_sonic_eagle, INT_KICK)
hook_mario_action(ACT_SONIC_FREEFALL, act_sonic_freefall)
hook_mario_action(ACT_DROPDASH, act_dropdash, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_AIRDASH, act_airdash, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_SONIC_WALKING, act_sonic_walking)
hook_mario_action(ACT_BOUND_JUMP, act_bound_jump, INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_BOUND_POUND, act_bound_pound)
hook_mario_action(ACT_SONIC_AIR_HIT_WALL, act_air_hit_wall)

hook_chat_command(
"sonic",
"[\\#00C7FF\\on\\#ffffff\\|\\#A02200\\off\\#ffffff\\] turn \\#4084d9\\Sonic \\#00C7FF\\on \\#ffffff\\or \\#A02200\\off",
sonic_command
)
