ACT_SONIC_WATER_FALLING =
    allocate_mario_action(
    ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT
)
ACT_SONIC_WATER_STANDING =
    allocate_mario_action(
    ACT_GROUP_SUBMERGED | ACT_FLAG_IDLE | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT
)
ACT_SONIC_WATER_WALKING =
    allocate_mario_action(
    ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT
)
ACT_SONIC_WATER_SPINDASH =
    allocate_mario_action(
    ACT_GROUP_SUBMERGED | ACT_FLAG_SWIMMING | ACT_FLAG_ATTACKING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT
)
ACT_SONIC_WATER_ROLLING =
    allocate_mario_action(
    ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_SWIMMING | ACT_FLAG_ATTACKING | ACT_FLAG_SWIMMING_OR_FLYING |
        ACT_FLAG_WATER_OR_TEXT
)

function sonic_underwater_check_object_grab(m)
    if (m.marioObj.collidedObjInteractTypes & INTERACT_GRABBABLE) ~= 0 then
        local object = mario_get_collided_object(m, INTERACT_GRABBABLE)
        local dx = object.oPosX - m.pos.x
        local dz = object.oPosZ - m.pos.z
        local dAngleToObject = atan2s(dz, dx) - m.faceAngle.x
        if (dAngleToObject >= -0x2AAA and dAngleToObject <= 0x2AAA) then
            m.usedObj = object
            mario_grab_used_object(m)
            if (m.heldObj ~= nil) then
                m.marioBodyState.grabPos = GRAB_POS_LIGHT_OBJ
                if m.heldObj.behavior == get_behavior_from_id(id_bhvKoopaShellUnderwater) then
                    if (m.playerIndex == 0) then
                        play_shell_music()
                    end
                    set_mario_action(m, ACT_WATER_SHELL_SWIMMING, 0)
                else
                    set_mario_action(m, ACT_HOLD_WATER_ACTION_END, 1)
                end
                return true
            end
        end
    end
end

function sonic_underwater_switch_press(m)
    local switch = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvFloorSwitchGrills)
    if switch ~= nil and m.marioObj.platform == switch then
        if (lateral_dist_between_objects(switch, m.marioObj) < 127.5) then
            if switch.oAction == 0 then
                switch.oAction = 1
            end
        end
    end
end

