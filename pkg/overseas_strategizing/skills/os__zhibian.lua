local os__zhibian = fk.CreateSkill {
  name = "os__zhibian"
}

Fk:loadTranslationTable{
  ['os__zhibian'] = '直辩',
  ['#os__zhibian-ask'] = '直辩：你可与一名角色拼点',
  ['os__zhibian_extract'] = '将%arg场上的一张牌移动到你的对应区域，或将其区域内的一张牌置于你的手牌中',
  ['beishui_os__zhibian'] = '背水：弃置一张非基本牌',
  ['os__zhibian_get'] = '将%arg区域内的一张牌置于你的手牌中',
  ['os__zhibian_move'] = '将%arg场上的一张牌移动到你的对应区域',
  [':os__zhibian'] = '出牌阶段开始时，你可与一名角色拼点，若你赢，则你可选择一项：1. 将其场上的一张牌移动到你的对应区域，或将其区域内的一张牌置于你的手牌中；2. 回复1点体力；背水：弃置一张非基本牌；若你没赢，你失去1点体力。',
  ['$os__zhibian1'] = '两国各增守将，皆事势宜然，何足相问。',
  ['$os__zhibian2'] = '固边大计，乃立国之本，岂有不设之理。',
}

os__zhibian:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__zhibian) and
      player.phase == Player.Play and not player:isKongcheng() and table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local target = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__zhibian-ask",
      skill_name = os__zhibian.name,
      cancelable = true,
    })
    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local target = room:getPlayerById(event:getCostData(self))
    local pindian = player:pindian({target}, os__zhibian.name)
    if pindian.results[target.id].winner == player then
      local choiceList = {}
      if not target:isAllNude() then table.insert(choiceList, "os__zhibian_extract:::" .. target.general) end
      if player:isWounded() then table.insert(choiceList, "recover") end
      if table.find(player:getCardIds({Player.Hand, Player.Equip}), function(id) return Fk:getCardById(id).type ~= Card.TypeBasic end) then
        table.insert(choiceList, "beishui_os__zhibian")
      end
      table.insert(choiceList, "Cancel")
      local choice = room:askToChoice(player, {
        choices = choiceList,
        skill_name = os__zhibian.name,
      })
      if choice == "Cancel" then return false end
      if choice == "beishui_os__zhibian" then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = os__zhibian.name,
          cancelable = false,
          pattern = ".|.|.|.|.|^basic",
        })
      end
      if choice ~= "recover" and not target:isAllNude() then
        choiceList = {"os__zhibian_get:::" .. target.general}
        if target:canMoveCardsInBoardTo(player, nil) then table.insert(choiceList, 1, "os__zhibian_move:::" .. target.general) end
        local choice = room:askToChoice(player, {
          choices = choiceList,
          skill_name = os__zhibian.name,
        })
        if choice:startsWith("os__zhibian_move") then
          room:askToMoveCardInBoard(player, {
            target_one = target,
            target_two = player,
            skill_name = os__zhibian.name,
            move_from = target,
          })
        else
          local cid = room:askToChooseCard({
            player = player,
            target = target,
            flag = "hej",
            skill_name = os__zhibian.name,
          })
          room:moveCardTo(cid, Player.Hand, player, fk.ReasonJustMove, os__zhibian.name)
        end
      end
      if choice == "recover" or choice == "beishui_os__zhibian" then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = os__zhibian.name,
        })
      end
    else
      room:loseHp(player, 1, os__zhibian.name)
    end
  end,
})

return os__zhibian
