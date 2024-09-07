-- File that handles Amy's stuff.

-- The moves.
ACT_AMY_IDLE =
    allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_IDLE | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_AMY_SITTING_DOWN =
allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_AMY_JUMP =
    allocate_mario_action(
    ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR | ACT_FLAG_CONTROL_JUMP_HEIGHT |
        ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION
)
ACT_AMY_WALKING = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING)
ACT_AMY_SWIMMING = allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_SWIMMING |
        ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT
)

ACT_GIANT_STEPS =
    allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_AMY_FACE_PLANT =
    allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_ATTACKING)
ACT_AMY_FACE_PLANT_SLIDE =
    allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_BUTT_OR_STOMACH_SLIDE | ACT_FLAG_ATTACKING)
ACT_AMY_HAMMER_HIT = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_AMY_HAMMER_SPIN = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_AMY_HAMMER_ATTACK = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
ACT_AMY_HAMMER_ATTACK_AIR =
    allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_AMY_HAMMER_SPIN_AIR =
    allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)
ACT_AMY_HAMMER_JUMP =
    allocate_mario_action(
    ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION
)
ACT_AMY_HAMMER_POUND =
    allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_AMY_HAMMER_POUND_LAND = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)

ACT_AMY_CROUCH_SLIDE =
    (ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_SHORT_HITBOX | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_FIRST_PERSON)

-- Misc functions.

function amy_hammer_pound(m)
    local v = {
        x = m.pos.x + sins(m.faceAngle.y) * 140,
        y = m.pos.y,
        z = m.pos.z + coss(m.faceAngle.y) * 140
    }
    spawn_non_sync_object(id_bhvHorStarParticleSpawner, E_MODEL_NONE, v.x, v.y, v.z, nil)
    spawn_non_sync_object(id_bhvMistCircParticleSpawner, E_MODEL_NONE, v.x, v.y, v.z, nil)
    play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_HEAVY_LANDING)
    audio_sample_play(SOUND_AMY_PIKO, v, 1)
    cur_obj_shake_screen(SHAKE_POS_MEDIUM)
end

function amy_spawn_heart_particles(m, angley, offset, anglex, vert)
    local v = {
        x = m.pos.x + sins(angley) * offset,
        y = m.pos.y,
        z = m.pos.z + coss(angley) * offset
    }

    if vert == true then
        v.x = m.pos.x + sins(angley) * offset * -coss(anglex)
        v.y = m.pos.y + sins(anglex) * offset
        v.z = m.pos.z + coss(angley) * offset * -coss(anglex)
    end

    spawn_non_sync_object(
        id_bhvRosyHeart,
        E_MODEL_ROSY_HEART,
        v.x,
        v.y,
        v.z,
        function(o)
            o.oLifetime = math.random(30, 50)
        end
    )
end

function amy_update_sliding(m, stopSpeed)
    local lossFactor
    local tempLossFactor
    local accel
    local oldSpeed
    local newSpeed

    local stopped = 0

    local intendedDYaw = m.intendedYaw - m.slideYaw
    local forward = coss(intendedDYaw)
    local sideward = sins(intendedDYaw)

    --! 10k glitch
    if (forward < 0.0 and m.forwardVel >= 0.0) then
        forward = forward * (0.5 + 0.5 * m.forwardVel / 100.0)
    end

    local floorClass = mario_get_floor_class(m)
    if floorClass == SURFACE_CLASS_VERY_SLIPPERY then
        accel = 11.3
        lossFactor = m.intendedMag / 32.0 * forward * 0.02 + 0.98

    elseif floorClass == SURFACE_CLASS_SLIPPERY then
        accel = 9.3
        lossFactor = m.intendedMag / 32.0 * forward * 0.02 + 0.96

    elseif floorClass == SURFACE_CLASS_NOT_SLIPPERY then
        accel = 6.3
        lossFactor = m.intendedMag / 32.0 * forward * 0.02 + 0.92

    else
        accel = 8.3
        lossFactor = m.intendedMag / 32.0 * forward * 0.02 + 0.92

    end
    
    if (m.controller.buttonDown & B_BUTTON) ~= 0 and m.forwardVel >= 125 then
        lossFactor = 1
    end

    oldSpeed = math.sqrt(m.slideVelX * m.slideVelX + m.slideVelZ * m.slideVelZ)

    --! This is attempting to use trig derivatives to rotate Mario's speed.
    -- It is slightly off/asymmetric since it uses the new X speed, but the old
    -- Z speed.
    m.slideVelX = m.slideVelX + (m.slideVelZ * (m.intendedMag / 32.0) * sideward * 0.09)
    m.slideVelZ = m.slideVelZ - (m.slideVelX * (m.intendedMag / 32.0) * sideward * 0.09)

    newSpeed = math.sqrt(m.slideVelX * m.slideVelX + m.slideVelZ * m.slideVelZ)

    if (oldSpeed > 0.0 and newSpeed > 0.0) then
        m.slideVelX = m.slideVelX * oldSpeed / newSpeed
        m.slideVelZ = m.slideVelZ * oldSpeed / newSpeed
    end

    update_sliding_angle(m, accel, lossFactor)

    if (mario_floor_is_slope(m) == 0 and m.forwardVel * m.forwardVel < stopSpeed * stopSpeed) then
        mario_set_forward_vel(m, 0.0)
        stopped = 1
    end

    return stopped
end

function update_amy_swimming_speed(m, maxSpeed)
    
    if (m.forwardVel <= 0.0) then
        m.forwardVel = m.forwardVel + 1.1
    elseif (m.forwardVel <= maxSpeed) then
        m.forwardVel = m.forwardVel + (1.1 - m.forwardVel / maxSpeed)
        --elseif (m.floor ~= nil and m.floor.normal.y >= 0.95) then
        --m.forwardVel = m.forwardVel - 1.0
    end

    m.vel.x = m.forwardVel * coss(m.faceAngle.x) * sins(m.faceAngle.y)
    m.vel.y = m.forwardVel * sins(m.faceAngle.x)
    m.vel.z = m.forwardVel * coss(m.faceAngle.x) * coss(m.faceAngle.y)