function act_sonic_water_falling(m)
    move_with_current(m)
    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        m.health = m.health + 0x100
    end

    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x300, 0x300)
        mario_set_forward_vel(m, 20)
    else
        mario_set_forward_vel(m, 0)
    end
    if m.vel.y < -20 then
        m.vel.y = m.vel.y + 5
    end
    if m.actionArg == 0 then
        if m.heldObj ~= nil then
            set_mario_animation(m, MARIO_ANIM_FALL_WITH_LIGHT_OBJ)
        else
            set_mario_animation(m, MARIO_ANIM_GENERAL_FALL)
        end
    elseif m.actionArg == 1 then
        if m.heldObj ~= nil then
            set_mario_animation(m, MARIO_ANIM_FALL_WITH_LIGHT_OBJ)
        else
            set_mario_animation(m, MARIO_ANIM_FALL_FROM_WATER)
        end
    else
        if m.heldObj ~= nil then
            set_mario_animation(m, MARIO_ANIM_JUMP_WITH_LIGHT_OBJ)
        else
            set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)
        end
    end
    stepResult = perform_air_step(m, 0)
    if stepResult == AIR_STEP_LANDED then --hit floor or cancelled
        set_mario_action(m, ACT_SONIC_WATER_STANDING, 0)
    end
    if (m.input & INPUT_A_PRESSED) ~= 0 and m.actionTimer >= 1 and m.heldObj == nil then
        m.vel.y = 40
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 2)
    end

    if (m.pos.y >= m.waterLevel - 150) then
        set_mario_particle_flags(m, PARTICLE_IDLE_WATER_WAVE, false)
        if (m.input & INPUT_A_PRESSED) ~= 0 then
            m.pos.y = m.waterLevel
            set_mario_particle_flags(m, PARTICLE_WATER_SPLASH, false)
            if (m.playerIndex == 0) then set_camera_mode(m.area.camera, m.area.camera.defMode, 1) end
            return do_sonic_jump(m)
        end
    end
    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_sonic_water_standing(m)
    stationary_ground_step(m)
    move_with_current(m)
    sonic_underwater_switch_press(m)
    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        m.health = m.health + 0x100
    end

    if (m.input & INPUT_A_PRESSED) ~= 0 then
        m.vel.y = 40
        mario_set_forward_vel(m, 0)
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 2)
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        if m.heldObj ~= nil then
            mario_drop_held_object(m)
        else
            audio_sample_play(SOUND_SONIC_SPIN, m.pos, 1)
            return set_mario_action(m, ACT_SONIC_WATER_SPINDASH, 0)
        end
    end

    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
        return set_mario_action(m, ACT_SONIC_WATER_WALKING, 0)
    end

    if (m.input & INPUT_OFF_FLOOR) ~= 0 then
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 0)
    end

    if m.heldObj ~= nil then
        set_mario_animation(m, MARIO_ANIM_IDLE_WITH_LIGHT_OBJ)
    else
        if m.actionState == 0 then
            set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_LEFT)
        elseif m.actionState == 1 then
            set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_RIGHT)
        elseif m.actionState == 2 then
            set_mario_animation(m, MARIO_ANIM_IDLE_HEAD_CENTER)
        end
    end

    if is_anim_at_end(m) ~= 0 then
        if m.actionState >= 3 then
            m.actionState = 0
        else
            m.actionState = m.actionState + 1
        end
    end

    if (m.pos.y >= m.waterLevel - 150) then
        set_mario_particle_flags(m, PARTICLE_IDLE_WATER_WAVE, false)
    end

    return 0
end

function act_sonic_water_walking(m)
    local e = gMarioStateExtras[m.playerIndex]
    move_with_current(m)
    sonic_underwater_switch_press(m)
    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        m.health = m.health + 0x100
    end

    if (m.input & INPUT_FIRST_PERSON) ~= 0 then
        return set_mario_action(m, ACT_SONIC_WATER_STANDING, 0)
    end

    if (m.input & INPUT_A_PRESSED) ~= 0 then
        m.vel.y = 40
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 2)
    end

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        if m.heldObj ~= nil then
            mario_drop_held_object(m)
        else
            audio_sample_play(SOUND_SONIC_SPIN, m.pos, 1)
            set_mario_action(m, ACT_SONIC_WATER_SPINDASH, 0)
        end
    end

    if (m.input & INPUT_ZERO_MOVEMENT) ~= 0 then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 5, 5))
        if math.abs(m.forwardVel) < 2 then
            return set_mario_action(m, ACT_SONIC_WATER_STANDING, 0)
        end
    end

    update_walking_speed(m)
    local stepResult = perform_ground_step(m)

    if stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_SONIC_WATER_FALLING, 1)
    elseif stepResult == GROUND_STEP_NONE then
        if m.heldObj ~= nil then
            anim_and_audio_for_hold_walk(m)
        else
            sonic_anim_and_audio_for_walk(m)
        end
        mario_set_forward_vel(m, m.forwardVel)
    elseif stepResult == GROUND_STEP_HIT_WALL then
        push_or_sidle_wall(m, m.pos)
        m.actionTimer = 0
    end

    return 0
end

