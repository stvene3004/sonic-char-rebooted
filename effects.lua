
define_custom_obj_fields({
    oScale = 'f32',
    oParticleEmitter = 'f32',
})
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
id_bhvSpinDust = hook_behavior(nil, OBJ_LIST_DEFAULT, true, spindust_init, spindust_loop)