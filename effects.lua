gItemHeld = {}

E_MODEL_PIKO_PIKO_HAMMER = smlua_model_util_get_id("piko_piko_hammer_geo")
E_MODEL_ROSY_HEART = smlua_model_util_get_id("rosy_heart_geo")

-- setup held items
for i = 0, (MAX_PLAYERS - 1) do
    gItemHeld[i] = nil
end

------------

define_custom_obj_fields({
    oPikoOwner = 'u32',
    oScale = 'f32',
    oParticleEmitter = 'f32',
    oLifetime = 'f32',
})

function bhv_piko_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj.oOpacity = 255
    obj.hookRender = 1
    obj_scale(obj, 1)
    obj.hitboxRadius = 100
    obj.hitboxHeight = 100
    obj.oIntangibleTimer = 0
    cur_obj_hide()
end

function bhv_piko_loop(obj)
    local m = gMarioStates[obj.oPikoOwner]
    local s = gPlayerSyncTable[obj.oPikoOwner]
    local e = gMarioStateExtras[obj.oPikoOwner]

    -- check if this should be inactive
    --if not active_player(m) then
    --    cur_obj_hide()
    --    return
    -- end

    -- if the player is off screen, hide the obj
    if m.marioBodyState.updateTorsoTime ~= gMarioStates[0].marioBodyState.updateTorsoTime then
        cur_obj_hide()
        return
    end

    -- update pallet
    local np = gNetworkPlayers[obj.oPikoOwner]
    if np ~= nil then
        obj.globalPlayerIndex = np.globalIndex
    end

    -- check if this should be activated
    if obj_is_hidden(obj) ~= 0 then
        cur_obj_unhide()
        obj_set_model_extended(obj, E_MODEL_PIKO_PIKO_HAMMER)
        obj_scale(obj, 1)
        obj.oAnimState = 0
        obj.header.gfx.node.flags = obj.header.gfx.node.flags & ~GRAPH_RENDER_BILLBOARD
        obj.oAnimations = nil
    end

    if m.action == ACT_AMY_HAMMER_ATTACK_AIR and (m.actionArg == 1 or m.actionArg == 0 or (m.actionArg == 2 and e.animFrame < 6))
	or m.action == ACT_AMY_HAMMER_ATTACK 
	or m.action == ACT_AMY_HAMMER_HIT 
	or m.action == ACT_AMY_HAMMER_SPIN
	or m.action == ACT_AMY_HAMMER_SPIN_AIR
	or m.action == ACT_AMY_HAMMER_POUND
	or m.action == ACT_AMY_HAMMER_POUND_LAND then
        cur_obj_unhide()
    else
        cur_obj_hide()
    end
end

function spindust_init(o)
    o.oFlags =  (OBJ_FLAG_SET_FACE_YAW_TO_MOVE_YAW | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE)
    o.oAnimState = 1
	o.oScale = 1
	cur_obj_scale(o.oScale)
    o.oFriction = 10.0
	o.oVelY = 0
end

function spindust_loop(o)
	obj_set_billboard(o)
	cur_obj_update_floor_and_walls()
    cur_obj_move_standard(-78)

    if o.oScale > 7 then
	    obj_mark_for_deletion(o)
	end
	cur_obj_scale(o.oScale)
	o.oTimer = o.oTimer + 1
	o.oAnimState = math.floor(o.oScale)
	o.oForwardVel = -20
	o.oScale = o.oScale + 0.2
end

function rosy_heart_init(o)
    o.oFlags =  (OBJ_FLAG_SET_FACE_YAW_TO_MOVE_YAW | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE)
	cur_obj_scale(1)
    o.activeFlags = o.activeFlags | ACTIVE_FLAG_UNK9
	o.oAnimState = 0
    o.hitboxDownOffset        = 20
    o.oDamageOrCoinValue = 0
    o.oHealth            = 0
    o.oNumLootCoins      = 1
    o.oNumLootCoins      = 1
    obj_set_billboard(o)
end

function rosy_heart_loop(o)
    local vel = math.random(-15, 15)
    if o.oLifetime == 0 then o.oLifetime = 30 end
    if o.oAnimState > 7 then
	    o.oAnimState = 0
	end
	if o.oTimer > o.oLifetime and o.oAnimState == 1 then
        obj_mark_for_deletion(o)
	end
	if (o.oTimer) % 5 == 0 then
	    vel = math.random(-15, 15)
	    
	end
	
	object_step()
	o.oForwardVel = approach_f32(o.oForwardVel, vel, 3, 3)
	o.oVelY = 10
	o.oAnimState = o.oAnimState + 1
	o.oTimer = o.oTimer + 1
