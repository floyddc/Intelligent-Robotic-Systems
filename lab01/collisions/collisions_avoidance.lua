-- Put your global variables here

MOVE_STEPS = 15
MAX_VELOCITY = 10
LIGHT_THRESHOLD = 1.5
PROX_THRESHOLD = 0.3 -- consider obstacle when proximity reading > this

n_steps = 0


--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
    left_v = 0.5 * MAX_VELOCITY
    right_v = 0.5 * MAX_VELOCITY
    robot.wheels.set_velocity(left_v,right_v)
    n_steps = 0
    if robot.leds then robot.leds.set_all_colors("black") end
end



--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
    n_steps = n_steps + 1

    -- default forward motion (reduced if obstacle near)
    local sum_left, sum_right, max_prox = prox_sides()
    local forward = MAX_VELOCITY
    if max_prox > 0 then
        forward = MAX_VELOCITY * (1 - math.min(max_prox,1))
    end

    -- obstacle avoidance: turn away from side with higher reading
    if max_prox > PROX_THRESHOLD then
        if sum_left > sum_right then
            -- obstacle on left -> turn right
            left_v = forward
            right_v = -0.6 * forward
        else
            -- obstacle on right -> turn left
            left_v = -0.6 * forward
            right_v = forward
        end
    else
        -- straight or small random walk
        if n_steps % MOVE_STEPS == 0 then
            left_v = robot.random.uniform(0.5*MAX_VELOCITY, MAX_VELOCITY)
            right_v = robot.random.uniform(0.5*MAX_VELOCITY, MAX_VELOCITY)
        end
    end

    robot.wheels.set_velocity(left_v, right_v)

    -- ground (spot) detection and light handling (same logic as before)
    local ground = robot.motor_ground
    local spot = false
    for i=1,4 do
        if ground[i].value == 0 then spot = true; break end
    end

    local light = false
    local sum_light = 0
    for i=1,#robot.light do sum_light = sum_light + robot.light[i].value end
    if sum_light > LIGHT_THRESHOLD then light = true end

    if robot.leds then
        if spot then
            robot.leds.set_all_colors("red")
        elseif light then
            robot.leds.set_all_colors("yellow")
        else
            robot.leds.set_all_colors("black")
        end
    end
end

function prox_sides()
    local n = #robot.proximity
    local half = math.floor(n/2)
    local sum_left, sum_right, max_v = 0,0,0
    for i=1,n do
        local v = robot.proximity[i].value
        if i <= half then sum_left = sum_left + v else sum_right = sum_right + v end
        if v > max_v then max_v = v end
    end
    return sum_left, sum_right, max_v
end



--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
    left_v = robot.random.uniform(0.5*MAX_VELOCITY, MAX_VELOCITY)
    right_v = robot.random.uniform(0.5*MAX_VELOCITY, MAX_VELOCITY)
    robot.wheels.set_velocity(left_v,right_v)
    n_steps = 0
    if robot.leds then robot.leds.set_all_colors("black") end
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