end

-- Action functions.
function act_amy_idle(m)
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
            set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_CENTER)
            smlua_anim_util_set_animation(m.marioObj, "AMY_IDLE")
            m.marioBodyState.handState = MARIO_HAND_OPEN
            if is_anim_at_end(m) ~= 0 then
                if m.actionTimer > math.random(15, 20) * 30 then
                    m.actionTimer = 0
                    m.actionState = 1
                else
                    m.actionState = 0
                end
            end
        elseif m.actionState == 1 then
            set_mario_animation(m, MARIO_ANIM_START_SLEEP_IDLE)
            smlua_anim_util_set_animation(m.marioObj, "AMY_WAIT_START")
            if is_anim_past_end(m) ~= 0 then
                m.actionState = 2
            end
        elseif m.actionState == 2 then
            set_mario_animation(m, MARIO_ANIM_START_SLEEP_SCRATCH)
            smlua_anim_util_set_animation(m.marioObj, "AMY_WAIT")

            if is_anim_past_end(m) ~= 0 then
                if m.actionTimer > math.random(20, 40) * 30 then
                    m.actionState = math.floor(math.random(6, 8) / 2)
                end
            end
        elseif m.actionState == 3 then
            set_mario_animation(m, MARIO_ANIM_START_SLEEP_YAWN)
            smlua_anim_util_set_animation(m.marioObj, "AMY_WAIT_KICK")
			
            if is_anim_at_end(m) ~= 0 then
                m.actionState = 2
				m.actionTimer = 0
            end
        elseif m.actionState == 4 then
            set_mario_animation(m, MARIO_ANIM_START_SLEEP_SITTING)
            smlua_anim_util_set_animation(m.marioObj, "AMY_WAIT_2")
            if is_anim_past_end(m) ~= 0 then
                set_mario_action(m, ACT_AMY_SITTING_DOWN, 0)
            end
        end
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_amy_sitting_down(m)
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
        return set_mario_action(m, ACT_AMY_HAMMER_ATTACK, 0)
    end

    if m.actionState == 0 then
        set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_LEFT)
        smlua_anim_util_set_animation(m.marioObj, "AMY_WAIT_2")
		set_anim_to_frame(m, 40)
		
        --if is_anim_past_frame(m, 20) ~= 0 then
        --    if m.actionTimer > math.random(40, 50) * 30 then
        --        e.animFrame = 8
        --        m.actionState = 2
        --    end
        --end
    elseif m.actionState == 1 then
        set_mario_animation(m, MARIO_ANIM_WAKE_FROM_LYING)
        smlua_anim_util_set_animation(m.marioObj, "AMY_WAIT_2_END")

        if (is_anim_past_frame(m, 25) ~= 0 and (m.input & INPUT_NONZERO_ANALOG) ~= 0)
        or is_anim_past_end(m) ~= 0 then
            set_mario_action(m, ACT_AMY_IDLE, 0)
        end
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_amy_jump(m)
    local e = gMarioStateExtras[m.playerIndex]
    local anim = 0
    
    if m.vel.y < 0 then
        anim = MARIO_ANIM_DOUBLE_JUMP_FALL
    else
        anim = MARIO_ANIM_DOUBLE_JUMP_RISE
    end
    
    if m.actionTimer == 0 then
        play_character_sound_if_no_flag(m, CHAR_SOUND_YAH_WAH_HOO, MARIO_ACTION_SOUND_PLAYED)
    end

    local stepResult =
        sonic_common_air_action_step(
        m,
        ACT_FREEFALL_LAND_STOP,
        anim,
        AIR_STEP_CHECK_LEDGE_GRAB | AIR_STEP_CHECK_HANG,
        true,
        true
    )
    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        return sonic_air_attacks(m)
    end
    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_AMY_HAMMER_POUND, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

function act_amy_walking(m)
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
            sonic_gen_anim_and_audio_for_walk(m, 18, 38)
        end
        if (m.intendedMag - m.forwardVel) > 16 then
            set_mario_particle_flags(m, PARTICLE_DUST, false)
        end
    elseif stepResult == GROUND_STEP_HIT_WALL then
        if m.heldObj == nil then
            push_or_sidle_wall(m, m.pos)
        else
            if m.forwardVel > 5 then
                mario_set_forward_vel(m, 5)
            end
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
            return set_mario_action(m, ACT_AMY_HAMMER_ATTACK, 0)
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

function act_amy_swimming(m)
    local e = gMarioStateExtras[m.playerIndex]
    lua_update_swimming_yaw(m)
    lua_update_swimming_pitch(m)
    update_amy_swimming_speed(m, e.movingSpeed)
    lua_update_water_pitch(m)
	move_with_current(m)

    m.actionState = 0
    local stepResult = perform_water_step(m)

    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        if m.heldObj ~= nil then
            return set_mario_action(m, ACT_HOLD_METAL_WATER_FALLING, 0)
        else
            return set_mario_action(m, ACT_METAL_WATER_FALLING, 1)
        end
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        if m.heldObj ~= nil then
            return set_mario_action(m, ACT_WATER_THROW, 0)
        else
            return set_mario_action(m, ACT_WATER_PUNCH, 0)
        end
    end

    if (m.input & INPUT_A_DOWN) == 0 then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 4, 4))
        if (m.forwardVel < 10) then
            return set_mario_action(m, ACT_SWIMMING_END, 0)
        end
    end
    
    if (m.input & INPUT_A_PRESSED) ~= 0 then
        lua_check_water_jump(m)
    end

    local animFrame = m.marioObj.header.gfx.animInfo.animFrame
    local anim = MARIO_ANIM_FLUTTERKICK
    
    if m.heldObj ~= nil then
        anim = MARIO_ANIM_FLUTTERKICK_WITH_OBJ
    else
        anim = MARIO_ANIM_FLUTTERKICK
    end

    if (animFrame == 0 or animFrame == 12) then
        play_sound(SOUND_ACTION_UNKNOWN434, m.marioObj.header.gfx.cameraToObject)
    end
    
    set_mario_anim_with_accel(m, anim, m.forwardVel * 0x1000)
    
    return 0
