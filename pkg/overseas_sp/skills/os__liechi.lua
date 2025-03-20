local os__liechi = fk.CreateSkill {
  name = "os__liechi"
}

Fk:loadTranslationTable{
  ['os__liechi'] = '烈斥',
  ['os__liechi_same'] = '令其将手牌弃至与你手牌数相同',
  ['os__liechi_one'] = '你弃置其一张牌',
  ['beishui_os__liechi'] = '背水：你弃置一张装备牌',
  [':os__liechi'] = '锁定技，当你受到伤害后，若你的体力值不大于伤害来源，你选择一项：1.令其将手牌弃至与你手牌数相同；2.弃置其一张牌；若本回合你进入过濒死状态，则你可背水：弃置一张装备牌。',
  ['$os__liechi1'] = '吾受汉帝恩，岂容吴贼辱？',
  ['$os__liechi2'] = '汉将有死无降，怎会如吴狗一般？',
}

os__liechi:addEffect(fk.Damaged, {
  global = false,
  anim_type = "masochism",
  frequency = Skill.Compulsory,

  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__liechi.name) and not player.dead and data.from ~= nil and data.from.hp >= player.hp and not data.from.dead
  end,

  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    local choices = {}

    if from:getHandcardNum() > player:getHandcardNum() then table.insert(choices, "os__liechi_same") end
    if not from:isNude() then table.insert(choices, "os__liechi_one") end

    if player:getMark("_os__liechi_dying-turn") > 0 and 
      table.find(player:getCardIds{Player.Equip, Player.Hand}, function(id) return Fk:getCardById(id).type == Card.TypeEquip and not player:prohibitDiscard(Fk:getCardById(id)) end) then
      table.insert(choices, "beishui_os__liechi")
    end

    if #choices == 0 then return false end

    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__liechi.name
    })

    if choice == "beishui_os__liechi" then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        pattern = ".|.|.|.|.|equip",
        skill_name = os__liechi.name
      })
    end

    if choice ~= "os__liechi_one" then
      local n = from:getHandcardNum() - player:getHandcardNum()

      if n > 0 then
        room:askToDiscard(from, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = os__liechi.name
        })
      end
    end

    if choice ~= "os__liechi_same" and not from:isNude() then
      local card = room:askToChooseCard(player, {
        target = from,
        flag = "he",
        skill_name = os__liechi.name
      })
      room:throwCard(card, os__liechi.name, from, player)
    end
  end,
})

os__liechi:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,

  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__liechi_dying-turn", 1)
  end,
})

return os__liechi
