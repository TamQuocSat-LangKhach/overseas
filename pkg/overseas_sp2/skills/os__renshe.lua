local os__renshe = fk.CreateSkill {
  name = "os__renshe"
}

Fk:loadTranslationTable{
  ['os__renshe'] = '忍涉',
  ['os__waishi_times'] = '令〖外使〗的发动次数上限于你的出牌阶段结束前+1',
  ['os__renshe_change'] = '将势力改为现存的另一个势力',
  ['os__renshe_draw'] = '与一名除伤害来源之外的其他角色各摸一张牌',
  ['@os__waishi_times'] = '外使次数+',
  ['#os__chijie-choose'] = '持节：你可更改你的势力',
  ['#os__renshe-target'] = '忍涉：选择一名除伤害来源之外的其他角色，与其各摸一张牌',
  [':os__renshe'] = '当你受到伤害后，你可选择一项：1.将势力改为现存的另一个势力；2.令〖外使〗的发动次数上限于你的出牌阶段结束前+1；3.与一名除伤害来源之外的其他角色各摸一张牌。',
  ['$os__renshe1'] = '无论风雨再大，都无法阻挡我的脚步。',
  ['$os__renshe2'] = '一定不能辜负女王的期望！',
}

os__renshe:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local choices = {"os__waishi_times"}
    local room = player.room
    if table.find(room.alive_players, function(p)
      return p.kingdom ~= player.kingdom
    end) then
      table.insert(choices, 1, "os__renshe_change")
    end
    if table.find(room.alive_players, function(p)
      return p ~= data.from and p ~= player
    end) then
      table.insert(choices, "os__renshe_draw")
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__renshe.name
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self)
    if choice == "os__waishi_times" then
      room:addPlayerMark(player, "@os__waishi_times", 1)
    elseif choice == "os__renshe_change" then
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      table.removeOne(kingdoms, player.kingdom)
      player.kingdom = room:askToChoice(player, {
        choices = kingdoms,
        skill_name = os__renshe.name,
        prompt = "#os__chijie-choose"
      })
      room:broadcastProperty(player, "kingdom")
    else
      local tos = room:askToChoosePlayers(player, {
        targets = table.map(
          table.filter(room.alive_players, function(p)
            return (p ~= data.from and p ~= player)
          end), Util.IdMapper
        ),
        min_num = 1,
        max_num = 1,
        prompt = "#os__renshe-target",
        skill_name = os__renshe.name
      })
      if #tos > 0 then
        for _, p in ipairs(room:getAlivePlayers()) do --顺序
          if not p.dead and (p.id == tos[1] or p == player) then
            p:drawCards(1, os__renshe.name)
          end
        end
      end
    end
  end,
})

os__renshe:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("@os__waishi_times") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@os__waishi_times", 0)
  end,
})

return os__renshe