end

function act_amy_hammer_hit(m)
    if (m.input & INPUT_A_PRESSED) ~= 0 and m.actionTimer < 5 then
        return set_mario_action(m, ACT_AMY_HAMMER_JUMP, 0)
    end
    m.flags = m.flags | MARIO_KICKING

    if m.actionTimer >= 6 then
        set_mario_action(m, ACT_WALKING, 0)
    end

    set_mario_animation(m, MARIO_ANIM_FIRST_PUNCH_FAST)
    if m.actionArg == 0 then
        smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_HIT_END")
    else
        smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_SPIN")
        m.marioBodyState.eyeState = 16
    end

    local stepResult = perform_ground_step(m)
    if stepResult == GROUND_STEP_NONE then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 2, 2))
        if mario_floor_is_slope(m) ~= 0 or mario_floor_is_steep(m) ~= 0 then
            apply_slope_accel(m)
        end

        if math.abs(m.forwardVel) >= 10 then
            set_mario_particle_flags(m, PARTICLE_DUST, false)
            play_sound(SOUND_MOVING_TERRAIN_SLIDE + m.terrainSoundAddend, m.marioObj.header.gfx.cameraToObject)
        end
    elseif stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_FREEFALL, 0)
    end
    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_amy_hammer_attack(m)
    local e = gMarioStateExtras[m.playerIndex]

    if m.actionTimer == 0 then
        e.animFrame = 0
        e.rotAngle = 0x000
    end

    m.marioBodyState.eyeState = 12

    set_mario_animation(m, MARIO_ANIM_FIRST_PUNCH)
    smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_HIT")

    set_anim_to_frame(m, e.animFrame)
    e.animFrame = e.animFrame + 2

    if e.animFrame >= 10 then
        m.flags = m.flags | MARIO_KICKING
    else
        if mario_check_object_grab(m) == true then
            return true
        end
    end

    amy_spawn_heart_particles(m, m.faceAngle.y, 120, e.rotAngle, true)

    local stepResult = perform_ground_step(m)
    if stepResult == GROUND_STEP_NONE then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 3, 3))
        if mario_floor_is_slope(m) ~= 0 or mario_floor_is_steep(m) ~= 0 then
            apply_slope_accel(m)
        end

        if math.abs(m.forwardVel) >= 10 then
            set_mario_particle_flags(m, PARTICLE_DUST, false)
            play_sound(SOUND_MOVING_TERRAIN_SLIDE + m.terrainSoundAddend, m.marioObj.header.gfx.cameraToObject)
        end
    elseif stepResult == GROUND_STEP_LEFT_GROUND then
        return set_mario_action(m, ACT_AMY_HAMMER_ATTACK_AIR, 1)
    end

    if is_anim_past_end(m) ~= 0 then
        play_character_sound_if_no_flag(m, CHAR_SOUND_PUNCH_HOO, MARIO_ACTION_SOUND_PLAYED)
        set_mario_action(m, ACT_AMY_HAMMER_HIT, 0)
    end

    if (m.input & INPUT_A_PRESSED) ~= 0 and e.animFrame >= 6 then
        amy_hammer_pound(m)
        return set_mario_action(m, ACT_AMY_HAMMER_JUMP, 0)
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_amy_hammer_attack_air(m)
    local e = gMarioStateExtras[m.playerIndex]

    if m.actionTimer == 0 then
        e.rotAngle = 0x000
        e.animFrame = 0
    end

    sonic_update_air(m)

    local stepResult = perform_air_step(m, 0)

    if stepResult == AIR_STEP_HIT_WALL and m.wall ~= nil then
        if m.actionArg == 1 then
            m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
            play_sound(SOUND_ACTION_BOUNCE_OFF_OBJECT, m.marioObj.header.gfx.cameraToObject)
            audio_sample_play(SOUND_AMY_PIKO, m.pos, 1)
            cur_obj_shake_screen(SHAKE_POS_MEDIUM)
            wall_bounce(m)
            if m.vel.y < 140 then
                set_mario_y_vel_based_on_fspeed(m, 40, 0.5)
            else
                m.vel.y = 140
            end
            if m.forwardVel < 40 then
                mario_set_forward_vel(m, 40)
            else
                mario_set_forward_vel(m, m.forwardVel)
            end
            e.wallClimbed = 1
        else
            queue_rumble_data_mario(m, 5, 40)
            mario_bonk_reflection(m, false)
            m.faceAngle.y = m.faceAngle.y + 0x9000
            if m.forwardVel > 16.0 then
                set_mario_action(m, ACT_SONIC_AIR_HIT_WALL, 0)
            end
        end
    elseif stepResult == AIR_STEP_LANDED then
        m.marioObj.oMarioWalkingPitch = 0x0000
        if (check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB) == 0) then
            if m.actionArg < 2 then
                if (m.input & INPUT_A_PRESSED) ~= 0 then
                    amy_hammer_pound(m)
                    return set_mario_action(m, ACT_AMY_HAMMER_JUMP, 0)
                else
                    set_mario_action(m, ACT_AMY_HAMMER_HIT, 1)
                end
            else
                if m.forwardVel ~= 0 then
                    set_mario_action(m, e.walkAction, 0)
                    m.faceAngle.y = atan2s(m.vel.z, m.vel.x)
                else
                    set_mario_action(m, ACT_FREEFALL_LAND, 0)
                end
            end
        end
    end

    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)

    e.rotFrames = e.rotFrames + 4
    if (e.rotFrames) % 7 == 0 then
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end

    if m.actionArg == 0 then
        m.marioBodyState.eyeState = 12
        smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_FLIP")
        set_anim_to_frame(m, e.animFrame)
        e.animFrame = e.animFrame + 1
        if e.animFrame >= 7 then
            m.actionArg = 1
        end
    elseif m.actionArg == 1 then
        smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_FLIP_LOOP")
        e.rotAngle = e.rotAngle + (0x80 * 100)
        if e.rotAngle > 0x10000 then
            e.rotAngle = e.rotAngle - 0x10000
        end
        set_anim_to_frame(m, 10 * e.rotAngle / 0x10000)
        amy_spawn_heart_particles(m, m.faceAngle.y, 120, e.rotAngle + 0x4500, true)
        m.marioBodyState.eyeState = 14
    elseif m.actionArg == 2 then
        smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_FLIP_END")
        set_anim_to_frame(m, e.animFrame)
        e.animFrame = e.animFrame + 1
        if e.animFrame >= 9 then
            set_mario_action(m, ACT_SONIC_FREEFALL, 0)
        end
    end

    if (m.controller.buttonDown & B_BUTTON) == 0 and e.rotAngle >= 0x9500 and m.actionArg == 1 then
        m.actionArg = 2
        e.animFrame = m.marioObj.header.gfx.animInfo.animFrame
    end

    m.actionTimer = m.actionTimer + 1
