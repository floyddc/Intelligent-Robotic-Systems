-- Simple phototaxis: go towards the light using foot-bot light sensors

MAX_VELOCITY = 80
BASE_SPEED = 0.5        -- fraction of MAX_VELOCITY used as forward speed
TURN_GAIN = 0.8         -- steering gain
LIGHT_THRESHOLD = 0.01  -- small threshold to avoid division by zero

local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end

function init()
    left_v = BASE_SPEED * MAX_VELOCITY
    right_v = BASE_SPEED * MAX_VELOCITY
    robot.wheels.set_velocity(left_v, right_v)
    if robot.leds then robot.leds.set_all_colors("green") end
end

function step()
    -- sum light on left and right sensor groups
    local n = #robot.light
    local half = math.floor(n/2)
    local sum_left, sum_right, total = 0,0,0
    for i=1,n do
        local v = robot.light[i].value
        total = total + v
        if i <= half then sum_left = sum_left + v else sum_right = sum_right + v end
    end

    local forward = BASE_SPEED * MAX_VELOCITY
    -- normalized difference drives turning
    local diff = (sum_right - sum_left) / (total + LIGHT_THRESHOLD)
    local turn = TURN_GAIN * diff * MAX_VELOCITY

    left_v = clamp(forward + turn, -MAX_VELOCITY, MAX_VELOCITY)
    right_v = clamp(forward - turn, -MAX_VELOCITY, MAX_VELOCITY)

    robot.wheels.set_velocity(left_v, right_v)

    -- optional LED feedback: brighter when near light
    if robot.leds then
        if total > 1.5 then
            robot.leds.set_all_colors("yellow")
        else
            robot.leds.set_all_colors("green")
        end
    end
end

function reset()
    left_v = BASE_SPEED * MAX_VELOCITY
    right_v = BASE_SPEED * MAX_VELOCITY
    robot.wheels.set_velocity(left_v, right_v)
    if robot.leds then robot.leds.set_all_colors("green") end
end

function destroy()
end