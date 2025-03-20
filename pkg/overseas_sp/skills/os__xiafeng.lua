local os__xiafeng = fk.CreateSkill {
  name = "os__xiafeng"
}

Fk:loadTranslationTable{
  ['os__xiafeng'] = '黠凤',
  ['@os__baonue'] = '暴虐值',
  ['#os__xiafeng'] = '黠凤：本回合使用的前X张牌无距离和次数限制且不能被响应，手牌上限+X',
  ['#os__xiafeng_log'] = '%from 消耗了 %arg 点暴虐值',
  [':os__xiafeng'] = '出牌阶段开始时，你可消耗至多3点<a href=>暴虐值</a>，令你本回合使用的前X张牌无距离和次数限制且不可被响应，手牌上限+X。（X为消耗暴虐值）',
  ['$os__xiafeng1'] = '穷奇凶戾，黠凤诡诈。',
  ['$os__xiafeng2'] = '鸾凤襄蛟，黠风殷狰。',
}

-- 主技能效果
os__xiafeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and player.phase == Player.Play and player:getMark("@os__baonue") > 0
  end,
  on_cost = function(self, event, target, player)
    local choices = {}
    for i = 1, math.min(3, player:getMark("@os__baonue")) do
      table.insert(choices, tostring(i))
    end
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = skill.name,
      prompt = "#os__xiafeng",
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local num = tonumber(event:getCostData(skill))
    local room = player.room
    room:setPlayerMark(player, "_os__xiafeng-turn", num)
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, num)
    room:removePlayerMark(player, "@os__baonue", num)
    room:sendLog{
      type = "#os__xiafeng_log",
      from = player.id,
      arg = event:getCostData(skill),
    }
  end,

  can_refresh = function(self, event, target, player)
    if player ~= target then return false end
    if event == fk.AfterCardUseDeclared then return true
    else return player:hasSkill(skill.name) and canBaonue(player, data, event) end
  end,
  on_refresh = function(self, event, target, player)
    if event == fk.AfterCardUseDeclared then 
      player.room:addPlayerMark(player, "_os__xiafeng_count-turn", 1)
    else
      addBaonue(player.room, player, data, event)
    end
  end,
})

-- 不可响应效果
os__xiafeng:addEffect(fk.CardUsing, {
  mute = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("_os__xiafeng_count-turn") <= player:getMark("_os__xiafeng-turn") and player:getMark("_os__xiafeng-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, target in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, target.id)
    end
  end,
})

-- 目标修正效果
os__xiafeng:addEffect('targetmod', {
  bypass_times = function(self, player, skill2, scope, card, to)
    return card and player:getMark("_os__xiafeng_count-turn") < player:getMark("_os__xiafeng-turn") and scope == Player.HistoryPhase
  end,
  bypass_distances = function(self, player, skill2, card)
    return card and player:getMark("_os__xiafeng_count-turn") < player:getMark("_os__xiafeng-turn")
  end,
})

return os__xiafeng
