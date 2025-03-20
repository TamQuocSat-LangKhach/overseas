local os_ex__xuanhuo = fk.CreateSkill {
  name = "os_ex__xuanhuo"
}

Fk:loadTranslationTable{
  ['os_ex__xuanhuo'] = '眩惑',
  ['#os_ex__xuanhuo-target'] = '你可对一名其他角色发动“眩惑”',
  ['#os_ex__xuanhuo-give'] = '眩惑：交给 %src 两张牌',
  ['#os_ex__xuanhuo-choose'] = '眩惑：选择令 %dest 视为使用【杀】或【决斗】的目标',
  ['os_ex__xuanhuo_slash'] = '视为对%arg使用【杀】',
  ['os_ex__xuanhuo_duel'] = '视为对%arg使用【决斗】',
  ['os_ex__xuanhuo_extract'] = '%arg获得你两张牌',
  [':os_ex__xuanhuo'] = '摸牌阶段结束时，你可交给一名其他角色A两张牌并选择另一名角色B，然后A选择一项：1. 视为对B使用一张【杀】或【决斗】；2. 你获得其两张牌。',
  ['$os_ex__xuanhuo1'] = '收人钱财，替人消灾。',
  ['$os_ex__xuanhuo2'] = '哼，叫你十倍奉还！',
}

os_ex__xuanhuo:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os_ex__xuanhuo) and player.phase == Player.Draw and #player:getCardIds{ Player.Hand, Player.Equip } > 1
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os_ex__xuanhuo-target",
      skill_name = os_ex__xuanhuo.name
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local cids = room:askToCards(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = os_ex__xuanhuo.name,
      prompt = "#os_ex__xuanhuo-give:" .. to.id
    })
    room:moveCardTo(cids, Player.Hand, to, fk.ReasonGive, os_ex__xuanhuo.name, nil, false)
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(to), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os_ex__xuanhuo-choose::" .. to.id,
      skill_name = os_ex__xuanhuo.name
    })
    local victim = room:getPlayerById(tos[1])
    room:doIndicate(to.id, {victim.id})
    local name = victim.general
    local choice = room:askToChoice(to, {
      choices = {"os_ex__xuanhuo_slash:::" .. name, "os_ex__xuanhuo_duel:::" .. name, "os_ex__xuanhuo_extract:::" .. player.general},
      skill_name = os_ex__xuanhuo.name
    })
    if choice:startsWith("os_ex__xuanhuo_extract") then
      room:obtainCard(player, room:askToChooseCards(player, {
        min_num = 2,
        max_num = 2,
        target = to,
        flag = "he",
        skill_name = os_ex__xuanhuo.name
      }), false, fk.ReasonPrey)
    elseif choice:startsWith("os_ex__xuanhuo_slash") then
      room:useVirtualCard("slash", nil, to, {victim}, os_ex__xuanhuo.name, true)
    else
      room:useVirtualCard("duel", nil, to, {victim}, os_ex__xuanhuo.name, true)
    end
  end,
})

return os_ex__xuanhuo
