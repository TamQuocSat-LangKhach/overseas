local os__yujue_others = fk.CreateSkill {
  name = "os__yujue_others&"
}

Fk:loadTranslationTable{
  ['os__yujue_others&'] = '鬻爵',
  ['#os__yujue_others'] = '鬻爵：你可交给汉孝灵皇帝刘宏一些牌，他可能会给你加官进爵',
  ['os__fengqix'] = '烽起',
  ['os__yujue'] = '鬻爵',
  [':os__yujue_others&'] = '出牌阶段，你可交给刘宏任意张牌（每阶段至多两张）。若其有〖烽起〗且你为群雄角色，“两”修改为“四”。'
}

os__yujue_others:addEffect('active', {
  anim_type = "support",
  min_card_num = 1,
  max_card_num = function(self, player)
    local room = Fk:currentRoom()
    local num = 0
    local max_num = (player.kingdom == "qun" and table.find(room.alive_players, function(p)
      return p:hasSkill("os__fengqix")
    end)) and 4 or 2
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__yujue") and p:getMark("_os__yujue-phase") < 2 and p ~= player then
        num = math.max(num, max_num - p:getMark("_os__yujue-phase"))
      end
    end
    return num
  end,
  target_num = 0,
  can_use = function(self, player)
    local room = Fk:currentRoom()
    local max_num = (player.kingdom == "qun" and table.find(room.alive_players, function(p)
      return p:hasSkill("os__fengqix")
    end)) and 4 or 2
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__yujue") and p:getMark("_os__yujue-phase") < max_num and p ~= player then
        return true
      end
    end
    return false
  end,
  card_filter = function(self, player, to_select, selected)
    local room = Fk:currentRoom()
    local num = 0
    local max_num = (player.kingdom == "qun" and table.find(room.alive_players, function(p)
      return p:hasSkill("os__fengqix")
    end)) and 4 or 2
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__yujue") and p:getMark("_os__yujue-phase") < 2 and p ~= player then
        num = math.max(num, max_num - p:getMark("_os__yujue-phase"))
      end
    end
    return #selected < num
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = effect.cards
    if #cards == 0 then return false end
    local max_num = (player.kingdom == "qun" and table.find(room.alive_players, function(p)
      return p:hasSkill("os__fengqix")
    end)) and 4 or 2 --还是错的
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return p:hasSkill("os__yujue") and max_num - p:getMark("_os__yujue-phase") >= #cards end)
    if #targets == 0 then return false end
    local to
    if #targets == 1 then
      to = targets[1]
    else
      to = room:askToChoosePlayers(player, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        cancelable = false,
        skill_name = os__yujue_others.name,
      })[1]
    end
    room:doIndicate(player.id, {to.id})
    --room:notifySkillInvoked(to, "os__yujue", "support")
    player:broadcastSkillInvoke("os__yujue")
    room:addPlayerMark(to, "_os__yujue-phase", #cards)
    room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, os__yujue_others.name, nil, false)
  end,
})

return os__yujue_others