end

function act_amy_hammer_jump(m)
    local e = gMarioStateExtras[m.playerIndex]

    if m.actionTimer == 0 then
        play_character_sound_if_no_flag(m, CHAR_SOUND_YAHOO_WAHA_YIPPEE, MARIO_ACTION_SOUND_PLAYED)
    end
	
    if m.actionTimer < 10 and m.vel.y > 20 then
        set_mario_particle_flags(m, PARTICLE_DUST, false)
    end

    local stepResult =
        sonic_common_air_action_step(
        m,
        ACT_FREEFALL_LAND,
        MARIO_ANIM_TRIPLE_JUMP,
        AIR_STEP_CHECK_LEDGE_GRAB | AIR_STEP_CHECK_HANG,
        true,
        true
    )
    play_flip_sounds(m, 2, 8, 20)

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        return sonic_air_attacks(m)
    end

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_AMY_HAMMER_POUND, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

function act_giant_steps(m)
    local e = gMarioStateExtras[m.playerIndex]

    if m.actionTimer == 0 then
        play_character_sound_if_no_flag(m, CHAR_SOUND_YAH_WAH_HOO, MARIO_ACTION_SOUND_PLAYED)
    end

    local stepResult = perform_air_step(m, 0)
    set_mario_animation(m, MARIO_ANIM_SLIDE_KICK)
    smlua_anim_util_set_animation(m.marioObj, "AMY_GIANT_STEPS")


    if stepResult == AIR_STEP_LANDED then
        if (check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB) == 0) then
            if (m.controller.buttonDown & Z_TRIG) ~= 0 then
                set_mario_action(m, ACT_CROUCH_SLIDE, 1)
            else
                set_mario_action(m, e.walkAction, 0)
            end
        end
    end

    if (m.controller.buttonDown & B_BUTTON) ~= 0 then
        set_mario_action(m, ACT_AMY_FACE_PLANT, 0)
    end

    if m.forwardVel > 120 then
        mario_set_forward_vel(m, m.forwardVel)
    else
        mario_set_forward_vel(m, m.forwardVel)
    end

    m.actionTimer = m.actionTimer + 1
end

function act_amy_hammer_spin(m)
    local e = gMarioStateExtras[m.playerIndex]
    if m.actionTimer == 0 then
        e.rotAngle = 0x0000
    end

    m.marioBodyState.eyeState = 4

    if (m.controller.buttonDown & B_BUTTON) == 0 then
        set_mario_action(m, ACT_WALKING, 0)
    end

    set_mario_animation(m, MARIO_ANIM_SWINGING_BOWSER)
    smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_SPIN_STAND")
    e.rotFrames = e.rotFrames + 4
    if (e.rotFrames) % 7 == 0 then
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end

    e.rotAngle = e.rotAngle + (0x80 * 100)
    if e.rotAngle > 0x10000 then
        e.rotAngle = e.rotAngle - 0x10000
    end

    amy_spawn_heart_particles(m, e.rotAngle, 140)

    local stepResult = perform_ground_step(m)
    if stepResult == GROUND_STEP_NONE then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 0.3, 0.3))
        if m.forwardVel < 0 then
            m.faceAngle.y = m.faceAngle.y + 0x8000
            mario_set_forward_vel(m, -m.forwardVel)
        end
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x100, 0x100)
        if mario_floor_is_slope(m) ~= 0 or mario_floor_is_steep(m) ~= 0 then
            apply_slope_accel(m)
        end

        if m.forwardVel ~= 0 then
            set_mario_particle_flags(m, PARTICLE_DUST, false)
            play_sound(SOUND_MOVING_TERRAIN_SLIDE + m.terrainSoundAddend, m.marioObj.header.gfx.cameraToObject)
        end
    elseif stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_AMY_HAMMER_SPIN_AIR, 0)
    elseif stepResult == GROUND_STEP_HIT_WALL then
        m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
        play_sound(SOUND_ACTION_BOUNCE_OFF_OBJECT, m.marioObj.header.gfx.cameraToObject)
        cur_obj_shake_screen(SHAKE_POS_MEDIUM)
        audio_sample_play(SOUND_AMY_PIKO, m.pos, 1)
        wall_bounce(m)
        if m.forwardVel < 5 then
            mario_set_forward_vel(m, 5)
        else
            mario_set_forward_vel(m, m.forwardVel)
        end
    end

    m.actionTimer = m.actionTimer + 1
    m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y + e.rotAngle
    return 0
end

