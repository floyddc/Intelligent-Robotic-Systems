MAX_VELOCITY = 80
LIGHT_GAIN = 1        -- steering gain for light attraction
OBSTACLE_GAIN = 1.5     -- steering gain for obstacle avoidance
SPEED_REDUCTION = 0.5   -- how much obstacles slow the robot
TURN_FAST = 0.5         -- outer wheel speed during turn
TURN_SLOW = 0.2         -- inner wheel speed during turn

local function clamp(x,a,b) 
    if x<a then return a elseif x>b then return b else return x end 
end

function init()
    left_v = MAX_VELOCITY
    right_v = MAX_VELOCITY
    robot.wheels.set_velocity(left_v, right_v)
    if robot.leds then robot.leds.set_all_colors("green") end
    math.randomseed(os.time())
end

function step()
    -- phototaxis
    local n_light = #robot.light
    local half_light = math.floor(n_light/2)
    local light_left, light_right, total_light = 0, 0, 0
    
    for i=1, n_light do
        local v = robot.light[i].value
        total_light = total_light + v
        if i <= half_light then 
            light_left = light_left + v 
        else 
            light_right = light_right + v 
        end
    end
    
    -- normalized difference: positive means light on right
    local light_diff = (light_right - light_left) / (total_light + 0.01)
    local light_turn = LIGHT_GAIN * light_diff * MAX_VELOCITY
    
    -- collision avoidance
    local n_prox = #robot.proximity
    local half_prox = math.floor(n_prox/2)
    local prox_left, prox_right, max_prox = 0, 0, 0
    
    for i=1, n_prox do
        local v = robot.proximity[i].value
        if i <= half_prox then 
            prox_left = prox_left + v 
        else 
            prox_right = prox_right + v 
        end
        if v > max_prox then max_prox = v end
    end
    
    -- normalized difference: positive means obstacle on left -> turn right
    local total_prox = prox_left + prox_right
    local prox_diff = (prox_left - prox_right) / (total_prox + 0.01)
    local obstacle_turn = OBSTACLE_GAIN * prox_diff * MAX_VELOCITY
    
    -- reduce speed when obstacles are near
    local speed_factor = 1.0 - (max_prox * SPEED_REDUCTION)
    speed_factor = clamp(speed_factor, 0.2, 1.0)
    
    -- detect narrow gap: center sensors low but sides close
    local mid = math.floor(n_prox/2)
    local front_sum, front_cnt = 0, 0
    for i = mid-1, mid+1 do
        if robot.proximity[i] then front_sum = front_sum + robot.proximity[i].value; front_cnt = front_cnt + 1 end
    end
    local front_avg = front_sum / (front_cnt + 0.001)
    local side_max = 0
    for i = 1, n_prox do
        if i < mid-1 or i > mid+1 then side_max = math.max(side_max, robot.proximity[i].value) end
    end

    -- if center is clear but sides are close, bias to go straight through the gap
    -- smooth, threshold-free gap handling: compute a continuous score
    -- gap_score in [-1,1]: positive means sides > front (potential gap)
    local gap_score = (side_max - front_avg) / (side_max + front_avg + 0.001)
    -- convert to a weight in [0,1] (negative values -> 0)
    local gap_weight = clamp(gap_score, 0.0, 1.0)

    -- blend speed and steering attenuation smoothly using gap_weight
    speed_factor = clamp(speed_factor + 0.3 * gap_weight, 0.2, 1.0)
    local light_atten = 1.0 - (0.7 * gap_weight)      -- up to 70% attenuation
    local obstacle_atten = 1.0 - (0.8 * gap_weight)   -- up to 80% attenuation
    light_turn = light_turn * light_atten
    obstacle_turn = obstacle_turn * obstacle_atten

    -- combine both steering commands
    local total_turn = light_turn + obstacle_turn

    -- simple random walk when no light and no close obstacles
    if total_light < 0.1 and max_prox < 0.1 and math.abs(total_turn) < 0.01 then
        if math.random() < 0.5 then
            left_v = TURN_FAST * MAX_VELOCITY * speed_factor
            right_v = TURN_SLOW * MAX_VELOCITY * speed_factor
        else
            left_v = TURN_SLOW * MAX_VELOCITY * speed_factor
            right_v = TURN_FAST * MAX_VELOCITY * speed_factor
        end
    else
        if total_turn > 0 then
            -- turn right: left wheel faster, right wheel slower
            left_v = TURN_FAST * MAX_VELOCITY * speed_factor
            right_v = TURN_SLOW * MAX_VELOCITY * speed_factor
        elseif total_turn < 0 then
            -- turn left: right wheel faster, left wheel slower
            left_v = TURN_SLOW * MAX_VELOCITY * speed_factor
            right_v = TURN_FAST * MAX_VELOCITY * speed_factor
        else
            -- straight
            left_v = MAX_VELOCITY * speed_factor
            right_v = MAX_VELOCITY * speed_factor
        end
    end
    
    robot.wheels.set_velocity(left_v, right_v)
end

function reset()
    left_v = MAX_VELOCITY
    right_v = MAX_VELOCITY
    robot.wheels.set_velocity(left_v, right_v)
    if robot.leds then robot.leds.set_all_colors("green") end
end

function destroy()
end