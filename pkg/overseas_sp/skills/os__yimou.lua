local os__yimou = fk.CreateSkill {
  name = "os__yimou"
}

Fk:loadTranslationTable{
  ['os__yimou'] = '毅谋',
  ['os__yimou_slash'] = '令其从牌堆获得一张【杀】',
  ['os__yimou_give'] = '令其将一张手牌交给另一名角色，摸两张牌',
  ['beishui_os__yimou'] = '背水：将所有手牌交给其',
  ['#os__yimou'] = '你想对 %dest 发动技能“毅谋”吗？',
  ['#os__yimou_give'] = '毅谋：将一张手牌交给一名其他角色，然后摸两张牌',
  [':os__yimou'] = '当至你距离1以内的角色受到伤害后，你可选择一项：1.令其从牌堆获得一张【杀】；2.令其将一张手牌交给另一名角色，摸两张牌。若为其他角色，则你可背水：将所有手牌交给其。',
  ['$os__yimou1'] = '今畜士众之力，据其要害，贼可破之。',
  ['$os__yimou2'] = '泰然若定，攻敌自溃！',
}

os__yimou:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__yimou.name) and target:distanceTo(player) < 2 and not (target.dead or player.dead)
  end,
  on_cost = function(self, event, target, player)
    local choices = {"os__yimou_slash"}
    if not target:isKongcheng() then table.insert(choices, "os__yimou_give") end
    if target ~= player and not player:isKongcheng() then table.insert(choices, "beishui_os__yimou") end
    table.insert(choices, "Cancel")
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__yimou.name,
      prompt = "#os__yimou::" .. target.id
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice = event:getCostData(self)
    if choice == "beishui_os__yimou" then
      room:moveCardTo(player:getCardIds(Player.Hand), Player.Hand, target, fk.ReasonGive, os__yimou.name, nil, false)
    end
    if choice ~= "os__yimou_give" then
      local id = room:getCardsFromPileByRule("slash")
      if #id > 0 then
        room:obtainCard(target, id[1], false, fk.ReasonPrey)
      end
    end
    if choice ~= "os__yimou_slash" and not target:isKongcheng() then
      local plist, cid = room:askToChooseCardsAndPlayers(target, {
        min_card_num = 1,
        max_card_num = 1,
        targets = table.map(room:getOtherPlayers(target), Util.IdMapper),
        pattern = ".|.|.|hand",
        prompt = "#os__yimou_give",
        skill_name = os__yimou.name
      })
      room:moveCardTo(cid, Player.Hand, plist[1], fk.ReasonGive, os__yimou.name, nil, false)
      target:drawCards(2, os__yimou.name)
    end
  end,
})

return os__yimou
