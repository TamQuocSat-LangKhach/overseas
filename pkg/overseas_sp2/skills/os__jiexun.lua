local os__jiexun = fk.CreateSkill {
  name = "os__jiexun"
}

Fk:loadTranslationTable{
  ['os__jiexun'] = '诫训',
  ['#os__jiexun-target'] = '你可对一名其他角色发动“诫训”',
  ['@os__jiexun_update'] = '诫训2级',
  ['@os__jiexun'] = '诫训',
  ['#os__jiexun-suit'] = '诫训：选择一种花色，令 %src 摸场上此花色牌数张牌，然后其弃置%arg张牌',
  ['os__jiexun_draw'] = '摸%arg张牌，重置〖诫训〗次数',
  ['os__jiexun_update'] = '升级〖复难〗和〖诫训〗',
  ['@@os__funan_update'] = '复难2级',
  [':os__jiexun'] = '1级：结束阶段开始时，你可选择一名其他角色并选择一种花色，令其摸场上此花色牌数张牌，然后其弃置X张牌（X为此技能发动过的次数）。若其以此法弃置了所有牌，你选择一项：1. 摸X张牌，然后重置X为0；2. 升级〖复难〗和〖诫训〗。<br/>2级：结束阶段开始时，你可选择一种花色，令一名其他角色摸场上此花色牌数张牌，然后其弃置X张牌（X为此技能升级前的X）。',
  ['$os__jiexun1'] = '帝王应以社稷为重，以大观为主。',
  ['$os__jiexun2'] = '吾冒昧进谏，只求陛下思虑。',
}

os__jiexun:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__jiexun.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local target = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__jiexun-target",
      skill_name = os__jiexun.name
    })
    if #target > 0 then
      local card_suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
      local num = player:getMark("@os__jiexun_update") == 0 and player:getMark("@os__jiexun") or player:getMark("@os__jiexun_update")
      local choice = room:askToChoice(player, {
        choices = card_suits,
        skill_name = os__jiexun.name,
        prompt = "#os__jiexun-suit:" .. target[1] .. "::" .. tostring(num)
      })
      event:setCostData(self, {target[1], table.indexOf(card_suits, choice)})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local target = room:getPlayerById(event:getCostData(self)[1])
    local suit = event:getCostData(self)[2]
    local num = 0
    for _, p in ipairs(player.room.alive_players) do
      num = num + #table.filter(p:getCardIds{ Player.Equip, Player.Judge }, function(id)
        return Fk:getCardById(id).suit == suit
      end)
    end
    if num > 0 then
      room:drawCards(target, num, os__jiexun.name)
    end
    num = player:getMark("@os__jiexun_update") == 0 and player:getMark("@os__jiexun") or player:getMark("@os__jiexun_update")
    if num > 0 then
      room:askToDiscard(target, {
        min_num = num,
        max_num = num,
        include_equip = true,
        skill_name = os__jiexun.name
      })
    end
    if player:getMark("@os__jiexun_update") == 0 then
      room:addPlayerMark(player, "@os__jiexun")
      if num > 0 and target:isNude() then
        local choice = room:askToChoice(player, {
          choices = {"os__jiexun_draw:::" .. num, "os__jiexun_update"},
          skill_name = os__jiexun.name
        })
        if choice == "os__jiexun_update" then
          room:setPlayerMark(player, "@@os__funan_update", 1)
          room:setPlayerMark(player, "@os__jiexun_update", num)
          room:setPlayerMark(player, "@os__jiexun", 0)
        else
          player:drawCards(num, os__jiexun.name)
          room:setPlayerMark(player, "@os__jiexun", 0)
        end
      end
    end
  end,
})

return os__jiexun
