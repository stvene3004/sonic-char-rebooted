-- File that handles Sonic's stuff.

-- The moves. (There's a whole buncha them.)
ACT_SONIC_IDLE =
allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_IDLE | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_SONIC_LYING_DOWN =
allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT)
ACT_SONIC_WALKING = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING)
ACT_SONIC_JUMP =
allocate_mario_action(
ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_AIR | ACT_FLAG_CONTROL_JUMP_HEIGHT |
ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_SHORT_HITBOX)
ACT_SONIC_HOLD_JUMP =
allocate_mario_action(
ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR | ACT_FLAG_CONTROL_JUMP_HEIGHT)

ACT_SPINDASH =
allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_ATTACKING | ACT_FLAG_INVULNERABLE | ACT_FLAG_SHORT_HITBOX)
ACT_SONIC_ROLL =
allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_BUTT_OR_STOMACH_SLIDE | ACT_FLAG_SHORT_HITBOX)
ACT_SONIC_FREEFALL =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_SONIC_EAGLE =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_SONIC_WINDMILL_KICK =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_DROPDASH =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_SHORT_HITBOX)
ACT_AIRDASH = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_SHORT_HITBOX)
ACT_BOUND_JUMP =
allocate_mario_action(
ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_AIR |
ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_SHORT_HITBOX)
ACT_BOUND_POUND =
allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_BOUND_POUND_LAND =
allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)

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
        set_mario_action(m, e.walkAction, 0)
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
            sonic_apply_slope_accel(m)
        else
            mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, 1, 1))
        end
        
        if m.forwardVel < 0 then
            m.faceAngle.y = atan2s(m.vel.z, m.vel.x)
            mario_set_forward_vel(m, math.abs(m.forwardVel))
        end

        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)
    elseif stepResult == GROUND_STEP_HIT_WALL then
        if m.forwardVel > 70 then
            mario_set_forward_vel(m, -16.0)

            m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
            return set_mario_action(m, ACT_GROUND_BONK, 0)
        else
            return set_mario_action(m, ACT_SONIC_IDLE, 0)
        end
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
    align_with_floor_but_better(m)

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
        m.heldObj.oForwardVel = 0
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
        m.particleFlags = m.particleFlags | PARTICLE_DUST | PARTICLE_MIST_CIRCLE
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

    local stepResult = perform_air_step(m, 0)

    if stepResult == AIR_STEP_HIT_WALL then
        mario_set_forward_vel(m, -16.0)
        m.vel.y = 40

        m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
        set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
    elseif stepResult == AIR_STEP_LANDED then
        set_mario_action(m, ACT_SONIC_WALKING, 0)
    end

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
            sonic_gen_anim_and_audio_for_walk(m, 20, 48)
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

    sonic_update_air(m)

    if stepResult == AIR_STEP_LANDED then
        m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE | PARTICLE_HORIZONTAL_STAR
        play_sound(SOUND_GENERAL_SHORT_POUND3, m.marioObj.header.gfx.cameraToObject)
        m.squishTimer = 5
        set_mario_action(m, ACT_BOUND_POUND_LAND, 1)
    end
    m.peakHeight = m.pos.y
    m.actionTimer = m.actionTimer + 1

    return 0
end

function act_bound_pound_land(m)
    local e = gMarioStateExtras[m.playerIndex]
    
    set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)
    set_anim_to_frame(m, e.animFrame)
    e.animFrame = e.animFrame + 2
    
    local stepResult = perform_ground_step(m)
    
    if stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_BOUND_POUND, 0)
    end
    
    -- A debuff so that players can't just bounce up slides.
    if (m.input & INPUT_ABOVE_SLIDE) ~= 0 then
        return set_mario_action(m, ACT_BUTT_SLIDE, 0)
    end
    
    if (m.input & INPUT_UNKNOWN_10) ~= 0 then
        return drop_and_set_mario_action(m, ACT_SHOCKWAVE_BOUNCE, 0)
    end
        
    set_mario_action(m, ACT_BOUND_JUMP, 1)
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
        --if is_anim_past_frame(m, 20) ~= 0 then
        --    if m.actionTimer > math.random(40, 50) * 30 then
        --        e.animFrame = 8
        --        m.actionState = 2
        --    end
        --end
    elseif m.actionState == 1 then
        --stop_custom_character_sound(m, CHAR_SOUND_SNORING1)
        --stop_custom_character_sound(m, CHAR_SOUND_SNORING2)

        set_mario_animation(m, MARIO_ANIM_WAKE_FROM_LYING)
        smlua_anim_util_set_animation(m.marioObj, "SONIC_IMPATIENT2_END")        
        if (is_anim_past_frame(m, 9) ~= 0 and (m.input & INPUT_NONZERO_ANALOG) ~= 0)
        or is_anim_past_end(m) ~= 0 then
            set_mario_action(m, ACT_SONIC_IDLE, 0)
        end
    elseif m.actionState == 2 then
        m.marioBodyState.eyeState = 16
        set_mario_animation(m, MARIO_ANIM_SLEEP_LYING)
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SLEEPING")

        set_anim_to_frame(m, e.animFrame)
        
        if (e.animFrame == 2) then
            play_character_sound(m, CHAR_SOUND_SNORING2)
        end

        if (e.animFrame == 25) then
            play_character_sound(m, CHAR_SOUND_SNORING1)
        end
        
        e.animFrame = e.animFrame + 1
        if e.animFrame >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd then
            e.animFrame = 0
        end
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end

