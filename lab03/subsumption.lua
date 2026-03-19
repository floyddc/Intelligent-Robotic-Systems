-- Subsumption architecture for foot-bot
-- Prioritize behaviors: halt > obstacle avoidance > phototaxis > random walk

MAX_VELOCITY = 60

function init()
    left_v = 0
    right_v = 0
end

function step()
    -- layer 0
    left_v, right_v = random_walk()

    -- layer 1
    left_v, right_v = phototaxis(left_v, right_v)

    -- layer 2
    left_v, right_v = obstacle_avoidance(left_v, right_v)

    -- layer 3
    left_v, right_v = halt(left_v, right_v)

    -- final decision
    robot.wheels.set_velocity(left_v, right_v)
end

function random_walk()
    return MAX_VELOCITY * (math.random() - 0.5), MAX_VELOCITY * (math.random() - 0.5)
end

function phototaxis(left_v, right_v)
    local light = robot.light
    local max_val = 0
    local lx, ly, total_light = 0, 0, 0

    for i=1, #light do
        local value = light[i].value
        local angle = light[i].angle
        lx = lx + value * math.cos(angle)
        ly = ly + value * math.sin(angle)
        total_light = total_light + value
    end

    if total_light < 0.001 then
        return 0, total_light
    end

    local angle = math.atan2(ly, lx)
    local light_turn = LIGHT_GAIN * angle * MAX_VELOCITY

    return light_turn, total_light
end

function obstacle_avoidance(left_v, right_v)
    local prox = robot.proximity

    local front, turn = 0, 0

    for i=1, #prox do
        front =  front + prox[i].value * math.cos(prox[i].angle)
        turn = turn + prox[i].value * math.sin(prox[i].angle)
    end

    local obstacle_intensity = 0
    for i=1, #prox do
        obstacle_intensity = obstacle_intensity + prox[i].value
    end

    -- normalization factor to keep it between 0 and 1
    obstacle_intensity = math.min(1, obstacle_intensity)
    
    local gain_front = 8
    local gain_turn = 30
    left_v = left_v - obstacle_intensity * (gain_front * front - gain_turn * turn)
    right_v = right_v - obstacle_intensity * (gain_front * front + gain_turn * turn)

    return left_v, right_v
end

function halt(left_v, right_v)
    local ground = robot.motor_ground

    for i=1, #ground do
        if ground[i].value < 0.1 then
            return 0, 0
        end
    end

    return left_v, right_v
end

function reset()
    left_v = MAX_VELOCITY
    right_v = MAX_VELOCITY
    robot.wheels.set_velocity(left_v, right_v)
    if robot.leds then robot.leds.set_all_colors("green") end
end

function destroy()
end