function act_amy_hammer_spin_air(m)
    local e = gMarioStateExtras[m.playerIndex]
    if m.actionTimer == 0 then
        e.rotAngle = 0x0000
    end

    m.marioBodyState.eyeState = 4

    if (m.controller.buttonDown & B_BUTTON) == 0 then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    set_mario_animation(m, MARIO_ANIM_SWINGING_BOWSER)
    smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_SPIN_STAND")
    e.rotFrames = e.rotFrames + 4
    if (e.rotFrames) % 7 == 0 then
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end

    e.rotAngle = e.rotAngle + (0x80 * 100)
    if e.rotAngle > 0x10000 then
        e.rotAngle = e.rotAngle - 0x10000
    end

    amy_spawn_heart_particles(m, e.rotAngle, 140)

    local stepResult = perform_air_step(m, 0)
    sonic_update_air(m)
    if stepResult == AIR_STEP_NONE then
        --mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 0.3, 0.3))
        if m.forwardVel < 0 then
            m.faceAngle.y = m.faceAngle.y + 0x8000
            mario_set_forward_vel(m, -m.forwardVel)
        end
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x100, 0x100)
    elseif stepResult == AIR_STEP_LANDED then
        set_mario_action(m, ACT_AMY_HAMMER_SPIN, 0)
    elseif stepResult == AIR_STEP_HIT_WALL then
        m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
        play_sound(SOUND_ACTION_BOUNCE_OFF_OBJECT, m.marioObj.header.gfx.cameraToObject)
        cur_obj_shake_screen(SHAKE_POS_MEDIUM)
        audio_sample_play(SOUND_AMY_PIKO, m.pos, 1)
        wall_bounce(m)

        if m.forwardVel < 5 then
            mario_set_forward_vel(m, 5)
        else
            mario_set_forward_vel(m, m.forwardVel)
        end
    end

    if m.vel.y < -20 then
        m.vel.y = -20
    end
    m.peakHeight = m.pos.y

    m.actionTimer = m.actionTimer + 1
    m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y + e.rotAngle
    return 0
end

function act_amy_face_plant(m)
    local e = gMarioStateExtras[m.playerIndex]
    if (m.actionArg == 0) then
        play_mario_sound(m, SOUND_ACTION_THROW, CHAR_SOUND_WHOA)
    else
        play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, CHAR_SOUND_WHOA)
    end

    -- Unimplemented slide boost mode.
    -- if m.forwardVel >= 125 then
    --     m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    -- end
    
    set_mario_animation(m, MARIO_ANIM_DIVE)
    smlua_anim_util_set_animation(m.marioObj, "AMY_TRIP")
    if m.marioObj.header.gfx.animInfo.animFrame >= 4 then
        m.marioBodyState.handState = MARIO_HAND_OPEN
    end
    m.marioBodyState.eyeState = 14
    if (mario_check_object_grab(m) ~= 0) then
        mario_grab_used_object(m)
        if (m.heldObj ~= nil) then
            m.marioBodyState.grabPos = GRAB_POS_LIGHT_OBJ
            if (m.action ~= ACT_AMY_FACE_PLANT) then
                return 1
            end
        end
    end

    sonic_update_air(m)

    local stepResult = perform_air_step(m, 0)

    if stepResult == AIR_STEP_NONE then
        if (m.vel.y < 0.0 and m.faceAngle.x > -0x2AAA) then
            m.faceAngle.x = m.faceAngle.x - 0x200
            if (m.faceAngle.x < -0x2AAA) then
                m.faceAngle.x = -0x2AAA
            end
        end
        m.marioObj.header.gfx.angle.x = -m.faceAngle.x
    elseif stepResult == AIR_STEP_LANDED then
        if (should_get_stuck_in_ground(m) ~= 0 and m.faceAngle.y == -0x2AAA) then
            queue_rumble_data_mario(m, 5, 80)
            play_character_sound(m, CHAR_SOUND_OOOF2)
            set_mario_particle_flags(m, PARTICLE_MIST_CIRCLE, false)
            drop_and_set_mario_action(m, ACT_HEAD_STUCK_IN_GROUND, 0)
        elseif check_fall_damage(m, ACT_HARD_FORWARD_GROUND_KB) == 0 then
            if (m.heldObj == nil) then
                set_mario_action(m, ACT_AMY_FACE_PLANT_SLIDE, 0)
                e.preVel = m.forwardVel
            else
                set_mario_action(m, ACT_DIVE_PICKING_UP, 0)
            end
        end
        m.faceAngle.x = 0
    elseif stepResult == AIR_STEP_HIT_WALL then
        mario_bonk_reflection(m, true)
        m.faceAngle.x = 0

        if (m.vel.y > 0.0) then
            m.vel.y = 0.0
        end

        set_mario_particle_flags(m, PARTICLE_VERTICAL_STAR, false)
        drop_and_set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
    elseif stepResult == AIR_STEP_HIT_LAVA_WALL then
        lava_boost_on_wall(m)
    end

    m.actionTimer = m.actionTimer + 1

    return 0
end