end

id_bhvRosyHeart = hook_behavior(nil, OBJ_LIST_DEFAULT, true, rosy_heart_init, rosy_heart_loop)
id_bhvSpinDust = hook_behavior(nil, OBJ_LIST_DEFAULT, true, spindust_init, spindust_loop)
id_bhvPikoPikoHammer = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_piko_init, bhv_piko_loop)

------------

function on_sync_valid()
    -- initialize all held items
    for i = 0, (MAX_PLAYERS - 1) do
        gItemHeld[i] = spawn_non_sync_object(id_bhvPikoPikoHammer, E_MODEL_PIKO_PIKO_HAMMER, 0, 0, 0,
        function(obj)
            obj.oPikoOwner = i
        end)
    end
end

function dot_along_angle(obj, m, angle)
    local v1 = {
        x = obj.oPosX - m.pos.x,
        y = obj.oPosY - m.pos.y,
        z = obj.oPosZ - m.pos.z,
    }
    vec3f_normalize(v1)
    local v2 = {
        x = sins(m.faceAngle.y + angle),
        y = 0,
        z = coss(m.faceAngle.y + angle),
    }
    return vec3f_dot(v1, v2)
end

function bhv_piko_piko_hammer_render(obj)
    local m = gMarioStates[obj.oPikoOwner]
    local e = gMarioStateExtras[obj.oPikoOwner]
    local animFrame = m.marioObj.header.gfx.animInfo.animFrame

    if m.action == ACT_AMY_HAMMER_ATTACK_AIR then
	    if m.actionArg == 1 then
            obj.oFaceAnglePitch = e.rotAngle + 0x9000
            obj.oFaceAngleRoll = 0
		elseif m.actionArg == 0 then
		    local pitch = 0x000
		    if e.animFrame == 0 then
                pitch = 0x4500
			elseif e.animFrame == 0 then
                pitch = -0x3500
			else
                pitch = -0x5000
			end
			
			obj.oFaceAnglePitch = approach_s32(obj.oFaceAnglePitch, pitch, 0x2800, 0x2800)
		end
    elseif m.action == ACT_AMY_HAMMER_ATTACK then
        local scalar = dot_along_angle(obj, m, 0) * 1.5
        if scalar > 0.723 then scalar = 0.723 end
        obj.oFaceAnglePitch = 0x5000 * scalar + 0x500
        obj.oFaceAngleRoll = 0x1000 * dot_along_angle(obj, m, -0x8000)
		e.rotAngle = obj.oFaceAnglePitch
    elseif m.action == ACT_AMY_HAMMER_POUND or m.action == ACT_AMY_HAMMER_POUND_LAND 
	or (m.action == ACT_AMY_HAMMER_HIT and m.actionArg == 1) then
        obj.oFaceAnglePitch = 0x4000
    elseif m.action == ACT_AMY_HAMMER_SPIN or m.action == ACT_AMY_HAMMER_SPIN_AIR then
        obj.oFaceAnglePitch = 0x4000
        obj.oAnimState = 1
    end
end

function on_object_render(obj)
    if get_id_from_behavior(obj.behavior) ~= id_bhvPikoPikoHammer then
        return
    end

    local m = gMarioStates[obj.oPikoOwner]

    --if not active_player(m) then
    --    return
    --end

    obj.oFaceAngleYaw = m.marioObj.header.gfx.angle.y + 0
    obj.oFaceAnglePitch = 0x1000
    obj.oFaceAngleRoll = 0

    obj.oPosX = get_hand_foot_pos_x(m, 1)
    obj.oPosY = get_hand_foot_pos_y(m, 1)
    obj.oPosZ = get_hand_foot_pos_z(m, 1)

    bhv_piko_piko_hammer_render(obj)

    -- if the player is off screen, move the obj to the player origin
    if m.marioBodyState.updateTorsoTime ~= gMarioStates[0].marioBodyState.updateTorsoTime then
        obj.oPosX = m.pos.x
        obj.oPosY = m.pos.y
        obj.oPosZ = m.pos.z
    end

    obj.oPosX = obj.oPosX + sins(m.faceAngle.y) * 10
    obj.oPosZ = obj.oPosZ + coss(m.faceAngle.y) * 10

    obj.header.gfx.pos.x = obj.oPosX
    obj.header.gfx.pos.y = obj.oPosY
    obj.header.gfx.pos.z = obj.oPosZ
end

hook_event(HOOK_ON_OBJECT_RENDER, on_object_render)
hook_event(HOOK_ON_SYNC_VALID, on_sync_valid)