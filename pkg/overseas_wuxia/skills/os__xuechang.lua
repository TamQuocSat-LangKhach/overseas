local os__xuechang = fk.CreateSkill {
  name = "os__xuechang"
}

Fk:loadTranslationTable{
  ['os__xuechang'] = '血偿',
  ['#os__xuechang_damage'] = '血偿',
  [':os__xuechang'] = '出牌阶段限一次，你可与一名角色拼点，若你赢，你获得其一张牌，若此牌为装备牌，则你视为对其使用一张【杀】；若你没赢，你受到其造成的1点伤害，你下次对其造成的伤害+1。',
  ['$os__xuechang1'] = '风尘难掩忠魂血，杀尽宦祸不得偿！',
  ['$os__xuechang2'] = '霜刃绚练，血舞婆娑。',
}

os__xuechang:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(os__xuechang.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:canPindian(Fk:currentRoom():getPlayerById(to_select)) and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, os__xuechang.name)
    if pindian.results[target.id].winner == player then
      if target:isNude() then return false end
      local cid = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = os__xuechang.name
      })
      room:obtainCard(player, cid, false)
      if Fk:getCardById(cid).type == Card.TypeEquip then
        room:useVirtualCard("slash", nil, player, target, os__xuechang.name, true)
      end
    else
      room:damage{
        from = target,
        to = player,
        damage = 1,
        skillName = os__xuechang.name,
      }
      room:addPlayerMark(player, "_os__xuechang+" .. target.id, 1)
    end
  end,
})

os__xuechang:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__xuechang+" .. data.to.id) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("_os__xuechang+" .. data.to.id)
    player.room:setPlayerMark(player, "_os__xuechang+" .. data.to.id, 0)
  end,
})

return os__xuechang