function act_amy_face_plant_slide(m)
    local e = gMarioStateExtras[m.playerIndex]
    if m.actionTimer == 0 then
        e.animFrame = 0
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
                set_mario_action(m, ACT_DIVE_PICKING_UP, 0)
                m.marioBodyState.grabPos = GRAB_POS_LIGHT_OBJ
                return 1
            end
        end
    end
    
    common_slide_action(m, ACT_STOMACH_SLIDE_STOP, ACT_FREEFALL, MARIO_ANIM_SWIM_PART1)
    
    if m.actionArg == 0 then
        smlua_anim_util_set_animation(m.marioObj, "AMY_FACEPLANT")
        if m.marioObj.header.gfx.animInfo.animFrame >= 4 then
            m.actionArg = 1
        end
    elseif m.actionArg == 1 then
        smlua_anim_util_set_animation(m.marioObj, "AMY_FACEPLANT_LOOP")
        set_anim_to_frame(m, e.animFrame)
        
        e.animFrame = e.animFrame + math.abs(m.forwardVel) / 16
        if e.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd then
            e.animFrame = e.animFrame - m.marioObj.header.gfx.animInfo.curAnim.loopEnd
        end
    end 
    
    m.marioBodyState.eyeState = 16
    m.marioBodyState.handState = MARIO_HAND_OPEN
    -- Unimplemented slide boost mode.
    -- if m.forwardVel >= 125 then
    --     m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    -- end

    if (m.input & INPUT_ABOVE_SLIDE) == 0
    and (m.input & (INPUT_A_PRESSED | INPUT_B_PRESSED)) ~= 0 then
        queue_rumble_data_mario(m, 5, 80)
        if m.forwardVel > 0 then
            return set_mario_action(m, ACT_FORWARD_ROLLOUT, 0)
        else
            return set_mario_action(m, ACT_BACKWARD_ROLLOUT, 0)
        end
    end

    play_mario_landing_sound_once(m, SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)

    --! If the dive slide ends on the same frame that we pick up on object,
    -- Mario will not be in the dive slide action for the call to
    -- mario_check_object_grab, and so will end up in the regular picking action,
    -- rather than the picking up after dive action.

    if amy_update_sliding(m, 8) ~= 0 then
        mario_set_forward_vel(m, 0.0)
        set_mario_action(m, ACT_STOMACH_SLIDE_STOP, 0)
    end

    --lazy-ass speed cap
    if m.forwardVel > 150 then
        m.forwardVel = 150
    -- Unimplemented slide boost mode.
    -- else    
    --     if (m.controller.buttonDown & B_BUTTON) ~= 0 and m.forwardVel >= 125 then
    --         mario_set_forward_vel(m, m.forwardVel)
    --     end
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_amy_hammer_pound(m)
    local e = gMarioStateExtras[m.playerIndex]
    local soundRng = math.random(1, 2)
    if soundRng == 1 then
        play_character_sound_if_no_flag(m, CHAR_SOUND_YAH_WAH_HOO, MARIO_ACTION_SOUND_PLAYED)
    else
        play_character_sound_if_no_flag(m, CHAR_SOUND_HOOHOO, MARIO_ACTION_SOUND_PLAYED)
    end

    m.marioBodyState.eyeState = 7

    m.vel.y = -70.0
    amy_spawn_heart_particles(m, e.rotAngle, 140)
    set_mario_animation(m, MARIO_ANIM_SWINGING_BOWSER)
    smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_SPIN")
    e.rotFrames = e.rotFrames + 4
    if (e.rotFrames) % 7 == 0 then
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end

    e.rotAngle = e.rotAngle + (0x80 * 100)
    if e.rotAngle > 0x10000 then
        e.rotAngle = e.rotAngle - 0x10000
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 and e.airdashed == 0 then
        e.airdashed = 1
        if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
            m.faceAngle.y = m.intendedYaw
        end
        m.vel.y = 0
        if m.forwardVel < 70 then
            mario_set_forward_vel(m, m.forwardVel + 40)
        elseif m.forwardVel < 150 then
            mario_set_forward_vel(m, m.forwardVel + 15)
        else
            mario_set_forward_vel(m, m.forwardVel + 1)
        end

        if m.vel.y > 200 then
            m.vel.y = 200
        end

        set_mario_action(m, ACT_AMY_HAMMER_SPIN_AIR, 0)
    end

    local stepResult = perform_air_step(m, 0)

    if stepResult == AIR_STEP_LANDED then
        m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE | PARTICLE_HORIZONTAL_STAR
        play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_HEAVY_LANDING)
        cur_obj_shake_screen(SHAKE_POS_MEDIUM)
        set_mario_action(m, ACT_AMY_HAMMER_POUND_LAND, 1)
    end
    m.peakHeight = m.pos.y
    m.actionTimer = m.actionTimer + 1
    m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y + e.rotAngle

    return 0
end

function act_amy_hammer_pound_land(m)
    local e = gMarioStateExtras[m.playerIndex]

    set_mario_animation(m, MARIO_ANIM_SWINGING_BOWSER)
    smlua_anim_util_set_animation(m.marioObj, "AMY_HAMMER_SPIN")

    m.marioBodyState.eyeState = 7

    local stepResult = perform_ground_step(m)

    if stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_SONIC_FREEFALL, 0)
    elseif stepResult == GROUND_STEP_NONE then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 6, 6))
    end

    -- A debuff so that players can't just bounce up slides.
    if (m.input & INPUT_ABOVE_SLIDE) ~= 0 then
        return set_mario_action(m, ACT_BUTT_SLIDE, 0)
    end

    if (m.input & INPUT_UNKNOWN_10) ~= 0 then
        return drop_and_set_mario_action(m, ACT_SHOCKWAVE_BOUNCE, 0)
    end

    if m.actionTimer > 8 then
        set_mario_action(m, ACT_AMY_WALKING, 0)
    end

    m.actionTimer = m.actionTimer + 1
end

function act_amy_crouch_slide(m)
    local e = gMarioStateExtras[m.playerIndex]
    local cancel = 0

    if (m.input & INPUT_A_PRESSED) ~= 0 then
        if (m.controller.buttonDown & Z_TRIG) == 0 then
            return do_sonic_jump(m)
        elseif m.actionArg ~= 1 or (m.actionArg == 1 and m.actionTimer > 2) then
            return set_mario_action(m, ACT_GIANT_STEPS, 0)
        end
    end

    if (m.input & INPUT_ABOVE_SLIDE) ~= 0 then
        return set_mario_action(m, ACT_BUTT_SLIDE, 0)
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        if (m.input & INPUT_Z_DOWN) ~= 0 then
            return set_mario_action(m, ACT_AMY_HAMMER_SPIN, 0)
        else
            return set_mario_action(m, ACT_AMY_HAMMER_ATTACK, 0)
        end
    end

    if (m.input & INPUT_FIRST_PERSON) ~= 0 then
        return set_mario_action(m, ACT_BRAKING, 0)
    end
	
    m.actionTimer = m.actionTimer + 1

    cancel = common_slide_action_with_jump(m, ACT_CROUCHING, ACT_GIANT_STEPS, ACT_FREEFALL, MARIO_ANIM_START_CROUCHING)
    return cancel
end

-- Hooks.

