local vector = require "vector"

-- Global variables
MAX_VELOCITY     = 15          
LIGHT_GAIN       = 80    -- gain for the attractive light field 
OBSTACLE_GAIN    = 12    -- gain for the repulsive obstacle field
UNIFORM_GAIN     = 8     -- constant forward drive (exploration base speed)
ANGULAR_GAIN     = 1.5   -- gain to convert resultant angle into omega
HALT_THRESHOLD   = 0.1   -- ground sensor value below which = black spot
-- max lenght = 100
HALT_GAIN        = 101   -- gain for the halt-on-black perceptual schema

-- Global state
L = 0            -- inter-wheel distance
n_steps = 0      -- step counter

local function clamp(x, a, b)
    if x < a then return a elseif x > b then return b else return x end
end

function init()
    L = robot.wheels.axis_length
    n_steps = 0
    robot.leds.set_all_colors("black")
end

-- Perceptual schema 1 – Phototaxis (attractive field)
-- Sum all light sensor readings as vectors; the result points toward the brightest region.
local function ps_pt()
    local result = {length = 0, angle = 0}
    for i = 1, #robot.light do
        local reading = robot.light[i]
        -- Each sensor contributes a vector toward its direction
        local v = {length = reading.value, angle = reading.angle}
        result = vector.vec2_polar_sum(result, v)
    end
    -- Scale by the gain
    result.length = result.length * LIGHT_GAIN
    return result
end

-- Perceptual schema 2 – Obstacle avoidance (repulsive field)
-- Each proximity sensor produces a repulsive force opposite to the sensor direction.
local function ps_oa()
    local result = {length = 0, angle = 0}
    for i = 1, #robot.proximity do
        local reading = robot.proximity[i]
        if reading.value > 0 then
            -- Repulsive: push in the opposite direction (angle + pi)
            local v = {length = reading.value, angle  = reading.angle + math.pi}
            result = vector.vec2_polar_sum(result, v)
        end
    end
    -- Scale by the gain
    result.length = result.length * OBSTACLE_GAIN
    return result
end

-- Perceptual schema 3 – Uniform forward drive (exploration)
-- A small constant vector pointing straight ahead so the robot keeps moving even when no stimulus is perceived.
local function ps_uniform()
    return {length = UNIFORM_GAIN, angle = 0}
end

-- Perceptual schema 4 – Halt on black spot (braking field)
-- When the ground is dark, produce a strong backward vector (angle = pi) whose intensity is proportional to how dark the reading is.
local function ps_halt()
    local result = {length = 0, angle = 0}
    for i = 1, #robot.motor_ground do
        local val = robot.motor_ground[i].value  ---could be 1 or 0 depending on the color of the ground
        if val < HALT_THRESHOLD then
            -- intensity 1 when val = 0 (black), otherwise intensity 0 
            local intensity = 1 - (val / HALT_THRESHOLD)
            local v = {length = intensity, angle = math.pi}
            result = vector.vec2_polar_sum(result, v)
        end
    end
    result.length = result.length * HALT_GAIN
    return result
end

-- Convert resultant vector to differential wheel velocities
local function vector_to_wheels(resultant)
    -- translational velocity
    local v = clamp(resultant.length, 0, MAX_VELOCITY)
    -- angular velocity
    local omega = ANGULAR_GAIN * resultant.angle
    -- differential drive conversion
    local vl = v - omega * L / 2
    local vr = v + omega * L / 2
    -- clamp wheels
    vl = clamp(vl, -MAX_VELOCITY, MAX_VELOCITY)
    vr = clamp(vr, -MAX_VELOCITY, MAX_VELOCITY)

    return vl, vr
end



-- step (called every tick)
function step()
    n_steps = n_steps + 1

    -- Individual motor schema vectors
    local pt_vec      = ps_pt()
    local oa_vec      = ps_oa()
    local uniform_vec = ps_uniform()
    local halt_vec    = ps_halt()

    -- Sum all vectors to obtain the resultant
    local resultant = vector.vec2_polar_sum(pt_vec, oa_vec)
    resultant       = vector.vec2_polar_sum(resultant, uniform_vec)
    resultant       = vector.vec2_polar_sum(resultant, halt_vec)

    -- Convert to wheel velocities
    local vl, vr = vector_to_wheels(resultant)

    -- LED feedback
    if halt_vec.length > 0 then
        robot.leds.set_all_colors("red")
    else
        local total_light = 0
        for i = 1, #robot.light do
            total_light = total_light + robot.light[i].value
        end
        if total_light > 0.5 then
            robot.leds.set_all_colors("yellow")
        else
            robot.leds.set_all_colors("green")
        end
    end

    -- Actuate
    robot.wheels.set_velocity(vl, vr)
end

function reset()
    n_steps = 0
    robot.leds.set_all_colors("black")
end

function destroy()
end
