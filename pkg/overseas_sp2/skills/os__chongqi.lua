local os__chongqi = fk.CreateSkill {
  name = "os__chongqi"
}

Fk:loadTranslationTable{
  ['os__chongqi'] = '宠齐',
  ['os__feifu'] = '非服',
  ['os__fuzuan'] = '复纂',
  ['#os__chongqi-ask'] = '宠齐：你可减1点体力上限，令一名其他角色获得〖复纂〗',
  [':os__chongqi'] = '锁定技，①当你获得此技能后，所有角色获得〖非服〗。②游戏开始时，你可减1点体力上限，令一名其他角色获得〖复纂〗。',
  ['$os__chongqi1'] = '吾既身承宠遇，敢不为君分忧？',
  ['$os__chongqi2'] = '臣得君上垂青，已是此生之幸。',
}

os__chongqi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__chongqi.name)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:handleAddLoseSkills(p, "os__feifu", nil, false, true)
    end
    local targets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return (not p:hasSkill("os__fuzuan"))
      end),
      Util.IdMapper
    )
    if #targets == 0 then return false end
    local target = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__chongqi-ask",
      skill_name = os__chongqi.name,
      cancelable = true,
    })
    if #target > 0 then
      room:changeMaxHp(player, -1)
      room:handleAddLoseSkills(room:getPlayerById(target[1].id), "os__fuzuan", nil)
    end
  end,
})

os__chongqi:addEffect(fk.SkillAcquire, {
  on_acquire = function(self, player, is_start)
    if not is_start then
      local room = player.room
      for _, p in ipairs(room.alive_players) do
        room:handleAddLoseSkills(p, "os__feifu", nil, false, true)
      end
    end
  end,
})

return os__chongqi