local airBonkActions = {
    [ACT_QUICKSAND_DEATH] = true,
    [ACT_GRABBED] = true,
    [ACT_SHOCKED] = true,
    [ACT_GETTING_BLOWN] = true,
    [ACT_HARD_BACKWARD_AIR_KB] = true,
    [ACT_BACKWARD_AIR_KB] = true,
    [ACT_SOFT_BACKWARD_GROUND_KB] = true,
    [ACT_HARD_FORWARD_AIR_KB] = true,
    [ACT_FORWARD_AIR_KB] = true,
    [ACT_SOFT_FORWARD_GROUND_KB] = true,
    [ACT_THROWN_FORWARD] = true,
    [ACT_THROWN_BACKWARD] = true,
    [ACT_DEATH_EXIT] = true
}

function amy_update(m)
    local e = gMarioStateExtras[m.playerIndex]

    sonic_walking_door_check(m)
    sonic_check_wall_kick(m)

    -- Stats.
    e.walkAction = ACT_AMY_WALKING
    e.movingSpeed = 44.0
    e.movingSpeedSlow = 32.0
    e.jumpHeight = 50
    e.jumpHeightMultiplier = 0.3

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

    if m.action == ACT_SOFT_BONK then
        m.actionTimer = m.actionTimer + 1
    end

    if (m.action == ACT_WATER_IDLE 
    or m.action == ACT_HOLD_WATER_IDLE
    or m.action == ACT_WATER_ACTION_END)
    and (m.controller.buttonDown & A_BUTTON) ~= 0 then
        m.action = ACT_AMY_SWIMMING
    end
	
    --if m.marioObj.header.gfx.animInfo.animID == 79 then
    --    m.marioObj.header.gfx.disableAutomaticShadowPos = true
    --end

    -- Animations 'n stuff.

    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        m.marioBodyState.eyeState = 1
    end

    if m.action == ACT_PANTING then
        m.marioBodyState.eyeState = 17
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_STAR_DANCE then
        smlua_anim_util_set_animation(m.marioObj, "AMY_STAR_DANCE")
        if m.marioObj.header.gfx.animInfo.animFrame < 27 then
            m.marioBodyState.eyeState = 11
        elseif m.marioObj.header.gfx.animInfo.animFrame < 40 then
            m.marioBodyState.eyeState = 9
            m.marioBodyState.handState = MARIO_HAND_OPEN
        elseif m.marioObj.header.gfx.animInfo.animFrame < 52 then
            m.marioBodyState.eyeState = 11
        else
            m.marioBodyState.eyeState = 19
            m.marioBodyState.handState = MARIO_HAND_OPEN
        end
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_WALKING then
        smlua_anim_util_set_animation(m.marioObj, "AMY_WALKING")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_RUNNING then
        smlua_anim_util_set_animation(m.marioObj, "AMY_JOGGING")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_RUNNING_UNUSED then
        smlua_anim_util_set_animation(m.marioObj, "AMY_RUNNING")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_SKID_ON_GROUND then
        smlua_anim_util_set_animation(m.marioObj, "AMY_SKID")
        m.marioBodyState.eyeState = 16
        m.marioBodyState.handState = MARIO_HAND_OPEN
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_STOP_SKID then
        smlua_anim_util_set_animation(m.marioObj, "AMY_SKID_STOP")
        m.marioBodyState.handState = MARIO_HAND_OPEN
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_TURNING_PART1 then
        smlua_anim_util_set_animation(m.marioObj, "AMY_SKID")
        m.marioBodyState.eyeState = 16
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_TURNING_PART2 then
        smlua_anim_util_set_animation(m.marioObj, "AMY_SKID_TURN")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_START_CROUCHING then
        smlua_anim_util_set_animation(m.marioObj, "AMY_CROUCHING_START")
        m.marioBodyState.handState = MARIO_HAND_OPEN
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_CROUCHING then
        smlua_anim_util_set_animation(m.marioObj, "AMY_CROUCHING")
        m.marioBodyState.handState = MARIO_HAND_OPEN
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_STOP_CROUCHING then
        smlua_anim_util_set_animation(m.marioObj, "AMY_CROUCHING_STOP")
        m.marioBodyState.handState = MARIO_HAND_OPEN
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_START_CRAWLING then
        smlua_anim_util_set_animation(m.marioObj, "AMY_CRAWLING_START")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_STOP_CRAWLING then
        smlua_anim_util_set_animation(m.marioObj, "AMY_CRAWLING_STOP")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_CREDITS_WAVING then
        smlua_anim_util_set_animation(m.marioObj, "AMY_CREDITS_WAVING")
        m.marioBodyState.eyeState = 9
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_FIRST_PERSON then
        smlua_anim_util_set_animation(m.marioObj, "AMY_IDLE_ALT")
        m.marioBodyState.handState = MARIO_HAND_OPEN
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_TAKE_CAP_OFF_THEN_ON then
        m.marioBodyState.handState = MARIO_HAND_OPEN
        smlua_anim_util_set_animation(m.marioObj, "AMY_EXIT_LEVEL")
        m.marioBodyState.capState = 0
		
        if m.marioObj.header.gfx.animInfo.animFrame > 5 then
		    if m.marioObj.header.gfx.animInfo.animFrame < 16 then
                m.marioBodyState.eyeState = 11
            elseif m.marioObj.header.gfx.animInfo.animFrame < 40 then
                m.marioBodyState.eyeState = 15
            elseif m.marioObj.header.gfx.animInfo.animFrame < 56 then
                m.marioBodyState.eyeState = 11
            elseif m.marioObj.header.gfx.animInfo.animFrame < 80 then
                m.marioBodyState.eyeState = 15
			end
        else
            m.marioBodyState.eyeState = 0
		end
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_DROWNING_PART1 then
        m.marioBodyState.eyeState = 14
    elseif m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_DROWNING_PART2 then
        if m.marioObj.header.gfx.animInfo.animFrame < 40 then
            m.marioBodyState.eyeState = 17
        else
            m.marioBodyState.eyeState = 16
        end
    end

    if m.action == ACT_DEATH_EXIT_LAND then
        if m.marioObj.header.gfx.animInfo.animFrame < 45 then
            m.marioBodyState.eyeState = 10
        else
            m.marioBodyState.eyeState = 13
        end
    end

    if airBonkActions[m.action] then
        m.marioBodyState.eyeState = 14
    end

    if
        m.action == ACT_HARD_BACKWARD_GROUND_KB or m.action == ACT_BACKWARD_GROUND_KB or
            m.action == ACT_HARD_FORWARD_GROUND_KB or
            m.action == ACT_FORWARD_GROUND_KB or
            m.action == ACT_FORWARD_WATER_KB or
            m.action == ACT_BACKWARD_WATER_KB or
            m.action == ACT_GROUND_BONK
     then
        m.marioBodyState.eyeState = 10
    end

    if e.modelState == 2 and (m.flags & MARIO_METAL_CAP) == 0 then
        m.marioBodyState.capState = 1
    end

    if m.action == ACT_SOFT_BONK and (m.controller.buttonPressed & Z_TRIG) ~= 0 and m.prevAction ~= ACT_HOLDING_POLE then
        set_mario_action(m, ACT_AMY_HAMMER_POUND, 0)
    end

    if (m.action == ACT_TURNING_AROUND and (m.input & INPUT_B_PRESSED) ~= 0) then
        m.vel.y = 0
        set_mario_action(m, ACT_AMY_HAMMER_ATTACK, 0)
    end

    visual_updates(m)
    return 0