function act_sonic_eagle(m)
    local e = gMarioStateExtras[m.playerIndex]
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

	if m.forwardVel < 0 and analog_stick_held_back(m) ~= 0 then
        m.faceAngle.y = atan2s(m.vel.z, m.vel.x)
        mario_set_forward_vel(m, math.abs(m.forwardVel))
    end

    if m.faceAngle.y ~= m.intendedYaw and m.forwardVel > 32 then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, m.forwardVel/16, m.forwardVel/16))
    else
        mario_set_forward_vel(m, m.forwardVel)
    end

    local stepResult =  perform_air_step(m, 0)

    if stepResult == AIR_STEP_LANDED then
        if check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB) == 0 then
            if m.forwardVel ~= 0 then
                set_mario_action(m, e.walkAction, 0)
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

function act_sonic_windmill_kick(m)
    local e = gMarioStateExtras[m.playerIndex]
    if m.actionTimer == 0 then
        play_character_sound_if_no_flag(m, CHAR_SOUND_PUNCH_HOO, MARIO_ACTION_SOUND_PLAYED)
        e.rotAngle = m.faceAngle.y
    end
    
    m.marioBodyState.eyeState = MARIO_EYES_LOOK_RIGHT
    
    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end
    
    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
        mario_set_forward_vel(m, math.abs(m.forwardVel))
    end
    
    if math.abs(m.forwardVel) >= 10 then
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x600, 0x600)
    else
        m.faceAngle.y = m.intendedYaw
    end
        
    if m.faceAngle.y ~= m.intendedYaw and m.forwardVel > 32 then
        mario_set_forward_vel(m, approach_f32(m.forwardVel, 0, m.forwardVel/16, m.forwardVel/16))
    else
        mario_set_forward_vel(m, m.forwardVel)
    end

    local stepResult = perform_air_step(m, 0)
    sonic_update_air(m)

    set_mario_animation(m, MARIO_ANIM_SLIDE_KICK)
    smlua_anim_util_set_animation(m.marioObj, "SONIC_WINDMILL_KICK")
    
    if stepResult == AIR_STEP_HIT_WALL and m.wall ~= nil then
        m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
        play_sound(SOUND_ACTION_BOUNCE_OFF_OBJECT, m.marioObj.header.gfx.cameraToObject)
        cur_obj_shake_screen(SHAKE_POS_SMALL)
        wall_bounce(m)
        if m.forwardVel < 5 then
            mario_set_forward_vel(m, 5)
        else
            mario_set_forward_vel(m, math.abs(m.forwardVel))
        end
    elseif stepResult == AIR_STEP_LANDED then
        if m.vel.x ~= 0 or m.vel.z ~= 0 then
            m.faceAngle.y = atan2s(m.vel.z, m.vel.x)
        end
        if (check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB) == 0) then
            if m.forwardVel ~= 0 then
                set_mario_action(m, e.walkAction, 0)
            else
                set_mario_action(m, ACT_FREEFALL_LAND, 0)
            end
        end
    end
    
    e.rotAngle = e.rotAngle + 0x3000
    m.marioObj.header.gfx.angle.y = e.rotAngle
    if (e.rotAngle) % 0x7 == 0 then
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end
    --m.flags = m.flags | MARIO_KICKING
    
    m.actionTimer = m.actionTimer + 1
    return 0
end