function act_water_roll(m)
    local e = gMarioStateExtras[m.playerIndex]
    move_with_current(m)
    sonic_underwater_switch_press(m)
    if m.actionTimer == 0 then
        e.rotAngle = 0x000
    end
    if (m.input & INPUT_A_PRESSED) ~= 0 then
        m.vel.y = 40
        mario_set_forward_vel(m, m.forwardVel)
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 2)
    end

    if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
        set_mario_action(m, ACT_SONIC_WATER_WALKING, 0)
    end

    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)

    local stepResult = perform_ground_step(m)
    if stepResult == GROUND_STEP_NONE then
        if mario_floor_is_slope(m) ~= 0 or mario_floor_is_steep(m) ~= 0 then
            apply_slope_accel(m)
        else
            mario_set_forward_vel(m, m.forwardVel - 1)
        end
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)
    elseif stepResult == GROUND_STEP_HIT_WALL then
        mario_set_forward_vel(m, -16.0)

        m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
        return set_mario_action(m, ACT_GROUND_BONK, 0)
    elseif stepResult == GROUND_STEP_LEFT_GROUND then
        m.vel.y = 0
        set_mario_action(m, ACT_SONIC_WATER_FALLING, 2)
    end

    if m.playerIndex == 0 then
        sonic_underwater_check_object_grab(m)
    end

    if math.abs(m.forwardVel) < 10 then
        set_mario_action(m, ACT_SONIC_WATER_WALKING, 0)
    end
    e.rotAngle = e.rotAngle + (0x50 * m.forwardVel)
    if e.rotAngle > 0x9000 then
        e.rotAngle = e.rotAngle - 0x9000
    end
    set_anim_to_frame(m, 10 * e.rotAngle / 0x9000)

    m.actionTimer = m.actionTimer + 1

    return 0
end

function act_water_spindash(m)
    local e = gMarioStateExtras[m.playerIndex]
    local MAXDASH = 12
    local MINDASH = 5

    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        m.health = m.health + 0x100
    end
    -- Spindash revving
    e.dashspeed = e.dashspeed + 0.5
    if m.actionTimer == 0 then
        e.dashspeed = 0
    end
    if e.dashspeed < MINDASH then
        e.dashspeed = MINDASH
    elseif e.dashspeed > MAXDASH then
        e.dashspeed = MAXDASH
        m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    end
    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)
    set_anim_to_frame(m, e.animFrame)
    if e.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd then
        e.animFrame = e.animFrame - m.marioObj.header.gfx.animInfo.curAnim.loopEnd
    end
    if (m.controller.buttonDown & B_BUTTON) == 0 then
        mario_set_forward_vel(m, e.dashspeed * 5)
        audio_sample_play(SOUND_SONIC_DASH, m.pos, 1)
        audio_sample_stop(SOUND_SONIC_SPIN)
        return set_mario_action(m, ACT_SONIC_WATER_ROLLING, 0)
    end
    if (m.controller.buttonDown & A_BUTTON) ~= 0 then
        m.vel.y = 40
        mario_set_forward_vel(m, 0)
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 2)
    end

    if m.playerIndex == 0 then
        sonic_underwater_check_object_grab(m)
    end
    sonic_underwater_switch_press(m)
    m.particleFlags = m.particleFlags | PARTICLE_DUST
    e.animFrame = e.animFrame + (e.dashspeed / 4)
    m.actionTimer = m.actionTimer + 1
    local stepResult = perform_air_step(m, 0)
    if stepResult == GROUND_STEP_LEFT_GROUND then
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 1)
    end

    m.forwardVel = approach_f32(m.forwardVel, 0.0, 1, 1)
    m.faceAngle.y = m.intendedYaw
    m.marioObj.header.gfx.angle.y = m.intendedYaw
    m.actionTimer = m.actionTimer + 1
    return 0
end

hook_mario_action(ACT_SONIC_WATER_FALLING, act_sonic_water_falling)
hook_mario_action(ACT_SONIC_WATER_STANDING, act_sonic_water_standing)
hook_mario_action(ACT_SONIC_WATER_WALKING, act_sonic_water_walking)
hook_mario_action(ACT_SONIC_WATER_SPINDASH, act_water_spindash)
hook_mario_action(ACT_SONIC_WATER_ROLLING, act_water_roll)
