-- Parameters
W      = 0.1    -- spontaneous walking probability
S      = 0.01   -- spontaneous stopping probability
PSmax  = 0.99   -- max stopping probability
PWmin  = 0.005  -- min walking probability
alpha  = 0.4    -- influence of stopped neighbours on Ps
beta   = 0.05   -- influence of stopped neighbours on Pw
MAXRANGE = 30   -- cm, range within which neighbours are counted

-- States
STATE_MOVING  = 0
STATE_STOPPED = 1
SPEED = 10

function init()
   state = STATE_MOVING
   robot.range_and_bearing.set_data(1, 0)
   robot.leds.set_all_colors("green")
end

-- Count stopped robots within MAXRANGE
function CountRAB()
    local number_robot_sensed = 0
    for i = 1, #robot.range_and_bearing do
        -- for each robot seen, check if it is close enough.
        if robot.range_and_bearing[i].range < MAXRANGE and
        robot.range_and_bearing[i].data[1]==1 then
        number_robot_sensed = number_robot_sensed + 1
        end
    end
    return number_robot_sensed
end

-- Obstacle avoidance: returns true if there is an obstacle ahead and turns the robot away
function obstacleAvoidance()
   local max_val = 0
   local max_idx = 0
   for i = 1, #robot.proximity do
      local val = robot.proximity[i].value
      local ang = robot.proximity[i].angle
      if math.abs(ang) < (math.pi / 2) and val > max_val then
         max_val = val
         max_idx = i
      end
   end

   if max_val > 0.1 then
      local angle = robot.proximity[max_idx].angle
      if angle > 0 then
         robot.wheels.set_velocity(SPEED, -SPEED)
      else
         robot.wheels.set_velocity(-SPEED, SPEED)
      end
      return true
   end
   return false
end

function step()
   local N  = CountRAB()

   -- Update probabilities
   local Ps = math.min(PSmax, S + alpha * N)
   local Pw = math.max(PWmin, W - beta  * N)

   if state == STATE_MOVING then
      robot.range_and_bearing.set_data(1, 0)
      robot.leds.set_all_colors("green")

      -- Try to avoid obstacles. If none, random walk
      if not obstacleAvoidance() then
         local left  = SPEED + robot.random.uniform(-2, 2)
         local right = SPEED + robot.random.uniform(-2, 2)
         robot.wheels.set_velocity(left, right)
      end

      -- Decide whether to stop
      if robot.random.uniform() <= Ps then
         state = STATE_STOPPED
      end

   else  -- STATE_STOPPED
      robot.range_and_bearing.set_data(1, 1)
      robot.leds.set_all_colors("red")
      robot.wheels.set_velocity(0, 0)

      -- Decide whether to start walking again
      if robot.random.uniform() <= Pw then
         state = STATE_MOVING
      end
   end
end

function reset()
   init()
end

function destroy()
end
