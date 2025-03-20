local os__shezhong = fk.CreateSkill {
  name = "os__shezhong"
}

Fk:loadTranslationTable{
  ['os__shezhong'] = '慑众',
  ['#os__shezhong1-target'] = '慑众：你可令至多 %arg 名其他角色下个摸牌阶段的摸牌数-1',
  ['@os__shezhong'] = '慑众',
  ['#os__shezhong2-target'] = '慑众：你可将手牌摸至与其中一名伤害来源的体力值相同（最多摸至5张）',
  ['#os__shezhong_draw'] = '慑众',
  [':os__shezhong'] = '结束阶段开始时，你可依次选择执行以下效果：1. 若你本回合对其他角色造成过伤害，则令至多X名其他角色下个摸牌阶段的额定摸牌数-1（X为你本回合造成的伤害值）；2. 若你本回合受到过伤害，则将手牌摸至与其中一名伤害来源的体力值相同（最多摸至5张）。',
  ['$os__shezhong1'] = '此乃吾之私怨，与汝等何干？！',
  ['$os__shezhong2'] = '拦吾去路者，下场有如此贼！',
}

os__shezhong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    if target ~= player or not player:hasSkill(os__shezhong.name) or player.phase ~= Player.Finish then return false end
    local room = player.room
    if table.find(room.alive_players, function(p)
      return p:getMark("_os__shezhong_damaged-turn") > 0
    end) then
      return true
    end
    if player:getMark("_os__shezhong_damage_others-turn") > 0 then return true end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if player:getMark("_os__shezhong_damage_others-turn") > 0 then
      local num = player:getMark("_os__shezhong_damage-turn")
      local victims = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = num,
        prompt = "#os__shezhong1-target:::" .. tostring(num),
        skill_name = os__shezhong.name,
        cancelable = true
      })
      if #victims > 0 then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if table.contains(victims, p.id) then
            room:addPlayerMark(p, "@os__shezhong")
          end
        end
      end
    end
    local availableTargets = table.map(table.filter(room.alive_players, function(p)
      return p:getMark("_os__shezhong_damaged-turn") > 0
    end), Util.IdMapper)
    if #availableTargets > 0 then
      local target = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__shezhong2-target",
        skill_name = os__shezhong.name,
        cancelable = true
      })
      if #target > 0 then
        local to = room:getPlayerById(target[1])
        local num = math.min(to.hp, 5) - player:getHandcardNum()
        if num > 0 then player:drawCards(num, os__shezhong.name) end
      end
    end
  end,
})

os__shezhong:addEffect({fk.Damage, fk.Damaged}, {
  anim_type = "control",
  can_refresh = function(self, event, target, player)
    if target ~= player or player.phase == Player.NotActive then return false end
    if event == fk.Damaged then return data.from ~= nil and not data.from.dead else return true end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "_os__shezhong_damage-turn", data.damage)
      if data.to ~= player then player.room:setPlayerMark(player, "_os__shezhong_damage_others-turn", 1) end
    else
      player.room:setPlayerMark(data.from, "_os__shezhong_damaged-turn", 1)
    end
  end,
})

local os__shezhong_draw = fk.CreateTriggerSkill{
  name = "#os__shezhong_draw",
  mute = true,
  anim_type = "negative",
}

os__shezhong:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("@os__shezhong") > 0 and data.n > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = math.max(data.n - player:getMark("@os__shezhong"), 0)
    player.room:setPlayerMark(player, "@os__shezhong", 0)
  end,
})

return os__shezhong
