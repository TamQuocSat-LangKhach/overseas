local chungang = fk.CreateSkill {
  name = "os__chungang"
}

Fk:loadTranslationTable{
  ['os__chungang'] = '纯刚',
  ['#os__chungang-discard'] = '受到 %src “纯刚” 的影响，请弃置一张牌',
  [':os__chungang'] = '锁定技，当其他角色于其摸牌阶段外获得不少于两张牌后，你令其弃置一张牌。',
  ['$os__chungang1'] = '陛下若此，天下何以观之！',
  ['$os__chungang2'] = '偏听谄谀之言，此为万民所仰之君乎？'
}

chungang:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(chungang.name) then return false end
    local room = player.room
    local guzheng_pairs = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.PlayerHand and move.to and move.to ~= player.id and room:getPlayerById(move.to).phase ~= Player.Draw then
        guzheng_pairs[move.to] = (guzheng_pairs[move.to] or 0) + #move.moveInfo
      end
    end
    for key, value in pairs(guzheng_pairs) do
      if not player.room:getPlayerById(key):isNude() and value > 1 then
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local guzheng_pairs = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.PlayerHand and move.to and move.to ~= player.id and room:getPlayerById(move.to).phase ~= Player.Draw then
        guzheng_pairs[move.to] = (guzheng_pairs[move.to] or 0) + #move.moveInfo
      end
    end
    for key, value in pairs(guzheng_pairs) do
      if not player.room:getPlayerById(key):isNude() and value > 1 then
        table.insertIfNeed(targets, key)
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(chungang.name) then break end
      local skill_target = room:getPlayerById(target_id)
      self:doCost(event, skill_target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = chungang.name,
      cancelable = false,
      prompt = "#os__chungang-discard:" .. player.id
    })
  end,
})

return chungang
