/// obj_echo_missile :: Step

// 1) Self-destruct if traveled too far
if (abs(x - origin_x) >= max_dist) {
    instance_destroy();
    return;
}

// 2) Collision at point (1×1) against all objects
//    Proper seven-argument form: collision_rectangle(x1,y1,x2,y2,obj,precise,notme)
var hit = collision_rectangle(
    x - 0.5, y - 0.5,
    x + 0.5, y + 0.5,
    noone,
    true,
    true
);
if (hit != noone 
 && variable_instance_exists(hit, "is_destructible") 
 && hit.is_destructible)
{
    with (hit)      instance_destroy();
    instance_destroy();
}


// will destroy anything marked with is_destructible = true;
