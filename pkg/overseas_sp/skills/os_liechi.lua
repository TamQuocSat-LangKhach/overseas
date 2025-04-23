local osLiechi = fk.CreateSkill {
  name = "os__liechi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__liechi"] = "烈斥",
  [":os__liechi"] = "锁定技，当你受到伤害后，若你的体力值不大于伤害来源，你选择一项：1.令其将手牌弃至与你手牌数相同；" ..
  "2.弃置其一张牌；若本回合你进入过濒死状态，则你可背水：弃置一张装备牌。",

  ["os__liechi_same"] = "令其将手牌弃至与你手牌数相同",
  ["os__liechi_one"] = "你弃置其一张牌",
  ["beishui_os__liechi"] = "背水：你弃置一张装备牌",

  ["$os__liechi1"] = "吾受汉帝恩，岂容吴贼辱？",
  ["$os__liechi2"] = "汉将有死无降，怎会如吴狗一般？",
}

osLiechi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osLiechi.name) and
      data.from and
      data.from.hp >= player.hp and
      data.from:isAlive() and
      not data.from:isNude()
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osLiechi.name
    local room = player.room
    local from = data.from
    local choices = {}
    if not from then
      return false
    end

    if from:getHandcardNum() > player:getHandcardNum() then table.insert(choices, "os__liechi_same") end
    if not from:isNude() then table.insert(choices, "os__liechi_one") end

    local events = room.logic:getEventsOfScope(GameEvent.Dying, 1, function(e)
      return e.data.who == player
    end, Player.HistoryTurn)
    if
      #choices > 0 and
      #events > 0 and
      table.find(
        player:getCardIds("he"),
        function(id)
          return Fk:getCardById(id).type == Card.TypeEquip and not player:prohibitDiscard(Fk:getCardById(id))
        end
      )
    then
      table.insert(choices, "beishui_os__liechi")
    end

    if #choices == 0 then return false end

    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = skillName,
      }
    )

    if choice == "beishui_os__liechi" then
      room:askToDiscard(
        player,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          pattern = ".|.|.|.|.|equip",
          skill_name = skillName,
          cancelable = false,
        }
      )
    end

    if choice ~= "os__liechi_one" then
      local n = from:getHandcardNum() - player:getHandcardNum()

      if n > 0 then
        room:askToDiscard(
          from,
          {
            min_num = n,
            max_num = n,
            skill_name = skillName,
            cancelable = false,
          }
        )
      end
    end

    if choice ~= "os__liechi_same" and not from:isNude() then
      local card = room:askToChooseCard(
        player,
        {
          target = from,
          flag = "he",
          skill_name = skillName,
        }
      )
      room:throwCard(card, skillName, from, player)
    end
  end,
})

return osLiechi