-- Hooks.

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
        m.action = e.walkAction
    end

    if m.action == ACT_SLIDE_KICK then
        set_mario_action(m, ACT_SONIC_WINDMILL_KICK, 0)
    end

    if m.action == ACT_SONIC_WINDMILL_KICK then
        m.vel.y = 25
        if m.forwardVel < 50 then mario_set_forward_vel(m, 50) end
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
    
    if m.action == ACT_BOUND_JUMP then
        m.vel.y = 65.0
    end

    local jumpActions = {
        [ACT_JUMP] = true,
        [ACT_DOUBLE_JUMP] = true,
        [ACT_LONG_JUMP] = true,
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

function sonic_update(m)
    local e = gMarioStateExtras[m.playerIndex]

    sonic_walking_door_check(m)
    sonic_check_wall_kick(m)
    
    -- Stats.
    e.walkAction = ACT_SONIC_WALKING
    e.movingSpeed = 64.0
    e.movingSpeedSlow = 48.0
    e.jumpHeight = 40
    e.jumpHeightMultiplier = 0.2

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

    if m.action == ACT_TURNING_AROUND then
        apply_slope_decel(m, 6)
    end
    
    if m.action ~= ACT_GROUND_POUND_LAND then
        e.lastforwardVel = m.forwardVel
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
        smlua_anim_util_set_animation(m.marioObj, "SONIC_STAR_DANCE")
        if m.marioObj.header.gfx.animInfo.animFrame < 18 then
            m.marioBodyState.eyeState = 12
        elseif m.marioObj.header.gfx.animInfo.animFrame < 46 then
            m.marioBodyState.eyeState = 11
        else
            m.marioBodyState.eyeState = 9
        end
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_SKID_ON_GROUND then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SKID")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_STOP_SKID then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SKID_STOP")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_TURNING_PART1 then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SKID")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_TURNING_PART2 then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_SKID_TURN")
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_RUNNING_UNUSED then
        smlua_anim_util_set_animation(m.marioObj, "SONIC_RUNNING")
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
            m.marioBodyState.eyeState = 8
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
        m.marioBodyState.eyeState = 8
    end

    if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_TAKE_CAP_OFF_THEN_ON then
        m.marioBodyState.handState = MARIO_HAND_FISTS
        smlua_anim_util_set_animation(m.marioObj, "SONIC_EXIT_LEVEL")
        m.marioBodyState.capState = 0
    end

    if e.modelState == 2 then
        if (m.flags & MARIO_METAL_CAP) == 0 then
            m.marioBodyState.capState = 1
        else
            m.marioBodyState.capState = 3
        end
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
        
    local waterActions = {
        [ACT_WATER_PLUNGE] = true,
        [ACT_WATER_IDLE] = true,
        [ACT_FLUTTER_KICK] = true,
        [ACT_SWIMMING_END] = true,
        [ACT_WATER_ACTION_END] = true,
        [ACT_HOLD_WATER_IDLE] = true,
        [ACT_HOLD_WATER_JUMP] = true,
        [ACT_HOLD_WATER_ACTION_END] = true,
        [ACT_BREASTSTROKE] = true
    }

    if waterActions[m.action] then
        if m.vel.y <= -25 then
            set_mario_particle_flags(m, PARTICLE_WATER_SPLASH, false)
        end
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 0)
    end

    if m.action == ACT_SONIC_WATER_FALLING and (m.controller.buttonDown & Z_TRIG) ~= 0 then
        m.vel.y = -50.0
        set_mario_particle_flags(m, PARTICLE_PLUNGE_BUBBLE, false)
        m.marioObj.header.gfx.scale.y = 1.5
        m.marioObj.header.gfx.scale.z = 0.7
        m.marioObj.header.gfx.scale.x = 0.7
        return set_mario_action(m, ACT_SONIC_WATER_FALLING, 2)
    end

    anti_faster_swimming(m)
    visual_updates(m)
    return 0
end

hook_mario_action(ACT_SPINDASH, act_spindash)
hook_mario_action(ACT_SONIC_ROLL, act_sonic_roll, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_SONIC_JUMP, act_sonic_jump)
hook_mario_action(ACT_SONIC_HOLD_JUMP, act_sonic_hold_jump)
hook_mario_action(ACT_SONIC_IDLE, act_sonic_idle)
hook_mario_action(ACT_SONIC_LYING_DOWN, act_sonic_lying_down)
hook_mario_action(ACT_SONIC_EAGLE, act_sonic_eagle)
hook_mario_action(ACT_SONIC_WINDMILL_KICK, act_sonic_windmill_kick, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_SONIC_FREEFALL, act_sonic_freefall)
hook_mario_action(ACT_DROPDASH, act_dropdash, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_AIRDASH, act_airdash, INT_FAST_ATTACK_OR_SHELL)
hook_mario_action(ACT_SONIC_WALKING, act_sonic_walking)
hook_mario_action(ACT_BOUND_POUND, act_bound_pound)
hook_mario_action(ACT_BOUND_POUND_LAND, act_bound_pound_land, INT_GROUND_POUND_OR_TWIRL)
hook_mario_action(ACT_BOUND_JUMP, act_bound_jump)