end

function amy_on_set_action(m)
    local e = gMarioStateExtras[m.playerIndex]
    if (m.action == ACT_PUNCHING and m.actionArg ~= 9) or m.action == ACT_MOVE_PUNCHING then
        m.vel.y = 0
        set_mario_action(m, ACT_AMY_HAMMER_ATTACK, 0)
    end

    if (m.action == ACT_PUNCHING and m.actionArg == 9) then
        set_mario_action(m, ACT_AMY_HAMMER_SPIN, 0)
    end

    if m.action == ACT_HOLD_WALKING then
        m.action = e.walkAction
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

    if m.action == ACT_SIDE_FLIP or m.action == ACT_BACKFLIP then
        m.vel.y = m.vel.y + 10
    end

    if m.action == ACT_JUMP_KICK then
        m.action = ACT_SONIC_EAGLE
    end

    if m.action == ACT_CROUCH_SLIDE then
        m.action = ACT_AMY_CROUCH_SLIDE
    end

    if m.action == ACT_BREASTSTROKE 
    or m.action == ACT_FLUTTER_KICK
    or m.action == ACT_HOLD_BREASTSTROKE
    or m.action == ACT_HOLD_FLUTTER_KICK then
        m.action = ACT_AMY_SWIMMING
    end
	

    if m.action == ACT_GIANT_STEPS then
        e.animFrame = 0
        m.faceAngle.y = m.intendedYaw
        m.vel.y = 20
        if m.forwardVel < 100 then mario_set_forward_vel(m, m.forwardVel + 35) end
    end
	
    --if (m.action == ACT_PUNCHING and m.actionArg == 9) or m.action == ACT_SLIDE_KICK then

    local jumpActions = {
        [ACT_JUMP] = true,
        [ACT_DOUBLE_JUMP] = true,
        [ACT_HOLD_JUMP] = true,
        [ACT_STEEP_JUMP] = true
    }

    if jumpActions[m.action] then
        return do_sonic_jump(m)
    end

    if m.action == ACT_GROUND_POUND or m.action == ACT_BOUND_POUND then
        return set_mario_action(m, ACT_AMY_HAMMER_POUND, 0)
    end

    if m.action == ACT_AMY_HAMMER_HIT then
        amy_hammer_pound(m)
    end

    --if m.playerIndex == 0 then
    --    if mario_check_object_grab(m) ~= 0 then
    --        return true
    --    end
    --end

    if m.action == ACT_AMY_HAMMER_JUMP then
        set_mario_y_vel_based_on_fspeed(m, 80, 0.28)
        if (m.flags & MARIO_WING_CAP) ~= 0 then
            m.action = ACT_FLYING_TRIPLE_JUMP
        end
    end
end

hook_mario_action(ACT_AMY_IDLE, act_amy_idle)
hook_mario_action(ACT_AMY_SITTING_DOWN, act_amy_sitting_down)
hook_mario_action(ACT_AMY_JUMP, act_amy_jump)
hook_mario_action(ACT_AMY_WALKING, act_amy_walking)
hook_mario_action(ACT_AMY_SWIMMING, act_amy_swimming)

hook_mario_action(ACT_GIANT_STEPS, act_giant_steps)
hook_mario_action(ACT_AMY_FACE_PLANT, act_amy_face_plant, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_AMY_FACE_PLANT_SLIDE, act_amy_face_plant_slide, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_AMY_HAMMER_HIT, act_amy_hammer_hit)
hook_mario_action(ACT_AMY_HAMMER_ATTACK, act_amy_hammer_attack)
hook_mario_action(ACT_AMY_HAMMER_ATTACK_AIR, act_amy_hammer_attack_air, INT_KICK)
hook_mario_action(ACT_AMY_HAMMER_JUMP, act_amy_hammer_jump)
hook_mario_action(ACT_AMY_HAMMER_SPIN, act_amy_hammer_spin, INT_KICK)
hook_mario_action(ACT_AMY_HAMMER_SPIN_AIR, act_amy_hammer_spin_air, INT_KICK)
hook_mario_action(ACT_AMY_HAMMER_POUND, act_amy_hammer_pound, INT_KICK)
hook_mario_action(ACT_AMY_HAMMER_POUND_LAND, act_amy_hammer_pound_land, INT_GROUND_POUND_OR_TWIRL)

hook_mario_action(ACT_AMY_CROUCH_SLIDE, act_amy_crouch_slide)