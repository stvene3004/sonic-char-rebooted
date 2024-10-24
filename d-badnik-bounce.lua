local bounceTypes = {
    [INTERACT_BOUNCE_TOP] = 1,
    [INTERACT_BOUNCE_TOP2] = 1,
    [INTERACT_KOOPA] = 1
}

local prevVelY
local prevHeight

function bb_update(m)
    if (m.action & ACT_FLAG_AIR) ~= 0 and m.action ~= ACT_GROUND_POUND then
        if m.vel.y >= 0 then
            prevHeight = m.pos.y
        end
    end
     
end

function bb_allow_interact(m, o, interactType)
    if bounceTypes[interactType] then
        prevVelY = m.vel.y
    end

    if bounceTypes[interactType] and (o.oInteractionSubtype & INT_SUBTYPE_TWIRL_BOUNCE) == 0 then
        if prevVelY < 0 and m.pos.y > o.oPosY then
            if m.action == ACT_AMY_HAMMER_ATTACK_AIR then
                o.oInteractStatus = ATTACK_FROM_ABOVE + (INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED)
                set_camera_shake_from_hit(SHAKE_ATTACK)
                m.particleFlags = m.particleFlags | PARTICLE_HORIZONTAL_STAR
                play_sound(SOUND_ACTION_HIT_2, m.marioObj.header.gfx.cameraToObject)
                badnik_bounce(m, prevHeight, true, 10)

                return false
            end
        end
    end

    --player_bounce(m, o, interactType)
end

-- Player bouncing, temporarily unused.
function player_bounce(m, o, interactType)
    local regularBounceActions = {
        [ACT_SONIC_JUMP] = true,
        [ACT_DROPDASH] = true,
        [ACT_SONIC_FREEFALL] = true,
        [ACT_AMY_JUMP] = true,
        [ACT_AMY_HAMMER_ATTACK_AIR] = true,
        [ACT_AMY_HAMMER_SPIN_AIR] = true
    }
    
    local marioBounceActions = {
        [ACT_JUMP] = true,
        [ACT_DOUBLE_JUMP] = true,
        [ACT_TRIPLE_JUMP] = true,
        [ACT_LONG_JUMP] = true,
        [ACT_SIDE_FLIP] = true,
        [ACT_BACKFLIP] = true,
        [ACT_WALL_KICK_AIR] = true,
        [ACT_FREEFALL] = true
    }
  
    -- Bounce interaction with players.
    local m2 = nearest_mario_state_to_object(m.marioObj)
    
    if m2 ~= nil and o == m2.marioObj then 
        local m2interaction = determine_interaction(m, m2.marioObj)
        if gServerSettings.playerInteractions ~= PLAYER_INTERACTIONS_NONE and (m2interaction & INT_HIT_FROM_ABOVE) ~= 0 then

            if regularBounceActions[m.action] then
                badnik_bounce(m, prevHeight, true)
                return false

            elseif marioBounceActions[m.action] and current_sonic_char(m) ~= 0 then
                m.action = ACT_SONIC_FREEFALL
                badnik_bounce(m, prevHeight, true)
                return false

            elseif m.action == ACT_BOUND_POUND then
                set_mario_action(m, ACT_BOUND_JUMP, 0)
                badnik_bounce(m, prevHeight, true)
                return false

            elseif m.action == ACT_BOUND_JUMP then
                m.action = ACT_SONIC_JUMP
                badnik_bounce(m, prevHeight, true)
                return false

            end
        end
    end
end

function badnik_bounce(m, prevHeightInput, noHoldA, additionalVel)
    local targetVel = math.sqrt(8 * math.abs(prevHeightInput - m.pos.y))
    local trueTargetVel = 0
            
    if targetVel ^ 2 > m.vel.y ^ 2 then
        trueTargetVel = targetVel
    else
        trueTargetVel = math.abs(m.vel.y)
    end
            
    if (m.action & ACT_FLAG_AIR) ~= 0 then
        if noHoldA == true then
            m.vel.y = trueTargetVel * 0.9
        else
            if (m.controller.buttonDown & A_BUTTON) ~= 0 then
                m.vel.y = trueTargetVel * 1.05
            else
                m.vel.y = trueTargetVel * 0.8
            end
        end
    end

    if additionalVel ~= nil then m.vel.y = m.vel.y + additionalVel end
end

function bb_on_interact(m, o, interactType, interactValue)
    if not bounceTypes[interactType] then return end
    local regularBounceActions = {
        [ACT_SONIC_JUMP] = true,
        [ACT_DROPDASH] = true,
        [ACT_SONIC_FREEFALL] = true,
        [ACT_AMY_JUMP] = true,
        [ACT_AMY_HAMMER_SPIN_AIR] = true
    }
    
    local marioBounceActions = {
        [ACT_JUMP] = true,
        [ACT_DOUBLE_JUMP] = true,
        [ACT_TRIPLE_JUMP] = true,
        [ACT_LONG_JUMP] = true,
        [ACT_SIDE_FLIP] = true,
        [ACT_BACKFLIP] = true,
        [ACT_WALL_KICK_AIR] = true,
        [ACT_FREEFALL] = true
    }
    

    if (o.oInteractionSubtype & INT_SUBTYPE_TWIRL_BOUNCE) == 0 then
        if prevVelY < 0 and m.pos.y > o.oPosY then
            
            if regularBounceActions[m.action] then
                o.oInteractStatus = ATTACK_FROM_ABOVE + (INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED)
                badnik_bounce(m, prevHeight)
            elseif marioBounceActions[m.action] and current_sonic_char(m) ~= 0 then
                o.oInteractStatus = ATTACK_FROM_ABOVE + (INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED)
                m.action = ACT_SONIC_FREEFALL
                badnik_bounce(m, prevHeight)
            elseif m.action == ACT_BOUND_POUND then
                set_mario_action(m, ACT_BOUND_JUMP, 0)
                badnik_bounce(m, prevHeight, true, 10)
            elseif m.action == ACT_BOUND_JUMP then
                m.action = ACT_SONIC_JUMP
                badnik_bounce(m, prevHeight)
            end
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, bb_update)
hook_event(HOOK_ON_INTERACT, bb_on_interact)
hook_event(HOOK_ALLOW_INTERACT, bb_allow_interact)